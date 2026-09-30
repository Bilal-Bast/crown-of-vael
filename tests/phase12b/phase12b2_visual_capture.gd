extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase12b2_visual.save"
	profile.campaign_difficulty = 0
	profile.selected_hero_id = "knight"
	profile.heroes["knight"]["evolution"] = 1
	profile.last_login_reward_date = CalendarService.day()
	var battle := main.get("battle") as BattleController
	battle.active = false
	battle.difficulty = 0
	battle.mode_config = {"mode": "campaign"}
	main.call("_select_tab", "Battle")
	for region in range(2, 11):
		var info: Dictionary = CampaignData.REGIONS[region - 1]
		var folder := str(EnemyArtService.ENEMY_REGION_FOLDERS[region])
		await _show_case(folder + "_mixed", main, battle, region, 1, (info["enemies"] as Array).slice(0, 5), [Vector2i(360, 640)])
		await _show_case(folder + "_boss", main, battle, region, 20, [info["boss"]], [Vector2i(360, 640), Vector2i(1080, 1920)])
	for sample in [[2, "Giant Spider"], [5, "Marsh Hydra"], [6, "Ancient Sand Wyrm"], [9, "Ancient Dragon"], [10, "Demon Lord"]]:
		var region := int(sample[0])
		var kind := str(sample[1])
		await _show_case(str(EnemyArtService.enemy_folder(kind, region)), main, battle, region, 20 if kind != "Giant Spider" else 1, [kind], [Vector2i(360, 640)])
	print("PHASE 12B.2 VISUAL CAPTURE: %s" % ("FAIL (%d)" % failures if failures else "PASS"))
	quit(1 if failures else 0)

func _show_case(name: String, main: Control, battle: BattleController, region: int, stage: int, kinds: Array, resolutions: Array) -> void:
	battle.active = false
	battle.stage = stage
	battle.region = region
	battle.enemies.clear()
	var profile := main.get("profile") as SaveData
	profile.region = region
	profile.stage = stage
	for kind in kinds:
		var enemy := CampaignData.enemy_stats(str(kind), 0, region, stage, 1)
		enemy["current_hp"] = enemy["hp"]
		enemy["attack_time"] = 3.0
		enemy["stun_time"] = 0.0
		battle.enemies.append(enemy)
	battle.changed.emit()
	main.call("_refresh_ui")
	for resolution in resolutions:
		DisplayServer.window_set_size(resolution)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://.godot/phase12b2_%s_%d.png" % [name, resolution.x]
		if root.get_texture().get_image().save_png(path) != OK:
			failures += 1
			push_error("PHASE 12B.2 capture failed: " + path)
		else:
			print("Captured ", path)
