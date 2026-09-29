extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	(main.get("profile") as SaveData).save_path = "res://.godot/phase3_visual.save"
	await process_frame
	for tab_name in ["Battle", "Heroes", "Equipment"]:
		main.call("_select_tab", tab_name)
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.resize(360, 640)
		var path := "res://.godot/phase3_%s_360.png" % tab_name.to_lower()
		var error := image.save_png(path)
		if error != OK:
			push_error("Could not capture %s: %s" % [tab_name, error])
			quit(1)
			return
		print("Captured %s at 360x640" % tab_name)
	var inventory: Array[Dictionary] = (main.get("profile") as SaveData).inventory
	main.call("_select_item", str(inventory[0]["id"]))
	await process_frame
	await RenderingServer.frame_post_draw
	var detail_image := root.get_texture().get_image()
	detail_image.resize(360, 640)
	detail_image.save_png("res://.godot/phase3_equipment_detail_360.png")
	(main.get("equipment_area") as ScrollContainer).scroll_vertical = 1800
	await process_frame
	await RenderingServer.frame_post_draw
	var inventory_image := root.get_texture().get_image()
	inventory_image.resize(360, 640)
	inventory_image.save_png("res://.godot/phase3_inventory_360.png")
	quit()
