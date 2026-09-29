extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	for resolution in [Vector2i(360, 640), Vector2i(1080, 1920)]:
		DisplayServer.window_set_size(resolution)
		await process_frame
		var main := scene.instantiate() as Control
		root.add_child(main)
		var profile := main.get("profile") as SaveData
		profile.save_path = "res://.godot/phase7_layout.save"
		(main.get("battle") as BattleController).active = false
		var screen := main.get("heroes_screen") as HeroesScreen
		var area := main.get("heroes_area") as ScrollContainer
		var nav_buttons: Dictionary = main.get("nav_buttons")
		var nav := (nav_buttons["Battle"] as Button).get_parent().get_parent() as Control
		for state in ["roster", "locked", "detail", "path", "evolution_result"]:
			if state == "roster":
				screen.view = "roster"
			elif state == "locked":
				screen.selected_id = "necromancer"
				screen.view = "detail"
			elif state in ["detail", "path"]:
				screen.selected_id = "knight"
				screen.view = "detail"
			else:
				profile.heroes["knight"]["evolution"] = 1
				screen.selected_id = "knight"
				screen.evolution_result = {"previous": "Squire", "next": "Knight", "element": "Physical", "before_stats": {"hp": 300.0, "atk": 48.0, "armor": 8.0}, "after_stats": {"hp": 350.0, "atk": 53.0, "armor": 11.0}}
				screen.view = "evolution_result"
			screen.refresh()
			main.call("_select_tab", "Heroes")
			await process_frame
			_check(area.visible and area.get_global_rect().end.y <= nav.get_global_rect().position.y + 1 and screen.size.x <= area.size.x + 1, "%s Heroes %s fits" % [resolution, state])
		main.queue_free()
		await process_frame
	print("PHASE 7 LAYOUT: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)

func _check(value: bool, label: String) -> void:
	if value:
		print("PASS: ", label)
	else:
		failed = true
		push_error("FAIL: " + label)
