extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase12a_visual.save"
	profile.last_login_reward_date = CalendarService.day()
	(main.get("battle") as BattleController).active = false
	profile.selected_hero_id = "knight"
	profile.heroes["knight"]["evolution"] = 2
	main.call("_refresh_ui")
	var field := main.get("battlefield") as Battlefield
	main.call("_select_tab", "Battle")
	await _capture("royal_knight_battle_idle", main)
	field._on_attack_started(-1, 0)
	await process_frame
	await _capture("royal_knight_battle_attack", main)
	field._on_damage_popup(-1, 35, false, false)
	await process_frame
	await _capture("royal_knight_battle_guard", main)
	var heroes := main.get("heroes_screen") as HeroesScreen
	var heroes_area := main.get("heroes_area") as ScrollContainer
	main.call("_select_tab", "Account")
	await _capture("royal_knight_profile", main)
	main.call("_select_tab", "Social")
	var social := main.get("social_screen") as SocialScreen
	social.tab = "Friends"
	if not profile.friends_state.friends.is_empty():
		profile.friends_state.friends[0]["hero"] = "knight"
		profile.friends_state.friends[0]["evolution"] = 2
	social.refresh()
	await _capture("royal_knight_social", main)
	main.call("_select_tab", "Heroes")
	heroes.selected_id = "knight"
	heroes.view = "detail"
	for stage in 5:
		heroes.preview_evolution = stage
		heroes.refresh()
		(main.get("heroes_area") as ScrollContainer).scroll_vertical = 0
		await _capture("knight_form_%d" % stage, main, heroes_area, true)
	heroes_area.scroll_vertical = 0
	await _capture("royal_knight_heroes_portrait", main)
	heroes.preview_evolution = -1
	heroes.evolution_result = {"previous": "Knight", "next": "Royal Knight", "element": "Steel", "before_stats": {"hp": 115, "atk": 12, "armor": 6}, "after_stats": {"hp": 132, "atk": 14, "armor": 7}}
	heroes.view = "evolution_result"
	heroes.refresh()
	await _capture("knight_to_royal_knight_evolution_result", main)
	print("PHASE 12A VISUAL CAPTURE: %s" % ("FAIL (%d)" % failures if failures else "PASS"))
	quit(1 if failures else 0)

func _capture(name: String, control: Control, scroll: ScrollContainer = null, bottom: bool = false) -> void:
	for resolution in [Vector2i(360, 640), Vector2i(1080, 1920)]:
		DisplayServer.window_set_size(resolution)
		await process_frame
		await process_frame
		if bottom and scroll != null:
			scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
			await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://.godot/phase12a_%s_%d.png" % [name, resolution.x]
		if root.get_texture().get_image().save_png(path) != OK:
			failures += 1
			push_error("PHASE 12A capture failed: " + path)
		else:
			print("Captured ", path)
