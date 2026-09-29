extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase6_visual.save"
	var adventure := main.get("adventure_screen") as AdventureScreen
	(main.get("battle") as BattleController).start_mode(profile, {"mode": "tower", "floor": 1})
	main.call("_refresh_ui")
	await _capture(main, "battle")
	(main.get("battle") as BattleController).active = false
	for view in ["hub", "dungeons", "tiers", "tower", "boss_rush", "endless", "result"]:
		adventure.view = view
		if view == "result":
			adventure.last_run = {"mode": "dungeon", "dungeon": "equipment", "tier": 2}
			adventure.last_result = {"won": true, "time": 24.6, "kills": 9, "damage": 870, "reward": {"gold": 40, "enhancement_stones": 4}, "equipment": [EquipmentData.create_item("steel_sword", 1)]}
		adventure.refresh()
		main.call("_select_tab", "Adventure")
		await _capture(main, view)
	profile.tower_highest = 20
	profile.artifact_slot3_unlocked = true
	for id in ["dragon_fang", "dragon_eye", "dragon_heart"]:
		profile.add_artifact_copy(id, 4)
	for index in 3:
		profile.equip_artifact(["dragon_fang", "dragon_eye", "dragon_heart"][index], index)
	main.call("_select_tab", "Artifacts")
	await _capture(main, "artifact_slot3")
	(main.get("battle") as BattleController).start_mode(profile, {"mode": "tower", "floor": 20})
	main.call("_select_tab", "Battle")
	await _capture(main, "battle_slot3")
	quit()

func _capture(main: Control, name: String) -> void:
	for resolution in [Vector2i(360, 640), Vector2i(1080, 1920)]:
		DisplayServer.window_set_size(resolution)
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image.get_size() != resolution:
			push_error("Capture size mismatch: %s %s" % [name, resolution])
			quit(1)
			return
		var file := "res://.godot/phase6_%s_%d.png" % [name, resolution.x]
		if image.save_png(file) != OK:
			push_error("Capture failed: " + file)
			quit(1)
			return
		print("Captured ", name, " ", resolution)
