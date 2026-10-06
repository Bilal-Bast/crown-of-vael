extends SceneTree

const CAPTURE_DIR := "res://.godot/battle_upgrade_ui_captures"
const SMALL := Vector2i(360, 640)
const LARGE := Vector2i(1080, 1920)

var failures := 0
var main: Control
var profile: SaveData
var upgrade_list: ScrollContainer
var lower_scroll: ScrollContainer

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/battle_upgrade_ui_capture.save")
	call_deferred("_run")

func _run() -> void:
	if root.get_texture() == null:
		push_error("Battle upgrade captures require a graphical viewport; do not use --headless.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	DisplayServer.window_set_size(SMALL)
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	profile = main.get("profile") as SaveData
	profile.save_path = "res://.godot/battle_upgrade_ui_capture.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	profile.region = 3
	profile.stage = 3
	profile.level = 1
	profile.exp = 0
	profile.upgrades = {"atk": 0, "hp": 0, "armor": 0, "speed": 0, "crit_chance": 0, "crit_damage": 0}
	profile.gold = 5000
	profile.skills = {
		"shield_bash": {"level": 1, "duplicates": 0, "rarity": 0},
		"whirlwind_slash": {"level": 1, "duplicates": 0, "rarity": 2},
		"iron_guard": {"level": 1, "duplicates": 0, "rarity": 1},
		"healing_light": {"level": 1, "duplicates": 0, "rarity": 2},
	}
	profile.equipped_skill_slots = ["shield_bash", "whirlwind_slash", "iron_guard", "healing_light"]
	profile.companions = {
		"wolf": {"level": 1, "stars": 1, "evolution": 0, "rarity": 0},
		"fairy": {"level": 1, "stars": 1, "evolution": 0, "rarity": 0},
		"archer_companion": {"level": 1, "stars": 1, "evolution": 0, "rarity": 0},
		"apprentice_mage": {"level": 1, "stars": 1, "evolution": 0, "rarity": 0}
	}
	profile.equipped_companion_slots = ["wolf", "fairy", "archer_companion", "apprentice_mage"]
	var battle := main.get("battle") as BattleController
	battle.start(profile)
	battle.wave = 3
	battle._spawn_wave()
	upgrade_list = main.get("upgrade_list_scroll") as ScrollContainer
	lower_scroll = main.get("battle_lower_scroll") as ScrollContainer
	for popup in ["tutorial_popup", "offline_popup", "login_popup"]:
		var node = main.get(popup)
		if node is Window or node is Control:
			node.hide()
	main.call("_refresh_ui")
	battle.refresh_hero_stats()
	battle.skill_runtime.start(profile)
	await _capture("battle_skills_above_upgrades_360x640", SMALL)
	await _capture("ashen_highlands_wave3_battle_360x640", SMALL)
	lower_scroll.scroll_vertical = 0
	upgrade_list.scroll_vertical = 0
	await _capture("battle_upgrade_list_top_360x640", SMALL)
	(main.get("upgrade_mode_buttons")["x10"] as Button).pressed.emit()
	await _capture("battle_upgrade_mode_x10_360x640", SMALL)
	(main.get("upgrade_mode_buttons")["MAX"] as Button).pressed.emit()
	await _capture("battle_upgrade_mode_max_360x640", SMALL)
	(main.get("upgrade_mode_buttons")["x1"] as Button).pressed.emit()
	var scroll_range := maxi(0, roundi(upgrade_list.get_v_scroll_bar().max_value - upgrade_list.get_v_scroll_bar().page))
	upgrade_list.scroll_vertical = roundi(scroll_range * 0.35)
	await _capture("battle_armor_attack_speed_cards_360x640", SMALL)
	upgrade_list.scroll_vertical = roundi(scroll_range * 0.92)
	await _capture("battle_crit_chance_crit_damage_cards_360x640", SMALL)
	upgrade_list.scroll_vertical = scroll_range
	await _capture("battle_upgrade_list_bottom_360x640", SMALL)
	profile.gold = 0
	main.call("_refresh_ui")
	upgrade_list.scroll_vertical = 0
	await _capture("battle_upgrades_insufficient_gold_360x640", SMALL)
	profile.gold = 5000
	main.call("_buy_upgrade", "atk")
	await _capture("battle_upgrades_upgraded_stat_360x640", SMALL)
	profile.upgrades["speed"] = 10
	profile.upgrades["crit_chance"] = 25
	profile.upgrades["crit_damage"] = 50
	main.call("_refresh_ui")
	lower_scroll.scroll_vertical = roundi(lower_scroll.get_v_scroll_bar().max_value - lower_scroll.get_v_scroll_bar().page)
	await _capture("battle_upgraded_stat_card_360x640", SMALL)
	for stat in ["speed", "crit_chance", "crit_damage"]:
		profile.upgrades[stat] = GameData.PREMIUM_UPGRADE_MAX_RANK
	main.call("_refresh_ui")
	lower_scroll.scroll_vertical = roundi(lower_scroll.get_v_scroll_bar().max_value - lower_scroll.get_v_scroll_bar().page)
	await _capture("battle_upgrade_max_level_360x640", SMALL)
	for stat in ["speed", "crit_chance", "crit_damage"]:
		profile.upgrades[stat] = 0
	main.call("_refresh_ui")
	main.call("_show_message", "")
	lower_scroll.scroll_vertical = 0
	DisplayServer.window_set_size(LARGE)
	for _i in 3:
		await process_frame
	await _capture("battle_full_overview_1080x1920", LARGE)
	main.queue_free()
	print("BATTLE UPGRADE UI CAPTURES: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _capture(name: String, resolution: Vector2i) -> void:
	DisplayServer.window_set_size(resolution)
	for _i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != resolution:
		failures += 1
		push_error("Invalid battle upgrade capture: " + name)
		return
	if image.save_png("%s/%s.png" % [CAPTURE_DIR, name]) != OK:
		failures += 1
		push_error("Could not save battle upgrade capture: " + name)
		return
	print("Captured " + name)
