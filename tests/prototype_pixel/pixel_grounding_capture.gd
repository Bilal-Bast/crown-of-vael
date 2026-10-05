extends SceneTree

const CAPTURE_DIR := "res://.godot/prototype_pixel_captures"
const SMALL := Vector2i(360, 640)
const LARGE := Vector2i(1080, 1920)

var main: Control
var battle: BattleController
var profile: SaveData
var failures := 0

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/pixel_grounding_capture.save")
	call_deferred("_run")

func _run() -> void:
	if root.get_texture() == null:
		push_error("Grounding captures require the graphical viewport; do not use --headless.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var host_profile := main.get("profile") as SaveData
	battle = main.get("battle") as BattleController
	profile = host_profile
	profile.save_path = "res://.godot/pixel_grounding_capture.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	profile.selected_hero_id = "knight"
	profile.heroes["knight"].evolution = 0
	profile.companions["wolf"] = {"rarity": 1, "level": 1, "stars": 1, "evolution": 0}
	profile.equipped_companion_slots.assign(["wolf", "", "", ""])
	main.call("_select_tab", "Battle")
	for popup in ["tutorial_popup", "offline_popup", "login_popup"]:
		var node = main.get(popup)
		if node is Window or node is Control:
			node.hide()
	for region in range(1, 11):
		_set_region_wave(region)
		await _capture("grounding_region_%02d_overview_360x640" % region, SMALL)
	_set_enemies(1, ["Goblin", "Corrupted Wolf", "Goblin Archer", "Skeleton", "Bandit", "Goblin Spearman", "Goblin Captain"])
	await _capture("grounding_hero_companion_humanoid_quadruped_360x640", SMALL)
	_set_enemies(4, ["Frost Spirit"])
	await _capture("grounding_hovering_frost_spirit_360x640", SMALL)
	_set_enemies(1, ["Goblin", "Corrupted Wolf", "Goblin Archer", "Skeleton", "Bandit", "Goblin Spearman", "Goblin Captain"])
	await _capture("grounding_normal_overview_1080x1920", LARGE)
	_set_enemies(10, ["Demon Lord"], true)
	await _capture("grounding_demon_lord_boss_overview_1080x1920", LARGE)
	main.queue_free()
	print("PIXEL GROUNDING CAPTURES: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _set_region_wave(region: int) -> void:
	_set_enemies(region, CampaignData.wave_kinds(region, 1, 1))

func _set_enemies(region: int, kinds: Array, boss := false) -> void:
	profile.region = region
	profile.stage = 20 if boss else 1
	battle.region = region
	battle.stage = 20 if boss else 1
	battle.wave = 1
	battle.mode_config = {"mode": "campaign"}
	battle.start(profile)
	battle.active = false
	battle.enemies.clear()
	for kind in kinds:
		var enemy := CampaignData.enemy_stats(str(kind), 0, region, battle.stage, 1)
		enemy.current_hp = enemy.hp
		enemy.attack_time = 10.0
		enemy.stun_time = 0.0
		enemy.spawned = true
		enemy.combat_ready = true
		enemy.entry_time = 0.0
		battle.enemies.append(enemy)
	var field := main.get("battlefield") as Battlefield
	field.enemy_attack_times.clear()
	field.enemy_hit_times.clear()
	field.enemy_attack_art_durations.clear()
	field.enemy_hit_art_durations.clear()
	field.deaths.clear()
	field.vfx.projectiles.clear()
	field.hero_run_time = 0.0
	battle.changed.emit()
	field.queue_redraw()

func _capture(name: String, resolution: Vector2i) -> void:
	DisplayServer.window_set_size(resolution)
	for _i in 4:
		await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != resolution:
		failures += 1
		push_error("Invalid grounding capture: " + name)
		return
	if image.save_png("%s/%s.png" % [CAPTURE_DIR, name]) != OK:
		failures += 1
		push_error("Could not save grounding capture: " + name)
		return
	print("Captured " + name)
