extends SceneTree

var failures := 0
var battle: BattleController
var field: Battlefield

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := SaveData.new()
	profile.save_path = "res://.godot/combat_pacing_smoke.save"
	profile.region = 1
	profile.stage = 1
	profile.selected_hero_id = "knight"
	profile.skills["whirlwind_slash"] = {"level": 1, "duplicates": 0, "rarity": 2}
	battle = BattleController.new()
	root.add_child(battle)
	battle.start(profile)
	battle.hero_attack_time = 100.0
	field = Battlefield.new()
	root.add_child(field)
	field.size = Vector2(360, 250)
	field.set_battle(battle)
	await process_frame

	_check(GameData.ENEMIES_PER_WAVE == 7 and is_equal_approx(GameData.ENEMY_ENTRY_INTERVAL, 0.60), "seven normal campaign enemies spawn every 0.60 seconds")
	_check(is_equal_approx(GameData.ENEMY_ENTRY_DURATION, 0.60), "entry travel duration is 0.60 seconds")
	_check(is_equal_approx(float(battle.wave_transition_duration), 1.5) and is_equal_approx(field.hero_run_duration, 1.5), "between-wave hero run remains 1.5 seconds")
	var original_stats := battle.hero.duplicate(true)
	_check(is_equal_approx(float(HeroArtService.metadata(0).scale), 0.675) and is_equal_approx(float(HeroArtService.metadata(0).scale) / 0.90, 0.75), "Squire presentation metadata is 25 percent smaller")
	for state in ["idle", "run", "attack", "guard", "hit"]:
		field.hero_visual_state = state
		field.hero_run_time = 0.5 if state == "run" else 0.0
		field._update_pixel_hero_sprite(field._hero_position(), 0.32)
		_check(is_equal_approx(field.pixel_hero_sprite.scale.x, (370.0 / 256.0) * 0.32 * 0.675), "Squire %s uses the shared reduced sprite scale" % state)
	_check(battle.hero == original_stats, "hero presentation changes do not affect combat stats")

	var entrant := battle.enemies[0]
	entrant["attack_time"] = 0.01
	var hp_before := float(entrant["current_hp"])
	var hero_hp_before := battle.hero_hp
	_check(not battle.is_enemy_combat_ready(0) and field._enemy_position(0).x > field.size.x, "the new enemy starts beyond the battlefield and is not combat-ready")
	battle._hero_attack()
	battle._hit_enemy(0, 100, false, false)
	_check(is_equal_approx(float(entrant["current_hp"]), hp_before), "basic attack and shared damage path cannot hit an off-screen entrant")
	_check(not battle.skill_runtime.cast("shield_bash", battle), "single-target skill has no target while only an entrant is available")
	_check(not battle.skill_runtime.cast("whirlwind_slash", battle), "AoE skill has no target while only an entrant is available")
	battle._process(0.30)
	_check(not battle.is_enemy_combat_ready(0) and field._enemy_position(0).x < field.size.x, "entry movement advances without enabling combat before completion")
	battle._process(0.29)
	_check(is_equal_approx(hero_hp_before, battle.hero_hp), "an entering enemy cannot attack the hero")
	_check(is_equal_approx(float(entrant["attack_time"]), 0.01), "enemy attack timer pauses during entry")
	battle._process(0.02)
	_check(battle.is_enemy_combat_ready(0) and is_equal_approx(field._enemy_position(0).x, 0.42 * field.size.x), "enemy becomes targetable at its visible combat position after the full entry")
	_check(battle.spawned_enemy_count == 2 and not battle.is_enemy_combat_ready(1), "second enemy starts entering as the first finishes independently")

	var ready_hp := float(battle.enemies[0]["current_hp"])
	var later_hp := float(battle.enemies[1]["current_hp"])
	battle.enemies[0]["current_hp"] = 100000.0
	battle.enemies[1]["current_hp"] = 100000.0
	ready_hp = float(battle.enemies[0]["current_hp"])
	later_hp = float(battle.enemies[1]["current_hp"])
	battle._hero_attack()
	_check(float(battle.enemies[0]["current_hp"]) < ready_hp and is_equal_approx(float(battle.enemies[1]["current_hp"]), later_hp), "basic attack selects the visible enemy while the later enemy stays protected")
	ready_hp = float(battle.enemies[0]["current_hp"])
	battle.skill_runtime.cast("whirlwind_slash", battle)
	_check(float(battle.enemies[0]["current_hp"]) < ready_hp and is_equal_approx(float(battle.enemies[1]["current_hp"]), later_hp), "AoE skill damages ready enemies only")

	profile.companions["wolf"] = {"rarity": 0, "level": 1, "stars": 1, "pieces": 0, "evolution": 0}
	profile.equipped_companion_slots[0] = "wolf"
	battle.companion_runtime.sync(profile)
	battle.companion_runtime.timers["wolf"] = 0.0
	ready_hp = float(battle.enemies[0]["current_hp"])
	battle.companion_runtime.process(0.0, battle)
	_check(float(battle.enemies[0]["current_hp"]) < ready_hp and is_equal_approx(float(battle.enemies[1]["current_hp"]), later_hp), "companion selects only a combat-ready enemy")

	profile.artifacts["dragon_heart"] = {"level": 1, "duplicates": 0, "rarity": 0}
	profile.equipped_artifact_slots[0] = "dragon_heart"
	battle.artifact_runtime.hero_attacks = 19
	ready_hp = float(battle.enemies[0]["current_hp"])
	battle.artifact_runtime.on_hero_attack(battle, 0, 1, false)
	_check(float(battle.enemies[0]["current_hp"]) < ready_hp and is_equal_approx(float(battle.enemies[1]["current_hp"]), later_hp), "all-enemies artifact burst skips entrants that are not ready")

	battle.enemies[0]["attack_time"] = 0.01
	battle._process(0.02)
	_check(battle.hero_hp < hero_hp_before, "enemy attack begins after its visible entry completes")
	_check(is_equal_approx(field.hero_run_duration, 1.5), "hero run timing stays unchanged after campaign pacing edits")

	var boss_profile := SaveData.new()
	boss_profile.save_path = "res://.godot/combat_pacing_boss_smoke.save"
	boss_profile.region = 1
	boss_profile.stage = 20
	boss_profile.selected_hero_id = "knight"
	var boss_battle := BattleController.new()
	root.add_child(boss_battle)
	boss_battle.start(boss_profile)
	_check(boss_battle.enemies.size() == 1 and bool(boss_battle.enemies[0]["combat_ready"]), "boss wave remains immediately combat-ready")
	_check(is_equal_approx(float(boss_battle.enemies[0]["entry_time"]), GameData.BOSS_ENTRY_ANIMATION_DURATION) and is_zero_approx(boss_battle.enemy_entry_timer), "boss entry animation and unpaced spawn behavior remain unchanged")
	boss_battle._process(0.1)
	_check(boss_battle.is_enemy_combat_ready(0) and is_equal_approx(float(boss_battle.enemies[0]["entry_time"]), 0.35), "boss entrance animation timer advances without delaying combat")

	battle.active = false
	field.queue_free()
	battle.queue_free()
	boss_battle.active = false
	boss_battle.queue_free()
	print("COMBAT PACING SMOKE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error("Combat pacing smoke: " + description)
