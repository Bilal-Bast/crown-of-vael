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
	profile.inventory.clear()
	profile.equipped.clear()
	for kind in EquipmentData.STARTER_KINDS:
		var item := EquipmentData.create_item(kind, 3)
		profile.inventory.append(item)
		profile.equipped[EquipmentData.ITEMS[kind].slot] = item.id
	for id in ArtifactData.ARTIFACTS:
		profile.artifacts[id] = {"level":2,"duplicates":1,"rarity":4}
	profile.equipped_artifact_slots.assign(["dragon_fang","dragon_eye","", "", "", ""])
	main.call("_select_tab","Battle")
	await _capture("home_360",360)
	await _capture("home_overview_1080",1080)
	var toggle := main.get("menu_toggle") as Button
	toggle.pressed.emit()
	await _capture("menu_drawer_360",360)
	main.call("_select_tab", "Heroes")
	await _capture("heroes_360", 360)
	await _capture("heroes_overview_1080", 1080)
	var heroes := main.get("heroes_screen") as HeroesScreen
	heroes.call("_open_detail", profile.selected_hero_id)
	await _capture("hero_detail_360", 360)
	main.call("_select_tab", "Adventure")
	await _capture("adventure_360", 360)
	await _capture("adventure_overview_1080", 1080)
	main.call("_select_tab", "Companions")
	await _capture("companions_360", 360)
	main.call("_select_tab", "Skills")
	await _capture("skills_360", 360)
	main.call("_select_tab", "Battle")
	await _capture("battle_ui_360", 360)
	var screen := main.get("summon_screen") as SummonScreen
	main.call("_select_tab","Summon")
	for sample in [
		{"banner":"equipment", "kind":"sacred_sword", "name":"equipment"},
		{"banner":"skills", "kind":"healing_light", "name":"skill"},
		{"banner":"artifacts", "kind":"dragon_heart", "name":"artifact"},
		{"banner":"companions", "kind":"wolf", "name":"companion"},
	]:
		screen.result_banner = sample.banner
		screen.results = [{"kind":sample.kind, "rarity":4, "is_new":true}]
		screen.featured_index = 0
		screen.page = 0
		screen.revealing = false
		screen.refresh()
		await _capture("summon_reveal_%s_1x_360" % sample.name, 360)
		if sample.banner == "equipment": await _capture("summon_reveal_overview_1080", 1080)
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
		screen.featured_index = 0
		screen.refresh()
		if count == 1: await _capture("summon_reveal_equipment_1x_360",360)
		if count == 10: await _capture("summon_reveal_10x_page1_360",360)
		if count == 30:
			await _capture("summon_reveal_30x_page1_360",360)
			await _capture("summon_reveal_30x_overview_1080", 1080)
		if count == 30:
			screen.page = 1
			screen.featured_index = 6
			screen.refresh()
			await _capture("summon_reveal_30x_later_page_360",360)
			screen.page = 0
	main.call("_select_tab","Equipment")
	await _capture("equipment_inventory_360",360)
	await _capture("equipment_inventory_1080",1080)
	if not profile.inventory.is_empty():
		main.call("_select_item", profile.inventory[0].id)
		await _capture("equipment_detail_360", 360)
	main.call("_select_tab","Artifacts")
	await _capture("artifact_collection_360",360)
	await _capture("artifact_collection_1080",1080)
	var artifacts := main.get("artifacts_screen") as ArtifactsScreen
	if ArtifactData.ARTIFACTS.size() > 0:
		artifacts.call("_select", str(ArtifactData.ARTIFACTS.keys()[0]))
		await _capture("artifact_detail_360", 360)
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
	if node == main:
		for property in ["login_popup", "tutorial_popup", "offline_popup"]:
			var popup := main.get(property) as Control
			if popup != null: popup.hide()
	if node.name in ["DailyLoginPopup", "TutorialPopup", "OfflinePopup"]: node.hide()
	if node is Window: node.hide()
	if node is Button and str(node.text).to_upper() in ["GOT IT","CONTINUE","OK"]: node.emit_signal("pressed")
	for child in node.get_children(): _dismiss(child)
