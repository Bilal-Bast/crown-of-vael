extends SceneTree

const CAPTURE_DIR := "res://.godot/prototype_pixel_captures"
const RESOLUTION := Vector2i(360, 640)

var main: Control
var battle: BattleController
var field: Battlefield
var failures := 0

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/combat_pacing_capture.save")
	call_deferred("_run")

func _run() -> void:
	if root.get_texture() == null:
		push_error("Combat pacing capture requires a graphical viewport; do not run with --headless.")
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
	profile.save_path = "res://.godot/combat_pacing_capture.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	profile.region = 1
	profile.stage = 1
	profile.selected_hero_id = "knight"
	profile.heroes["knight"].evolution = 0
	battle.region = 1
	battle.stage = 1
	battle.wave = 1
	battle.mode_config = {"mode": "campaign"}
	battle.start(profile)
	battle.active = false
	main.call("_select_tab", "Battle")
	for popup in ["tutorial_popup", "offline_popup", "login_popup"]:
		var node = main.get(popup)
		if node is Window or node is Control: node.hide()
	DisplayServer.window_set_size(RESOLUTION)
	_set_flow_wave()
	field._on_attack_started(0, -1)
	await _capture("battle_pacing_flow_360x640")
	_set_crowded_wave()
	await _capture("battle_pacing_crowded_seven_360x640")
	main.queue_free()
	print("COMBAT PACING CAPTURES: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _set_flow_wave() -> void:
	battle.enemies.clear()
	var kinds := ["Goblin", "Skeleton", "Corrupted Wolf"]
	for index in kinds.size():
		var enemy := CampaignData.enemy_stats(kinds[index], 0, 1, 1, 1)
		enemy.current_hp = enemy.hp
		enemy.spawned = true
		enemy.combat_ready = index == 0
		enemy.entry_time = 0.0 if index == 0 else GameData.ENEMY_ENTRY_DURATION * (0.5 if index == 1 else 1.0)
		enemy.attack_time = 3.0
		enemy.stun_time = 0.0
		battle.enemies.append(enemy)
	battle.spawned_enemy_count = 3
	field.enemy_attack_times.clear()
	field.enemy_hit_times.clear()
	field.enemy_attack_art_durations.clear()
	field.enemy_hit_art_durations.clear()
	field.deaths.clear()
	field.vfx.projectiles.clear()
	battle.changed.emit()

func _set_crowded_wave() -> void:
	battle.enemies.clear()
	var kinds := CampaignData.wave_kinds(1, 1, 1, false, false)
	for kind in kinds:
		var enemy := CampaignData.enemy_stats(str(kind), 0, 1, 1, 1)
		enemy.current_hp = enemy.hp
		enemy.spawned = true
		enemy.combat_ready = true
		enemy.entry_time = 0.0
		enemy.attack_time = 3.0
		enemy.stun_time = 0.0
		battle.enemies.append(enemy)
	battle.spawned_enemy_count = battle.enemies.size()
	field.enemy_attack_times.clear()
	field.enemy_hit_times.clear()
	field.enemy_attack_art_durations.clear()
	field.enemy_hit_art_durations.clear()
	field.deaths.clear()
	field.vfx.projectiles.clear()
	battle.changed.emit()

func _capture(name: String) -> void:
	for _i in 3: await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.get_size() != RESOLUTION:
		failures += 1
		push_error("Unexpected combat pacing capture size: " + name)
		return
	var path := "%s/%s.png" % [CAPTURE_DIR, name]
	if image.save_png(path) != OK:
		failures += 1
		push_error("Could not save combat pacing capture: " + path)
	else:
		print("Captured " + path)
