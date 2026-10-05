extends SceneTree

const CAPTURE_DIR := "res://.godot/prototype_pixel_captures"
const RESOLUTION_SMALL := Vector2i(360, 640)
const RESOLUTION_LARGE := Vector2i(1080, 1920)
const RESOLUTION_TALL := Vector2i(1080, 2400)
const ENEMIES := ["Goblin", "Skeleton", "Corrupted Wolf"]
const GREENVALE_ROSTER := ["Goblin", "Skeleton", "Corrupted Wolf", "Goblin Archer", "Goblin Spearman", "Bandit", "Goblin Captain", "Armored Skeleton", "Goblin Warlord"]
const ENTRY_FPS := {"Goblin": 11.0, "Skeleton": 9.0, "Corrupted Wolf": 11.0, "Goblin Archer": 11.0, "Goblin Spearman": 10.0, "Bandit": 12.0, "Goblin Captain": 10.0, "Armored Skeleton": 8.0, "Goblin Warlord": 8.0}

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
	_check(PixelBattleArt.validation_report().is_empty(), "All prototype textures and combat animation sheets load")
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
	for kind in GREENVALE_ROSTER:
		_check(PixelBattleArt.enemy_sheet(kind) != null, "%s production pixel sheet loads" % kind)
		var frame_count := PixelBattleArt.enemy_entry_frame_count(kind)
		_check(frame_count in [4, 5, 6], "%s entry frame count is valid" % kind)
	_check(PixelBattleArt.enemy_entry_frame_count("Goblin") == 4 and is_equal_approx(PixelBattleArt.enemy_entry_fps("Goblin"), ENTRY_FPS["Goblin"]), "Goblin entry uses four frames at 11 FPS")
	_check(PixelBattleArt.enemy_entry_frame_count("Skeleton") == 4 and is_equal_approx(PixelBattleArt.enemy_entry_fps("Skeleton"), ENTRY_FPS["Skeleton"]), "Skeleton entry uses four frames at 9 FPS")
	_check(PixelBattleArt.enemy_entry_frame_count("Corrupted Wolf") == 4 and is_equal_approx(PixelBattleArt.enemy_entry_fps("Corrupted Wolf"), ENTRY_FPS["Corrupted Wolf"]), "Wolf entry uses four frames at 11 FPS")
	for kind in GREENVALE_ROSTER:
		_check(PixelBattleArt.enemy_entry_frame(kind, 0) != null, "%s entry frame loads" % kind)
	_check(PixelBattleArt.background_texture() != null, "Greenvale pixel background loads")
	_check(battlefield.pixel_background_layer != null and battlefield.pixel_background_layer.visible, "Pixel background layer is active")
	for kind in ENEMIES:
		var sheet := PixelBattleArt.enemy_sheet(kind)
		_check(PixelBattleArt.frame_texture(sheet, "attack", "test:%s" % kind) != null, "%s attack frame loads" % kind)
		_check(PixelBattleArt.frame_texture(sheet, "hit", "test:%s" % kind) != null, "%s hit frame loads" % kind)
	battle.region = 3
	_check(PixelBattleArt.is_active(battle), "Ashen Highlands shares the production pixel renderer")
	battle.region = 1

	_set_enemies(["Goblin"])
	await _capture("squire_vs_goblin_360x640", RESOLUTION_SMALL)
	_set_enemies(["Skeleton"])
	await _capture("squire_vs_skeleton_360x640", RESOLUTION_SMALL)
	_set_enemies(["Corrupted Wolf"])
	await _capture("squire_vs_corrupted_wolf_360x640", RESOLUTION_SMALL)
	for kind in ENEMIES:
		_set_enemies([kind], true)
		battle.enemies[0]["entry_time"] = 0.25
		_check(battlefield.enemy_visual_state(0) == "entry", "%s uses entry animation while moving" % kind)
		var frame_count := PixelBattleArt.enemy_entry_frame_count(kind)
		var fps := PixelBattleArt.enemy_entry_fps(kind)
		var first_frame := int(floor((GameData.ENEMY_ENTRY_DURATION - float(battle.enemies[0]["entry_time"])) * fps)) % frame_count
		battlefield._update_pixel_enemy_sprite(0, battlefield._enemy_position(0), battle.enemies[0], "entry", 1.0)
		var first_texture := battlefield.pixel_enemy_sprites[0].texture
		battle.enemies[0]["entry_time"] -= 0.10
		var next_frame := int(floor((GameData.ENEMY_ENTRY_DURATION - float(battle.enemies[0]["entry_time"])) * fps)) % frame_count
		battlefield._update_pixel_enemy_sprite(0, battlefield._enemy_position(0), battle.enemies[0], "entry", 1.0)
		_check(first_texture == PixelBattleArt.enemy_entry_frame(kind, first_frame) and battlefield.pixel_enemy_sprites[0].texture == PixelBattleArt.enemy_entry_frame(kind, next_frame) and first_frame != next_frame, "%s entry frames advance at the configured playback speed" % kind)
		battle.enemies[0]["entry_time"] = 0.25
		await _capture("%s_entry_360x640" % str(kind).to_lower().replace(" ", "_"), RESOLUTION_SMALL)
		battle.enemies[0]["entry_time"] = 0.0
		_check(battlefield.enemy_visual_state(0) == "idle", "%s returns to idle after entry" % kind)
	_check(PixelBattleArt.enemy_entry_frame("Unsupported Greenvale enemy", 0) == null, "unsupported enemy falls back without an entry sheet")
	_set_mixed_entry_wave()
	battle.enemies[0]["entry_time"] = 0.0
	battle.enemies[1]["entry_time"] = 0.0
	battle.enemies[2]["entry_time"] = 0.01
	_check(battlefield.enemy_visual_state(0) == "idle" and battlefield.enemy_visual_state(1) == "idle" and battlefield.enemy_visual_state(2) == "entry", "mixed wave holds settled enemies while another enters")
	await _capture("greenvale_mixed_entry_360x640", RESOLUTION_SMALL)
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
	battlefield.hero_attack_art_time = 0.0
	battlefield.hero_guard_art_time = 0.0
	battlefield.hero_hit_art_time = 0.0
	battlefield.queue_redraw()
	await process_frame
	await process_frame
	var expected_run_frame := int(floor((battlefield.hero_run_duration - battlefield.hero_run_time) * 10.0)) % 6
	battlefield._update_pixel_hero_sprite(battlefield._hero_position(), 0.36)
	_check(battlefield.pixel_hero_sprite != null and battlefield.pixel_hero_sprite.texture == PixelBattleArt.hero_run_frame(expected_run_frame), "Squire run animation is used during the inter-wave transition")
	await _capture("squire_run_after_wave_1_360x640", RESOLUTION_SMALL)
	battle.wave = 2
	battlefield._on_presentation_event("wave_run", {"duration": 1.5})
	battlefield.hero_run_time = 0.75
	battlefield.queue_redraw()
	await process_frame
	await _capture("squire_run_after_wave_2_360x640", RESOLUTION_SMALL)
	await _capture("greenvale_mixed_wave_1080x1920", RESOLUTION_LARGE)
	await _capture("battle_overview_1080x1920", RESOLUTION_LARGE)
	for layout in ["normal", "crowded", "boss"]:
		for resolution in [RESOLUTION_SMALL, RESOLUTION_LARGE, RESOLUTION_TALL]:
			battle.stage = 20 if layout == "boss" else 1
			match layout:
				"normal": _set_enemies(["Goblin"])
				"crowded":
					_set_mixed_entry_wave()
					battle.enemies[0]["entry_time"] = 0.0
					battle.enemies[1]["entry_time"] = 0.0
					battle.enemies[2]["entry_time"] = 0.15
					battle.changed.emit()
				"boss": _set_enemies(["Goblin Warlord"])
			await _capture("battle_layout_%s_%dx%d" % [layout, resolution.x, resolution.y], resolution)
			var expected_height := main.get_viewport_rect().size.y * 0.30
			var actual_height := (main.get("battlefield_host") as Control).custom_minimum_size.y
			_check(is_equal_approx(actual_height, expected_height), "battlefield scales to 30%% at %dx%d" % [resolution.x, resolution.y])
	await _capture_combat_animation_samples()
	await _capture_greenvale_boss_samples()

	main.queue_free()
	print("PIXEL BATTLE PROTOTYPE: %s (production Greenvale captures, %d failures)" % ["FAIL" if failures else "PASS", failures])
	quit(1 if failures else 0)

