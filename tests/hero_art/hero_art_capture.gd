extends SceneTree

const CAPTURE_DIR := "res://.godot/hero_art_captures"
const FORMS := ["Squire", "Knight", "Royal Knight", "Paladin", "Divine Paladin"]
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/hero_art_capture.save"
	profile.last_login_reward_date = CalendarService.day()
	profile.tutorial_state["completed"] = true
	profile.tutorial_state["skipped"] = true
	profile.tutorial_state["features"]["Heroes"] = true
	profile.offline_pending_rewards = {}
	profile.selected_hero_id = "knight"
	var battle := main.get("battle") as BattleController
	battle.active = false
	for enemy_index in battle.enemies.size():
		battle.enemies[enemy_index]["spawned"] = true
		battle.enemies[enemy_index]["entry_time"] = 0.0
	var field := main.get("battlefield") as Battlefield
	main.call("_select_tab", "Battle")
	await process_frame
	for popup_name in ["tutorial_popup", "offline_popup", "login_popup"]:
		var popup := main.get(popup_name) as Control
		if popup != null:
			popup.hide()
	for form in FORMS.size():
		profile.heroes["knight"]["evolution"] = form
		main.call("_refresh_ui")
		field.hero_visual_state = "idle"
		field.hero_attack_art_time = 0.0
		field.hero_guard_art_time = 0.0
		field.hero_hit_art_time = 0.0
		await _capture("%s_battle_idle_360" % _slug(FORMS[form]), Vector2i(360, 640))
		field.hero_run_time = 1.5
		field.hero_run_duration = 1.5
		await create_timer(0.28).timeout
		await _capture("%s_battle_run_360" % _slug(FORMS[form]), Vector2i(360, 640))
		field.hero_run_time = 0.0
		field._on_attack_started(-1, 0)
		await create_timer(0.10).timeout
		await _capture("%s_battle_attack_360" % _slug(FORMS[form]), Vector2i(360, 640))
		field._on_attack_started(-2, 0)
		await process_frame
		await _capture("%s_battle_guard_360" % _slug(FORMS[form]), Vector2i(360, 640))
		field.hero_guard_art_time = 0.0
		field._on_damage_popup(-1, 35, false, false)
		await process_frame
		await _capture("%s_battle_hit_360" % _slug(FORMS[form]), Vector2i(360, 640))
		field.hero_visual_state = "idle"
		field.hero_attack_art_time = 0.0
		field.hero_guard_art_time = 0.0
		field.hero_hit_art_time = 0.0
	var heroes := main.get("heroes_screen") as HeroesScreen
	main.call("_select_tab", "Heroes")
	heroes.selected_id = "knight"
	heroes.view = "detail"
	for form in FORMS.size():
		profile.heroes["knight"]["evolution"] = form
		heroes.preview_evolution = form
		heroes.refresh()
		(main.get("heroes_area") as ScrollContainer).scroll_vertical = 0
		await process_frame
		await _capture("%s_portrait_360" % _slug(FORMS[form]), Vector2i(360, 640))
	for next_form in range(1, FORMS.size()):
		profile.heroes["knight"]["evolution"] = next_form
		heroes.view = "evolution_result"
		heroes.evolution_result = {
			"previous": FORMS[next_form - 1], "next": FORMS[next_form], "element": "Holy",
			"before_stats": {"hp": 120, "atk": 13, "armor": 7},
			"after_stats": {"hp": 140, "atk": 15, "armor": 9},
		}
		heroes.refresh()
		await process_frame
		await _capture("%s_to_%s_evolution_result_360" % [_slug(FORMS[next_form - 1]), _slug(FORMS[next_form])], Vector2i(360, 640))
	profile.heroes["knight"]["evolution"] = 4
	main.call("_select_tab", "Battle")
	main.call("_refresh_ui")
	await _capture("divine_paladin_battle_overview_1080", Vector2i(1080, 1920))
	print("HERO ART CAPTURES: ", "FAIL (%d)" % failures if failures else "PASS")
	quit(1 if failures else 0)

func _capture(name: String, resolution: Vector2i) -> void:
	for popup_name in ["tutorial_popup", "offline_popup", "login_popup"]:
		var popup := root.get_child(0).get(popup_name) as Control
		if popup != null:
			popup.hide()
	DisplayServer.window_set_size(resolution)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [CAPTURE_DIR, name]
	if root.get_texture().get_image().save_png(path) != OK:
		failures += 1
		push_error("Hero capture failed: " + path)
	else:
		print("Captured ", path)

func _slug(value: String) -> String:
	return value.to_lower().replace(" ", "_")
