extends SceneTree

const IDS := ["Shadow Hound", "Shade", "Dark Mage", "Phantom Archer", "Shadow Knight", "Void Spawn", "Void Reaper", "Shadow Champion", "Lord of Shadows"]
var failures := 0
var field: Battlefield
var battle: BattleController

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := SaveData.new()
	profile.region = 8
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
	_check(PixelBattleArt.is_active(battle), "Region 8 uses the locked pixel battlefield")
	_check(field.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Region 8 keeps nearest-neighbor sprite filtering")
	_check(CampaignData.REGIONS[7].name == "Shadowlands", "campaign Region 8 identity is unchanged")
	PixelBattleArt.set_battle_region(8)
	var background := PixelBattleArt.background_texture()
	_check(background != null and Vector2i(background.get_size()) == Vector2i(1280, 720), "Shadowlands background loads at 1280x720")
	for id in IDS:
		_check(EnemyArtService.enemy_folder(id, 8) != "" and PixelBattleArt.enemy_sheet(id) != null, "%s resolves to pixel idle art" % id)
		var elite: bool = id in ["Void Reaper", "Shadow Champion"]
		var boss: bool = id == "Lord of Shadows"
		for state in ["idle", "entry", "attack", "hit"]:
			var count := PixelBattleArt.animation_frame_count(id, state)
			var expected := 4 if state in ["idle", "entry"] else (6 if boss and state == "attack" else (5 if state == "attack" else (4 if elite or boss else 3)))
			var sheet := PixelBattleArt.animation_frame(id, state, 0)
			_check(count == expected and sheet != null, "%s %s has %d frames and loads" % [id, state, expected])
			var expected_fps := 7.0 if state == "idle" else (8.0 if boss and state == "entry" else 11.0)
			_check(is_equal_approx(PixelBattleArt.animation_fps(id, state), expected_fps), "%s %s FPS is correct" % [id, state])
			var image := PixelBattleArt.animation_sheet(id, state).get_image() if PixelBattleArt.animation_sheet(id, state) != null else null
			_check(image != null and image.get_width() == expected * 256 and image.get_height() == 256, "%s %s sheet parses" % [id, state])
			_check(image != null and image.get_pixel(0, 0).a == 0.0 and image.get_pixel(image.get_width() - 1, 0).a == 0.0, "%s %s has transparent corners" % [id, state])
		if boss:
			_check(PixelBattleArt.animation_frame_count(id, "entrance") == 4 and PixelBattleArt.animation_frame(id, "entrance", 3) != null, "Lord of Shadows entrance loads four frames")
			_check(PixelBattleArt.animation_frame_count(id, "death") == 6 and PixelBattleArt.animation_frame(id, "death", 5) != null, "Lord of Shadows death loads six frames")
			_check(is_equal_approx(PixelBattleArt.animation_fps(id, "death"), 8.0), "Lord of Shadows death FPS is 8")
	_check(PixelBattleArt.BODY_PLACEMENT["Shadow Hound"].width > PixelBattleArt.BODY_PLACEMENT["Shadow Hound"].height and PixelBattleArt.BODY_PLACEMENT["Shadow Hound"].offset_y > 0.5, "Shadow Hound uses low wide quadruped placement")
	_check(PixelBattleArt.BODY_PLACEMENT["Shade"].offset_y < 0.3, "Shade uses elevated floating placement")
	_check(PixelBattleArt.BODY_PLACEMENT["Void Spawn"].width > 1.0 and PixelBattleArt.BODY_PLACEMENT["Void Spawn"].offset_y > 0.3, "Void Spawn uses custom irregular placement")
	_check(PixelBattleArt.BODY_PLACEMENT["Void Reaper"].width > 1.0 and PixelBattleArt.BODY_PLACEMENT["Shadow Champion"].width > 1.0, "elite metadata scales larger than normals")
	_check(PixelBattleArt.BODY_PLACEMENT["Lord of Shadows"].height > 1.0, "Lord of Shadows uses large boss placement")
	_check(not EnemyArtService.metadata("Shadow Hound").get("flip_h", false), "Shadow Hound left-facing art is not flipped")
	_check(not EnemyArtService.metadata("Phantom Archer").get("flip_h", false), "Phantom Archer left-facing art is not flipped")
	var archer := CampaignData.enemy_stats("Phantom Archer", 0, 8, 1, 1)
	archer.current_hp = archer.hp
	archer.spawned = true
	archer.attack_time = 3.0
	archer.stun_time = 0.0
	battle.enemies.clear()
	battle.enemies.append(archer)
	field._on_attack_started(0, -1)
	_check(not field.vfx.projectiles.is_empty() and field.vfx.projectiles[0].style == "pixel_arrow", "Phantom Archer uses existing pixel arrow projectile")
	_check(not field.vfx.projectiles.is_empty() and field.vfx.projectiles[0]["from"].x > field.vfx.projectiles[0]["to"].x, "Phantom Archer arrow travels left toward the hero")
	var mage := CampaignData.enemy_stats("Dark Mage", 0, 8, 1, 1)
	_check(str(mage.get("archetype", "")) == "MAGIC", "Dark Mage retains existing magic archetype")
	mage.current_hp = mage.hp
	mage.spawned = true
	mage.attack_time = 3.0
	mage.stun_time = 0.0
	battle.enemies.clear()
	battle.enemies.append(mage)
	field.vfx.projectiles.clear()
	field._on_attack_started(0, -1)
	_check(not field.vfx.projectiles.is_empty() and field.vfx.projectiles[0].style == "orb", "Dark Mage retains existing magic projectile path")
	_check(is_equal_approx(float(battle.wave_transition_duration), 1.5) and is_equal_approx(float(field.hero_run_duration), 1.5), "wave transition and hero run remain 1.5 seconds")
	_check(GameData.ENEMIES_PER_WAVE == 7 and is_equal_approx(GameData.ENEMY_ENTRY_INTERVAL, 0.60), "seven-enemy waves use the 0.60-second entry cadence")
	_check(battle.enemies.size() == 1, "Region 8 roster does not alter wave spawning")
	var warnings := PixelBattleArt.validation_report()
	for warning in warnings: push_error(warning)
	_check(warnings.is_empty(), "Region 8 sheets and background pass resource validation")
	field.queue_free()
	battle.queue_free()
	print("SHADOWLANDS PIXEL SMOKE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error("Shadowlands smoke: " + description)
