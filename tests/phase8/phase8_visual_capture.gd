extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase8_visual.save"
	var battle := main.get("battle") as BattleController
	battle.active = false
	var adventure := main.get("adventure_screen") as AdventureScreen
	adventure.view = "campaign"
	main.call("_select_tab", "Adventure")
	await _capture("campaign_overview")
	adventure.view = "map"
	adventure.refresh()
	await _capture("world_map")
	adventure.view = "stages"
	adventure.map_region = 1
	adventure.refresh()
	await _capture("stage_select")
	main.call("_select_tab", "Battle")
	for region in range(1, 11):
		profile.region = region
		profile.stage = 1
		profile.campaign_difficulty = 0
		battle.start(profile)
		main.call("_refresh_ui")
		await _capture("region_%02d" % region)
		battle.active = false
	profile.region = 2
	profile.stage = 5
	battle.start(profile)
	battle.wave = 3
	battle._spawn_wave()
	main.call("_refresh_ui")
	await _capture("elite_stage")
	battle.active = false
	profile.stage = 6
	battle.start(profile)
	battle.force_treasure = true
	battle._spawn_wave()
	main.call("_refresh_ui")
	await _capture("treasure_enemy")
	battle.active = false
	profile.stage = 20
	battle.start(profile)
	main.call("_refresh_ui")
	await _capture("region_boss")
	battle.active = false
	profile.campaign_difficulty = 5
	profile.region = 10
	profile.stage = 19
	battle.start(profile)
	main.call("_refresh_ui")
	await _capture("infernal_variant")
	battle.active = false
	quit()

func _capture(name: String) -> void:
	for resolution in [Vector2i(360, 640), Vector2i(1080, 1920)]:
		DisplayServer.window_set_size(resolution)
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image.get_size() != resolution:
			push_error("Unexpected capture size: %s" % name)
			quit(1)
			return
		var path := "res://.godot/phase8_%s_%d.png" % [name, resolution.x]
		if image.save_png(path) != OK:
			push_error("Capture failed: " + path)
			quit(1)
			return
		print("Captured ", name, " ", resolution)
