extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/phase12c_capture.save"
	profile.region = 1
	profile.stage = 1
	profile.campaign_difficulty = 0
	profile.selected_hero_id = "knight"
	profile.heroes["knight"]["evolution"] = 1
	profile.last_login_reward_date = CalendarService.day()
	var battle := main.get("battle") as BattleController
	var field := main.get("battlefield") as Battlefield
	battle.active = false
	battle.region = 1
	battle.stage = 1
	battle.mode_config = {"mode": "campaign"}
	_set_enemy(battle, "Goblin", 1, 1)
	main.call("_select_tab", "Battle")
	DisplayServer.window_set_size(Vector2i(360, 640))
	await _capture("normal_melee_hit", main, field, func():
		field._on_attack_started(-1, 0)
		field._on_damage_popup(0, 34, false, false))
	await _capture("critical_hit", main, field, func(): field._on_damage_popup(0, 92, true, false))
	profile.selected_hero_id = "ranger"
	await _capture("ranged_projectile", main, field, func(): field._on_attack_started(-1, 0))
	profile.selected_hero_id = "knight"
	await _capture("shield_bash", main, field, func():
		field._on_attack_started(-2, 0)
		field._on_damage_popup(0, 62, false, true))
	await _capture("whirlwind_slash", main, field, func(): battle.skill_cast.emit("whirlwind_slash", 0))
	await _capture("healing_light", main, field, func():
		battle.skill_cast.emit("healing_light", 1)
		battle.skill_healed.emit(250))
	battle.stage = 20
	battle.region = 1
	profile.stage = 20
	_set_enemy(battle, "Goblin Warlord", 1, 20)
	await _capture("boss_intro", main, field, func(): field._on_presentation_event("boss_intro", {"name": "Goblin Warlord"}))
	battle.enemies[0]["current_hp"] = 0
	await _capture("boss_defeat", main, field, func():
		field._on_enemy_defeated(0, 2400, 850)
		field._on_presentation_event("boss_defeat", {"boss": true}))
	var summon := main.get("summon_screen") as SummonScreen
	summon.results = [{"rarity": 4, "kind": "iron_sword", "level": 1}]
	summon.result_banner = "equipment"
	summon.revealing = false
	summon.refresh()
	main.call("_select_tab", "Summon")
	await _capture_main("summon_reveal", main)
	var heroes := main.get("heroes_screen") as HeroesScreen
	heroes.selected_id = "knight"
	heroes.view = "evolution_result"
	heroes.evolution_result = {"previous": "Paladin", "next": "Divine Paladin", "element": "Holy", "before_stats": {"hp": 150, "atk": 16, "armor": 9}, "after_stats": {"hp": 175, "atk": 19, "armor": 11}}
	heroes.refresh()
	main.call("_select_tab", "Heroes")
	await _capture_main("evolution_result", main)
	main.call("_select_tab", "Battle")
	battle.stage = 1
	profile.stage = 1
	_set_enemy(battle, "Goblin", 1, 1)
	field.vfx.effects.clear()
	field.vfx.labels.clear()
	field.vfx.projectiles.clear()
	field.vfx.boss_banner_time = 0.0
	field.vfx.clear_time = 0.0
	field.deaths.clear()
	await _capture_main("normal_melee_1080", main, Vector2i(1080, 1920))
	battle.stage = 20
	battle.region = 1
	profile.stage = 20
	battle.enemies[0]["current_hp"] = battle.enemies[0]["hp"]
	battle.enemies[0]["archetype"] = "BOSS"
	field.vfx.boss_banner_name = "GOBLIN WARLORD"
	field.vfx.boss_banner_time = 1.2
	main.call("_refresh_ui")
	await _capture_main("boss_battle_1080", main, Vector2i(1080, 1920))
	print("PHASE 12C VISUAL CAPTURE: %s" % ("FAIL (%d)" % failures if failures else "PASS"))
	quit(1 if failures else 0)

func _set_enemy(battle: BattleController, kind: String, region: int, stage: int) -> void:
	battle.enemies.clear()
	var enemy := CampaignData.enemy_stats(kind, 0, region, stage, 1)
	enemy["current_hp"] = enemy["hp"]
	enemy["attack_time"] = 3.0
	enemy["stun_time"] = 0.0
	battle.enemies.append(enemy)
	battle.changed.emit()

func _capture(name: String, main: Control, field: Battlefield, trigger: Callable) -> void:
	field.vfx.effects.clear()
	field.vfx.labels.clear()
	field.vfx.projectiles.clear()
	field.vfx.boss_banner_time = 0.0
	field.vfx.clear_time = 0.0
	field.deaths.clear()
	field.flashes.clear()
	field.enemy_attack_times.clear()
	field.enemy_hit_times.clear()
	field.lunges.clear()
	field.hero_lunge = 0.0
	field.hero_projectiles.clear()
	trigger.call()
	field.queue_redraw()
	main.call("_refresh_ui")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_save_capture(name)

func _capture_main(name: String, main: Control, resolution := Vector2i(360, 640)) -> void:
	DisplayServer.window_set_size(resolution)
	main.call("_refresh_ui")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_save_capture(name)

func _save_capture(name: String) -> void:
	var path := "res://.godot/phase12c_%s_%d.png" % [name, DisplayServer.window_get_size().x]
	if root.get_texture().get_image().save_png(path) != OK:
		failures += 1
		push_error("Phase 12C capture failed: " + path)
	else:
		print("Captured ", path)
