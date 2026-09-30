extends SceneTree

const RESOLUTIONS := [Vector2i(360, 640), Vector2i(1080, 1920), Vector2i(1080, 2400)]
const SCREENS := ["battle", "boss_fight", "heroes", "equipment", "summon", "adventure", "settings", "offline_rewards", "onboarding"]

var failures := 0
var main: Control
var profile: SaveData
var battle: BattleController
var battlefield: Battlefield

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/phase12e_capture_%d.save" % Time.get_ticks_usec())
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/phase12e_captures"))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	profile = main.get("profile") as SaveData
	battle = main.get("battle") as BattleController
	battlefield = main.get("battlefield") as Battlefield
	battle.active = false
	profile.tutorial_state.completed = true
	for feature in TutorialService.FEATURES: profile.tutorial_state.features[feature] = true
	for resolution in RESOLUTIONS:
		DisplayServer.window_set_size(resolution)
		for screen in SCREENS:
			await _prepare(screen)
			await _capture(screen, resolution)
	main.queue_free()
	print("PHASE 12E VISUAL CAPTURE: %s (%d screens)" % ["FAIL" if failures else "CAPTURED", RESOLUTIONS.size() * SCREENS.size()])
	quit(1 if failures else 0)

func _prepare(screen: String) -> void:
	main.get("tutorial_popup").hide()
	main.get("offline_popup").hide()
	profile.offline_pending_rewards = {}
	battle.active = false
	profile.stage = 1
	battle.stage = 1
	battle.region = 1
	battle.mode_config = {"mode": "campaign"}
	_set_enemy("Goblin", false)
	match screen:
		"battle":
			profile.stage = 1
			battle.stage = 1
			battle.region = 1
			_set_enemy("Goblin", false)
			main.call("_select_tab", "Battle")
		"boss_fight":
			profile.stage = 20
			battle.stage = 20
			battle.region = 1
			battle.mode_config = {"mode": "campaign"}
			_set_enemy("Goblin Warlord", true)
			battlefield.vfx.boss_banner_name = "GOBLIN WARLORD"
			battlefield.vfx.boss_banner_time = 1.1
			main.call("_select_tab", "Battle")
		"heroes":
			main.call("_select_tab", "Heroes")
		"equipment":
			main.call("_select_tab", "Equipment")
		"summon":
			var screen_node := main.get("summon_screen") as SummonScreen
			screen_node.results = [{"rarity": 4, "kind": "iron_sword", "level": 1}]
			screen_node.result_banner = "equipment"
			screen_node.revealing = false
			screen_node.refresh()
			main.call("_select_tab", "Summon")
		"adventure": main.call("_select_tab", "Adventure")
		"settings": main.call("_select_tab", "Settings")
		"offline_rewards":
			profile.offline_pending_rewards = {"seconds": 4 * 3600 + 32 * 60, "gold": 580, "exp": 104, "gold_per_hour": 120, "exp_per_hour": 18}
			main.call("_show_offline_popup")
		"onboarding":
			profile.tutorial_state.completed = false
			profile.tutorial_state.skipped = false
			profile.stage = 1
			battle.stage = 1
			_set_enemy("Goblin", false)
			main.call("_select_tab", "Battle")
			main.call("_show_onboarding_step", "battle")
	main.call("_refresh_ui")
	await process_frame

func _set_enemy(kind: String, is_boss: bool) -> void:
	battle.enemies.clear()
	var enemy := CampaignData.enemy_stats(kind, 0, 1, battle.stage, 1)
	enemy["current_hp"] = enemy["hp"]
	enemy["attack_time"] = 3.0
	enemy["stun_time"] = 0.0
	if is_boss: enemy["archetype"] = "BOSS"
	battle.enemies.append(enemy)
	battle.changed.emit()

func _capture(screen: String, resolution: Vector2i) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var size_name := "%dx%d" % [resolution.x, resolution.y]
	var path := "res://.godot/phase12e_captures/%s_%s.png" % [size_name, screen]
	var result := root.get_texture().get_image().save_png(path)
	if result != OK:
		failures += 1
		push_error("Phase 12E capture failed: " + path)
	else:
		print("Captured ", path)
