extends SceneTree

const Debug = preload("res://tests/phase5_debug.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1080, 1920))
	await process_frame
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase5_visual.save"
	Debug.grant_currency(profile, 10000, 200, 4, 100, 1000)
	for id in ["wolf", "fairy", "young_dragon", "griffin"]:
		if not profile.companions.has(id):
			Debug.grant_companion_copies(profile, id, 1, 2)
	for index in 4:
		profile.equip_companion(["wolf", "fairy", "young_dragon", "griffin"][index], index)
	for id in ["dragon_fang", "dragon_eye", "dragon_heart", "blood_crown"]:
		if not profile.artifacts.has(id):
			Debug.grant_artifact_copies(profile, id, 1, 3)
	profile.equip_artifact("dragon_fang", 0)
	profile.equip_artifact("dragon_eye", 1)
	profile.stage = 1
	profile.campaign_complete = false
	(main.get("battle") as BattleController).start(profile)
	main.call("_refresh_ui")
	await _capture("battle")
	main.call("_select_tab", "Companions")
	await _capture("companions")
	(main.get("companions_screen") as CompanionsScreen).call("_select", "wolf")
	await _capture("companions_detail")
	main.call("_select_tab", "Artifacts")
	await _capture("artifacts")
	(main.get("artifacts_screen") as ArtifactsScreen).call("_select", "dragon_fang")
	await _capture("artifacts_detail")
	main.call("_select_tab", "Summon")
	await _capture("summon")
	(main.get("summon_area") as ScrollContainer).scroll_vertical = 1250
	await _capture("summon_lower")
	quit()

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != Vector2i(1080, 1920):
		push_error("Expected 1080x1920 render, got %s." % str(image.get_size()))
		quit(1)
		return
	var large_error := image.save_png("res://.godot/phase5_%s_1080.png" % name)
	DisplayServer.window_set_size(Vector2i(360, 640))
	await process_frame
	await RenderingServer.frame_post_draw
	var small_image := root.get_texture().get_image()
	if small_image.get_size() != Vector2i(360, 640):
		push_error("Expected 360x640 render, got %s." % str(small_image.get_size()))
		quit(1)
		return
	var small_error := small_image.save_png("res://.godot/phase5_%s_360.png" % name)
	DisplayServer.window_set_size(Vector2i(1080, 1920))
	await process_frame
	if large_error != OK or small_error != OK:
		push_error("Could not capture %s." % name)
		quit(1)
	else:
		print("Captured %s at 360x640 and 1080x1920" % name)
