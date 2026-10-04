extends SceneTree

const CAPTURE_DIR := "res://.godot/prototype_pixel_captures"
const SMALL := Vector2i(360, 640)
const LARGE := Vector2i(1080, 1920)
const MIXED := ["Drake", "Dragon Cultist", "Flame Drake", "Storm Drake", "Dragon Knight", "Wyvern", "Elder Wyvern"]
var main: Control
var battle: BattleController
var field: Battlefield
var failures := 0

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/dragon_peaks_capture.save")
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.position = Vector2.ZERO
	main.scale = Vector2.ONE
	var profile := main.get("profile") as SaveData
	battle = main.get("battle") as BattleController
	field = main.get("battlefield") as Battlefield
	profile.save_path = "res://.godot/dragon_peaks_capture.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	profile.region = 9
	profile.stage = 1
	profile.selected_hero_id = "knight"
	profile.heroes["knight"].evolution = 0
	battle.region = 9
	battle.stage = 1
	battle.wave = 1
	battle.mode_config = {"mode": "campaign"}
	battle.start(profile)
	battle.active = false
	main.call("_select_tab", "Battle")
	for popup in ["tutorial_popup", "offline_popup", "login_popup"]:
		var node = main.get(popup)
		if node is Window or node is Control:
			node.hide()

	_set_enemies(["Drake"]); _attack(0); await _capture("dragon_peaks_drake_attack_360", SMALL)
	_set_enemies(["Dragon Cultist"]); _attack(0); await _capture("dragon_peaks_cultist_attack_360", SMALL)
	_set_enemies(["Flame Drake"]); _attack(0); await _capture("dragon_peaks_flame_drake_attack_360", SMALL)
	_set_enemies(["Storm Drake"]); _attack(0); await _capture("dragon_peaks_storm_drake_attack_360", SMALL)
	_set_enemies(["Dragon Knight"]); _attack(0); await _capture("dragon_peaks_knight_attack_360", SMALL)
	_set_enemies(["Wyvern"]); _attack(0); await _capture("dragon_peaks_wyvern_attack_360", SMALL)
	_set_enemies(["Elder Wyvern"]); _attack(0); await _capture("dragon_peaks_elder_wyvern_360", SMALL)
	_set_enemies(["Dragon Champion"]); _attack(0); await _capture("dragon_peaks_champion_360", SMALL)
	_set_enemies(["Ancient Dragon"], true, true); await _capture("dragon_peaks_ancient_dragon_entrance_360", SMALL)
	_set_enemies(["Ancient Dragon"], false, true); _attack(0); await _capture("dragon_peaks_ancient_dragon_attack_360", SMALL)
	_set_enemies(["Ancient Dragon"], false, true); battle.enemies[0].current_hp = 0; field._on_enemy_defeated(0, 0, 0); field.deaths[0]["age"] = 0.35; await _capture("dragon_peaks_ancient_dragon_death_360", SMALL)
	_set_enemies(MIXED); await _capture("dragon_peaks_mixed_seven_enemy_360", SMALL)
	_set_enemies(MIXED); field.hero_run_time = 1.0; await _capture("dragon_peaks_hero_run_360", SMALL)
	_set_enemies(MIXED); await _capture("dragon_peaks_battle_overview_1080", LARGE)
	_set_enemies(["Ancient Dragon"], false, true); await _capture("dragon_peaks_ancient_dragon_boss_overview_1080", LARGE)
	main.queue_free()
	print("DRAGON PEAKS CAPTURES: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _set_enemies(kinds: Array, entering := false, boss := false) -> void:
	battle.enemies.clear()
	battle.stage = 20 if boss else 1
	for kind in kinds:
		var enemy := CampaignData.enemy_stats(str(kind), 0, 9, battle.stage, 1)
		enemy.current_hp = enemy.hp
		enemy.attack_time = 3.0
		enemy.stun_time = 0.0
		enemy.spawned = true
		enemy.entry_time = 0.25 if entering else 0.0
		battle.enemies.append(enemy)
	field.enemy_attack_times.clear()
	field.enemy_hit_times.clear()
	field.enemy_attack_art_durations.clear()
	field.enemy_hit_art_durations.clear()
	field.deaths.clear()
	field.vfx.projectiles.clear()
	field.hero_run_time = 0.0
	battle.changed.emit()

func _attack(index: int) -> void:
	field.vfx.projectiles.clear()
	field.vfx.labels.clear()
	field.vfx.effects.clear()
	field._on_attack_started(index, -1)
	var kind := str(battle.enemies[index].get("visual", ""))
	var fps := PixelBattleArt.animation_fps(kind, "attack")
	field.enemy_attack_times[index] = field.enemy_attack_art_durations[index] - minf(2.0, PixelBattleArt.animation_frame_count(kind, "attack") - 1.0) / fps
	field._process(0.0)

func _capture(name: String, resolution: Vector2i) -> void:
	DisplayServer.window_set_size(resolution)
	for _i in 3:
		await process_frame
	var battlefield_host := main.get("battlefield_host") as Control
	if battlefield_host == null or absf(battlefield_host.custom_minimum_size.y - main.get_viewport_rect().size.y * 0.30) > 2.0:
		failures += 1
		push_error("Battlefield no longer occupies the top 30 percent: " + name)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != resolution:
		failures += 1
		push_error("Unexpected capture dimensions: " + name)
	if image.save_png("%s/%s.png" % [CAPTURE_DIR, name]) != OK:
		failures += 1
		push_error("Capture failed: " + name)
	print("Captured " + name)
