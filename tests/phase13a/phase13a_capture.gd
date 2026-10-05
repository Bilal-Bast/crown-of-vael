extends SceneTree

const CAPTURE_DIR := "res://.godot/phase13a_capture"

var main: Control
var profile: SaveData
var failures := 0
var prefix := "final"

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/phase13a_capture.save")
	call_deferred("_run")

func _run() -> void:
	if root.get_texture() == null:
		push_error("Phase 13A viewport capture requires a graphical renderer; do not use --headless.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dismiss_feature_popups(main)
	profile = main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase13a_capture.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	profile.selected_hero_id = "knight"
	profile.heroes["knight"].evolution = 0
	for id in CompanionData.COMPANIONS:
		profile.companions[id] = {"level": 4, "rarity": 3, "stars": 2, "evolution": 0, "pieces": 1}
	profile.companions["wolf"].evolution = 2
	profile.equipped_companion_slots.assign(["wolf", "fairy", "young_dragon", "archer_companion"])
	profile.inventory.clear()
	profile.equipped.clear()
	for kind in ["rusted_sword", "worn_helmet", "leather_tunic", "old_gloves", "traveler_boots", "copper_necklace", "iron_ring", "knight_sword"]:
		var item := EquipmentData.create_item(kind, 3)
		profile.inventory.append(item)
		if kind == "knight_sword":
			profile.equipped["Weapon"] = item.id
	for id in ArtifactData.ARTIFACTS:
		profile.artifacts[id] = {"level": 3, "duplicates": 1, "rarity": 4}
	profile.equipped_artifact_slots.assign(["blood_crown", "dragon_heart", "dragon_fang", "", "", ""])
	var battle := main.get("battle") as BattleController
	battle.region = 1
	battle.stage = 1
	battle.mode_config = {"mode": "campaign"}
	battle.start(profile)
	battle.active = false
	for popup in ["tutorial_popup", "offline_popup", "login_popup"]:
		var node = main.get(popup)
		if node is Window or node is Control:
			node.hide()
	await _capture_tab("companions", "Companions", 360)
	await _capture("companions_1080", 1080)
	var companion_screen := main.get("companions_screen") as CompanionsScreen
	companion_screen.selected_id = "wolf"
	companion_screen.refresh()
	await _capture("companion_detail", 360)
	main.set("selected_item_id", profile.inventory.back().id)
	await _capture_tab("equipment", "Equipment", 360)
	await _capture("equipment_1080", 1080)
	await _capture("equipment_detail", 360)
	var artifact_screen := main.get("artifacts_screen") as ArtifactsScreen
	artifact_screen.selected_id = "dragon_heart"
	artifact_screen.refresh()
	await _capture_tab("artifacts", "Artifacts", 360)
	await _capture("artifacts_1080", 1080)
	await _capture("artifact_detail", 360)
	main.call("_select_tab", "Battle")
	var field := main.get("battlefield") as Battlefield
	var kinds := ["Goblin", "Corrupted Wolf", "Goblin Archer"]
	battle.enemies.clear()
	for kind in kinds:
		var enemy := CampaignData.enemy_stats(kind, 0, 1, 1, 1)
		enemy.current_hp = enemy.hp
		enemy.attack_time = 10.0
		enemy.stun_time = 0.0
		enemy.spawned = true
		enemy.combat_ready = true
		enemy.entry_time = 0.0
		battle.enemies.append(enemy)
	battle.changed.emit()
	profile.equipped_companion_slots.assign(["wolf", "", "", ""])
	field.queue_redraw()
	await _capture("battle_one_companion", 360)
	field.companion_lunges[0] = 0.18
	field.queue_redraw()
	await _capture("battle_companion_attack", 360)
	profile.equipped_companion_slots.assign(["wolf", "griffin", "archer_companion", "cleric_companion"])
	field.queue_redraw()
	await _capture("battle_multiple_companions", 360)
	await _capture("battle_overview", 1080)
	main.queue_free()
	print("PHASE 13A CAPTURE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _capture_tab(name: String, tab: String, resolution: int) -> void:
	main.call("_select_tab", tab)
	await _capture(name, resolution)

func _capture(name: String, width: int) -> void:
	var resolution := Vector2i(width, 1920 if width == 1080 else 640)
	DisplayServer.window_set_size(resolution)
	for _i in 3:
		await process_frame
		_dismiss_feature_popups(main)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != resolution:
		failures += 1
		push_error("Invalid Phase 13A capture: " + name)
		return
	var path := "%s/%s_%s.png" % [CAPTURE_DIR, prefix, name]
	if image.save_png(path) != OK:
		failures += 1
		push_error("Failed to save Phase 13A capture: " + path)
	else:
		print("Captured " + path)

func _dismiss_feature_popups(node: Node) -> void:
	if node is Window:
		node.hide()
	if node is Button and str(node.text).to_upper() in ["GOT IT", "CONTINUE", "OK"]:
		node.emit_signal("pressed")
	for child in node.get_children():
		_dismiss_feature_popups(child)
