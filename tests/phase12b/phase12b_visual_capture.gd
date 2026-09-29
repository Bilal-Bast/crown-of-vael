extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase12b_visual.save"
	profile.region = 1
	profile.stage = 1
	profile.campaign_difficulty = 0
	profile.selected_hero_id = "knight"
	profile.heroes["knight"]["evolution"] = 1
	profile.last_login_reward_date = CalendarService.day()
	var battle := main.get("battle") as BattleController
	battle.active = true
	battle.region = 1
	battle.difficulty = 0
	battle.mode_config = {"mode": "campaign"}
	battle.active = false
	main.call("_refresh_ui")
	main.call("_select_tab", "Battle")
	await _show_case("greenvale_regular_mixed", main, battle, ["Goblin", "Skeleton", "Corrupted Wolf", "Goblin Archer", "Goblin Spearman"], 1)
	await _show_case("greenvale_archer", main, battle, ["Goblin Archer"], 1)
	await _show_case("greenvale_corrupted_wolf", main, battle, ["Corrupted Wolf"], 1)
	await _show_case("greenvale_elite_captain", main, battle, ["Goblin Captain"], 5)
	await _show_case("greenvale_elite_armored_skeleton", main, battle, ["Armored Skeleton"], 10)
	await _show_case("greenvale_warlord_boss", main, battle, ["Goblin Warlord"], 20)
	await _show_case("greenvale_background_readability", main, battle, [], 1)
	print("PHASE 12B VISUAL CAPTURE: %s" % ("FAIL (%d)" % failures if failures else "PASS"))
	quit(1 if failures else 0)

func _show_case(name: String, main: Control, battle: BattleController, kinds: Array, stage: int) -> void:
	battle.active = false
	battle.stage = stage
	battle.region = 1
	battle.difficulty = 0
	battle.mode_config = {"mode": "campaign"}
	battle.enemies.clear()
	var profile := main.get("profile") as SaveData
	profile.stage = stage
	for kind in kinds:
		var enemy := CampaignData.enemy_stats(str(kind), 0, 1, stage, 1)
		enemy["current_hp"] = enemy["hp"]
		enemy["attack_time"] = 3.0
		enemy["stun_time"] = 0.0
		battle.enemies.append(enemy)
	battle.changed.emit()
	main.call("_refresh_ui")
	for resolution in [Vector2i(360, 640), Vector2i(1080, 1920)]:
		DisplayServer.window_set_size(resolution)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://.godot/phase12b_%s_%d.png" % [name, resolution.x]
		if root.get_texture().get_image().save_png(path) != OK:
			failures += 1
			push_error("PHASE 12B capture failed: " + path)
		else:
			print("Captured ", path)
