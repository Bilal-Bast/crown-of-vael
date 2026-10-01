extends SceneTree

const CAPTURE_DIR := "res://.godot/prototype_pixel_captures"
const RESOLUTION_SMALL := Vector2i(360, 640)
const RESOLUTION_LARGE := Vector2i(1080, 1920)
const ENEMIES := ["Goblin", "Skeleton", "Corrupted Wolf"]

var failures := 0
var main: Control
var profile: SaveData
var battle: BattleController
var battlefield: Battlefield

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/prototype_pixel_test.save")
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.position = Vector2.ZERO
	main.scale = Vector2.ONE
	main.rotation = 0.0
	profile = main.get("profile") as SaveData
	battle = main.get("battle") as BattleController
	battlefield = main.get("battlefield") as Battlefield
	profile.save_path = "res://.godot/prototype_pixel_test.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	profile.last_login_reward_date = CalendarService.day()
	for feature in TutorialService.FEATURES:
		profile.tutorial_state.features[feature] = true
	await process_frame
	var tutorial_popup := main.get("tutorial_popup") as Window
	if tutorial_popup != null:
		tutorial_popup.hide()
	var offline_popup := main.get("offline_popup") as Control
	if offline_popup != null:
		offline_popup.hide()
	var login_popup := main.get("login_popup") as Window
	if login_popup != null:
		login_popup.hide()
	var tutorial_popup_debug: Window = main.get("tutorial_popup") as Window
	if tutorial_popup_debug != null:
		tutorial_popup_debug.hide()
	profile.selected_hero_id = "knight"
	profile.heroes["knight"]["evolution"] = 0
	profile.region = 1
	profile.stage = 1
	battle.region = 1
	battle.stage = 1
	battle.wave = 1
	battle.mode_config = {"mode": "campaign"}
	battle.active = false
	battle.start(profile)
	_check(battle.active and not battle.enemies.is_empty(), "Greenvale campaign battle starts")
	battle.active = false
	main.call("_select_tab", "Battle")
	var tutorial_popup_after_select: Window = main.get("tutorial_popup") as Window
	if tutorial_popup_after_select != null:
		tutorial_popup_after_select.hide()
	_check(PixelBattleArt.is_active(battle), "Prototype activates for Squire in Greenvale campaign")
	_check(PixelBattleArt.validation_report().is_empty(), "All prototype textures load and sprite sheets have three frames")
	var run_frames: Array[Texture2D] = []
	for frame_index in 6:
		var run_frame := PixelBattleArt.hero_run_frame(frame_index)
		_check(run_frame != null, "Squire run frame %d loads" % (frame_index + 1))
		if run_frame != null:
			run_frames.append(run_frame)
	_check(run_frames.size() == 6 and run_frames[0] == PixelBattleArt.hero_run_frame(6), "Six run frames loop back to frame one")
	_check(PixelBattleArt.enemy_sheet("Goblin") != null, "Goblin sheet loads")
	_check(PixelBattleArt.enemy_sheet("Skeleton") != null, "Skeleton sheet loads")
	_check(PixelBattleArt.enemy_sheet("Corrupted Wolf") != null, "Corrupted Wolf sheet loads")
	_check(PixelBattleArt.background_texture() != null, "Greenvale pixel background loads")
	_check(battlefield.pixel_background_layer != null and battlefield.pixel_background_layer.visible, "Pixel background layer is active")
	for kind in ENEMIES:
		var sheet := PixelBattleArt.enemy_sheet(kind)
		_check(PixelBattleArt.frame_texture(sheet, "attack", "test:%s" % kind) != null, "%s attack frame loads" % kind)
		_check(PixelBattleArt.frame_texture(sheet, "hit", "test:%s" % kind) != null, "%s hit frame loads" % kind)
	battle.region = 2
	_check(not PixelBattleArt.is_active(battle), "Prototype stays scoped outside Greenvale")
	battle.region = 1

	_set_enemies(["Goblin"])
	await _capture("squire_vs_goblin_360x640", RESOLUTION_SMALL)
	_set_enemies(["Skeleton"])
	await _capture("squire_vs_skeleton_360x640", RESOLUTION_SMALL)
	_set_enemies(["Corrupted Wolf"])
	await _capture("squire_vs_corrupted_wolf_360x640", RESOLUTION_SMALL)
	_set_enemies(ENEMIES)
	await _capture("greenvale_mixed_wave_360x640", RESOLUTION_SMALL)
	battlefield._on_attack_started(-1, 0)
	await process_frame
	_check(battlefield.hero_attack_art_time > 0.0, "Squire attack presentation starts")
	await _capture("squire_attack_360x640", RESOLUTION_SMALL)
	for index in battle.enemies.size():
		battlefield._on_attack_started(index, -1)
		_check(float(battlefield.enemy_attack_times.get(index, 0.0)) > 0.0, "%s attack presentation starts" % str(battle.enemies[index].get("visual", "enemy")))
	await _capture("greenvale_enemy_attacks_360x640", RESOLUTION_SMALL)
	battlefield._on_damage_popup(0, 10, false, false)
	_check(battlefield.enemy_visual_state(0) == "hit", "Enemy hit presentation starts")
	await _capture("enemy_hit_360x640", RESOLUTION_SMALL)
	battlefield._on_skill_cast("shield_bash", 0)
	_check(battlefield.pixel_skill_effect_time > 0.0, "Pixel Shield Bash effect starts")
	# Keep the inspection effect visible despite window resizing and screenshot readback.
	battlefield.pixel_skill_effect_time = 1.2
	_check(battlefield.pixel_skill_effect_time > 0.0, "Pixel Shield Bash effect is active for capture")
	battlefield.queue_redraw()
	await _capture("shield_bash_360x640", RESOLUTION_SMALL)
	await _capture("battle_overview_360x640", RESOLUTION_SMALL)
	battle.active = false
	for enemy in battle.enemies:
		enemy["current_hp"] = 0.0
	battle.changed.emit()
	battle.wave = 1
	battlefield._on_presentation_event("wave_run", {"duration": 1.5})
	battlefield.hero_run_time = 0.75
	battlefield.queue_redraw()
	await process_frame
	_check(battlefield.pixel_hero_sprite != null and battlefield.pixel_hero_sprite.texture == PixelBattleArt.hero_run_frame(1), "Squire run animation is used during the inter-wave transition")
	await _capture("squire_run_after_wave_1_360x640", RESOLUTION_SMALL)
	battle.wave = 2
	battlefield._on_presentation_event("wave_run", {"duration": 1.5})
	battlefield.hero_run_time = 0.75
	battlefield.queue_redraw()
	await process_frame
	await _capture("squire_run_after_wave_2_360x640", RESOLUTION_SMALL)
	await _capture("greenvale_mixed_wave_1080x1920", RESOLUTION_LARGE)
	await _capture("battle_overview_1080x1920", RESOLUTION_LARGE)

	main.queue_free()
	print("PIXEL BATTLE PROTOTYPE: %s (13 captures, %d failures)" % ["FAIL" if failures else "PASS", failures])
	quit(1 if failures else 0)

func _set_enemies(kinds: Array) -> void:
	battle.enemies.clear()
	for kind in kinds:
		var enemy := CampaignData.enemy_stats(str(kind), 0, 1, battle.stage, 1)
		enemy["current_hp"] = enemy["hp"]
		enemy["attack_time"] = 3.0
		enemy["stun_time"] = 0.0
		battle.enemies.append(enemy)
	battlefield.enemy_attack_times.clear()
	battlefield.enemy_hit_times.clear()
	battlefield.flashes.clear()
	battle.changed.emit()

func _capture(name: String, resolution: Vector2i) -> void:
	DisplayServer.window_set_size(resolution)
	for _frame in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.get_size() == resolution, "%s capture is %dx%d" % [name, resolution.x, resolution.y])
	var path := "%s/%s.png" % [CAPTURE_DIR, name]
	_check(image.save_png(path) == OK, "%s capture saves" % name)
	print("Captured ", path)

func _check(condition: bool, description: String) -> void:
	if condition:
		return
	failures += 1
	push_error("Prototype smoke failure: " + description)