func _set_enemies(kinds: Array, entering: bool = false) -> void:
	battle.enemies.clear()
	for kind in kinds:
		var enemy := CampaignData.enemy_stats(str(kind), 0, 1, battle.stage, 1)
		enemy["current_hp"] = enemy["hp"]
		enemy["attack_time"] = 3.0
		enemy["stun_time"] = 0.0
		enemy["spawned"] = true
		enemy["entry_time"] = GameData.ENEMY_ENTRY_DURATION if entering else 0.0
		enemy["combat_ready"] = not entering
		battle.enemies.append(enemy)
	battlefield.enemy_attack_times.clear()
	battlefield.enemy_hit_times.clear()
	battlefield.enemy_attack_art_durations.clear()
	battlefield.enemy_hit_art_durations.clear()
	battlefield.deaths.clear()
	battlefield.flashes.clear()
	battle.changed.emit()

func _set_mixed_entry_wave() -> void:
	_set_enemies(ENEMIES, true)
	for _index in range(ENEMIES.size(), GameData.ENEMIES_PER_WAVE):
		var enemy := CampaignData.enemy_stats("Goblin", 0, 1, battle.stage, 1)
		enemy["current_hp"] = 0.0
		enemy["attack_time"] = 3.0
		enemy["stun_time"] = 0.0
		enemy["spawned"] = false
		enemy["entry_time"] = 0.0
		battle.enemies.append(enemy)
	battle.changed.emit()

