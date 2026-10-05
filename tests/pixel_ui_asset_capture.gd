extends SceneTree

const OUT := "res://.godot/pixel_ui_asset_captures"
var main: Control
var failures := 0

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/pixel_ui_asset_capture.save")
	call_deferred("_run")

func _run() -> void:
	if root.get_texture() == null:
		push_error("Viewport unavailable; asset captures must run without --headless.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dismiss(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/pixel_ui_asset_capture.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	profile.gems = 100000
	profile.last_login_reward_date = CalendarService.day()
	profile.offline_pending_rewards.clear()
	if main.get("login_popup") != null: main.get("login_popup").hide()
	if main.get("tutorial_popup") != null: main.get("tutorial_popup").hide()
	if main.get("offline_popup") != null: main.get("offline_popup").hide()
	for id in ArtifactData.ARTIFACTS:
		profile.artifacts[id] = {"level": 2, "duplicates": 2, "rarity": 4}
	profile.equipped_artifact_slots.assign(["dragon_fang", "dragon_eye", "", "", "", ""])
	profile.equipped_skill_slots.assign(["shield_bash", "whirlwind_slash", "iron_guard", "healing_light"])
	(main.get("skill_bar") as SkillBar).queue_redraw()
	await _capture("battle_skill_bar_360", 360)
	profile.inventory.clear()
	profile.equipped.clear()
	for kind in EquipmentData.STARTER_KINDS:
		var item := EquipmentData.create_item(kind, 3)
		profile.inventory.append(item)
		profile.equipped[EquipmentData.ITEMS[kind].slot] = item.id
	main.call("_select_tab", "Equipment")
	main.call("_select_item", profile.inventory[0].id)
	await _capture("equipment_detail_360", 360)
	main.set("selected_item_id", "")
	main.call("_refresh_progression_screens")
	main.get("equipment_area").scroll_vertical = 0
	await _capture("equipment_360", 360)
	await _capture("equipment_overview_1080", 1080)
	main.call("_select_tab", "Artifacts")
	var relic_screen := main.get("artifacts_screen") as ArtifactsScreen
	relic_screen.call("_select", "dragon_heart")
	await _capture("artifact_detail_360", 360)
	relic_screen.set("selected_id", "")
	relic_screen.refresh()
	await _capture("artifact_360", 360)
	await _capture("artifact_overview_1080", 1080)
	for id in SkillData.SKILLS:
		profile.skills[id] = {"level": 2, "duplicates": 3, "rarity": int(SkillData.SKILLS[id].rarity)}
	main.call("_select_tab", "Skills")
	await _capture("skills_360", 360)
	await _capture("skills_overview_1080", 1080)
	var screen := main.get("summon_screen") as SummonScreen
	main.call("_select_tab", "Summon")
	for test_case in [
		{"banner":"equipment", "kind":"sacred_sword", "name":"summon_equipment_reward_360"},
		{"banner":"artifacts", "kind":"dragon_heart", "name":"summon_artifact_reward_360"},
		{"banner":"skills", "kind":"healing_light", "name":"summon_skill_reward_360"},
	]:
		screen.results = [{"kind":test_case.kind, "rarity":4, "is_new":true}]
		screen.result_banner = test_case.banner
		screen.revealing = false
		screen.page = 0
		screen.refresh()
		await _capture(test_case.name, 360)
	main.queue_free()
	print("PIXEL UI ASSET CAPTURES: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _capture(name: String, width: int) -> void:
	var resolution := Vector2i(width, 1920 if width == 1080 else 640)
	DisplayServer.window_set_size(resolution)
	for _i in 4:
		await process_frame
		_dismiss(main)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != resolution:
		failures += 1
		push_error("Invalid capture %s: got %s" % [name, str(image.get_size()) if image else "null"])
		return
	var path := "%s/%s.png" % [OUT, name]
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		failures += 1
		push_error("Could not save capture " + path)
	else:
		print("CAPTURE " + path)

func _dismiss(node: Node) -> void:
	if node == main:
		for property in ["login_popup", "tutorial_popup", "offline_popup"]:
			var popup := main.get(property) as Window
			if popup != null: popup.hide()
	if node.name in ["DailyLoginPopup", "TutorialPopup", "OfflinePopup"]: node.hide()
	if node is Window: node.hide()
	if node is Button and str(node.text).to_upper() in ["GOT IT", "CONTINUE", "OK"]: node.emit_signal("pressed")
	for child in node.get_children(): _dismiss(child)
