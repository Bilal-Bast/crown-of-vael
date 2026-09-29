extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase11_visual.save"
	profile.last_login_reward_date = CalendarService.day()
	(main.get("battle") as BattleController).active = false
	var account := main.get("account_screen") as AccountScreen
	var social := main.get("social_screen") as SocialScreen
	var account_area := main.get("account_area") as ScrollContainer
	var social_area := main.get("social_area") as ScrollContainer
	profile.account_meta.account_type = "Linked"
	main.call("_schedule_cloud_sync")
	if (main.get("cloud_sync_timer") as Timer).time_left <= 0.0:
		failed = true
		push_error("PHASE 11 SYNC: progression changes should debounce cloud writes")
	(main.get("cloud_sync_timer") as Timer).stop()
	profile.account_meta.account_type = "Guest"
	main.call("_select_tab", "Account")
	account.refresh()
	await _capture("account_guest", account, account_area)
	profile.account_meta.account_type = "Linked"
	profile.account_meta.provider = "Google"
	profile.save()
	account.refresh()
	await _capture("account_linked", account, account_area)
	var cloud := DevelopmentCloudSaveProvider.new()
	cloud.save_cloud(profile)
	profile.level += 2
	profile.save()
	account.conflict_payload = AccountService.new(profile, DevelopmentAuthProvider.new(), cloud).inspect_cloud()
	account.refresh()
	await _capture("cloud_conflict", account, account_area)
	main.call("_select_tab", "Social")
	social.tab = "Friends"
	social.refresh()
	await _capture("friends_list", social, social_area)
	if profile.friends_state.incoming.is_empty(): SocialService.new(profile)
	social.refresh()
	await _capture("friend_request", social, social_area)
	social.tab = "Guild"
	var guild := GuildService.new(profile)
	if profile.guild_state.guild.is_empty(): guild.create("Crown Wardens", "CROWN", "Development guild")
	social.refresh()
	await _capture("guild_overview", social, social_area)
	for view in [{"name":"guild_boss", "scroll":380}, {"name":"guild_roster", "scroll":850}, {"name":"guild_chat", "scroll":1300}]:
		social.refresh()
		social_area.scroll_vertical = int(view.scroll)
		await _capture(str(view.name), social, social_area)
	social.tab = "PvP"
	social._find_opponents()
	social.refresh()
	await _capture("pvp_opponents", social, social_area)
	var duel_result := PvPService.new(profile).fight(social.opponents[0], false, "timeout_win") if not social.opponents.is_empty() else {"ok": false}
	social.notice = "%s • %s %d Rating • %ds • +%d Gold" % ["Victory" if duel_result.get("won", false) else "Defeat", duel_result.get("rank", "Bronze"), int(duel_result.get("rating", 1000)), int(duel_result.get("duration", 60)), int(duel_result.get("reward", {}).get("gold", 0))]
	social.refresh()
	await _capture("pvp_result", social, social_area)
	social.notice = "Master • 2,500 rating • 12 wins"
	social.refresh()
	await _capture("pvp_rank", social, social_area)
	print("PHASE 11 VISUAL: %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func _capture(name: String, screen: Control, area: ScrollContainer) -> void:
	for resolution in [Vector2i(360, 640), Vector2i(1080, 1920)]:
		DisplayServer.window_set_size(resolution)
		await process_frame
		await RenderingServer.frame_post_draw
		if screen.size.x > area.size.x + 1:
			failed = true
			push_error("PHASE 11 LAYOUT: %s exceeds width at %s" % [name, resolution])
		var path := "res://.godot/phase11_%s_%d.png" % [name, resolution.x]
		if root.get_texture().get_image().save_png(path) != OK:
			failed = true
			push_error("Capture failed: " + path)
		else: print("Captured ", path)
