extends SceneTree

const CAPTURE_DIR := "res://.godot/prototype_pixel_captures"
const SMALL := Vector2i(360, 640)
const LARGE := Vector2i(1080, 1920)
const MIXED := ["Shadow Hound", "Shade", "Dark Mage", "Phantom Archer", "Shadow Knight", "Void Spawn", "Void Reaper"]
var main: Control
var battle: BattleController
var field: Battlefield
var failures := 0
var phantom_archer_projectile: Dictionary = {}

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/shadowlands_capture.save")
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.position = Vector2.ZERO
	main.scale = Vector2.ONE
	var profile := main.get("profile") as SaveData
	battle = main.get("battle") as BattleController
	field = main.get("battlefield") as Battlefield
	profile.save_path = "res://.godot/shadowlands_capture.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	profile.region = 8
	profile.stage = 1
	profile.selected_hero_id = "knight"
	profile.heroes["knight"].evolution = 0
	battle.region = 8
	battle.stage = 1
	battle.wave = 1
	battle.mode_config = {"mode": "campaign"}
	battle.start(profile)
	battle.active = false
	main.call("_select_tab", "Battle")
	for popup in ["tutorial_popup", "offline_popup", "login_popup"]:
		var node = main.get(popup)
		if node is Window or node is Control:
			node.hide()
	if "--dark-archer-only" in OS.get_cmdline_user_args():
		_set_enemies(["Phantom Archer"])
		_attack(0)
		await _capture("shadowlands_phantom_archer_arrow_360", SMALL)
		main.queue_free()
		print("PHANTOM ARCHER CAPTURE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
		quit(1 if failures else 0)
		return

	_set_enemies(["Shadow Hound"]); _attack(0); await _capture("shadowlands_shadow_hound_attack_360", SMALL)
	_set_enemies(["Shade"]); _attack(0); await _capture("shadowlands_shade_attack_360", SMALL)
	_set_enemies(["Dark Mage"]); _attack(0); await _capture("shadowlands_dark_mage_attack_360", SMALL)
	_set_enemies(["Phantom Archer"]); _attack(0); await _capture("shadowlands_phantom_archer_arrow_360", SMALL)
	_set_enemies(["Shadow Knight"]); _attack(0); await _capture("shadowlands_shadow_knight_attack_360", SMALL)
	_set_enemies(["Void Spawn"]); _attack(0); await _capture("shadowlands_void_spawn_attack_360", SMALL)
	_set_enemies(["Void Reaper"]); _attack(0); await _capture("shadowlands_void_reaper_360", SMALL)
	_set_enemies(["Shadow Champion"]); _attack(0); await _capture("shadowlands_shadow_champion_360", SMALL)
	_set_enemies(["Lord of Shadows"], false, true); battle.enemies[0].entry_time = 0.25; await _capture("shadowlands_lord_entrance_360", SMALL)
	_set_enemies(["Lord of Shadows"], false, true); _attack(0); await _capture("shadowlands_lord_attack_360", SMALL)
	_set_enemies(["Lord of Shadows"], false, true); battle.enemies[0].current_hp = 0; field._on_enemy_defeated(0, 0, 0); field.deaths[0]["age"] = 0.35; await _capture("shadowlands_lord_death_360", SMALL)
	_set_enemies(MIXED); await _capture("shadowlands_mixed_wave_360", SMALL)
	_set_enemies(MIXED); field.hero_run_time = 1.0; await _capture("shadowlands_hero_run_360", SMALL)
	_set_enemies(MIXED); await _capture("shadowlands_battle_overview_1080", LARGE)
	_set_enemies(["Lord of Shadows"], false, true); await _capture("shadowlands_lord_boss_overview_1080", LARGE)
	main.queue_free()
	print("SHADOWLANDS CAPTURES: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _set_enemies(kinds: Array, entering := false, boss := false) -> void:
	battle.enemies.clear()
	battle.stage = 20 if boss else 1
	for kind in kinds:
		var enemy = CampaignData.enemy_stats(str(kind), 0, 8, battle.stage, 1)
		enemy.current_hp = enemy.hp
		enemy.attack_time = 3.0
		enemy.stun_time = 0.0
		enemy.spawned = true
		enemy.entry_time = 0.25 if entering else 0.0
		battle.enemies.append(enemy)
	field.enemy_attack_times.clear()
	field.enemy_hit_times.clear()
	field.enemy_attack_art_durations.clear()
	field.enemy_hit_art_durations.clear()
	field.deaths.clear()
	field.vfx.projectiles.clear()
	field.hero_run_time = 0.0
	battle.changed.emit()

func _attack(index: int) -> void:
	field.vfx.projectiles.clear()
	field.vfx.labels.clear()
	field.vfx.effects.clear()
	field._on_attack_started(index, -1)
	var kind := str(battle.enemies[index].get("visual", ""))
	var fps := PixelBattleArt.animation_fps(kind, "attack")
	field.enemy_attack_times[index] = field.enemy_attack_art_durations[index] - minf(2.0, PixelBattleArt.animation_frame_count(kind, "attack") - 1.0) / fps
	field._process(0.0)
	if kind == "Phantom Archer" and not field.vfx.projectiles.is_empty():
		phantom_archer_projectile = field.vfx.projectiles[0].duplicate()

func _stage_phantom_archer_arrow_capture() -> void:
	if phantom_archer_projectile.is_empty():
		failures += 1
		push_error("Phantom Archer capture has no projectile")
		return
	var projectile: Dictionary = phantom_archer_projectile.duplicate()
	var start := Vector2(field.size.x * 0.74, field.size.y * 0.50)
	var finish := Vector2(field.size.x * 0.34, field.size.y * 0.50)
	projectile["from"] = start
	projectile["to"] = finish
	projectile["age"] = float(projectile["life"]) * 0.45
	field.vfx.projectiles.clear()
	field.vfx.projectiles.append(projectile)
	field.queue_redraw()

func _capture(name: String, resolution: Vector2i) -> void:
	DisplayServer.window_set_size(resolution)
	for _i in 3:
		await process_frame
	var battlefield_host := main.get("battlefield_host") as Control
	if battlefield_host == null or absf(battlefield_host.custom_minimum_size.y - main.get_viewport_rect().size.y * 0.30) > 2.0:
		failures += 1
		push_error("Battlefield no longer occupies the top 30 percent: " + name)
	if name == "shadowlands_phantom_archer_arrow_360":
		_stage_phantom_archer_arrow_capture()
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != resolution:
		failures += 1
		push_error("Unexpected capture dimensions: " + name)
	if image.save_png("%s/%s.png" % [CAPTURE_DIR, name]) != OK:
		failures += 1
		push_error("Capture failed: " + name)
	print("Captured " + name)
