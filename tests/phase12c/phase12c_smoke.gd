extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error("PHASE 12C: " + label)

func _run() -> void:
	var audio_script := load("res://scripts/systems/audio_service.gd")
	var audio = audio_script.new()
	root.add_child(audio)
	check(not audio.play_event("unknown_test_event"), "missing audio mapping remains silent")
	check(not audio.play_event("sword_swing"), "missing combat SFX remains silent")
	audio.set_music("boss")
	check(audio.active_music == -1, "missing boss music remains silent")
	var settings := {"master": 0.4, "music": 0.3, "sfx": 0.6, "ui": 0.5, "muted": false}
	audio.apply_settings(settings)
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")) - linear_to_db(0.4)) < 0.02, "master volume applies")
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")) - linear_to_db(0.6)) < 0.02, "SFX volume applies")
	settings["muted"] = true
	audio.apply_settings(settings)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "mute applies")
	settings["muted"] = false
	audio.apply_settings(settings)
	audio.queue_free()

	var save_path := "res://.godot/phase12c_smoke_settings.save"
	var profile := SaveData.new()
	profile.save_path = save_path
	profile.audio_settings = {"master": 0.4, "music": 0.3, "sfx": 0.6, "ui": 0.5, "muted": true}
	profile.reduced_effects = true
	profile.save()
	var loaded := SaveData.load_from(save_path)
	check(is_equal_approx(float(loaded.audio_settings["sfx"]), 0.6) and bool(loaded.audio_settings["muted"]), "audio settings persist")
	check(loaded.reduced_effects, "reduced effects setting persists")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	var vfx := CombatVfxService.new()
	vfx.pulse(Vector2.ZERO, Color.WHITE)
	vfx.label(Vector2.ZERO, "12", Color.WHITE)
	vfx.projectile(Vector2.ZERO, Vector2(100, 0), Color("a9e9e3"))
	check(vfx.effects.size() == 1 and vfx.labels.size() == 1 and vfx.projectiles.size() == 1, "bounded VFX queues accept transient effects")
	vfx.tick(1.0)
	check(vfx.effects.is_empty() and vfx.labels.is_empty() and vfx.projectiles.is_empty(), "effects, projectiles and labels clean up")
	var idle := EnemyArtService.texture_for("Goblin", "idle")
	check(EnemyArtService.presentation_texture_for("Goblin", "attack") == idle, "missing attack retains real idle enemy art")
	check(EnemyArtService.presentation_texture_for("Goblin", "hit") == idle, "missing hit retains real idle enemy art")

	profile.region = 1
	profile.stage = 20
	var battle := BattleController.new()
	var field := Battlefield.new()
	field.set_battle(battle)
	battle.start(profile)
	var initial_boss_timer := battle.boss_time
	var initial_run_time := battle.run_time
	field._on_presentation_event("boss_intro", {"name": "Test Boss"})
	field.vfx.tick(0.2)
	check(battle.active and is_equal_approx(battle.boss_time, initial_boss_timer) and is_equal_approx(battle.run_time, initial_run_time), "boss VFX does not change combat timers")
	check(field.vfx.boss_banner_time > 0.0, "boss entrance cue stays brief and visible")
	field.free()
	battle.free()

	check(SummonData.COSTS == {1: 100, 10: 900, 50: 4250} and SummonData.PITY_LIMIT == 100, "summon costs and pity limit remain unchanged")
	check(SummonData.rarity_weights(1) == [7400, 2000, 500, 90, 10, 0, 0, 0], "summon rarity table remains unchanged")
	check(HeroData.evolution_cost("knight", 0) == {"level": 20, "crests": 10, "gold": 5000}, "Knight evolution requirement remains unchanged")
	print("PHASE 12C SMOKE: ", "FAIL (%d)" % failures if failures else "PASS")
	quit(1 if failures else 0)