func _capture_combat_animation_samples() -> void:
	battle.active = false
	battle.stage = 1
	_set_enemies(["Goblin"])
	battlefield.hero_attack_art_time = 0.0
	battlefield.hero_guard_art_time = 0.0
	battlefield.hero_hit_art_time = 0.0
	battlefield.hero_run_time = 0.0
	battlefield._process(0.0)
	_clear_animation_capture_vfx()
	await _capture("squire_idle_360x640", RESOLUTION_SMALL)
	battlefield._on_attack_started(-1, 0)
	battlefield.hero_attack_art_time = battlefield.hero_attack_art_duration - 2.0 / PixelBattleArt.animation_fps("Squire", "attack")
	battlefield._process(0.0)
	_clear_animation_capture_vfx()
	await _capture("squire_attack_animation_360x640", RESOLUTION_SMALL)
	battlefield.hero_attack_art_time = 0.0
	battlefield._on_skill_cast("shield_bash", 0)
	battlefield.hero_guard_art_time = battlefield.hero_guard_art_duration - 2.0 / PixelBattleArt.animation_fps("Squire", "guard")
	battlefield.pixel_skill_effect_time = 0.24
	# Preserve the production-sized burst through window resizing and screenshot readback.
	battlefield.pixel_impact_overlay.duration = 1.2
	battlefield.pixel_impact_overlay.age = 0.0
	battlefield._process(0.0)
	_clear_animation_capture_vfx()
	await _capture("squire_shield_bash_360x640", RESOLUTION_SMALL)
	battlefield.hero_guard_art_time = 0.0
	battlefield._on_damage_popup(-1, 9, false, false)
	battlefield.hero_hit_art_time = battlefield.hero_hit_art_duration - 1.0 / PixelBattleArt.animation_fps("Squire", "hit")
	battlefield._process(0.0)
	_clear_animation_capture_vfx()
	await _capture("squire_hit_360x640", RESOLUTION_SMALL)

	for kind in ENEMIES:
		_set_enemies([kind])
		_clear_animation_capture_vfx()
		await _capture("%s_idle_animation_360x640" % str(kind).to_lower().replace(" ", "_"), RESOLUTION_SMALL)
		battlefield._on_attack_started(0, -1)
		var attack_fps := PixelBattleArt.animation_fps(kind, "attack")
		battlefield.enemy_attack_times[0] = float(battlefield.enemy_attack_art_durations[0]) - 1.5 / attack_fps
		battlefield._process(0.0)
		_clear_animation_capture_vfx()
		await _capture("%s_attack_animation_360x640" % str(kind).to_lower().replace(" ", "_"), RESOLUTION_SMALL)
		battlefield._on_damage_popup(0, 11, false, false)
		var hit_fps := PixelBattleArt.animation_fps(kind, "hit")
		battlefield.enemy_hit_times[0] = float(battlefield.enemy_hit_art_durations[0]) - 1.0 / hit_fps
		battlefield._process(0.0)
		_clear_animation_capture_vfx()
		await _capture("%s_hit_animation_360x640" % str(kind).to_lower().replace(" ", "_"), RESOLUTION_SMALL)
	for kind in GREENVALE_ROSTER.slice(3):
		_set_enemies([kind], kind == "Goblin Warlord")
		_clear_animation_capture_vfx()
		await _capture("%s_idle_animation_360x640" % str(kind).to_lower().replace(" ", "_"), RESOLUTION_SMALL)
		battlefield._on_attack_started(0, -1)
		var attack_fps := PixelBattleArt.animation_fps(kind, "attack")
		battlefield.enemy_attack_times[0] = float(battlefield.enemy_attack_art_durations[0]) - minf(2.0, PixelBattleArt.animation_frame_count(kind, "attack") - 1.0) / attack_fps
		battlefield._process(0.0)
		_clear_animation_capture_vfx()
		await _capture("%s_attack_animation_360x640" % str(kind).to_lower().replace(" ", "_"), RESOLUTION_SMALL)
		if kind != "Goblin Warlord":
			battlefield._on_damage_popup(0, 11, false, false)
			var hit_fps := PixelBattleArt.animation_fps(kind, "hit")
			battlefield.enemy_hit_times[0] = float(battlefield.enemy_hit_art_durations[0]) - 1.0 / hit_fps
			battlefield._process(0.0)
			_clear_animation_capture_vfx()
			await _capture("%s_hit_animation_360x640" % str(kind).to_lower().replace(" ", "_"), RESOLUTION_SMALL)

	_set_seven_active_enemies()
	_clear_animation_capture_vfx()
	await _capture("greenvale_crowded_seven_enemy_360x640", RESOLUTION_SMALL)
	_set_enemies(ENEMIES)
	battlefield._on_attack_started(0, -1)
	battlefield._process(0.12)
	battlefield._on_attack_started(2, -1)
	_check(battlefield.enemy_visual_state(0) == "attack" and battlefield.enemy_visual_state(2) == "attack" and battlefield.enemy_visual_state(1) == "idle", "simultaneous enemy actions remain independent")
	_clear_animation_capture_vfx()
	await _capture("greenvale_multiple_independent_attacks_360x640", RESOLUTION_SMALL)
	await _capture("greenvale_combat_overview_1080x1920", RESOLUTION_LARGE)
	_set_enemies(["Goblin Archer"])
	_clear_animation_capture_vfx()
	battlefield._on_attack_started(0, -1)
	battlefield._process(0.08)
	if not battlefield.vfx.projectiles.is_empty():
		battlefield.vfx.projectiles[0]["age"] = 0.18
		battlefield.vfx.projectiles[0]["life"] = 0.8
	await _capture("goblin_archer_pixel_projectile_360x640", RESOLUTION_SMALL)
	_set_seven_active_enemies()
	_clear_animation_capture_vfx()
	await _capture("greenvale_production_battle_overview_1080x1920", RESOLUTION_LARGE)

