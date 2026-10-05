extends SceneTree

const OUT := "res://.godot/phase13b_captures"
const SMALL := Vector2i(360, 640)
const LARGE := Vector2i(1080, 1920)

var main: Control
var profile: SaveData
var battle: BattleController
var field: Battlefield
var failures := 0

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/phase13b_capture.save")
	call_deferred("_run")

func _run() -> void:
	if root.get_texture() == null:
		push_error("Phase 13B viewport captures require a graphical renderer; do not use --headless.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	profile = main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase13b_capture.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	for feature in TutorialService.FEATURES:
		profile.tutorial_state.features[feature] = true
	profile.offline_pending_rewards = {}
	profile.selected_hero_id = "knight"
	profile.stage = 1
	profile.region = 1
	profile.equipped_companion_slots.assign(["wolf", "", "", ""])
	profile.companions["wolf"] = {"level": 4, "rarity": 3, "stars": 2, "evolution": 0, "pieces": 1}
	profile.skills["shield_bash"] = {"level": 1, "rarity": 0}
	profile.skills["whirlwind_slash"] = {"level": 1, "rarity": 2}
	profile.skills["iron_guard"] = {"level": 1, "rarity": 1}
	profile.skills["healing_light"] = {"level": 1, "rarity": 2}
	profile.equipped_skill_slots.assign(["shield_bash", "whirlwind_slash", "iron_guard", "healing_light"])
	battle = main.get("battle") as BattleController
	field = main.get("battlefield") as Battlefield
	battle.start(profile)
	battle.active = false
	battle.mode_config = {"mode": "campaign"}
	battle.boss_time = 58.0
	for name in ["tutorial_popup", "offline_popup", "login_popup"]:
		var popup = main.get(name)
		if popup is Window or popup is Control:
			popup.hide()
	main.call("_select_tab", "Battle")
	DisplayServer.window_set_size(SMALL)
	_set_region_wave(1, ["Goblin"])
	await _capture("battle_hud_360", SMALL)
	await _capture("normal_hit_360", SMALL, func(): field._on_damage_popup(0, 34, false, false))
	await _capture("critical_hit_360", SMALL, func(): field._on_damage_popup(0, 92, true, false))
	await _capture("shield_bash_360", SMALL, func():
		field._on_skill_cast("shield_bash", 0)
		field._on_damage_popup(0, 62, false, true))
	await _capture("whirlwind_360", SMALL, func(): field._on_skill_cast("whirlwind_slash", 1))
	await _capture("iron_guard_360", SMALL, func():
		battle.skill_runtime.defense_time = 4.0
		field._on_skill_cast("iron_guard", 2))
	await _capture("healing_light_360", SMALL, func():
		field._on_skill_cast("healing_light", 3)
		field._on_skill_healed(250))
	await _capture("battle_cry_360", SMALL, func(): field._on_skill_cast("battle_cry", 3))
	await _capture("companion_attack_360", SMALL, func(): field._on_companion_attack(0, 0, 18))
	_set_region_wave(1, ["Goblin Archer"])
	await _capture("ranged_projectile_360", SMALL, func(): _add_pixel_arrow())
	_set_region_wave(10, ["Lesser Demon", "Demon Archer", "Hellhound", "Demon Knight", "Infernal Mage", "Corrupted Giant", "Demon Champion"])
	await _capture("seven_enemy_wave_360", SMALL)
	await _capture("seven_enemy_wave_1080", LARGE)
	_set_boss(10, "Demon Lord")
	await _capture("boss_fight_360", SMALL)
	await _capture("boss_overview_1080", LARGE)
	await _capture("boss_death_360", SMALL, func():
		battle.enemies[0]["current_hp"] = 0
		field._on_enemy_defeated(0, 900, 1200)
		field._on_presentation_event("boss_defeat", {"boss": true}))
	_set_region_wave(1, ["Goblin"])
	await _capture("normal_overview_1080", LARGE)
	for item in [[1, "Goblin Archer", "bright_green"], [2, "Skeleton Archer", "dark_forest"], [4, "Ice Archer", "snow"], [6, "Tomb Archer", "desert"], [8, "Phantom Archer", "shadowlands"], [9, "Drake", "dragon_peaks"], [10, "Demon Archer", "demon_realm"]]:
		var region := int(item[0])
		var enemy_kind := str(item[1])
		var label := str(item[2])
		_set_region_wave(region, [enemy_kind])
		await _capture("contrast_%s_360" % label, SMALL, func(): _add_pixel_arrow())
	main.queue_free()
	print("PHASE 13B CAPTURE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _set_region_wave(region: int, kinds: Array) -> void:
	profile.region = region
	profile.stage = 1
	battle.region = region
	battle.stage = 1
	battle.wave = 1
	battle.mode_config = {"mode": "campaign"}
	battle.active = false
	battle.enemies.clear()
	for kind in kinds:
		var enemy := CampaignData.enemy_stats(str(kind), 0, region, 1, 1)
		enemy["current_hp"] = enemy["hp"]
		enemy["spawned"] = true
		enemy["combat_ready"] = true
		enemy["entry_time"] = 0.0
		enemy["attack_time"] = 12.0
		enemy["stun_time"] = 0.0
		battle.enemies.append(enemy)
	battle.changed.emit()
	main.call("_refresh_ui")
	field.queue_redraw()

func _set_boss(region: int, kind: String) -> void:
	profile.stage = 20
	battle.stage = 20
	battle.region = region
	profile.region = region
	battle.mode_config = {"mode": "campaign"}
	battle.active = false
	battle.boss_time = 58.0
	battle.enemies.clear()
	var enemy := CampaignData.enemy_stats(kind, 0, region, 20, 1)
	enemy["current_hp"] = enemy["hp"]
	enemy["archetype"] = "BOSS"
	enemy["boss"] = true
	enemy["spawned"] = true
	enemy["combat_ready"] = true
	enemy["entry_time"] = 0.0
	enemy["attack_time"] = 12.0
	enemy["stun_time"] = 0.0
	battle.enemies.append(enemy)
	battle.changed.emit()
	main.call("_refresh_ui")
	field.queue_redraw()

func _capture(name: String, resolution: Vector2i, trigger: Callable = Callable()) -> void:
	_reset_effects()
	DisplayServer.window_set_size(resolution)
	if trigger.is_valid():
		trigger.call()
		print("Capture trigger %s: labels=%d effects=%d projectiles=%d" % [name, field.vfx.labels.size(), field.vfx.effects.size(), field.vfx.projectiles.size()])
	field.queue_redraw()
	main.call("_refresh_ui")
	for _i in 2:
		await process_frame
		_dismiss_popups(main)
	for label in field.vfx.labels:
		label["age"] = float(label["life"]) * 0.16
	for effect in field.vfx.effects:
		effect["age"] = float(effect["life"]) * 0.28
	for projectile in field.vfx.projectiles:
		projectile["age"] = float(projectile["life"]) * 0.38
	field.effects_overlay.queue_redraw()
	paused = true
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	paused = false
	if image == null or image.is_empty() or image.get_size() != resolution:
		failures += 1
		push_error("Invalid Phase 13B capture: " + name)
		return
	var path := "%s/%s.png" % [OUT, name]
	if image.save_png(path) != OK:
		failures += 1
		push_error("Failed to save Phase 13B capture: " + path)
	else:
		print("Captured " + path)

func _add_pixel_arrow() -> void:
	field.vfx.projectile(field._hero_position() + Vector2(20, -82), field._enemy_position(0) + Vector2(0, -84), Color("ead3a1"), 0.40, 8, "pixel_arrow")
	field.queue_redraw()

func _reset_effects() -> void:
	field.vfx.effects.clear()
	field.vfx.labels.clear()
	field.vfx.projectiles.clear()
	field.vfx.shake_time = 0.0
	field.vfx.shake_strength = 0.0
	field.vfx.boss_banner_time = 0.0
	field.vfx.clear_time = 0.0
	field.floaters.clear()
	field.impacts.clear()
	field.deaths.clear()
	field.flashes.clear()
	field.lunges.clear()
	field.companion_lunges.clear()
	field.hero_lunge = 0.0
	field.hero_bash = false
	field.hero_attack_art_time = 0.0
	field.hero_guard_art_time = 0.0
	field.hero_hit_art_time = 0.0
	field.pixel_skill_effect_time = 0.0
	field.pixel_impact_overlay.hide()
	battle.skill_runtime.defense_time = 0.0

func _dismiss_popups(node: Node) -> void:
	if node is Window:
		node.hide()
	if node is Button and str(node.text).to_upper() in ["GOT IT", "CONTINUE", "OK"]:
		node.emit_signal("pressed")
	for child in node.get_children():
		_dismiss_popups(child)
