extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase9_visual.save"
	profile.last_login_reward_date = CalendarService.day()
	(main.get("battle") as BattleController).active = false
	var quests := main.get("quests_screen") as QuestsScreen
	var login := main.get("login_screen") as LoginScreen
	var service := ProgressionService.new(profile)
	profile.daily_reset_date = ""
	profile.weekly_reset_week = ""
	service.refresh()
	profile.daily_counters.clear()
	profile.weekly_counters.clear()
	profile.daily_claimed.clear()
	profile.weekly_claimed.clear()
	profile.last_monthly_reward_date = ""
	for state in ["daily", "weekly", "achievements"]:
		quests.tab = state
		main.call("_select_tab", "Quests")
		await _capture(state)
	service.report("enemy_defeated", 100)
	service.report("campaign_stage_cleared", 10)
	service.claim_quest("daily", "kills")
	service.claim_quest("daily", "stages")
	quests.tab = "daily"
	quests.refresh()
	await _capture("daily_claim_state")
	main.call("_select_tab", "Login")
	login.refresh()
	await _capture("monthly_calendar")
	main.call("_select_tab", "Battle")
	profile.last_login_reward_date = ""
	main.call("_show_login_popup")
	await _capture("daily_login_popup")
	print("PHASE 9 VISUAL CAPTURE: PASS")
	quit()

func _capture(name: String) -> void:
	for resolution in [Vector2i(360, 640), Vector2i(1080, 1920)]:
		DisplayServer.window_set_size(resolution)
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := "res://.godot/phase9_%s_%d.png" % [name, resolution.x]
		if image.save_png(path) != OK: push_error("Capture failed: " + path)
		else: print("Captured ", path)