func _capture_greenvale_boss_samples() -> void:
	battle.stage = 20
	_set_enemies(["Goblin Warlord"], true)
	battle.enemies[0]["entry_time"] = 0.24
	await _capture("goblin_warlord_entrance_360x640", RESOLUTION_SMALL)
	battle.enemies[0]["entry_time"] = 0.0
	battlefield._on_attack_started(0, -1)
	var boss_attack_fps := PixelBattleArt.animation_fps("Goblin Warlord", "attack")
	battlefield.enemy_attack_times[0] = float(battlefield.enemy_attack_art_durations[0]) - 3.0 / boss_attack_fps
	battlefield._process(0.0)
	await _capture("goblin_warlord_attack_360x640", RESOLUTION_SMALL)
	battle.enemies[0]["current_hp"] = 0.0
	battlefield._on_enemy_defeated(0, 0, 0)
	battlefield.deaths[0]["age"] = 0.42
	battlefield.queue_redraw()
	await _capture("goblin_warlord_defeat_360x640", RESOLUTION_SMALL)
	await _capture("goblin_warlord_boss_overview_1080x1920", RESOLUTION_LARGE)

func _set_seven_active_enemies() -> void:
	battle.enemies.clear()
	var crowded_kinds := ["Goblin", "Skeleton", "Corrupted Wolf", "Goblin Archer", "Goblin Spearman", "Bandit", "Goblin"]
	for index in GameData.ENEMIES_PER_WAVE:
		var kind: String = crowded_kinds[index % crowded_kinds.size()]
		var enemy := CampaignData.enemy_stats(kind, 0, 1, battle.stage, 1)
		enemy["current_hp"] = enemy["hp"]
		enemy["spawned"] = true
		enemy["entry_time"] = 0.0
		enemy["attack_time"] = 3.0
		battle.enemies.append(enemy)
	battle.changed.emit()

func _clear_animation_capture_vfx() -> void:
	battlefield.floaters.clear()
	battlefield.impacts.clear()
	battlefield.deaths.clear()
	battlefield.queue_redraw()

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
