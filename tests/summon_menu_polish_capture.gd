extends SceneTree

const OUT := "res://.godot/summon_menu_polish_captures"
var main: Control
var failures := 0

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/summon_menu_polish_capture.save")
	call_deferred("_run")

func _run() -> void:
	if root.get_texture() == null:
		push_error("Graphical viewport unavailable. Captures must run without --headless.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dismiss(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/summon_menu_polish_capture.save"
	profile.gems = 100000
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	for kind in EquipmentData.STARTER_KINDS:
		var item := EquipmentData.create_item(kind, 3)
		profile.inventory.append(item)
	for id in ArtifactData.ARTIFACTS:
		profile.artifacts[id] = {"level":2,"duplicates":1,"rarity":4}
	profile.equipped_artifact_slots.assign(["dragon_fang","dragon_eye","", "", "", ""])
	main.call("_select_tab","Battle")
	await _capture("home_360",360)
	await _capture("home_overview_1080",1080)
	var toggle := main.get("menu_toggle") as Button
	toggle.pressed.emit()
	await _capture("menu_drawer_360",360)
	var screen := main.get("summon_screen") as SummonScreen
	main.call("_select_tab","Summon")
	for banner in SummonData.BANNERS:
		screen.selected_banner = banner
		screen.results.clear()
		screen.refresh()
		await _capture("summon_%s_360" % banner,360)
		if banner == "equipment": await _capture("summon_overview_1080",1080)
	var service := SummonService.new(profile)
	screen.selected_banner = "equipment"
	for count in [1,10,30]:
		screen.results = service.summon("equipment",count)
		screen.result_banner = "equipment"
		screen.revealing = false
		screen.page = 0
		screen.refresh()
		await _capture("summon_reveal_%dx_360" % count,360)
		if count == 30:
			screen.page = 1
			screen.refresh()
			await _capture("summon_reveal_30x_page2_360",360)
			screen.page = 0
	main.call("_select_tab","Equipment")
	await _capture("equipment_inventory_360",360)
	await _capture("equipment_inventory_1080",1080)
	main.call("_select_tab","Artifacts")
	await _capture("artifact_collection_360",360)
	await _capture("artifact_collection_1080",1080)
	main.queue_free()
	print("SUMMON / MENU CAPTURES: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL",failures])
	quit(1 if failures else 0)

func _capture(name: String, width: int) -> void:
	var resolution := Vector2i(width,1920 if width == 1080 else 640)
	DisplayServer.window_set_size(resolution)
	for _i in 3:
		await process_frame
		_dismiss(main)
	# Let the staggered reward-card fade finish before taking review captures.
	await create_timer(0.55).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != resolution:
		failures += 1
		push_error("Invalid capture %s: expected %s, got %s" % [name,resolution,str(image.get_size()) if image else "null"])
		return
	var path := "%s/%s.png" % [OUT,name]
	if image.save_png(path) != OK:
		failures += 1
		push_error("Could not save capture " + path)
	else:
		print("CAPTURE " + path)

func _dismiss(node: Node) -> void:
	if node.name in ["DailyLoginPopup", "TutorialPopup", "OfflinePopup"]: node.hide()
	if node is Window: node.hide()
	if node is Button and str(node.text).to_upper() in ["GOT IT","CONTINUE","OK"]: node.emit_signal("pressed")
	for child in node.get_children(): _dismiss(child)
