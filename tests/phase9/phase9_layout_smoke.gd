extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for resolution in [Vector2i(360, 640), Vector2i(1080, 1920)]:
		DisplayServer.window_set_size(resolution)
		var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
		root.add_child(main)
		var profile := main.get("profile") as SaveData
		profile.save_path = "res://.godot/phase9_layout.save"
		profile.last_login_reward_date = CalendarService.day()
		(main.get("battle") as BattleController).active = false
		for tab in ["Quests", "Login"]:
			main.call("_select_tab", tab)
			await process_frame
			var area := main.get("quests_area") as ScrollContainer if tab == "Quests" else main.get("login_area") as ScrollContainer
			var screen := main.get("quests_screen") as Control if tab == "Quests" else main.get("login_screen") as Control
			if screen.size.x > area.size.x + 1:
				failed = true
				push_error("PHASE 9 LAYOUT: %s content exceeds width at %s: %s > %s" % [tab, resolution, screen.size.x, area.size.x])
			if tab == "Quests":
				for label in screen.find_children("", "Label", true, false):
					if "/" in label.text or "Activity" in label.text:
						if label.size.y < 20:
							failed = true
							push_error("PHASE 9 LAYOUT: collapsed quest label: " + label.text)
		main.queue_free()
		await process_frame
	print("PHASE 9 LAYOUT: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
