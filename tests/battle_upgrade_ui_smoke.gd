extends SceneTree

var failures := 0

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/battle_upgrade_ui_smoke.save")
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	main.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	main.size = Vector2(360, 640)
	root.add_child(main)
	await process_frame
	await process_frame
	var profile := main.get("profile") as SaveData
	var battle := main.get("battle") as BattleController
	profile.save_path = "res://.godot/battle_upgrade_ui_smoke.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	profile.gold = 10000
	var lower: VBoxContainer = main.get("battle_lower_content")
	var upgrades_panel: Control = main.get("upgrade_panel")
	var upgrade_scroll: ScrollContainer = main.get("upgrade_list_scroll")
	var upgrade_buttons: Dictionary = main.get("upgrade_buttons")
	_check(lower.get_child_count() >= 3, "battle lower section contains skills, upgrades, and hero information")
	_check(lower.get_child(0).get_global_rect().position.y < upgrades_panel.get_global_rect().position.y, "skill bar is above upgrade panel")
	_check(upgrades_panel.get_global_rect().position.y < lower.get_child(2).get_global_rect().position.y, "hero information is below upgrades")
	var order := ["atk", "hp", "armor", "speed", "crit_chance", "crit_damage"]
	_check(upgrade_buttons.size() == order.size() and upgrade_buttons.has_all(order), "all six Gold-upgradeable stats are listed")
	await process_frame
	_check(upgrade_scroll.get_v_scroll_bar().max_value > upgrade_scroll.get_v_scroll_bar().page, "upgrade rows scroll inside their own bounded list")
	var scroll_max := int(upgrade_scroll.get_v_scroll_bar().max_value - upgrade_scroll.get_v_scroll_bar().page)
	upgrade_scroll.scroll_vertical = scroll_max
	await process_frame
	_check(upgrade_scroll.scroll_vertical > 0, "upgrade list can scroll to later rows")
	upgrade_scroll.scroll_vertical = 0
	for stat in order:
		var before_gold := profile.gold
		var before_rank := int(profile.upgrades[stat])
		var before_value := float(profile.hero_stats()[stat])
		var expected_cost := GameData.upgrade_cost(before_rank, stat)
		var button := upgrade_buttons[stat] as Button
		_check(not button.disabled and button.text.contains("GOLD"), "%s row shows an enabled purchase and cost" % stat)
		button.pressed.emit()
		await process_frame
		var after_value := float(profile.hero_stats()[stat])
		_check(int(profile.upgrades[stat]) == before_rank + 1, "%s purchase increments rank" % stat)
		_check(profile.gold == before_gold - expected_cost, "%s purchase deducts the correct Gold cost" % stat)
		_check(after_value > before_value, "%s purchase raises its combat stat" % stat)
		_check((upgrade_buttons[stat] as Button).text.contains("→"), "%s row shows current and next values" % stat)
	var hero_info := (main.get("hero_stats_text") as Label).text
	_check(hero_info.contains("SPEED %.2f/s" % float(profile.hero_stats()["speed"])), "Attack Speed purchase immediately updates hero information")
	_check(hero_info.contains("CRIT %d%%" % roundi(float(profile.hero_stats()["crit_chance"]) * 100.0)), "Crit Chance purchase immediately updates hero information")
	_check(hero_info.contains("CRIT DMG %d%%" % roundi(float(profile.hero_stats()["crit_damage"]) * 100.0)), "Crit Damage purchase immediately updates hero information")
	_check(battle.active, "combat continues while the player uses upgrade controls")
	var restored := SaveData.load_from(profile.save_path)
	for stat in order:
		_check(int(restored.upgrades[stat]) == int(profile.upgrades[stat]), "%s upgrade rank persists through save/load" % stat)
	_check(float(restored.hero_stats()["speed"]) > 1.4 and float(restored.hero_stats()["crit_chance"]) > 0.15 and float(restored.hero_stats()["crit_damage"]) > 1.75, "saved premium ranks affect assembled hero combat stats")
	var legacy_path := "res://.godot/battle_upgrade_legacy.save"
	var legacy_file := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({"upgrades": {"atk": 2, "hp": 3, "armor": 4}}))
	legacy_file.close()
	var legacy_profile := SaveData.load_from(legacy_path)
	_check(legacy_profile.upgrades["speed"] == 0 and legacy_profile.upgrades["crit_chance"] == 0 and legacy_profile.upgrades["crit_damage"] == 0, "legacy saves default newly added upgrade ranks to zero")
	for rank in [0, 10, 25, 50, 100]:
		var sample := GameData.hero_stats(1, {"speed": rank, "crit_chance": rank, "crit_damage": rank})
		_check(is_equal_approx(float(sample["speed"]), 1.4 + float(rank) * 0.01), "attack speed rank %d contribution" % rank)
		_check(is_equal_approx(float(sample["crit_chance"]), 0.15 + float(rank) * 0.0025), "crit chance rank %d contribution" % rank)
		_check(is_equal_approx(float(sample["crit_damage"]), 1.75 + float(rank) * 0.01), "crit damage rank %d contribution" % rank)
		print("UPGRADE RANK %d: speed %.2f/s (Gold +%.2f), crit %.2f%% (Gold +%.2fpp), crit damage %.0f%% (Gold +%.0fpp)" % [rank, sample["speed"], float(rank)*0.01, sample["crit_chance"]*100.0, float(rank)*0.25, sample["crit_damage"]*100.0, float(rank)])
	_check(GameData.upgrade_cost(10, "speed") == ceili(GameData.upgrade_cost(10) * 2.25), "attack speed premium cost multiplier")
	_check(GameData.upgrade_cost(10, "crit_chance") == ceili(GameData.upgrade_cost(10) * 2.75), "crit chance premium cost multiplier")
	_check(GameData.upgrade_cost(10, "crit_damage") == ceili(GameData.upgrade_cost(10) * 1.75), "crit damage premium cost multiplier")
	var cap_stats := HeroData.apply_stats(GameData.hero_stats(1, {"crit_chance": 100}, {"crit_chance": 1.2}), profile)
	_check(float(cap_stats["crit_chance"]) == 1.0, "final assembled Crit Chance has an absolute 100% cap")
	_check(is_equal_approx(float(GameData.hero_stats(1, {"speed": 999})["speed"]), 2.4), "Gold Attack Speed contribution stops at rank 100")
	profile.gold = 0
	main.call("_refresh_ui")
	for stat in order:
		_check((upgrade_buttons[stat] as Button).disabled, "%s purchase is disabled without enough Gold" % stat)
	profile.gold = 10000000
	for stat in ["speed", "crit_chance", "crit_damage"]:
		profile.upgrades[stat] = GameData.PREMIUM_UPGRADE_MAX_RANK
		_check(not profile.buy_upgrade(stat), "%s refuses purchases above its rank cap" % stat)
	main.call("_refresh_ui")
	for stat in ["speed", "crit_chance", "crit_damage"]:
		_check((upgrade_buttons[stat] as Button).disabled and (upgrade_buttons[stat] as Button).text.contains("MAX RANK"), "%s maximum rank is visible and disabled" % stat)
	main.call("_select_tab", "Heroes")
	_check((main.get("heroes_area") as Control).visible and not (main.get("battle_area") as Control).visible, "navigation remains available while battle controls are shown")
	main.queue_free()
	print("BATTLE UPGRADE UI SMOKE: %s (%d failures)" % ["FAIL" if failures else "PASS", failures])
	quit(1 if failures else 0)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("Battle upgrade UI smoke: " + description)
