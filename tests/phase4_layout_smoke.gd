extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	(main.get("profile") as SaveData).save_path = "res://.godot/phase4_layout.save"
	await process_frame
	var nav_buttons: Dictionary = main.get("nav_buttons")
	var nav := (nav_buttons["Battle"] as Button).get_parent().get_parent() as Control
	for tab in ["Skills", "Summon"]:
		main.call("_select_tab", tab)
		await process_frame
		var area := main.get("skills_area" if tab == "Skills" else "summon_area") as ScrollContainer
		var content := main.get("skills_screen" if tab == "Skills" else "summon_screen") as Control
		var valid := area.visible and area.get_global_rect().end.y <= nav.get_global_rect().position.y and content.size.x <= area.size.x + 1
		print("%s layout: area=%s content=%s nav_y=%.0f" % [tab, str(area.size), str(content.size), nav.get_global_rect().position.y])
		if not valid:
			push_error("%s screen clipped or overlaps navigation." % tab)
			quit(1)
			return
	print("PASS: Phase 4 Skills and Summon screens fit portrait viewport.")
	quit()
