extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	(main.get("profile") as SaveData).save_path = "res://.godot/phase4_visual.save"
	await process_frame
	var profile := main.get("profile") as SaveData
	profile.stage = 1
	profile.campaign_complete = false
	(main.get("battle") as BattleController).start(profile)
	main.call("_refresh_ui")
	await _capture("battle")
	main.call("_select_tab", "Skills")
	await _capture("skills")
	main.call("_select_tab", "Summon")
	await _capture("summon")
	profile.gems = 10000 # Debug-only capture funding.
	main.call("_on_summon_changed")
	var screen := main.get("summon_screen") as SummonScreen
	screen.call("_summon", "equipment", 1, "gems")
	await _capture("summon_portal")
	screen.call("_skip_reveal")
	await _capture("summon_one")
	screen.call("_summon", "skills", 10, "gems")
	screen.call("_skip_reveal")
	await _capture("summon_ten")
	quit()

func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.resize(360, 640)
	var error := image.save_png("res://.godot/phase4_%s_360.png" % name)
	if error != OK:
		push_error("Capture failed: %s" % name)
		quit(1)
	else:
		print("Captured %s at 360x640" % name)
