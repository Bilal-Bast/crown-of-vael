extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/phase12d_visual_capture_%d.save" % Time.get_ticks_usec())
	DisplayServer.window_set_size(Vector2i(360, 640))
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.tutorial_state = TutorialService.fresh_state()
	profile.last_login_reward_date = CalendarService.day()
	var battle := main.get("battle") as BattleController
	battle.active = false
	profile.offline_pending_rewards = {}
	main.call("_show_onboarding_step", "battle")
	await _capture("onboarding_battle_360")
	profile.gold = 850
	main.call("_show_onboarding_step", "upgrade")
	await _capture("upgrade_tutorial_360")
	profile.tutorial_state.completed = true
	main.call("_show_feature_for_tab", "Skills")
	await _capture("feature_unlock_360")
	main.get("tutorial_popup").hide()
	main.get("offline_popup").hide()
	for feature_name in TutorialService.FEATURES: profile.tutorial_state.features[feature_name] = true
	profile.offline_pending_rewards = {"seconds": 4 * 3600 + 32 * 60, "gold": 580, "exp": 104, "gold_per_hour": 120, "exp_per_hour": 18}
	main.call("_show_offline_popup")
	await _capture("offline_rewards_360")
	(main.get("offline_ad_button") as Button).grab_focus()
	await _capture("offline_reward_2x_360")

	main.get("offline_popup").hide()
	profile.level = 18
	profile.gold = 3420
	profile.evolution_crests = 7
	var heroes := main.get("heroes_screen") as HeroesScreen
	heroes.selected_id = "knight"
	heroes.view = "detail"
	heroes.refresh()
	main.call("_select_tab", "Heroes")
	await process_frame
	(main.get("heroes_area") as ScrollContainer).scroll_vertical = 360
	await _capture("evolution_requirements_360")

	profile.inventory.clear()
	profile.equipped.clear()
	main.call("_select_tab", "Equipment")
	await _capture("empty_equipment_360")

	profile.gold = 2400000
	profile.gems = 1200000
	profile.level = 99
	profile.upgrades = {"hp": 999, "atk": 999, "armor": 999}
	main.call("_refresh_ui")
	main.call("_select_tab", "Battle")
	await _capture("compact_hud_360")

	DisplayServer.window_set_size(Vector2i(1080, 1920))
	profile.tutorial_state.completed = false
	profile.tutorial_state.skipped = false
	profile.tutorial_state.steps = {}
	main.call("_show_onboarding_step", "battle")
	await _capture("onboarding_battle_1080")
	main.get("tutorial_popup").hide()
	profile.offline_pending_rewards = {"seconds": 12 * 3600, "gold": 1440, "exp": 216, "gold_per_hour": 120, "exp_per_hour": 18}
	main.call("_show_offline_popup")
	await _capture("offline_rewards_1080")
	print("PHASE 12D VISUAL CAPTURE: %s" % ("FAIL (%d)" % failures if failures else "PASS"))
	quit(1 if failures else 0)

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://.godot/phase12d_%s.png" % name
	if root.get_texture().get_image().save_png(path) != OK:
		failures += 1
		push_error("Phase 12D capture failed: " + path)
	else:
		print("Captured ", path)
