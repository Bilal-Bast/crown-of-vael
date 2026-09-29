extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase10_visual.save"
	profile.last_login_reward_date = CalendarService.day()
	(main.get("battle") as BattleController).active = false
	var pass_screen := main.get("battle_pass_screen") as BattlePassScreen
	var shop := main.get("shop_screen") as ShopScreen
	MonetizationDebug.set_bp_level(profile, 3)
	main.call("_select_tab", "Pass")
	pass_screen.premium_view = false
	pass_screen.refresh()
	await _capture("pass_free", pass_screen, main.get("battle_pass_area"))
	pass_screen.premium_view = true
	pass_screen.refresh()
	await _capture("pass_locked", pass_screen, main.get("battle_pass_area"))
	MonetizationDebug.toggle_premium(profile)
	pass_screen.refresh()
	await _capture("pass_premium", pass_screen, main.get("battle_pass_area"))
	main.call("_select_tab", "Shop")
	for tab in ["Featured", "Subscription", "Daily", "Weekly", "Cosmetics"]:
		shop.tab = tab
		shop.refresh()
		await _capture("shop_" + tab.to_lower(), shop, main.get("shop_area"))
	shop.tab = "Featured"
	shop.refresh()
	var dialog := shop.confirm
	shop.tab = "Weekly"
	shop.refresh()
	shop.call("_confirm_offer", "weekly", 0)
	await _capture("purchase_confirmation", shop, main.get("shop_area"))
	dialog.hide()
	main.call("_select_tab", "Login")
	await _capture("rewarded_ad_prompt", main.get("login_screen"), main.get("login_area"))
	print("PHASE 10 VISUAL: %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func _capture(name: String, screen: Control, area: ScrollContainer) -> void:
	for resolution in [Vector2i(360, 640), Vector2i(1080, 1920)]:
		DisplayServer.window_set_size(resolution)
		await process_frame
		await RenderingServer.frame_post_draw
		if screen.size.x > area.size.x + 1:
			failed = true
			push_error("PHASE 10 LAYOUT: %s exceeds width at %s" % [name, resolution])
		var path := "res://.godot/phase10_%s_%d.png" % [name, resolution.x]
		if root.get_texture().get_image().save_png(path) != OK:
			failed = true
			push_error("Capture failed: " + path)
		else: print("Captured ", path)

