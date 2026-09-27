extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase2_visual_test.save"
	profile.stage = 1
	profile.gold = 0
	profile.gems = 0
	profile.level = 1
	profile.exp = 0
	profile.upgrades = {"hp": 0, "atk": 0, "armor": 0}
	profile.campaign_complete = false
	profile.boss_retry_required = false
	(main.get("battle") as BattleController).start(profile)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png("res://.godot/phase2_capture.png")
	print("Capture: %s x %s, result %s" % [image.get_width(), image.get_height(), error])
	quit(0 if error == OK else 1)
