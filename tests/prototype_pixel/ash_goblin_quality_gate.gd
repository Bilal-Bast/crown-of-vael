extends SceneTree

var enemy_id := "Ash Goblin"
var capture_path := ""

var main: Control
var profile: SaveData
var battle: BattleController
var field: Battlefield

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/ash_goblin_quality_gate.save")
	call_deferred("_capture")

func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		enemy_id = args[0]
	var slug := enemy_id.to_lower().replace(" ", "_")
	capture_path = "res://.godot/prototype_pixel_captures/%s_idle_quality_gate_360x640.png" % slug
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.position = Vector2.ZERO
	main.scale = Vector2.ONE
	profile = main.get("profile") as SaveData
	battle = main.get("battle") as BattleController
	field = main.get("battlefield") as Battlefield
	profile.save_path = "res://.godot/ash_goblin_quality_gate.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	profile.region = 3
	profile.stage = 1
	profile.selected_hero_id = "knight"
	profile.heroes["knight"].evolution = 0
	battle.region = 3
	battle.stage = 1
	battle.wave = 1
	battle.mode_config = {"mode": "campaign"}
	battle.start(profile)
	battle.active = false
	main.call("_select_tab", "Battle")
	for popup_name in ["tutorial_popup", "offline_popup", "login_popup"]:
		var popup = main.get(popup_name)
		if popup is Window or popup is Control:
			popup.hide()
	var enemy = CampaignData.enemy_stats(enemy_id, 0, 3, 1, 1)
	enemy.current_hp = enemy.hp
	enemy.attack_time = 30.0
	enemy.stun_time = 0.0
	enemy.spawned = true
	enemy.entry_time = 0.0
	battle.enemies = [enemy]
	battle.changed.emit()
	DisplayServer.window_set_size(Vector2i(360, 640))
	for _i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/prototype_pixel_captures"))
	var result := image.save_png(capture_path)
	print("%s idle quality gate: %s" % [enemy_id, "PASS" if result == OK else "FAIL"])
	quit(0 if result == OK else 1)
