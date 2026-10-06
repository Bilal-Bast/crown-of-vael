extends SceneTree

var failures := 0

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/battle_upgrade_ui_smoke.save")
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(main)
	await process_frame
	await process_frame
	var profile := main.get("profile") as SaveData
	var battle := main.get("battle") as BattleController
	profile.save_path = "res://.godot/battle_upgrade_ui_smoke.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	profile.campaign_complete = false
	profile.boss_retry_required = false
	profile.gold = 10000
	profile.upgrades = {"atk": 0, "hp": 0, "armor": 0, "speed": 0, "crit_chance": 0, "crit_damage": 0}
	battle.start(profile)
	await process_frame
	var battle_area: Control = main.get("battle_area")
	var battlefield_host: Control = main.get("battlefield_host")
	var skill_panel := main.find_child("BattleSkillPanel", true, false) as Control
	var upgrades_panel: Control = main.get("upgrade_panel")
	var upgrade_scroll: ScrollContainer = main.get("upgrade_list_scroll")
	var upgrade_buttons: Dictionary = main.get("upgrade_buttons")
	var nav_buttons: Dictionary = main.get("nav_buttons")
	var skill_bar: SkillBar = main.get("skill_bar")
	var nav_top_before := (nav_buttons["Heroes"] as Control).get_global_rect().position.y
	_check(battle_area.get_child_count() == 1 and battle_area.get_child(0) == battlefield_host, "battlefield fills the top battle section")
	_check(absf(battlefield_host.get_global_rect().position.y - main.get_global_rect().position.y) <= 1.0, "battlefield begins at the top edge")
	_check(skill_panel.get_parent() == battlefield_host, "skill strip overlays the bottom of the battlefield")
	_check(upgrade_scroll.get_parent() == main.get("feature_screens"), "scrolling upgrades begin in the lower feature section")
	var upgrade_guide_y := main.size.y * 0.33
	_check(absf(upgrades_panel.get_global_rect().position.y - upgrade_guide_y) <= 40.0, "upgrade panel begins just below the marked one-third screen guide")
	_check(skill_panel.get_global_rect().end.y <= battle_area.get_global_rect().end.y + 1.0, "skill controls stay above the upgrade boundary")
	_check(main.get("battle_power_divider") == null, "Power divider is removed from the Battle flow")
	_check(PixelUiIcons.gold_coin() != null and PixelUiIcons.gems() != null, "top currencies use pixel-art icons")
	var top_panel := main.find_child("TopCurrencyPanel", true, false) as Control
	var top_box := top_panel.get_child(0) as VBoxContainer
	_check(top_box.get_child_count() == 2 and (top_box.get_child(0) as HBoxContainer).get_child_count() == 3, "top overlay keeps three compact currency capsules and the hero status row")
	for capsule in (top_box.get_child(0) as HBoxContainer).get_children():
		_check((capsule as PanelContainer).get_child(0).get_child_count() == 2, "currency capsule shows an icon and value on one line")
	_check((main.get("upgrade_mode_buttons") as Dictionary).size() == 3, "x1, x10, and MAX purchase modes are available")
	_check((main.get("skill_auto_button") as Button).get_global_rect().position.x < skill_bar.get_global_rect().position.x, "skill Auto control sits at left of skill row")
	var left_shortcuts := main.find_child("FloatingShortcutsLeft", true, false) as Control
	var right_shortcuts := main.find_child("FloatingShortcutsRight", true, false) as Control
	_check(skill_bar.get_global_rect().position.x >= left_shortcuts.get_global_rect().end.x, "skill touch area stays clear of the left shortcut rail")
	_check(skill_bar.get_global_rect().end.x <= right_shortcuts.get_global_rect().position.x, "skill touch area stays clear of the right shortcut rail")
	_check((main.get("skill_auto_button") as Button).text.contains("ON"), "skill Auto starts enabled")
	_check(CompanionPixelArt.formation_x("archer_companion", 0) < CompanionPixelArt.formation_x("wolf", 0), "ranged companions are positioned behind melee companions")
	_check(CompanionPixelArt.formation_x("archer_companion", 3) < 0.24 and CompanionPixelArt.formation_x("wolf", 0) > 0.24, "ranged companions group behind hero while melee companions flank beside it")
	_check(CompanionPixelArt.formation_scale("fairy", 4) < CompanionPixelArt.formation_scale("fairy", 2) and is_equal_approx(CompanionPixelArt.formation_scale("wolf", 1), 1.0), "crowded companion groups compact slightly without resizing source art")
	_check(upgrade_scroll == main.get("battle_lower_scroll"), "upgrade cards use one continuous dedicated vertical scroller")
	_check(skill_bar.battle == battle, "four-skill row remains connected to the current battle runtime")
	var order := ["atk", "hp", "armor", "speed", "crit_chance", "crit_damage"]
	_check(upgrade_buttons.size() == order.size() and upgrade_buttons.has_all(order), "all six Gold-upgradeable stats are listed")
	await process_frame
	_check(upgrade_scroll.get_v_scroll_bar().max_value > upgrade_scroll.get_v_scroll_bar().page, "upgrade rows scroll while fixed Battle controls remain outside the scroller")
	for stat in order:
		_check(upgrade_buttons[stat].get_parent().get_parent().name == "UpgradeCard_%s" % stat, "%s has an individual RPG card" % stat)
		_check(main.get("_upgrade_stat_icon").call(stat) != null, "%s uses a production pixel icon" % stat)
	var scroll_max := int(upgrade_scroll.get_v_scroll_bar().max_value - upgrade_scroll.get_v_scroll_bar().page)
	upgrade_scroll.scroll_vertical = scroll_max
	await process_frame
	_check(upgrade_scroll.scroll_vertical > 0, "upgrade list can scroll to later rows")
	_check(is_equal_approx((nav_buttons["Heroes"] as Control).get_global_rect().position.y, nav_top_before), "bottom navigation stays fixed while upgrades scroll")
	var run_time_before_scroll := battle.run_time
	await create_timer(0.35).timeout
	_check(battle.run_time > run_time_before_scroll and battle.active, "combat and automatic skill runtime continue while the upgrade list scrolls")
	upgrade_scroll.scroll_vertical = 0
	battle.set_process(false)
	for stat in order:
		var before_gold := profile.gold
		var before_rank := int(profile.upgrades[stat])
		var before_value := float(profile.hero_stats()[stat])
		var expected_cost := GameData.upgrade_cost(before_rank, stat)
		var button := upgrade_buttons[stat] as Button
		_check(not button.disabled and main.get("upgrade_actions")[stat].text == "ENHANCE", "%s card shows an enabled Enhance action" % stat)
		_check(main.get("upgrade_costs")[stat].text != "", "%s card shows its Gold price" % stat)
		button.pressed.emit()
		await process_frame
		var after_value := float(profile.hero_stats()[stat])
		_check(int(profile.upgrades[stat]) == before_rank + 1, "%s purchase increments rank" % stat)
		_check(profile.gold == before_gold - expected_cost, "%s purchase deducts the correct Gold cost" % stat)
		_check(after_value > before_value, "%s purchase raises its combat stat" % stat)
		_check(main.get("upgrade_values")[stat].text != "" and main.get("upgrade_ranks")[stat].text != "", "%s card shows current value and upgrade rank" % stat)
	_check((main.get("power_text") as Label).text != "", "Power remains visible in the compact top bar")
	_check(battle.active, "combat continues while the player uses upgrade controls")
	var restored := SaveData.load_from(profile.save_path)
	for stat in order:
		_check(int(restored.upgrades[stat]) == int(profile.upgrades[stat]), "%s upgrade rank persists through save/load" % stat)
	_check(float(restored.hero_stats()["speed"]) > 1.4 and float(restored.hero_stats()["crit_chance"]) > 0.15 and float(restored.hero_stats()["crit_damage"]) > 1.75, "saved premium ranks affect assembled hero combat stats")
	profile.gold = 100000000
	var rank_before_x10 := int(profile.upgrades["atk"])
	var gold_before_x10 := profile.gold
	(main.get("upgrade_mode_buttons")["x10"] as Button).pressed.emit()
	(main.get("upgrade_buttons")["atk"] as Button).pressed.emit()
	_check(profile.upgrades["atk"] == rank_before_x10 + 10, "x10 purchases ten ranks")
	var x10_cost := 0
	for rank in range(rank_before_x10, rank_before_x10 + 10):
		x10_cost += GameData.upgrade_cost(rank, "atk")
	_check(profile.gold == gold_before_x10 - x10_cost, "x10 deducts each rank cost")
	_check(int(SaveData.load_from(profile.save_path).upgrades["atk"]) == int(profile.upgrades["atk"]), "x10 batch purchase persists through save/load")
	var partial_rank := int(profile.upgrades["atk"])
	profile.gold = GameData.upgrade_cost(partial_rank, "atk") + GameData.upgrade_cost(partial_rank + 1, "atk") + GameData.upgrade_cost(partial_rank + 2, "atk")
	var partial_cost := profile.gold
	(main.get("upgrade_buttons")["atk"] as Button).pressed.emit()
	_check(profile.upgrades["atk"] == partial_rank + 3 and profile.gold == 0 and partial_cost > 0, "x10 stops after the last affordable rank")
	var hp_rank := int(profile.upgrades["hp"])
	profile.gold = GameData.upgrade_cost(hp_rank, "hp") + GameData.upgrade_cost(hp_rank + 1, "hp")
	(main.get("upgrade_mode_buttons")["MAX"] as Button).pressed.emit()
	(main.get("upgrade_buttons")["hp"] as Button).pressed.emit()
	_check(profile.upgrades["hp"] == hp_rank + 2 and profile.gold == 0, "MAX stops after all affordable ranks are bought")
	profile.gold = 100000000
	var auto_button := main.get("skill_auto_button") as Button
	auto_button.pressed.emit()
	_check(not battle.skill_runtime.auto_enabled and auto_button.text.contains("OFF"), "Auto button disables automatic skill casts")
	var manual_skill := profile.equipped_skill_slots[0]
	if not battle.enemies.is_empty():
		battle.enemies[0]["current_hp"] = float(battle.enemies[0]["hp"])
		battle.enemies[0]["combat_ready"] = true
	battle.skill_runtime.cooldowns[manual_skill] = 0.0
	battle.skill_runtime.process(0.01, battle)
	_check(float(battle.skill_runtime.cooldowns[manual_skill]) == 0.0, "ready skill stays uncast automatically while Auto is off")
	_check(battle.skill_runtime.manual_cast(0, battle), "ready equipped skill casts manually while Auto is off")
	auto_button.pressed.emit()
	_check(battle.skill_runtime.auto_enabled and auto_button.text.contains("ON"), "Auto button restores automatic skill behavior")
	if not battle.enemies.is_empty():
		battle.enemies[0]["current_hp"] = float(battle.enemies[0]["hp"])
		battle.enemies[0]["combat_ready"] = true
	battle.skill_runtime.cooldowns[manual_skill] = 0.0
	battle.skill_runtime.process(0.01, battle)
	_check(float(battle.skill_runtime.cooldowns[manual_skill]) > 0.0, "ready skill auto-casts when Auto is enabled")
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
		_check((upgrade_buttons[stat] as Button).disabled and main.get("upgrade_actions")[stat].text == "MAX LEVEL", "%s maximum rank is visible and disabled" % stat)
	profile.upgrades["atk"] = GameData.upgrade_max_rank("atk") - 1
	profile.gold = 100000000
	(main.get("upgrade_mode_buttons")["MAX"] as Button).pressed.emit()
	(main.get("upgrade_buttons")["atk"] as Button).pressed.emit()
	_check(int(profile.upgrades["atk"]) == GameData.upgrade_max_rank("atk"), "MAX stops at the stat rank cap")
	main.call("_select_tab", "Heroes")
	_check((main.get("heroes_area") as Control).visible and (main.get("battle_area") as Control).visible, "battlefield remains visible behind the selected feature screen")
	main.queue_free()
	print("BATTLE UPGRADE UI SMOKE: %s (%d failures)" % ["FAIL" if failures else "PASS", failures])
	quit(1 if failures else 0)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("Battle upgrade UI smoke: " + description)
