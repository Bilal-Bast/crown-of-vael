extends SceneTree

var failures := 0
var stage_clear_count := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := SaveData.new()
	profile.save_path = "res://.godot/battle_flow_smoke.save"
	profile.stage = 1
	profile.region = 1
	var battle := BattleController.new()
	root.add_child(battle)
	battle.stage_cleared.connect(_on_stage_cleared)
	battle.start(profile)
	_check(GameData.ENEMIES_PER_WAVE == 7, "normal waves are configured for seven enemies")
	_check(battle.enemies.size() == 7 and battle.spawned_enemy_count == 1, "wave starts with one entered enemy")
	_check(bool(battle.enemies[0]["spawned"]) and float(battle.enemies[0]["current_hp"]) > 0.0, "first enemy enters immediately")
	_check(not bool(battle.enemies[1]["spawned"]) and float(battle.enemies[1]["current_hp"]) == 0.0, "remaining enemies wait to enter")
	_check(is_equal_approx(battle.enemy_entry_timer, GameData.ENEMY_ENTRY_INTERVAL), "entry cadence uses the centralized interval")

	var battlefield := Battlefield.new()
	root.add_child(battlefield)
	battlefield.size = Vector2(360.0, 250.0)
	battlefield.set_battle(battle)
	var positions: Array[Vector2] = []
	for index in 7:
		var position := battlefield._enemy_position(index)
		_check(not positions.has(position), "enemy %d has a distinct lane position" % index)
		positions.append(position)
	_check(battlefield._enemy_position(0).x > battlefield.size.x, "first enemy enters from beyond the right edge")

	battle.enemies[0]["current_hp"] = 100000.0
	battle._process(GameData.ENEMY_ENTRY_INTERVAL - 0.01)
	_check(battle.spawned_enemy_count == 1, "entry interval does not spawn enemies early")
	battle._process(0.02)
	_check(battle.spawned_enemy_count == 2, "second enemy enters on the timer")
	_check(float(battle.enemies[0]["current_hp"]) > 0.0, "second enemy can enter while first is alive")
	for expected_count in range(3, GameData.ENEMIES_PER_WAVE + 1):
		battle._process(GameData.ENEMY_ENTRY_INTERVAL + 0.01)
		_check(battle.spawned_enemy_count == expected_count, "enemy %d enters separately" % expected_count)
	_check(battle.spawned_enemy_count == 7, "all seven entered one after another")
	_check(is_zero_approx(battlefield.hero_run_time), "hero does not run while the wave is still active")

	_clear_current_wave(battle)
	_check(battle.wave == 1 and is_equal_approx(battle.wave_transition_time, 1.5), "wave waits for the run transition after all seven die")
	_check(is_equal_approx(battlefield.hero_run_time, 1.5), "hero run starts only after the wave is cleared")
	var hero_run_start_x := battlefield._hero_position().x
	battle._process(0.75)
	battlefield._process(0.75)
	_check(battlefield._hero_position().x > hero_run_start_x, "hero moves right during the transition")
	battle._process(0.74)
	battlefield._process(0.74)
	_check(battle.wave == 1, "next wave does not start before the run completes")
	battle._process(0.02)
	battlefield._process(0.02)
	_check(battle.wave == 2 and battle.spawned_enemy_count == 1, "next wave begins after the run with one enemy entered")
	_check(is_zero_approx(battlefield.hero_run_time), "hero resets when the next wave begins")

	_clear_current_wave(battle)
	battle._process(1.51)
	_check(battle.wave == 3 and battle.spawned_enemy_count == 1, "wave two advances to wave three")
	_clear_current_wave(battle)
	_check(not battle.active and stage_clear_count == 1, "wave three uses normal stage-clear behavior")

	battle.active = false
	field_free(battlefield)
	print("BATTLE FLOW SMOKE: %s (%d failures)" % ["FAIL" if failures else "PASS", failures])
	quit(1 if failures else 0)

func _clear_current_wave(battle: BattleController) -> void:
	for index in battle.enemies.size():
		battle.enemies[index]["spawned"] = true
		battle.enemies[index]["current_hp"] = 0.0
		battle.enemies[index]["armor"] = 0.0
	battle.spawned_enemy_count = battle.enemies.size()
	battle.enemies[0]["current_hp"] = 1.0
	_check(not battle._all_enemies_defeated(), "wave remains incomplete while one entered enemy is alive")
	battle._hit_enemy(0, 1, false, false)

func _on_stage_cleared() -> void:
	stage_clear_count += 1

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("Battle flow smoke: " + message)

func field_free(field: Node) -> void:
	field.queue_free()
