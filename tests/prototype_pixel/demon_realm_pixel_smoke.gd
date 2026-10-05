extends SceneTree

const IDS := ["Lesser Demon", "Demon Archer", "Hellhound", "Demon Knight", "Infernal Mage", "Corrupted Giant", "Demon Champion", "Infernal Reaper", "Demon Lord"]
var failures := 0
var battle: BattleController
var field: Battlefield

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := SaveData.new()
	profile.region = 10
	profile.stage = 1
	profile.selected_hero_id = "knight"
	battle = BattleController.new()
	root.add_child(battle)
	battle.start(profile)
	battle.active = false
	field = Battlefield.new()
	root.add_child(field)
	field.size = Vector2(360, 190)
	field.set_battle(battle)
	await process_frame
	_check(PixelBattleArt.is_active(battle), "Region 10 uses the locked pixel battlefield")
	_check(field.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Demon Realm keeps nearest-neighbor filtering")
	_check(CampaignData.REGIONS[9].name == "Demon Realm", "campaign Region 10 identity remains unchanged")
	PixelBattleArt.set_battle_region(10)
	var background := PixelBattleArt.background_texture()
	_check(background != null and Vector2i(background.get_size()) == Vector2i(1280, 720), "Demon Realm background loads at 1280x720")
	for id in IDS:
		_check(EnemyArtService.enemy_folder(id, 10) != "" and PixelBattleArt.enemy_sheet(id) != null, "%s resolves to Region 10 pixel art" % id)
		_check(not bool(EnemyArtService.metadata(id).get("flip_h", false)), "%s art faces left without runtime flipping" % id)
		var elite: bool = id in ["Demon Champion", "Infernal Reaper"]
		var boss: bool = id == "Demon Lord"
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
				_check(image != null and image.detect_alpha(), "%s %s has an alpha channel" % [id, state])
				if image != null:
					for frame in expected:
						var visible := 0
						var opaque := 0
						var clear_corners := 0
						for corner in [Vector2i(frame * 256, 0), Vector2i(frame * 256 + 255, 0), Vector2i(frame * 256, 255), Vector2i(frame * 256 + 255, 255)]:
							if image.get_pixelv(corner).a < 0.01: clear_corners += 1
						for y in 256:
							for x in 256:
								var alpha := image.get_pixel(frame * 256 + x, y).a
								if alpha > 0.1: visible += 1
								if alpha > 0.75: opaque += 1
						_check(visible > 500 and opaque > 250 and clear_corners >= 2, "%s %s frame %d retains a transparent edge and visible art" % [id, state, frame])
		if boss:
			_check(PixelBattleArt.animation_frame_count(id, "entrance") == 4 and PixelBattleArt.animation_frame(id, "entrance", 3) != null, "Demon Lord has a four-frame entrance")
			_check(PixelBattleArt.animation_frame_count(id, "death") == 6 and PixelBattleArt.animation_frame(id, "death", 5) != null, "Demon Lord has a dedicated six-frame death")
			_check(is_equal_approx(PixelBattleArt.animation_fps(id, "entrance"), 8.0) and is_equal_approx(PixelBattleArt.animation_fps(id, "death"), 8.0), "Demon Lord entrance and death play at 8 FPS")
	_check(PixelBattleArt.BODY_PLACEMENT["Hellhound"].width > PixelBattleArt.BODY_PLACEMENT["Hellhound"].height, "Hellhound uses low wide quadruped placement")
	_check(PixelBattleArt.BODY_PLACEMENT["Corrupted Giant"].height > 1.0 and PixelBattleArt.BODY_PLACEMENT["Corrupted Giant"].height < 1.2, "Corrupted Giant remains a large normal enemy")
	_check(PixelBattleArt.BODY_PLACEMENT["Demon Champion"].width > PixelBattleArt.BODY_PLACEMENT["Demon Knight"].width, "Demon Champion has large elite placement")
	_check(PixelBattleArt.BODY_PLACEMENT["Infernal Reaper"].height > PixelBattleArt.BODY_PLACEMENT["Infernal Reaper"].width, "Infernal Reaper uses tall elite placement")
	_check(PixelBattleArt.BODY_PLACEMENT["Demon Lord"].width > 1.0 and PixelBattleArt.BODY_PLACEMENT["Demon Lord"].height < 1.0, "Demon Lord has custom boss placement")
	_check(GameData.ENEMIES_PER_WAVE == 7 and is_equal_approx(GameData.ENEMY_ENTRY_INTERVAL, 0.9), "seven-enemy waves retain the 0.9-second entry cadence")
	_check(is_equal_approx(battle.wave_transition_duration, 1.5) and is_equal_approx(field.hero_run_duration, 1.5), "hero run between waves remains 1.5 seconds")
	var mage := CampaignData.enemy_stats("Infernal Mage", 0, 10, 1, 1)
	_check(str(mage.get("archetype", "")) == "MAGIC", "Infernal Mage preserves existing MAGIC behavior")
	var archer := CampaignData.enemy_stats("Demon Archer", 0, 10, 1, 1)
	archer.current_hp = archer.hp
	archer.spawned = true
	battle.enemies = [archer]
	field.vfx.projectiles.clear()
	field._on_attack_started(0, -1)
	_check(field.vfx.projectiles.size() == 1 and field.vfx.projectiles[0].style == "pixel_arrow", "Demon Archer reuses the existing pixel arrow projectile")
	if not field.vfx.projectiles.is_empty():
		_check(field.vfx.projectiles[0].color == Color("d85b46"), "Demon Archer uses restrained ember arrow styling")
		_check(Vector2(field.vfx.projectiles[0].from).x > Vector2(field.vfx.projectiles[0].to).x, "Demon Archer projectile travels left")
	var warnings := PixelBattleArt.validation_report()
	for warning in warnings: push_error(warning)
	_check(warnings.is_empty(), "all Region 10 animation sheets and background pass resource validation")
	field.queue_free()
	battle.queue_free()
	print("DEMON REALM PIXEL SMOKE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error("Demon Realm smoke: " + description)
