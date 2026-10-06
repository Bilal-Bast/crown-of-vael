extends SceneTree

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/layout_smoke.save")
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(main)
	(main.get("profile") as SaveData).save_path = "res://.godot/layout_smoke.save"
	await process_frame
	await process_frame
	var field := main.get("battlefield") as Control
	var battle_area := main.get("battle_area") as Control
	var nav_buttons: Dictionary = main.get("nav_buttons")
	var nav := (nav_buttons["Heroes"] as Button).get_parent().get_parent() as Control
	var upgrades: Dictionary = main.get("upgrade_buttons")
	var upgrade_panel := main.get("upgrade_panel") as Control
	var upgrade_list: ScrollContainer = main.get("upgrade_list_scroll")
	var skill_panel := main.find_child("BattleSkillPanel", true, false) as Control
	var guide_y := main.size.y * 0.33
	if battle_area.get_child_count() != 1 or battle_area.get_child(0) != main.get("battlefield_host") or skill_panel.get_parent() != main.get("battlefield_host") or absf(field.get_global_rect().position.y - main.get_global_rect().position.y) > 1.0 or absf(upgrade_panel.get_global_rect().position.y - guide_y) > 24.0:
		push_error("Battlefield should fill the top section, with skills over it and upgrades starting at the one-third guide.")
		quit(1)
		return
	if upgrade_list.get_v_scroll_bar().max_value <= upgrade_list.get_v_scroll_bar().page:
		push_error("Battle upgrades need their own scrollable list.")
		quit(1)
		return
	var fits := field.size.y >= main.size.y * 0.33 - 12.0 and skill_panel.get_global_rect().end.y <= battle_area.get_global_rect().end.y + 1.0 and battle_area.get_global_rect().end.y <= nav.get_global_rect().position.y and nav.get_global_rect().end.y <= main.get_global_rect().end.y + 1
	print("Layout: viewport=%s field=%s battle_end=%.0f nav_start=%.0f nav_end=%.0f upgrade_panel_start=%.0f" % [str(main.size), str(field.size), battle_area.get_global_rect().end.y, nav.get_global_rect().position.y, nav.get_global_rect().end.y, upgrade_panel.get_global_rect().position.y])
	if not fits:
		push_error("Portrait layout has clipped or overlapping core panels.")
		quit(1)
		return
	main.call("_select_tab", "Heroes")
	var heroes := main.get("heroes_area") as Control
	var equipment := main.get("equipment_area") as Control
	var placeholder := main.get("placeholder_area") as Control
	if not battle_area.visible or not heroes.visible or placeholder.visible or heroes.get_global_rect().end.y > nav.get_global_rect().position.y:
		push_error("Heroes screen did not fit cleanly.")
		quit(1)
		return
	main.call("_select_tab", "Equipment")
	if not equipment.visible or heroes.visible or equipment.get_global_rect().end.y > nav.get_global_rect().position.y:
		push_error("Equipment screen did not fit cleanly.")
		quit(1)
		return
	main.call("_select_tab", "Battle")
	if not battle_area.visible or placeholder.visible or equipment.visible:
		push_error("Battle tab did not reopen cleanly.")
		quit(1)
		return
	main.call("_select_tab", "Heroes")
	main.call("_select_tab", "Heroes")
	if str(main.get("selected_tab")) != "Battle" or not (main.get("battle_lower_scroll") as Control).visible or heroes.visible:
		push_error("Tapping the selected dock item again should return to Battle.")
		quit(1)
		return
	print("PASS: portrait battle layout fits inside the viewport.")
	quit()
