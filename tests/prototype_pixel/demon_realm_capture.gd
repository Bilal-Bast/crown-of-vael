extends SceneTree

const CAPTURE_DIR := "res://.godot/prototype_pixel_captures"
const SMALL := Vector2i(360, 640)
const LARGE := Vector2i(1080, 1920)
const MIXED := ["Lesser Demon", "Demon Archer", "Hellhound", "Demon Knight", "Infernal Mage", "Corrupted Giant", "Demon Champion"]
var main: Control
var battle: BattleController
var field: Battlefield
var failures := 0

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/demon_realm_capture.save")
	call_deferred("_run")

func _run() -> void:
	if root.get_texture() == null:
		push_error("Demon Realm capture requires a graphical renderer; --headless has no capturable viewport.")
		quit(2)
		return
	if not _check_user_logs_writable():
		quit(2)
		return
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
	profile.save_path = "res://.godot/demon_realm_capture.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	profile.region = 10
	profile.stage = 1
	profile.selected_hero_id = "knight"
	profile.heroes["knight"].evolution = 0
	battle.region = 10
	battle.stage = 1
	battle.wave = 1
	battle.mode_config = {"mode": "campaign"}
	battle.start(profile)
	battle.active = false
	main.call("_select_tab", "Battle")
	for popup in ["tutorial_popup", "offline_popup", "login_popup"]:
		var node = main.get(popup)
		if node is Window or node is Control: node.hide()

	_set_enemies(["Lesser Demon"]); _attack(0); await _capture("demon_realm_lesser_demon_attack_360", SMALL)
	_set_enemies(["Demon Archer"]); _enemy_attack(0); await _capture("demon_realm_archer_projectile_360", SMALL)
	_set_enemies(["Hellhound"]); _attack(0); await _capture("demon_realm_hellhound_attack_360", SMALL)
	_set_enemies(["Demon Knight"]); _attack(0); await _capture("demon_realm_demon_knight_attack_360", SMALL)
	_set_enemies(["Infernal Mage"]); _enemy_attack(0); await _capture("demon_realm_infernal_mage_projectile_360", SMALL)
	_set_enemies(["Corrupted Giant"]); _attack(0); await _capture("demon_realm_corrupted_giant_attack_360", SMALL)
	_set_enemies(["Demon Champion"]); _attack(0); await _capture("demon_realm_demon_champion_attack_360", SMALL)
	_set_enemies(["Infernal Reaper"]); _attack(0); await _capture("demon_realm_infernal_reaper_attack_360", SMALL)
	_set_enemies(["Demon Lord"], true, true); await _capture("demon_realm_demon_lord_entrance_360", SMALL)
	_set_enemies(["Demon Lord"], false, true); _attack(0); await _capture("demon_realm_demon_lord_attack_360", SMALL)
	_set_enemies(["Demon Lord"], false, true); field._on_damage_popup(0, 99, false, false); await _capture("demon_realm_demon_lord_hit_360", SMALL)
	_set_enemies(["Demon Lord"], false, true); battle.enemies[0].current_hp = 0; field._on_enemy_defeated(0, 0, 0); field.deaths[0]["age"] = 0.35; await _capture("demon_realm_demon_lord_death_360", SMALL)
	_set_enemies(MIXED); await _capture("demon_realm_mixed_seven_enemy_360", SMALL)
	_set_enemies(MIXED); field.hero_run_time = 1.0; await _capture("demon_realm_hero_run_360", SMALL)
	_set_enemies(MIXED); await _capture("demon_realm_battle_overview_1080", LARGE)
	_set_enemies(["Demon Lord"], false, true); await _capture("demon_realm_demon_lord_boss_overview_1080", LARGE)
	main.queue_free()
	print("DEMON REALM CAPTURES: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _set_enemies(kinds: Array, entering := false, boss := false) -> void:
	battle.enemies.clear()
	battle.stage = 20 if boss else 1
	for kind in kinds:
		var enemy := CampaignData.enemy_stats(str(kind), 0, 10, battle.stage, 1)
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
	field.enemy_attack_times[index] = field.enemy_attack_art_durations[index] + 0.8
	field._process(0.0)

func _enemy_attack(index: int) -> void:
	field._on_attack_started(index, -1)
	field.enemy_attack_times[index] = field.enemy_attack_art_durations[index] + 0.8
	if not field.vfx.projectiles.is_empty():
		field.vfx.projectiles[0]["age"] = 0.12
		field.vfx.projectiles[0]["life"] = 0.8
	field._process(0.0)

func _capture(name: String, resolution: Vector2i) -> void:
	DisplayServer.window_set_size(resolution)
	for _i in 3: await process_frame
	var battlefield_host := main.get("battlefield_host") as Control
	if battlefield_host == null or absf(battlefield_host.custom_minimum_size.y - main.get_viewport_rect().size.y * 0.30) > 2.0:
		failures += 1
		push_error("Battlefield no longer occupies the top 30 percent: " + name)
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		failures += 1
		push_error("Viewport returned no capturable image: " + name)
		return
	if image.get_size() != resolution:
		failures += 1
		push_error("Unexpected capture dimensions: " + name)
	if image.save_png("%s/%s.png" % [CAPTURE_DIR, name]) != OK:
		failures += 1
		push_error("Capture failed: " + name)
	print("Captured " + name)

func _check_user_logs_writable() -> bool:
	var logs_dir := OS.get_user_data_dir().path_join("logs")
	if DirAccess.make_dir_recursive_absolute(logs_dir) != OK and not DirAccess.dir_exists_absolute(logs_dir):
		push_error("Cannot create user://logs for capture runtime: " + logs_dir)
		return false
	var check_path := logs_dir.path_join("capture_write_check.tmp")
	var check_file := FileAccess.open(check_path, FileAccess.WRITE)
	if check_file == null:
		push_error("user://logs is not writable: " + logs_dir)
		return false
	check_file.store_string("ok")
	check_file.close()
	DirAccess.remove_absolute(check_path)
	return true
