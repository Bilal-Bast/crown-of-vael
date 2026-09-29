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
	var field := main.get("battlefield") as Battlefield
	main.call("_select_tab", "Battle")
	await _capture("squire_battle_idle", main)
	field._on_attack_started(-1, 0)
	await process_frame
	await _capture("squire_battle_attack", main)
	var heroes := main.get("heroes_screen") as HeroesScreen
	var heroes_area := main.get("heroes_area") as ScrollContainer
	main.call("_select_tab", "Heroes")
	heroes.selected_id = "knight"
	heroes.view = "detail"
	for stage in 5:
		heroes.preview_evolution = stage
		heroes.refresh()
		(main.get("heroes_area") as ScrollContainer).scroll_vertical = 0
		await _capture("knight_form_%d" % stage, main, heroes_area, true)
	heroes.preview_evolution = -1
	heroes.evolution_result = {"previous": "Squire", "next": "Knight", "element": "Steel", "before_stats": {"hp": 100, "atk": 10, "armor": 5}, "after_stats": {"hp": 115, "atk": 12, "armor": 6}}
	heroes.view = "evolution_result"
	heroes.refresh()
	await _capture("evolution_result", main)
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
