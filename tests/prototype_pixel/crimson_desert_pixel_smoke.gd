extends SceneTree

const IDS := ["Desert Raider", "Sand Scorpion", "Desert Skeleton", "Fire Cultist", "Sand Wolf", "Tomb Archer", "Sand Golem", "Crimson Champion", "Ancient Sand Wyrm"]
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := SaveData.new()
	profile.region = 6
	profile.stage = 1
	profile.selected_hero_id = "knight"
	var battle := BattleController.new()
	root.add_child(battle)
	battle.start(profile)
	_check(PixelBattleArt.is_active(battle), "Region 6 uses the shared pixel battlefield")
	_check(CampaignData.REGIONS[5].name == "Crimson Desert", "campaign Region 6 identity is unchanged")
	PixelBattleArt.set_battle_region(6)
	var background := PixelBattleArt.background_texture()
	_check(background != null and Vector2i(background.get_size()) == Vector2i(1280, 720), "Crimson Desert background loads at 1280x720")
	for id in IDS:
		_check(EnemyArtService.enemy_folder(id, 6) != "" and PixelBattleArt.enemy_sheet(id) != null, "%s resolves to pixel idle art" % id)
		var elite: bool = id in ["Sand Golem", "Crimson Champion"]
		var boss: bool = id == "Ancient Sand Wyrm"
		for state in ["idle", "entry", "attack", "hit"]:
			var count := PixelBattleArt.enemy_entry_frame_count(id) if state == "entry" else PixelBattleArt.animation_frame_count(id, state)
			var expected := 4 if state in ["idle", "entry"] else (6 if boss and state == "attack" else (5 if state == "attack" else (4 if elite or boss else 3)))
			var sheet := PixelBattleArt.enemy_entry_frame(id, 0) if state == "entry" else PixelBattleArt.animation_frame(id, state, 0)
			_check(count == expected and sheet != null, "%s %s has %d frames and loads" % [id, state, expected])
			_check(is_equal_approx(PixelBattleArt.animation_fps(id, state), 7.0 if state == "idle" else 11.0), "%s %s FPS is unchanged" % [id, state])
		if boss:
			_check(PixelBattleArt.animation_frame_count(id, "entrance") == 4 and PixelBattleArt.animation_sheet(id, "entrance") != null, "Wyrm entrance loads")
			_check(PixelBattleArt.animation_frame_count(id, "death") == 6 and PixelBattleArt.animation_frame(id, "death", 5) != null, "Wyrm death loads six frames")
		for state in ["idle", "entry", "attack", "hit"]:
			var texture := PixelBattleArt.animation_sheet(id, state)
			if texture != null:
				var image := texture.get_image()
				_check(image.get_width() == PixelBattleArt.animation_frame_count(id, state) * 256 and image.get_height() == 256, "%s %s sheet parses" % [id, state])
				_check(image.get_pixel(0, 0).a == 0.0 and image.get_pixel(image.get_width() - 1, 0).a == 0.0, "%s %s has transparent corners" % [id, state])
	_check(PixelBattleArt.BODY_PLACEMENT["Sand Scorpion"].width > PixelBattleArt.BODY_PLACEMENT["Sand Scorpion"].height, "Scorpion uses low wide body metadata")
	_check(PixelBattleArt.BODY_PLACEMENT["Sand Wolf"].width > PixelBattleArt.BODY_PLACEMENT["Sand Wolf"].height, "Wolf uses low quadruped metadata")
	_check(PixelBattleArt.BODY_PLACEMENT["Ancient Sand Wyrm"].width > 1.0 and PixelBattleArt.BODY_PLACEMENT["Ancient Sand Wyrm"].height < 1.0, "Wyrm uses wide top battlefield placement")
	_check(EnemyArtService.metadata("Tomb Archer").get("flip_h", false), "Tomb Archer retains left facing metadata and existing arrow path")
	var warnings := PixelBattleArt.validation_report()
	for warning in warnings: push_error(warning)
	_check(warnings.is_empty(), "Region 6 sheets and background pass resource validation")
	battle.queue_free()
	print("CRIMSON DESERT PIXEL SMOKE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error("Crimson Desert smoke: " + description)
