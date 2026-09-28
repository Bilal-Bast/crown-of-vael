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
		profile.save_path = "res://.godot/phase6_layout.save"
		var adventure := main.get("adventure_screen") as AdventureScreen
		var nav_buttons: Dictionary = main.get("nav_buttons")
		var nav := (nav_buttons["Battle"] as Button).get_parent().get_parent() as Control
		for tab in ["Battle", "Adventure"]:
			main.call("_select_tab", tab)
			await process_frame
			var area := main.get("battle_area" if tab == "Battle" else "adventure_area") as Control
			var content := area if tab == "Battle" else adventure as Control
			_check(area.visible and area.get_global_rect().end.y <= nav.get_global_rect().position.y + 1 and content.size.x <= area.size.x + 1, "%s %s screen fits" % [resolution, tab])
		for view in ["hub", "dungeons", "tiers", "tower", "boss_rush", "endless", "result"]:
			adventure.view = view
			if view == "result":
				adventure.last_run = {"mode": "dungeon", "dungeon": "gold", "tier": 1}
				adventure.last_result = {"won": true, "time": 15.0, "reward": {"gold": 120}, "equipment": []}
			adventure.refresh()
			main.call("_select_tab", "Adventure")
			await process_frame
			var scroll := main.get("adventure_area") as ScrollContainer
			_check(adventure.size.x <= scroll.size.x + 1 and scroll.get_global_rect().end.y <= nav.get_global_rect().position.y + 1, "%s %s layout" % [resolution, view])
		main.queue_free()
		await process_frame
	print("PHASE 6 LAYOUT: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)

func _check(value: bool, label: String) -> void:
	if value:
		print("PASS: ", label)
	else:
		failed = true
		push_error("FAIL: " + label)
