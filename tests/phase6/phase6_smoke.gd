extends SceneTree

const Debug = preload("res://tests/phase6/phase6_debug.gd")
const TEST_SAVE := "res://.godot/phase6_smoke.save"
var failed := false
var finished := {}
var procs: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _assert(value: bool, label: String) -> void:
	if value:
		print("PASS: ", label)
	else:
		failed = true
		push_error("FAIL: " + label)

func _capture(result: Dictionary) -> void:
	finished = result

func _proc(label: String, _color: Color) -> void:
	procs.append(label)

func _clear_wave(battle: BattleController) -> void:
	var wave_number := battle.wave
	for index in battle.enemies.size():
		if battle.wave != wave_number or not battle.active:
			break
		if float(battle.enemies[index]["current_hp"]) > 0.0:
			battle._hit_enemy(index, 100000, false, false)

func _run() -> void:
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"phase5_version": 1, "stage": 6, "gold": 500, "gems": 42, "level": 4, "evolution_crests": 3, "artifacts": {"dragon_fang": {"rarity": 2, "level": 1, "duplicates": 0}, "dragon_eye": {"rarity": 2, "level": 1, "duplicates": 0}, "dragon_heart": {"rarity": 2, "level": 1, "duplicates": 0}}, "equipped_artifact_slots": ["dragon_fang", "dragon_eye", "", "", "", ""]}))
	file.close()
	var profile := SaveData.load_from(TEST_SAVE)
	_assert(profile.stage == 6 and profile.gold == 500 and profile.gems == 42 and profile.evolution_crests == 3 and profile.artifact_slot_limit() == 2 and profile.hero_pieces == 0, "Phase 5 save migration and Slot 3 locked")
	_assert(not profile.equip_artifact("dragon_heart", 2), "Slot 3 blocked before Tower Floor 20")
	var service := PveService.new(profile)
	service.refresh_day("2026-01-01")
	_assert(PveData.DUNGEONS.size() == 6 and PveData.unlocked_tier(profile) == 3 and profile.unlocked_dungeon_tier == 3, "Six dungeons and campaign tier unlocks")
	profile.stage = 2
	_assert(service.can_start({"mode": "dungeon", "dungeon": "gold", "tier": 3}), "Dungeon tier stays unlocked after campaign stage loss")
	profile.stage = 6
	for id in PveData.DUNGEONS:
		_assert(int(profile.dungeon_attempts[id]["remaining"]) == 2, "%s has two attempts" % id)
		var run := service.begin({"mode": "dungeon", "dungeon": id, "tier": 1})
		_assert(not run.is_empty() and int(profile.dungeon_attempts[id]["remaining"]) == 1, "%s attempt begins and deducts once" % id)
		var result := service.complete(run, {"won": true, "progress": 3, "time": 12.5, "kills": 9, "damage": 200})
		_assert(int(result["reward"][str({"gold": "gold", "exp": "exp", "equipment": "enhancement_stones", "companions": "companion_essence", "artifacts": "artifact_dust", "hero_trial": "hero_pieces"}[id])]) > 0, "%s reward type" % id)
		if id == "equipment":
			_assert(result["equipment"].size() == 1 and profile.inventory.has(result["equipment"][0]), "Equipment Dungeon adds inventory reward")
		if id == "hero_trial":
			_assert(profile.evolution_crests > 3 and profile.hero_pieces > 0, "Hero Trial materials persist")
		_assert(not service.begin({"mode": "dungeon", "dungeon": id, "tier": 4}).size(), "%s locked tier rejected" % id)
	service.refresh_day("2026-01-02")
	_assert(int(profile.dungeon_attempts["gold"]["remaining"]) == 2 and int(profile.boss_rush_state["remaining"]) == 2 and int(profile.endless_state["reward_remaining"]) == 2, "Local day resets independent attempts")
	var battle := BattleController.new()
	root.add_child(battle)
	battle.mode_finished.connect(_capture)
	battle.artifact_proc.connect(_proc)
	var dungeon_run := service.begin({"mode": "dungeon", "dungeon": "gold", "tier": 1})
	battle.start_mode(profile, dungeon_run)
	_assert(battle.enemies.size() == 5 and battle.enemies[0]["kind"] == "Treasure Goblin", "Gold Dungeon enemy configuration")
	for n in 3:
		_clear_wave(battle)
	_assert(not battle.active and bool(finished.get("won", false)) and int(finished.get("progress", 0)) == 3, "Three-wave dungeon clear through shared battle")
	service.complete(dungeon_run, finished)
	var hp1 := float(PveData.wave_enemies({"mode": "tower", "floor": 1}, 1)[0]["hp"])
	var hp100 := float(PveData.wave_enemies({"mode": "tower", "floor": 100}, 1)[0]["hp"])
	_assert(hp100 > hp1 and PveData.wave_enemies({"mode": "tower", "floor": 10}, 1)[0]["kind"] == "Tower Warden", "Tower scales to 100 floors and bosses every ten")
	var tower_run := service.begin({"mode": "tower", "floor": 1})
	battle.start_mode(profile, tower_run)
	_clear_wave(battle)
	var first := service.complete(tower_run, finished)
	_assert(profile.tower_highest == 1 and first["first_clear"] and int(first["reward"]["gems"]) > 0, "Tower first clear progresses and rewards")
	var replay := service.complete(service.begin({"mode": "tower", "floor": 1}), {"won": true, "progress": 1})
	_assert(not replay["first_clear"] and int(replay["reward"]["gems"]) == 0, "Tower first-clear rewards cannot duplicate")
	Debug.set_tower_floor(profile, 19)
	var floor20 := service.begin({"mode": "tower", "floor": 20})
	var floor20_result := service.complete(floor20, {"won": true, "progress": 1})
	_assert(floor20_result["first_clear"] and int(floor20_result["reward"]["gems"]) >= 11 and int(floor20_result["reward"]["evolution_crests"]) == 1 and profile.artifact_slot_limit() == 3 and profile.equip_artifact("dragon_heart", 2), "Floor 20 milestone chest unlocks artifact Slot 3")
	_assert(ArtifactData.set_count("dragon_relics", profile.equipped_artifact_slots) == 3 and float(profile.hero_stats().get("fire_burst_bonus", 0.0)) >= 0.5, "Dragon Relics three-piece burst bonus active")
	battle.start_mode(profile, {"mode": "tower", "floor": 20})
	battle.enemies[0]["current_hp"] = 100000.0
	for attack in 20:
		battle.artifact_runtime.on_hero_attack(battle, 0, 100, false)
	var set_burst := 100000.0 - float(battle.enemies[0]["current_hp"])
	profile.unequip_artifact(0)
	battle.refresh_hero_stats()
	battle.artifact_runtime.start()
	battle.enemies[0]["current_hp"] = 100000.0
	for attack in 20:
		battle.artifact_runtime.on_hero_attack(battle, 0, 100, false)
	var plain_burst := 100000.0 - float(battle.enemies[0]["current_hp"])
	_assert(set_burst > plain_burst and plain_burst > 0.0 and procs.has("FIRE BURST • SET"), "Dragon Relics three-piece increases live fire damage and proc feedback")
	profile.equip_artifact("dragon_fang", 0)
	profile.save()
	var loaded := SaveData.load_from(TEST_SAVE)
	_assert(loaded.tower_highest == 20 and loaded.artifact_slot_limit() == 3 and loaded.equipped_artifact_slots[2] == "dragon_heart" and loaded.hero_pieces > 0 and int(loaded.dungeon_attempts["gold"]["remaining"]) == 1, "Phase 6 progress and materials save/load")
	var rush_run := service.begin({"mode": "boss_rush"})
	battle.start_mode(profile, rush_run)
	_assert(battle.enemies.size() == 1 and battle.enemies[0]["kind"] == "Goblin Warlord", "Boss Rush starts with Warlord")
	battle.hero_hp = float(battle.hero["hp"]) * 0.5
	_clear_wave(battle)
	_assert(battle.wave == 2 and battle.hero_hp > float(battle.hero["hp"]) * 0.5 and battle.hero_hp < float(battle.hero["hp"]), "Boss Rush carries HP and heals between bosses")
	for n in 4:
		_clear_wave(battle)
	var rush_result := service.complete(rush_run, finished)
	_assert(int(finished["progress"]) == 5 and int(rush_result["reward"]["gems"]) >= 15 and profile.boss_rush_state["full_clear"] and int(profile.boss_rush_state["best_boss"]) == 5, "Five-boss full clear and bonus rewards")
	var endless_run := service.begin({"mode": "endless"})
	battle.start_mode(profile, endless_run)
	for n in 3:
		_clear_wave(battle)
	_assert(battle.active and battle.wave == 4 and float(PveData.scale({"mode": "endless"}, 4)["hp"]) > float(PveData.scale({"mode": "endless"}, 1)["hp"]), "Endless waves advance without cap")
	battle._lose(false)
	var endless_result := service.complete(endless_run, finished)
	_assert(not battle.active and int(profile.endless_state["best_wave"]) == 4 and int(endless_result["reward"]["gold"]) > 0, "Endless death records best wave and eligible reward")
	var second := service.begin({"mode": "endless"})
	service.complete(second, {"won": false, "progress": 1})
	var practice := service.begin({"mode": "endless"})
	var before_gold := profile.gold
	var practice_result := service.complete(practice, {"won": false, "progress": 10})
	_assert(not practice["rewarded"] and int(practice_result["reward"]["gold"]) == 0 and profile.gold == before_gold and int(profile.endless_state["best_wave"]) == 10, "Practice continues after two rewarded runs without rewards")
	_assert(service.begin({"mode": "boss_rush"}).size() > 0 and service.begin({"mode": "boss_rush"}).is_empty(), "Boss Rush two attempts per day")
	loaded = SaveData.load_from(TEST_SAVE)
	_assert(int(loaded.boss_rush_state["best_boss"]) == 5 and loaded.boss_rush_state["full_clear"] and int(loaded.endless_state["best_wave"]) == 10 and int(loaded.endless_state["reward_remaining"]) == 0, "Boss Rush and Endless records persist")
	Debug.grant_materials(profile, 2, 3)
	_assert(profile.hero_pieces >= 3, "Debug-only material helper")
	print("PHASE 6 SMOKE: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
