extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase7_visual.save"
	profile.level = 20
	profile.gold = 10000
	profile.evolution_crests = 20
	profile.hero_pieces = 100
	for id in HeroData.HEROES:
		profile.heroes[id]["unlocked"] = id != "necromancer"
		profile.heroes[id]["pieces"] = 18 if id != "necromancer" else 62
		profile.heroes[id]["stars"] = 2 if id != "knight" else 3
	var battle := main.get("battle") as BattleController
	battle.active = false
	var screen := main.get("heroes_screen") as HeroesScreen
	screen.view = "roster"
	screen.refresh()
	main.call("_select_tab", "Heroes")
	await _capture("heroes_roster")
	screen.selected_id = "mage"
	screen.view = "detail"
	screen.refresh()
	await _capture("hero_detail")
	screen.selected_id = "necromancer"
	screen.view = "detail"
	screen.refresh()
	await _capture("hero_locked")
	screen.selected_id = "knight"
	screen.view = "detail"
	screen.refresh()
	(main.get("heroes_area") as ScrollContainer).scroll_vertical = 620
	await _capture("hero_evolution_path")
	profile.heroes["knight"]["evolution"] = 1
	screen.evolution_result = {"previous": "Squire", "next": "Knight", "element": "Physical", "before_stats": {"hp": 965.0, "atk": 143.0, "armor": 30.0}, "after_stats": {"hp": 1042.0, "atk": 154.0, "armor": 34.0}}
	screen.view = "evolution_result"
	screen.refresh()
	(main.get("heroes_area") as ScrollContainer).scroll_vertical = 0
	await _capture("hero_evolution_result")
	for id in HeroData.HEROES:
		profile.heroes[id]["unlocked"] = true
		profile.selected_hero_id = id
		battle.start(profile)
		main.call("_select_tab", "Battle")
		main.call("_refresh_ui")
		if HeroData.HEROES[id]["style"] in ["magic", "arrow", "dark_bolt"]:
			battle.hero_attack_time = 0.0
			battle._process(0.01)
		await _capture("battle_%s" % id)
		battle.active = false
	quit()

func _capture(name: String) -> void:
	for resolution in [Vector2i(360, 640), Vector2i(1080, 1920)]:
		DisplayServer.window_set_size(resolution)
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image.get_size() != resolution:
			push_error("Expected %s for %s, got %s" % [resolution, name, image.get_size()])
			quit(1)
			return
		var path := "res://.godot/phase7_%s_%d.png" % [name, resolution.x]
		if image.save_png(path) != OK:
			push_error("Could not save " + path)
			quit(1)
			return
		print("Captured ", name, " ", resolution)
