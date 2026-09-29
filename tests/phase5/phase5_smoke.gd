extends SceneTree

const Debug = preload("res://tests/phase5/phase5_debug.gd")
const TEST_SAVE := "res://.godot/phase5_smoke.save"
var failed := false
var companion_hits: Array[int] = []
var procs: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var old := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	old.store_string(JSON.stringify({"phase4_version": 1, "stage": 4, "gold": 300, "gems": 33, "level": 5, "exp": 12, "banners": {"equipment": {"level": 3, "exp": 7, "pity": 41, "free_day": "2026-01-01", "ad_day": "", "ad_count": 0}}, "skills": {"shield_bash": {"level": 2, "duplicates": 1, "rarity": 1}}, "equipped_skill_slots": ["shield_bash", "", "", ""]}))
	old.close()
	var profile := SaveData.load_from(TEST_SAVE)
	_assert(profile.stage == 4 and profile.level == 5 and profile.gems == 33 and profile.inventory.size() == 7 and profile.skills["shield_bash"]["level"] == 2, "Phase 4 progress preserved")
	_assert(profile.banners["equipment"]["pity"] == 41 and profile.banners["companions"]["level"] == 1 and profile.banners["artifacts"]["pity"] == 0 and profile.companions.is_empty() and profile.artifacts.is_empty(), "Phase 5 migration defaults")
	for level in 10:
		var table := SummonData.rarity_weights(level + 1, "artifacts")
		var sum := 0
		for value in table:
			sum += int(value)
		_assert(sum == 10000 and int(table[0]) == 0 and int(table[1]) == 0, "Artifact rarity table level %d" % (level + 1))
	_assert(int(SummonData.rarity_weights(10, "artifacts")[4]) < int(SummonData.rarity_weights(10, "equipment")[4]), "Artifact Legendary rate lower")
	var service := SummonService.new(profile)
	_assert(service.summon("companions", 1).is_empty() and service.summon("artifacts", 1).is_empty(), "Insufficient Gems rejected")
	Debug.grant_currency(profile, 100000, 1000, 20, 1000, 10000)
	seed(8517)
	for banner in ["companions", "artifacts"]:
		var gems_before := profile.gems
		_assert(service.summon(banner, 1).size() == 1 and profile.gems == gems_before - 100, "%s 1x cost" % banner)
		gems_before = profile.gems
		_assert(service.summon(banner, 10).size() == 10 and profile.gems == gems_before - 900, "%s 10x cost" % banner)
		gems_before = profile.gems
		_assert(service.summon(banner, 50).size() == 50 and profile.gems == gems_before - 4250, "%s 50x cost" % banner)
		_assert(int(profile.banners[banner]["level"]) > 1 and int(profile.banners[banner]["pity"]) == 61, "%s level and pity progress" % banner)
		_assert(service.summon(banner, 1, "daily", "2026-09-28").size() == 1 and service.summon(banner, 1, "daily", "2026-09-28").is_empty(), "%s daily free" % banner)
		for i in SummonData.AD_DAILY_LIMIT:
			_assert(service.summon(banner, 1, "ad", "2026-09-28").size() == 1, "%s simulated ad %d" % [banner, i])
		_assert(service.summon(banner, 1, "ad", "2026-09-28").is_empty(), "%s ad cap" % banner)
		profile.banners[banner]["pity"] = 99
		var guaranteed := service.summon(banner, 1, "daily", "2026-09-29")
		_assert(guaranteed.size() == 1 and int(guaranteed[0]["rarity"]) >= 4 and int(profile.banners[banner]["pity"]) == 0, "%s 100th Legendary pity" % banner)
	_assert(int(profile.banners["equipment"]["pity"]) == 41 and int(profile.banners["skills"]["pity"]) == 0, "Four independent banner counters")
	_assert(profile.companions.size() >= 4 and profile.artifacts.size() >= 4 and profile.companion_essence > 1000 and profile.artifact_dust > 1000, "Summon ownership and materials")
	var wolf_was_owned := profile.companions.has("wolf")
	Debug.grant_companion_copies(profile, "wolf", 1 if not wolf_was_owned else 0)
	var wolf: Dictionary = profile.companions["wolf"]
	var wolf_attack := CompanionData.attack("wolf", wolf)
	var wolf_passive := CompanionData.passive_value("wolf", wolf)
	Debug.grant_companion_copies(profile, "wolf", 5)
	_assert(profile.star_companion("wolf") and wolf["stars"] == 2 and CompanionData.attack("wolf", wolf) > wolf_attack and CompanionData.passive_value("wolf", wolf) > wolf_passive, "Companion pieces and star growth")
	wolf["level"] = 4
	_assert(profile.level_companion("wolf") and wolf["level"] == 5, "Companion Essence and Gold leveling")
	_assert(profile.evolve_companion("wolf") and CompanionData.display_name("wolf", wolf) == "Dire Wolf", "Wolf first evolution")
	Debug.grant_companion_copies(profile, "wolf", 10)
	_assert(profile.star_companion("wolf"), "Wolf third star")
	wolf["level"] = 10
	_assert(profile.evolve_companion("wolf") and CompanionData.display_name("wolf", wolf) == "Shadow Wolf", "Wolf second evolution")
	Debug.grant_companion_copies(profile, "wolf", 20)
	_assert(profile.star_companion("wolf"), "Wolf fourth star")
	wolf["level"] = 20
	_assert(profile.evolve_companion("wolf") and CompanionData.display_name("wolf", wolf) == "Fenrir", "Wolf final evolution")
	for id in ["fairy", "young_dragon", "griffin"]:
		if not profile.companions.has(id):
			Debug.grant_companion_copies(profile, id, 1)
	var base_power := profile.power()
	for index in 4:
		_assert(profile.equip_companion(["wolf", "fairy", "young_dragon", "griffin"][index], index), "Companion slot %d" % index)
	_assert(profile.equipped_companion_slots.size() == 4 and profile.power() > base_power and float(profile.hero_stats()["skill_damage"]) > 0.0, "Four active companions and live passives add Power")
	var four_companion_power := profile.power()
	_assert(profile.unequip_companion(3) and profile.power() < four_companion_power and profile.equip_companion("griffin", 3), "Companion unequip and re-equip updates Power")
	var battle := BattleController.new()
	root.add_child(battle)
	profile.stage = 1
	battle.companion_attack.connect(_on_companion_attack)
	battle.artifact_proc.connect(_on_artifact_proc)
	battle.start(profile)
	_assert(float(battle.hero["skill_damage"]) > 0.0 and float(battle.hero["speed"]) > 1.4, "Companion passives affect live combat")
	for enemy in battle.enemies:
		enemy["current_hp"] = 100000.0
		enemy["atk"] = 0.0
	battle.hero_attack_time = 1000.0
	battle._process(0.7)
	_assert(companion_hits.size() == 4 and float(battle.enemies[0]["current_hp"]) < 100000.0, "Four companions auto-attack for damage")
	battle.enemies[0]["current_hp"] = 0.0
	for id in battle.companion_runtime.timers:
		battle.companion_runtime.timers[id] = 0.0
	battle.companion_runtime.process(0.01, battle)
	_assert(float(battle.enemies[1]["current_hp"]) < 100000.0, "Companions target the next living enemy")
	for id in ArtifactData.ARTIFACTS:
		if not profile.artifacts.has(id):
			Debug.grant_artifact_copies(profile, id, 1)
	var crit_base := float(GameData.hero_stats(profile.level, profile.upgrades, profile.gear_stats())["crit_damage"])
	_assert(float(profile.hero_stats()["crit_damage"]) > float(crit_base), "Artifact owned bonus without equip")
	var artifact_power := profile.power()
	_assert(profile.equip_artifact("blood_crown", 0) and profile.equip_artifact("hourglass_arkon", 1) and not profile.equip_artifact("dragon_heart", 2), "Two active artifact slots and locked slot")
	_assert(profile.power() > artifact_power and battle.artifact_runtime.cooldown_rate(profile) > 1.0, "Equipped effect adds Power and Hourglass recovery")
	battle.refresh_hero_stats()
	battle.skill_runtime.cooldowns["shield_bash"] = 5.0
	battle.skill_runtime.process(1.0, battle)
	_assert(float(battle.skill_runtime.cooldowns["shield_bash"]) < 4.0, "Hourglass accelerates cooldown")
	battle.hero_hp = float(battle.hero["hp"]) * 0.5
	battle.artifact_runtime.on_hero_attack(battle, 0, 100, true)
	_assert(battle.hero_hp > float(battle.hero["hp"]) * 0.5 and procs.has("BLOOD HEAL"), "Blood Crown heals on crit")
	profile.equip_artifact("dragon_heart", 0)
	battle.refresh_hero_stats()
	for enemy in battle.enemies:
		enemy["current_hp"] = 100000.0
	var before_burst := float(battle.enemies[1]["current_hp"])
	battle.artifact_runtime.hero_attacks = 0
	for i in 20:
		battle.artifact_runtime.on_hero_attack(battle, 0, 100, false)
	_assert(float(battle.enemies[1]["current_hp"]) < before_burst and procs.has("FIRE BURST"), "Dragon Heart 20-attack AoE")
	profile.equip_artifact("dragon_fang", 0)
	var one_piece_crit := float(profile.hero_stats()["crit_damage"])
	profile.equip_artifact("dragon_eye", 1)
	var set_two := ArtifactData.equipped_stats(profile.artifacts, profile.equipped_artifact_slots)
	_assert(ArtifactData.set_count("dragon_relics", profile.equipped_artifact_slots) == 2 and float(set_two.get("crit_damage", 0.0)) >= 0.1 and float(profile.hero_stats()["crit_damage"]) > one_piece_crit, "Dragon Relics two-piece bonus affects stats")
	var set_three := ArtifactData.equipped_stats(profile.artifacts, ["dragon_fang", "dragon_eye", "dragon_heart"])
	_assert(float(set_three.get("fire_burst_bonus", 0.0)) >= 0.5, "Generic three-piece set bonus ready for future slot")
	var fang: Dictionary = profile.artifacts["dragon_fang"]
	Debug.grant_artifact_copies(profile, "dragon_fang", 2)
	var owned_before_level := ArtifactData.owned_value("dragon_fang", fang)
	var effect_before_level := ArtifactData.effect_value("dragon_fang", fang)
	_assert(profile.level_artifact("dragon_fang") and int(fang["level"]) == 2 and ArtifactData.owned_value("dragon_fang", fang) > owned_before_level and ArtifactData.effect_value("dragon_fang", fang) > effect_before_level, "Duplicate, Dust and Gold artifact leveling")
	profile.equip_artifact("guardian_sigil", 0)
	battle.artifact_runtime.guard_time = 0.0
	battle.refresh_hero_stats()
	var armor_before := float(battle.hero["armor"])
	battle.artifact_runtime.guard_timer = 0.01
	battle.artifact_runtime.process(0.02, battle)
	_assert(float(battle.hero["armor"]) > armor_before and procs.has("GUARD"), "Guardian periodic defense buff")
	profile.equip_artifact("phoenix_feather", 0)
	battle.artifact_runtime.revive_used = false
	battle.hero_hp = 0.0
	_assert(battle.artifact_runtime.prevent_death(battle) and battle.hero_hp > 0.0 and not battle.artifact_runtime.prevent_death(battle), "Phoenix once-per-battle revive")
	profile.save()
	var restored := SaveData.load_from(TEST_SAVE)
	_assert(restored.companions == profile.companions and restored.artifacts == profile.artifacts and restored.equipped_companion_slots == profile.equipped_companion_slots and restored.equipped_artifact_slots == profile.equipped_artifact_slots, "Companion and artifact save/load")
	_assert(restored.banners == profile.banners and restored.companion_essence == profile.companion_essence and restored.artifact_dust == profile.artifact_dust, "Banner and material save/load")
	_assert(service.summon("equipment", 1).size() == 1 and service.summon("skills", 1).size() == 1, "Existing summon banners still work")
	if not failed:
		print("PASS: Phase 5 migration, four banners, companion progression/combat, artifact bonuses/procs/sets, Power, save/load")
	quit(1 if failed else 0)

func _on_companion_attack(slot: int, _target: int, _amount: int) -> void:
	companion_hits.append(slot)

func _on_artifact_proc(label: String, _color: Color) -> void:
	procs.append(label)

func _assert(valid: bool, name: String) -> void:
	if not valid:
		failed = true
		push_error("FAIL: %s" % name)
