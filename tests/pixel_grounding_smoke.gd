extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := SaveData.new()
	profile.save_path = "res://.godot/pixel_grounding_smoke.save"
	profile.region = 1
	profile.stage = 1
	profile.selected_hero_id = "knight"
	var battle := BattleController.new()
	root.add_child(battle)
	battle.start(profile)
	battle.active = false
	var field := Battlefield.new()
	root.add_child(field)
	field.size = Vector2(360.0, 250.0)
	field.set_battle(battle)
	var baseline := field._ground_line_y()
	_check(is_equal_approx(baseline / field.size.y, Battlefield.GROUND_LINE_RATIO), "shared battlefield ground line is finite and within the play area")
	field.hero_run_time = 1.0
	_check(is_equal_approx(field._hero_position().y, baseline), "hero keeps the shared baseline throughout the between-wave run")
	field.hero_run_time = 0.0
	for state in ["idle", "run", "attack", "guard", "hit"]:
		field.hero_visual_state = state
		field.hero_run_time = 0.0
		field._update_pixel_hero_sprite(field._hero_position(), 0.32)
		var hero_contact := field.pixel_hero_sprite.position.y + (Battlefield.PIXEL_FRAME_GROUND_Y - 128.0) * field.pixel_hero_sprite.scale.y
		_check(is_equal_approx(hero_contact, baseline), "Squire %s keeps its fixed frame contact point" % state)
	for visual in ["beast", "humanoid"]:
		var companion_pos: Vector2 = field._companion_anchor_position(0, visual, 0.32)
		var contact_offset := -5.0 if visual == "beast" else -6.0
		_check(is_equal_approx(companion_pos.y + contact_offset * 0.32 * 1.20, baseline), "%s companion rests on the shared ground" % visual)
	var flyer_pos: Vector2 = field._companion_anchor_position(0, "fairy", 0.32)
	_check(flyer_pos.y < baseline and flyer_pos.y > baseline - 20.0, "flying companions hold a small, consistent hover above the ground")
	for region in range(1, CampaignData.REGIONS.size() + 1):
		battle.region = region
		profile.region = region
		battle.stage = 1
		battle.enemies.clear()
		for kind in CampaignData.wave_kinds(region, 1, 1):
			var normal_enemy := CampaignData.enemy_stats(kind, 0, region, 1, 1)
			normal_enemy["current_hp"] = normal_enemy["hp"]
			normal_enemy["spawned"] = true
			normal_enemy["combat_ready"] = true
			normal_enemy["entry_time"] = 0.0
			battle.enemies.append(normal_enemy)
		_check(is_finite(field._ground_line_y()) and field._ground_line_y() > 0.0 and field._ground_line_y() < field.size.y, "region %d ground line remains in the battlefield" % region)
		var normal_pos: Vector2 = field._enemy_position(0)
		field._update_pixel_enemy_sprite(0, normal_pos, battle.enemies[0], "idle", 0.32)
		var normal_sprite: Sprite2D = field.pixel_enemy_sprites[0]
		var body: Dictionary = PixelBattleArt.BODY_PLACEMENT.get(str(battle.enemies[0]["visual"]), {})
		var hover := float(PixelBattleArt.HOVER_PLACEMENT.get(str(battle.enemies[0]["visual"]), 0.0))
		var normal_contact := normal_sprite.position.y + (float(body.get("contact_y", Battlefield.PIXEL_FRAME_GROUND_Y)) - 128.0 + hover) * normal_sprite.scale.y
		_check(is_equal_approx(normal_contact, normal_pos.y), "region %d enemy contact resolves to its lane ground" % region)
		battle.stage = 20
		battle.enemies.clear()
		var boss_enemy := CampaignData.enemy_stats(str(CampaignData.REGIONS[region - 1]["boss"]), 0, region, 20, 1)
		boss_enemy["current_hp"] = boss_enemy["hp"]
		boss_enemy["spawned"] = true
		boss_enemy["combat_ready"] = true
		boss_enemy["entry_time"] = 0.0
		battle.enemies.append(boss_enemy)
		var boss_pos: Vector2 = field._enemy_position(0)
		_check(boss_pos.y > 0.0 and boss_pos.y < field.size.y and is_equal_approx(boss_pos.y, baseline), "region %d boss stays on the shared floor inside the battlefield" % region)
		field._update_pixel_enemy_sprite(0, boss_pos, battle.enemies[0], "idle", 0.32)
		var boss_sprite: Sprite2D = field.pixel_enemy_sprites[0]
		var boss_body: Dictionary = PixelBattleArt.BODY_PLACEMENT.get(str(battle.enemies[0]["visual"]), {})
		var boss_hover := float(PixelBattleArt.HOVER_PLACEMENT.get(str(battle.enemies[0]["visual"]), 0.0))
		var boss_contact := boss_sprite.position.y + (float(boss_body.get("contact_y", Battlefield.PIXEL_FRAME_GROUND_Y)) - 128.0 + boss_hover) * boss_sprite.scale.y
		_check(is_equal_approx(boss_contact, boss_pos.y), "region %d boss contact is grounded with its scale metadata" % region)
	var shade_hover := float(PixelBattleArt.HOVER_PLACEMENT.get("Shade", -1.0))
	_check(shade_hover > 0.0 and shade_hover <= 20.0, "hovering enemies use explicit bounded clearance")
	_check(float(PixelBattleArt.BODY_PLACEMENT["Frostfang Giant"]["height"]) > 1.0 and float(PixelBattleArt.BODY_PLACEMENT["Marsh Hydra"]["height"]) > 1.0, "large grounded enemies retain their visual scale while using the common contact rule")
	_check(float(PixelBattleArt.BODY_PLACEMENT["Demon Lord"]["contact_y"]) < Battlefield.PIXEL_FRAME_GROUND_Y, "Demon Lord uses a boss-specific frame contact point for its shorter lower silhouette")
	profile.region = 1
	battle.region = 1
	battle.stage = 1
	battle.enemies.clear()
	for kind in CampaignData.wave_kinds(1, 1, 1):
		var crowd_enemy := CampaignData.enemy_stats(kind, 0, 1, 1, 1)
		crowd_enemy["current_hp"] = crowd_enemy["hp"]
		crowd_enemy["spawned"] = true
		crowd_enemy["combat_ready"] = true
		crowd_enemy["entry_time"] = 0.0
		battle.enemies.append(crowd_enemy)
	field._update_pixel_hero_sprite(field._hero_position(), 0.32)
	field._update_pixel_enemy_sprite(0, field._enemy_position(0), battle.enemies[0], "idle", 0.32)
	field._update_pixel_enemy_sprite(4, field._enemy_position(4), battle.enemies[4], "idle", 0.32)
	_check(field.pixel_enemy_sprites[0].z_index < field.pixel_hero_sprite.z_index and field.pixel_enemy_sprites[4].z_index > field.pixel_hero_sprite.z_index, "rear enemies draw behind the hero and front enemies draw in front")
	battle.active = false
	field.queue_free()
	battle.queue_free()
	print("PIXEL GROUNDING SMOKE: %s (%d failures)" % ["FAIL" if failures else "PASS", failures])
	quit(1 if failures else 0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("Pixel grounding smoke: " + message)
