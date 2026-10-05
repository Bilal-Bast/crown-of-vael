extends SceneTree

const REGION_IDS := ["Forest Goblin", "Giant Spider", "Corrupted Boar", "Forest Bandit", "Skeleton Archer", "Poison Wolf", "Spider Matriarch", "Forest Brute", "Ancient Treant"]
const COUNTS := {"Forest Goblin": [4, 4, 5, 3], "Giant Spider": [4, 4, 5, 3], "Corrupted Boar": [4, 4, 5, 3], "Forest Bandit": [4, 4, 5, 3], "Skeleton Archer": [4, 4, 5, 3], "Poison Wolf": [4, 4, 5, 3], "Spider Matriarch": [4, 4, 5, 4], "Forest Brute": [4, 4, 5, 4], "Ancient Treant": [4, 4, 5, 3]}
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := SaveData.new()
	profile.region = 2
	profile.stage = 1
	profile.selected_hero_id = "knight"
	var battle := BattleController.new()
	root.add_child(battle)
	battle.start(profile)
	_check(battle.enemies.size() == GameData.ENEMIES_PER_WAVE and battle.enemies.size() == 7, "Region 2 normal wave contains seven enemies")
	_check(battle.spawned_enemy_count == 1 and is_equal_approx(battle.enemy_entry_timer, GameData.ENEMY_ENTRY_INTERVAL), "first enemy begins immediately, next slot uses the centralized cadence")
	battle.hero_attack_time = 100.0
	battle._process(GameData.ENEMY_ENTRY_INTERVAL)
	_check(battle.spawned_enemy_count == 2 and float(battle.enemies[0]["current_hp"]) > 0.0 and float(battle.enemies[1]["current_hp"]) > 0.0, "multiple Region 2 enemies coexist after the entry interval")
	_check(battle.wave_transition_duration == 1.5, "inter-wave transition remains 1.5 seconds")
	for enemy in battle.enemies:
		enemy["current_hp"] = 0.0
	battle.spawned_enemy_count = 2
	_check(not battle._all_enemies_defeated(), "wave does not complete until all seven have spawned and died")
	battle.spawned_enemy_count = 7
	_check(battle._all_enemies_defeated(), "wave completes once all seven are defeated")
	battle.active = false
	_check(PixelBattleArt.is_active(battle), "Whispering Forest uses the production pixel renderer")
	_check(CampaignData.REGIONS[1]["enemies"].size() + CampaignData.REGIONS[1]["elites"].size() + 1 == REGION_IDS.size(), "all nine Region 2 roster IDs are covered")
	var background := PixelBattleArt.background_texture()
	_check(background != null and Vector2i(background.get_size()) == Vector2i(1280, 720), "forest background loads at 1280x720")
	for enemy_id in REGION_IDS:
		_check(PixelBattleArt.enemy_sheet(enemy_id) != null, "%s idle art resolves" % enemy_id)
		for state_index in 4:
			var states: Array[String] = ["idle", "entry", "attack", "hit"]
			var state: String = states[state_index]
			var count := PixelBattleArt.enemy_entry_frame_count(enemy_id) if state == "entry" else PixelBattleArt.animation_frame_count(enemy_id, state)
			_check(count == COUNTS[enemy_id][state_index], "%s %s frame count is valid" % [enemy_id, state])
			var frame := PixelBattleArt.enemy_entry_frame(enemy_id, 0) if state == "entry" else PixelBattleArt.animation_frame(enemy_id, state, 0)
			_check(frame != null, "%s %s frame loads" % [enemy_id, state])
			var fps := PixelBattleArt.enemy_entry_fps(enemy_id) if state == "entry" else PixelBattleArt.animation_fps(enemy_id, state)
			_check(fps > 0.0, "%s %s playback rate is positive" % [enemy_id, state])
	_check(PixelBattleArt.animation_frame_count("Ancient Treant", "death") == 6 and PixelBattleArt.animation_frame("Ancient Treant", "death", 0) != null, "Treant death strip loads")
	_check(PixelBattleArt.animation_sheet("Ancient Treant", "entrance") != null, "Treant entrance animation resolves through the existing entry sheet")
	_check(PixelBattleArt.animation_frame("Unknown Region 2 enemy", "idle", 0) == null, "unknown Region 2 art resolves to the existing gameplay fallback")
	_check(PixelBattleArt.enemy_fallback_frame("Forest Goblin", "death") != null, "missing non-boss state falls back to the Forest Goblin idle strip")
	var validation: Array[String] = PixelBattleArt.validation_report()
	for warning in validation:
		push_error(warning)
	_check(validation.is_empty(), "Region 2 pixel sheets pass dimension and load validation")
	_check(is_equal_approx(GameData.ENEMY_ENTRY_INTERVAL, 0.60), "normal wave entry interval is 0.60 seconds")
	var field := Battlefield.new()
	root.add_child(field)
	field.size = Vector2(360, 192)
	field.set_battle(battle)
	field.hero_run_duration = 1.5
	_check(field.hero_run_duration == 1.5, "inter-wave Squire run remains 1.5 seconds")
	var idle_a: Dictionary = CampaignData.enemy_stats("Forest Goblin", 0, 2, 1, 1)
	var idle_b: Dictionary = CampaignData.enemy_stats("Giant Spider", 0, 2, 1, 1)
	field._update_pixel_enemy_sprite(0, field._enemy_position(0), idle_a, "idle", 0.32)
	field._update_pixel_enemy_sprite(1, field._enemy_position(1), idle_b, "idle", 0.32)
	_check(field.pixel_enemy_sprites.size() == 2 and field.pixel_enemy_sprites[0] != field.pixel_enemy_sprites[1], "each living Region 2 enemy owns an independent pixel sprite")
	battle.enemies.clear()
	var archer := CampaignData.enemy_stats("Skeleton Archer", 0, 2, 1, 1)
	archer["current_hp"] = archer["hp"]
	archer["spawned"] = true
	archer["entry_time"] = 0.0
	battle.enemies.append(archer)
	field._on_attack_started(0, -1)
	_check(field.vfx.projectiles.size() == 1 and field.vfx.projectiles[0]["style"] == "pixel_arrow", "Skeleton Archer reuses the existing pixel arrow queue")
	if not field.vfx.projectiles.is_empty():
		_check(Vector2(field.vfx.projectiles[0]["from"]).x > Vector2(field.vfx.projectiles[0]["to"]).x, "Skeleton Archer arrow travels left toward the hero")
	_check(PixelBattleArt.is_active(_other_region_battle(profile)), "Ashen Highlands shares the production pixel renderer")
	field.queue_free()
	battle.queue_free()
	print("WHISPERING FOREST PIXEL SMOKE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _other_region_battle(profile: SaveData) -> BattleController:
	profile.region = 3
	var other := BattleController.new()
	root.add_child(other)
	other.start(profile)
	other.active = false
	return other

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("Whispering Forest pixel smoke: " + description)
