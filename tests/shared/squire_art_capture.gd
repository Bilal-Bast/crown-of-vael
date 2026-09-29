extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/squire_art_capture.save"
	profile.last_login_reward_date = CalendarService.day()
	profile.selected_hero_id = "knight"
	profile.heroes["knight"]["evolution"] = 0
	(main.get("battle") as BattleController).active = false
	var battlefield := main.get("battlefield") as Battlefield
	main.call("_select_tab", "Battle")
	await _capture("battle_idle")
	battlefield._on_attack_started(-1, 0)
	await _capture("battle_attack")
	battlefield._on_damage_popup(-1, 10, false, false)
	await _capture("battle_guard")
	var heroes := main.get("heroes_screen") as HeroesScreen
	heroes.selected_id = "knight"
	heroes.view = "detail"
	heroes.refresh()
	main.call("_select_tab", "Heroes")
	await _capture("heroes_portrait")
	print("SQUIRE ART CAPTURE: PASS")
	quit()

func _capture(name: String) -> void:
	for resolution in [Vector2i(360, 640), Vector2i(1080, 1920)]:
		DisplayServer.window_set_size(resolution)
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image.get_size() != resolution:
			push_error("Unexpected capture size: " + name)
			quit(1)
			return
		var path := "res://.godot/squire_art_%s_%d.png" % [name, resolution.x]
		if image.save_png(path) != OK:
			push_error("Capture failed: " + path)
			quit(1)
			return
		print("Captured ", path)
