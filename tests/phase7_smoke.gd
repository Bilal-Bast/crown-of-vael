extends SceneTree

const Debug = preload("res://tests/phase7_debug.gd")
const TEST_SAVE := "res://.godot/phase7_smoke.save"
var failed := false
var hero_hits := 0
var companion_hits := 0

func _initialize() -> void:
	call_deferred("_run")

func _assert(value: bool, label: String) -> void:
	if value:
		print("PASS: ", label)
	else:
		failed = true
		push_error("FAIL: " + label)

func _hero_damage(target: int, _amount: int, _critical: bool, _bash: bool) -> void:
	if target >= 0:
		hero_hits += 1

func _companion_damage(_slot: int, _target: int, _amount: int) -> void:
	companion_hits += 1

func _run() -> void:
	var old := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	old.store_string(JSON.stringify({"phase6_version": 1, "stage": 7, "gold": 1234, "gems": 17, "level": 12, "exp": 9, "hero_pieces": 25, "tower_highest": 20, "artifact_slot3_unlocked": true, "skills": {"shield_bash": {"level": 2, "duplicates": 0, "rarity": 0}}, "equipped_skill_slots": ["shield_bash", "", "", ""]}))
	old.close()
	var profile := SaveData.load_from(TEST_SAVE)
	var progress := HeroProgress.new(profile)
	_assert(profile.selected_hero_id == "knight" and profile.heroes.size() == 5 and profile.heroes["knight"]["unlocked"] and not profile.heroes["mage"]["unlocked"], "Phase 6 migration grants Squire and preserves locked roster")
	_assert(profile.stage == 7 and profile.gold == 1234 and profile.gems == 17 and profile.level == 12 and profile.tower_highest == 20 and profile.artifact_slot_limit() == 3 and profile.skills["shield_bash"]["level"] == 2, "Phase 6 progression preserved")
	_assert(HeroData.HEROES.size() == 5 and HeroData.ELEMENTS.size() == 7 and SkillData.hero_tags("shield_bash").is_empty(), "Launch roster, elements, and future skill tags exist")
	_assert(not progress.select("mage", false), "Locked hero cannot be selected")
	for id in ["mage", "ranger", "assassin", "necromancer"]:
		var requirement := int(HeroData.HEROES[id]["unlock"])
		Debug.grant_hero_pieces(profile, id, requirement - 1)
		_assert(not progress.unlock(id) and not profile.heroes[id]["unlocked"], "%s rejects insufficient unlock pieces" % id)
		Debug.grant_hero_pieces(profile, id, 1)
		_assert(progress.unlock(id) and profile.heroes[id]["unlocked"] and int(profile.heroes[id]["pieces"]) == 0, "%s unlock consumes %d pieces" % [id, requirement])
	_assert(profile.hero_milestones.has("heroes_2") and profile.hero_milestones.has("heroes_5"), "Hero unlock milestones claim once")
	var generic_before := profile.hero_pieces
	_assert(not progress.convert("mage", generic_before / HeroData.CONVERSION_RATE + 1), "Generic conversion rejects insufficient pieces")
	_assert(progress.convert("mage", 2) and profile.hero_pieces == generic_before - HeroData.CONVERSION_RATE * 2 and int(profile.heroes["mage"]["pieces"]) == 2, "Generic pieces convert at centralized rate")
	var mage_owned_before := float(profile.hero_stats()["skill_damage"])
	var star_power_before := profile.power()
	profile.heroes["mage"]["pieces"] = 20
	var mage_active_before := HeroData.passive_scale(profile.heroes["mage"])
	_assert(progress.star_up("mage") and int(profile.heroes["mage"]["stars"]) == 2 and int(profile.heroes["mage"]["pieces"]) == 0 and HeroData.passive_scale(profile.heroes["mage"]) > mage_active_before, "Star 2 consumes 20 pieces and improves passive")
	profile.heroes["mage"]["pieces"] = 40
	_assert(progress.star_up("mage") and int(profile.heroes["mage"]["stars"]) == 3 and profile.hero_milestones.has("hero_star_3"), "Star 3 consumes 40 pieces and awards milestone")
	profile.heroes["mage"]["pieces"] = 80
	_assert(progress.star_up("mage"), "Star 4 consumes 80 pieces")
	profile.heroes["mage"]["pieces"] = 160
	_assert(progress.star_up("mage") and int(profile.heroes["mage"]["stars"]) == 5 and not progress.star_up("mage"), "Star 5 consumes 160 pieces and is the cap")
	_assert(float(profile.hero_stats()["skill_damage"]) > mage_owned_before and profile.power() > star_power_before, "Hero star bonus affects live stats and Power")
	var battle := BattleController.new()
	root.add_child(battle)
	battle.damage_popup.connect(_hero_damage)
	battle.companion_attack.connect(_companion_damage)
	battle.start(profile)
	_assert(not progress.select("mage", battle.active) and profile.selected_hero_id == "knight", "Cannot switch during active battle")
	battle.active = false
	_assert(not progress.select("missing", false) and progress.select("mage", false) and profile.selected_hero_id == "mage", "Unlocked hero switches outside battle; invalid hero rejected")
	profile.save()
	_assert(SaveData.load_from(TEST_SAVE).selected_hero_id == "mage", "Selected non-Knight hero persists")
	var mage_stats := profile.hero_stats()
	_assert(float(mage_stats["skill_damage"]) > 0.30 and float(mage_stats["speed"]) < 1.4, "Mage active skill passive and slow combat identity")
	_assert(progress.select("ranger", false), "Ranger selected")
	var ranger_stats := profile.hero_stats()
	_assert(float(ranger_stats["speed"]) > float(mage_stats["speed"]) and float(ranger_stats["atk"]) < float(profile.hero_stats()["hp"]), "Ranger fast sustained identity")
	_assert(progress.select("assassin", false), "Assassin selected")
	var assassin_stats := profile.hero_stats()
	_assert(float(assassin_stats["crit_chance"]) > float(ranger_stats["crit_chance"]) and float(assassin_stats["crit_damage"]) > float(ranger_stats["crit_damage"]) and float(assassin_stats["hp"]) < float(ranger_stats["hp"]), "Assassin crit burst identity")
	_assert(progress.select("necromancer", false), "Necromancer selected")
	var necro_stats := profile.hero_stats()
	_assert(float(necro_stats["companion_damage"]) > 0.39, "Necromancer active plus owned companion bonuses")
	_assert(progress.select("knight", false), "Knight selected")
	var knight_stats := profile.hero_stats()
	_assert(float(knight_stats["armor"]) > float(mage_stats["armor"]) and float(knight_stats["hp"]) > float(assassin_stats["hp"]), "Knight durability identity")
	_assert(float(knight_stats["skill_damage"]) > 0.0 and float(knight_stats["crit_damage"]) > 1.75 and float(knight_stats["companion_damage"]) > 0.0, "Owned hero bonuses stay active on Knight")
	var requirement_probe := SaveData.new()
	var requirement_progress := HeroProgress.new(requirement_probe)
	requirement_probe.level = 19
	requirement_probe.gold = 5000
	requirement_probe.evolution_crests = 10
	_assert(not requirement_progress.can_evolve("knight"), "Knight evolution requires Hero Level 20")
	requirement_probe.level = 20
	requirement_probe.gold = 4999
	_assert(not requirement_progress.can_evolve("knight"), "Knight evolution requires 5,000 Gold")
	requirement_probe.gold = 5000
	requirement_probe.evolution_crests = 9
	_assert(not requirement_progress.can_evolve("knight"), "Knight evolution requires 10 Evolution Crests")
	var previous_power := profile.power()
	Debug.grant_evolution_resources(profile)
	var expected_names := ["Knight", "Royal Knight", "Paladin", "Divine Paladin"]
	for stage in 4:
		var cost: Dictionary = HeroData.KNIGHT_EVOLUTION[stage]
		var gold_before := profile.gold
		var crests_before := profile.evolution_crests
		var before_stats := profile.hero_stats()
		var event := progress.evolve("knight")
		var reward: Dictionary = HeroData.MILESTONES["evolve_knight_%d" % (stage + 1)]
		_assert(not event.is_empty() and event["next"] == expected_names[stage] and int(profile.heroes["knight"]["evolution"]) == stage + 1, "Knight evolution %d reaches %s" % [stage + 1, expected_names[stage]])
		_assert(profile.gold == gold_before - int(cost["gold"]) and profile.evolution_crests == crests_before - int(cost["crests"]) + int(reward["crests"]), "Evolution %d deducts resources once and grants milestone" % (stage + 1))
		_assert(float(profile.hero_stats()["hp"]) > float(before_stats["hp"]) and profile.power() > previous_power, "Evolution %d increases stats and Power" % (stage + 1))
		previous_power = profile.power()
	_assert(not progress.can_evolve("knight") and progress.evolve("knight").is_empty() and profile.evolution == 4, "Divine Paladin is permanent maximum and cannot downgrade")
	_assert(HeroData.element("knight", {"evolution": 0}) == "Physical" and HeroData.element("knight", profile.heroes["knight"]) == "Holy", "Knight evolution switches Physical to Holy")
	for id in ["mage", "ranger", "assassin", "necromancer"]:
		_assert(HeroData.HEROES[id]["path"].size() == 5 and HeroData.evolution_cost(id, 0).is_empty(), "%s five-stage future evolution path" % id)
	profile.save()
	var loaded := SaveData.load_from(TEST_SAVE)
	_assert(loaded.selected_hero_id == "knight" and loaded.heroes["mage"]["unlocked"] and int(loaded.heroes["mage"]["stars"]) == 5 and int(loaded.heroes["knight"]["evolution"]) == 4 and loaded.hero_milestones.has("evolve_knight_4"), "Selected hero, unlocks, stars, evolution, and milestones persist")
	for id in HeroData.HEROES:
		loaded.selected_hero_id = id
		battle.start(loaded)
		for enemy in battle.enemies:
			enemy["current_hp"] = 100000.0
			enemy["atk"] = 0.0
		battle.hero_attack_time = 0.0
		var before_hits := hero_hits
		battle._process(0.01)
		var ranged: bool = HeroData.HEROES[id]["style"] in ["magic", "arrow", "dark_bolt"]
		_assert(hero_hits == before_hits if ranged else hero_hits > before_hits, "%s %s basic attack starts" % [id, "projectile" if ranged else "melee"])
		if ranged:
			battle._process(0.23)
			_assert(hero_hits > before_hits and battle.pending_hero_hits.is_empty(), "%s projectile travels then hits" % id)
		battle.active = false
	# Necromancer companion multiplier is applied by the shared runtime.
	loaded.selected_hero_id = "necromancer"
	loaded.companions["wolf"] = {"rarity": 0, "level": 1, "stars": 1, "pieces": 0, "evolution": 0}
	loaded.equipped_companion_slots = ["wolf", "", "", ""]
	battle.start(loaded)
	for enemy in battle.enemies:
		enemy["current_hp"] = 100000.0
		enemy["atk"] = 0.0
	battle.hero_attack_time = 1000.0
	var hp_before := float(battle.enemies[0]["current_hp"])
	battle._process(0.7)
	var necro_damage := hp_before - float(battle.enemies[0]["current_hp"])
	loaded.selected_hero_id = "knight"
	battle.start(loaded)
	for enemy in battle.enemies:
		enemy["current_hp"] = 100000.0
		enemy["atk"] = 0.0
	battle.hero_attack_time = 1000.0
	hp_before = float(battle.enemies[0]["current_hp"])
	battle._process(0.7)
	var knight_companion_damage := hp_before - float(battle.enemies[0]["current_hp"])
	_assert(necro_damage > knight_companion_damage and companion_hits >= 2, "Necromancer companion bonus affects shared companion attacks")
	loaded.selected_hero_id = "mage"
	for config in [{"mode": "dungeon", "dungeon": "gold", "tier": 1}, {"mode": "tower", "floor": 1}, {"mode": "boss_rush"}, {"mode": "endless", "rewarded": false}]:
		battle.start_mode(loaded, config)
		_assert(battle.profile.selected_hero_id == "mage" and float(battle.hero["skill_damage"]) > 0.30 and battle.active, "%s uses selected hero and shared combat runtime" % config["mode"])
		battle.active = false
	var trial_profile := SaveData.new()
	trial_profile.save_path = TEST_SAVE
	trial_profile.stage = 7
	var trial_service := PveService.new(trial_profile)
	trial_service.refresh_day("2026-09-28")
	var pieces_before := 0
	for id in ["mage", "ranger", "assassin", "necromancer"]:
		pieces_before += int(trial_profile.heroes[id]["pieces"])
	var trial_run := trial_service.begin({"mode": "dungeon", "dungeon": "hero_trial", "tier": 2})
	var trial_result := trial_service.complete(trial_run, {"won": true, "progress": 3})
	var pieces_after := 0
	for id in ["mage", "ranger", "assassin", "necromancer"]:
		pieces_after += int(trial_profile.heroes[id]["pieces"])
	_assert(pieces_after == pieces_before + 1 and trial_result["reward"].has("hero_piece"), "Hero Trial grants a specific launch-hero piece")
	print("PHASE 7 SMOKE: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
