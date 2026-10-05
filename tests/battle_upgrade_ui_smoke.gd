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
	_check(upgrade_buttons.size() == 3 and upgrade_buttons.has_all(["atk", "hp", "armor"]), "only existing Gold-upgradeable stats are listed")
	await process_frame
	_check(upgrade_scroll.get_v_scroll_bar().max_value > upgrade_scroll.get_v_scroll_bar().page, "upgrade rows scroll inside their own bounded list")
	var scroll_max := int(upgrade_scroll.get_v_scroll_bar().max_value - upgrade_scroll.get_v_scroll_bar().page)
	upgrade_scroll.scroll_vertical = scroll_max
	await process_frame
	_check(upgrade_scroll.scroll_vertical > 0, "upgrade list can scroll to later rows")
	upgrade_scroll.scroll_vertical = 0
	var order := ["atk", "hp", "armor"]
	for stat in order:
		var before_gold := profile.gold
		var before_rank := int(profile.upgrades[stat])
		var before_value := float(profile.hero_stats()[stat])
		var expected_cost := GameData.upgrade_cost(before_rank)
		var button := upgrade_buttons[stat] as Button
		_check(not button.disabled and button.text.contains("GOLD"), "%s row shows an enabled purchase and cost" % stat)
		button.pressed.emit()
		await process_frame
		var after_value := float(profile.hero_stats()[stat])
		_check(int(profile.upgrades[stat]) == before_rank + 1, "%s purchase increments rank" % stat)
		_check(profile.gold == before_gold - expected_cost, "%s purchase deducts the correct Gold cost" % stat)
		_check(after_value > before_value, "%s purchase raises its combat stat" % stat)
		_check((upgrade_buttons[stat] as Button).text.contains("→"), "%s row shows current and next values" % stat)
	_check(battle.active, "combat continues while the player uses upgrade controls")
	var restored := SaveData.load_from(profile.save_path)
	for stat in order:
		_check(int(restored.upgrades[stat]) == int(profile.upgrades[stat]), "%s upgrade rank persists through save/load" % stat)
	profile.gold = 0
	main.call("_refresh_ui")
	for stat in order:
		_check((upgrade_buttons[stat] as Button).disabled, "%s purchase is disabled without enough Gold" % stat)
	main.call("_select_tab", "Heroes")
	_check((main.get("heroes_area") as Control).visible and not (main.get("battle_area") as Control).visible, "navigation remains available while battle controls are shown")
	main.queue_free()
	print("BATTLE UPGRADE UI SMOKE: %s (%d failures)" % ["FAIL" if failures else "PASS", failures])
	quit(1 if failures else 0)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("Battle upgrade UI smoke: " + description)
