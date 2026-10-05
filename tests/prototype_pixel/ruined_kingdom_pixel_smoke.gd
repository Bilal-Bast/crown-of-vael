extends SceneTree

const IDS := ["Fallen Knight", "Corrupted Soldier", "Undead Guard", "Dark Archer", "Armored Ghoul", "War Beast", "Royal Executioner", "Fallen Champion", "Corrupted King"]
var failures := 0
var field: Battlefield
var battle: BattleController

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := SaveData.new()
	profile.region = 7
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
	_check(PixelBattleArt.is_active(battle), "Region 7 uses the locked pixel battlefield")
	_check(CampaignData.REGIONS[6].name == "Ruined Kingdom", "campaign Region 7 identity is unchanged")
	PixelBattleArt.set_battle_region(7)
	var background := PixelBattleArt.background_texture()
	_check(background != null and Vector2i(background.get_size()) == Vector2i(1280, 720), "Ruined Kingdom background loads at 1280x720")
	for id in IDS:
		_check(EnemyArtService.enemy_folder(id, 7) != "" and PixelBattleArt.enemy_sheet(id) != null, "%s resolves to pixel idle art" % id)
		var elite: bool = id in ["Royal Executioner", "Fallen Champion"]
		var boss: bool = id == "Corrupted King"
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
			_check(PixelBattleArt.animation_frame_count(id, "entrance") == 4 and PixelBattleArt.animation_frame(id, "entrance", 3) != null, "Corrupted King entrance loads four frames")
			_check(PixelBattleArt.animation_frame_count(id, "death") == 6 and PixelBattleArt.animation_frame(id, "death", 5) != null, "Corrupted King death loads six frames")
			_check(is_equal_approx(PixelBattleArt.animation_fps(id, "death"), 8.0), "Corrupted King death FPS is 8")
	_check(PixelBattleArt.BODY_PLACEMENT["Armored Ghoul"].height < 1.0, "Armored Ghoul keeps its compact grounded silhouette")
	_check(PixelBattleArt.BODY_PLACEMENT["War Beast"].width > PixelBattleArt.BODY_PLACEMENT["War Beast"].height, "War Beast uses low wide quadruped placement")
	_check(PixelBattleArt.BODY_PLACEMENT["Royal Executioner"].width > 1.0 and PixelBattleArt.BODY_PLACEMENT["Fallen Champion"].width > 1.0, "elite metadata scales larger than normals")
	_check(PixelBattleArt.BODY_PLACEMENT["Corrupted King"].height > 1.0, "Corrupted King uses large boss placement")
	_check(not EnemyArtService.metadata("War Beast").get("flip_h", false), "War Beast left-facing art is not flipped")
	_check(not EnemyArtService.metadata("Dark Archer").get("flip_h", false), "Dark Archer left-facing art is not flipped")
	var archer := CampaignData.enemy_stats("Dark Archer", 0, 7, 1, 1)
	archer.current_hp = archer.hp
	archer.spawned = true
	archer.attack_time = 3.0
	archer.stun_time = 0.0
	battle.enemies.clear()
	battle.enemies.append(archer)
	field._on_attack_started(0, -1)
	_check(not field.vfx.projectiles.is_empty() and field.vfx.projectiles[0].style == "pixel_arrow", "Dark Archer uses existing pixel arrow projectile")
	_check(not field.vfx.projectiles.is_empty() and field.vfx.projectiles[0]["from"].x > field.vfx.projectiles[0]["to"].x, "Dark Archer arrow travels left toward the hero")
	_check(is_equal_approx(float(battle.wave_transition_duration), 1.5) and is_equal_approx(float(field.hero_run_duration), 1.5), "wave transition and hero run remain 1.5 seconds")
	_check(GameData.ENEMIES_PER_WAVE == 7 and is_equal_approx(GameData.ENEMY_ENTRY_INTERVAL, 0.60), "seven-enemy waves use the 0.60-second entry cadence")
	_check(battle.enemies.size() == 1, "Region 7 roster does not alter wave spawning")
	var warnings := PixelBattleArt.validation_report()
	for warning in warnings: push_error(warning)
	_check(warnings.is_empty(), "Region 7 sheets and background pass resource validation")
	field.queue_free()
	battle.queue_free()
	print("RUINED KINGDOM PIXEL SMOKE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error("Ruined Kingdom smoke: " + description)
