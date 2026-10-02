extends SceneTree

const CAPTURE_DIR := "res://.godot/prototype_pixel_captures"
const SMALL := Vector2i(360, 640)
const LARGE := Vector2i(1080, 1920)
const NORMALS := ["Forest Goblin", "Giant Spider", "Corrupted Boar", "Forest Bandit", "Skeleton Archer", "Poison Wolf"]
const MIX := ["Forest Goblin", "Giant Spider", "Corrupted Boar", "Forest Bandit", "Skeleton Archer", "Poison Wolf"]
var main: Control
var profile: SaveData
var battle: BattleController
var battlefield: Battlefield
var failures := 0

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/whispering_forest_capture.save")
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.position = Vector2.ZERO
	main.scale = Vector2.ONE
	profile = main.get("profile") as SaveData
	battle = main.get("battle") as BattleController
	battlefield = main.get("battlefield") as Battlefield
	profile.save_path = "res://.godot/whispering_forest_capture.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	profile.selected_hero_id = "knight"
	profile.heroes["knight"]["evolution"] = 0
	profile.region = 2
	profile.stage = 1
	battle.region = 2
	battle.stage = 1
	battle.wave = 1
	battle.mode_config = {"mode": "campaign"}
	battle.start(profile)
	battle.active = false
	main.call("_select_tab", "Battle")
	for popup_name in ["tutorial_popup", "offline_popup", "login_popup"]:
		var popup = main.get(popup_name)
		if popup is Window or popup is Control:
			popup.hide()
	for kind in NORMALS:
		_set_enemies([kind])
		_clear_vfx()
		await _capture("wf_%s_idle_360x640" % _slug(kind), SMALL)
		_start_attack(0)
		await _capture("wf_%s_attack_360x640" % _slug(kind), SMALL)
		_start_hit(0)
		await _capture("wf_%s_hit_360x640" % _slug(kind), SMALL)
		if kind == "Skeleton Archer":
			_start_attack(0)
			if not battlefield.vfx.projectiles.is_empty():
				battlefield.vfx.projectiles[0]["age"] = 0.18
				battlefield.vfx.projectiles[0]["life"] = 0.8
			await _capture("wf_skeleton_archer_projectile_360x640", SMALL)
	for kind in ["Spider Matriarch", "Forest Brute"]:
		_set_enemies([kind])
		await _capture("wf_%s_idle_360x640" % _slug(kind), SMALL)
		_start_attack(0)
		await _capture("wf_%s_attack_360x640" % _slug(kind), SMALL)
		_start_hit(0)
		await _capture("wf_%s_hit_360x640" % _slug(kind), SMALL)
	_set_enemies(["Ancient Treant"], true, true)
	await _capture("wf_ancient_treant_entrance_360x640", SMALL)
	battle.enemies[0]["entry_time"] = 0.0
	_start_attack(0)
	await _capture("wf_ancient_treant_attack_360x640", SMALL)
	battle.enemies[0]["current_hp"] = 0.0
	battlefield._on_enemy_defeated(0, 0, 0)
	if not battlefield.deaths.is_empty():
		battlefield.deaths[0]["age"] = 0.32
	battlefield.queue_redraw()
	await _capture("wf_ancient_treant_death_360x640", SMALL)
	_set_enemies(MIX + ["Spider Matriarch"])
	await _capture("wf_crowded_mixed_seven_360x640", SMALL)
	battlefield.hero_run_time = 1.1
	await _capture("wf_interwave_run_360x640", SMALL)
	battlefield.hero_run_time = 0.0
	await _capture("wf_battle_overview_1080x1920", LARGE)
	_set_enemies(["Ancient Treant"], false, true)
	await _capture("wf_ancient_treant_overview_1080x1920", LARGE)
	main.queue_free()
	print("WHISPERING FOREST CAPTURES: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _set_enemies(kinds: Array, entering := false, boss := false) -> void:
	battle.enemies.clear()
	battle.stage = 20 if boss else 1
	for kind in kinds:
		var enemy := CampaignData.enemy_stats(str(kind), 0, 2, battle.stage, 1)
		enemy["current_hp"] = enemy["hp"]
		enemy["attack_time"] = 3.0
		enemy["stun_time"] = 0.0
		enemy["spawned"] = true
		enemy["entry_time"] = 0.42 if entering else 0.0
		battle.enemies.append(enemy)
	battlefield.enemy_attack_times.clear()
	battlefield.enemy_hit_times.clear()
	battlefield.enemy_attack_art_durations.clear()
	battlefield.enemy_hit_art_durations.clear()
	battlefield.deaths.clear()
	battle.changed.emit()

func _start_attack(index: int) -> void:
	_clear_vfx()
	battlefield._on_attack_started(index, -1)
	var kind := str(battle.enemies[index].get("visual", ""))
	var fps := PixelBattleArt.animation_fps(kind, "attack")
	battlefield.enemy_attack_times[index] = battlefield.enemy_attack_art_durations[index] - minf(2.0, PixelBattleArt.animation_frame_count(kind, "attack") - 1.0) / fps
	battlefield._process(0.0)

func _start_hit(index: int) -> void:
	_clear_vfx()
	battlefield._on_damage_popup(index, 11, false, false)
	var kind := str(battle.enemies[index].get("visual", ""))
	var fps := PixelBattleArt.animation_fps(kind, "hit")
	battlefield.enemy_hit_times[index] = battlefield.enemy_hit_art_durations[index] - 1.0 / fps
	battlefield._process(0.0)

func _clear_vfx() -> void:
	battlefield.floaters.clear()
	battlefield.impacts.clear()
	battlefield.queue_redraw()

func _capture(name: String, resolution: Vector2i) -> void:
	DisplayServer.window_set_size(resolution)
	for _frame in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != resolution:
		failures += 1
		push_error("Unexpected capture size for " + name)
	if image.save_png("%s/%s.png" % [CAPTURE_DIR, name]) != OK:
		failures += 1
		push_error("Capture write failed for " + name)
	print("Captured ", name)

func _slug(value: String) -> String:
	return value.to_lower().replace(" ", "_")
