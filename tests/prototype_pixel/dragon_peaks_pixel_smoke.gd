extends SceneTree

const IDS := ["Drake", "Dragon Cultist", "Flame Drake", "Storm Drake", "Dragon Knight", "Wyvern", "Elder Wyvern", "Dragon Champion", "Ancient Dragon"]
var failures := 0
var battle: BattleController
var field: Battlefield

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := SaveData.new()
	profile.region = 9
	profile.stage = 1
	profile.selected_hero_id = "knight"
	battle = BattleController.new()
	root.add_child(battle)
	battle.start(profile)
	field = Battlefield.new()
	root.add_child(field)
	field.size = Vector2(360, 190)
	field.set_battle(battle)
	await process_frame
	_check(PixelBattleArt.is_active(battle), "Region 9 uses the locked pixel battlefield")
	_check(field.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Dragon Peaks keeps nearest-neighbor filtering")
	_check(CampaignData.REGIONS[8].name == "Dragon Peaks", "campaign Region 9 identity remains unchanged")
	PixelBattleArt.set_battle_region(9)
	var background := PixelBattleArt.background_texture()
	_check(background != null and Vector2i(background.get_size()) == Vector2i(1280, 720), "Dragon Peaks background loads at 1280x720")
	for id in IDS:
		_check(EnemyArtService.enemy_folder(id, 9) != "" and PixelBattleArt.enemy_sheet(id) != null, "%s resolves to Region 9 pixel art" % id)
		_check(not bool(EnemyArtService.metadata(id).get("flip_h", false)), "%s remains left-facing without a state flip" % id)
		var elite: bool = id in ["Elder Wyvern", "Dragon Champion"]
		var boss: bool = id == "Ancient Dragon"
		for state in ["idle", "entry", "attack", "hit"]:
			var count := PixelBattleArt.animation_frame_count(id, state)
			var expected := 4 if state in ["idle", "entry"] else (6 if boss and state == "attack" else (5 if state == "attack" else (4 if elite or boss else 3)))
			var animation := PixelBattleArt.animation_sheet(id, state)
			_check(count == expected and animation != null, "%s %s has %d frames" % [id, state, expected])
			var fps := 7.0 if state == "idle" else (8.0 if boss and state == "entry" else 11.0)
			_check(is_equal_approx(PixelBattleArt.animation_fps(id, state), fps), "%s %s FPS is correct" % [id, state])
			_check(animation != null and animation.get_width() == expected * 256 and animation.get_height() == 256, "%s %s sheet dimensions are valid" % [id, state])
			if animation != null:
				var image := animation.get_image()
				_check(image != null and image.detect_alpha(), "%s %s preserves real alpha" % [id, state])
				if image != null:
					for frame in expected:
						var x := frame * 256
						var visible := 0
						var opaque := 0
						var transparent := 0
						var clear_corners := 0
						for corner in [Vector2i(frame * 256, 0), Vector2i(frame * 256 + 255, 0), Vector2i(frame * 256, 255), Vector2i(frame * 256 + 255, 255)]:
							if image.get_pixelv(corner).a < 0.01:
								clear_corners += 1
						for y in 256:
							for px in 256:
								var alpha := image.get_pixel(frame * 256 + px, y).a
								if alpha > 0.1:
									visible += 1
								if alpha > 0.75:
									opaque += 1
								if alpha < 0.01:
									transparent += 1
						_check(visible > 1200 and opaque > 400 and transparent > 1000 and clear_corners >= 2, "%s %s frame %d alpha QA (visible=%d opaque=%d transparent=%d clear_corners=%d)" % [id, state, frame, visible, opaque, transparent, clear_corners])
		if boss:
			_check(PixelBattleArt.animation_frame_count(id, "entrance") == 4 and PixelBattleArt.animation_frame(id, "entrance", 3) != null, "Ancient Dragon entrance has four frames")
			_check(PixelBattleArt.animation_frame_count(id, "death") == 6 and PixelBattleArt.animation_frame(id, "death", 5) != null, "Ancient Dragon death has six frames")
			_check(is_equal_approx(PixelBattleArt.animation_fps(id, "entrance"), 8.0) and is_equal_approx(PixelBattleArt.animation_fps(id, "death"), 8.0), "Ancient Dragon entrance and death play at 8 FPS")
	_check(PixelBattleArt.BODY_PLACEMENT["Drake"].width > PixelBattleArt.BODY_PLACEMENT["Drake"].height and PixelBattleArt.BODY_PLACEMENT["Drake"].offset_y > 0.5, "Drake uses low wide reptile placement")
	_check(PixelBattleArt.BODY_PLACEMENT["Flame Drake"].width > PixelBattleArt.BODY_PLACEMENT["Flame Drake"].height, "Flame Drake uses low wide reptile placement")
	_check(PixelBattleArt.BODY_PLACEMENT["Storm Drake"].width > PixelBattleArt.BODY_PLACEMENT["Storm Drake"].height, "Storm Drake uses low agile reptile placement")
	_check(PixelBattleArt.BODY_PLACEMENT["Wyvern"].height > 1.0 and PixelBattleArt.BODY_PLACEMENT["Elder Wyvern"].width > PixelBattleArt.BODY_PLACEMENT["Wyvern"].width, "Wyvern flight and elder scale are represented in placement")
	_check(PixelBattleArt.BODY_PLACEMENT["Dragon Champion"].width > PixelBattleArt.BODY_PLACEMENT["Dragon Knight"].width, "Dragon Champion is larger than Dragon Knight")
	_check(PixelBattleArt.BODY_PLACEMENT["Ancient Dragon"].width > 1.0 and PixelBattleArt.BODY_PLACEMENT["Ancient Dragon"].height > 0.8 and PixelBattleArt.BODY_PLACEMENT["Ancient Dragon"].height < 1.2, "Ancient Dragon has custom boss placement within battlefield bounds")
	_check(GameData.ENEMIES_PER_WAVE == 7 and is_equal_approx(GameData.ENEMY_ENTRY_INTERVAL, 0.9), "seven-enemy waves retain the 0.9-second entry cadence")
	_check(is_equal_approx(battle.wave_transition_duration, 1.5) and is_equal_approx(field.hero_run_duration, 1.5), "hero run between waves remains 1.5 seconds")
	_check(absf(field.size.y - 190.0) < 0.01, "battlefield presentation area sizing remains unchanged")
	var drake := CampaignData.enemy_stats("Drake", 0, 9, 1, 1)
	drake.current_hp = drake.hp
	drake.spawned = true
	drake.attack_time = 3.0
	drake.stun_time = 0.0
	battle.enemies.clear()
	battle.enemies.append(drake)
	field.vfx.projectiles.clear()
	field._on_attack_started(0, -1)
	_check(field.vfx.projectiles.is_empty(), "Drake keeps its existing melee attack without new projectile behavior")
	var warnings := PixelBattleArt.validation_report()
	for warning in warnings: push_error(warning)
	_check(warnings.is_empty(), "Region 9 animation sheets and background pass resource validation")
	field.queue_free()
	battle.queue_free()
	print("DRAGON PEAKS PIXEL SMOKE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error("Dragon Peaks smoke: " + description)
