extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	(main.get("profile") as SaveData).save_path = "res://.godot/phase5_layout.save"
	await process_frame
	var nav_buttons: Dictionary = main.get("nav_buttons")
	var nav := (nav_buttons["Battle"] as Button).get_parent().get_parent() as Control
	for tab in ["Battle", "Companions", "Artifacts", "Summon"]:
		main.call("_select_tab", tab)
		await process_frame
		var area := main.get("battle_area" if tab == "Battle" else ("companions_area" if tab == "Companions" else ("artifacts_area" if tab == "Artifacts" else "summon_area"))) as Control
		var content := main.get("companions_screen" if tab == "Companions" else ("artifacts_screen" if tab == "Artifacts" else "summon_screen")) as Control if tab != "Battle" else area
		var fits := area.visible and area.get_global_rect().end.y <= nav.get_global_rect().position.y + 1 and content.size.x <= area.size.x + 1
		if tab == "Battle":
			fits = fits and (main.get("battlefield") as Control).size.y >= 390
		print("%s: area=%s content=%s nav_y=%.0f" % [tab, str(area.size), str(content.size), nav.get_global_rect().position.y])
		if not fits:
			push_error("Phase 5 %s screen clips or overlaps navigation." % tab)
			quit(1)
			return
	print("PASS: Phase 5 screens fit the portrait viewport.")
	quit()
