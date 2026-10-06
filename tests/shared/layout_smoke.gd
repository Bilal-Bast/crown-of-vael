extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var main := scene.instantiate() as Control
	root.add_child(main)
	(main.get("profile") as SaveData).save_path = "res://.godot/layout_smoke.save"
	await process_frame
	await process_frame
	var field := main.get("battlefield") as Control
	var battle_area := main.get("battle_area") as Control
	var nav_buttons: Dictionary = main.get("nav_buttons")
	var nav := (nav_buttons["Battle"] as Button).get_parent().get_parent() as Control
	var upgrades: Dictionary = main.get("upgrade_buttons")
	var upgrade := upgrades["atk"] as Control
	var upgrade_list: ScrollContainer = main.get("upgrade_list_scroll")
	if battle_area.get_child_count() != 3 or battle_area.get_child(1).name != "BattleSkillPanel" or battle_area.get_child(2).name != "BattleLowerControlsScroll" or upgrade.get_global_rect().position.y <= battle_area.get_child(1).get_global_rect().position.y:
		push_error("Battle order should be Battlefield, Skills, scrollable upgrade cards.")
		quit(1)
		return
	if upgrade_list.get_v_scroll_bar().max_value <= upgrade_list.get_v_scroll_bar().page:
		push_error("Battle upgrades need their own scrollable list.")
		quit(1)
		return
	var fits := field.size.y >= 390 and battle_area.get_global_rect().end.y <= nav.get_global_rect().position.y and nav.get_global_rect().end.y <= main.get_global_rect().end.y + 1
	print("Layout: viewport=%s field=%s battle_end=%.0f nav_start=%.0f nav_end=%.0f upgrade_end=%.0f" % [str(main.size), str(field.size), battle_area.get_global_rect().end.y, nav.get_global_rect().position.y, nav.get_global_rect().end.y, upgrade.get_global_rect().end.y])
	if not fits:
		push_error("Portrait layout has clipped or overlapping core panels.")
		quit(1)
		return
	main.call("_select_tab", "Heroes")
	var heroes := main.get("heroes_area") as Control
	var equipment := main.get("equipment_area") as Control
	var placeholder := main.get("placeholder_area") as Control
	if battle_area.visible or not heroes.visible or placeholder.visible or heroes.get_global_rect().end.y > nav.get_global_rect().position.y:
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
	print("PASS: portrait battle layout fits inside the viewport.")
	quit()
