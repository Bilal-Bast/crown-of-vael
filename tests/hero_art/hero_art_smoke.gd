extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if value:
		return
	failures += 1
	push_error("HERO ART: " + label)

func _run() -> void:
	HeroArtService.clear_cache_for_tests()
	var expected_forms := ["squire", "knight", "royal_knight", "paladin", "divine_paladin"]
	for form in expected_forms.size():
		check(HeroArtService.form_folder(form) == expected_forms[form], "%s maps to evolution" % expected_forms[form])
		for state in ["idle", "run", "attack", "guard", "hit"]:
			var sheet := HeroArtService.texture_for(form, state)
			check(sheet != null, "%s %s sheet loads" % [expected_forms[form], state])
			if sheet != null:
				check(sheet.get_width() == 1024 and sheet.get_height() == 256, "%s %s has four frames" % [expected_forms[form], state])
				check(sheet.get_image().detect_alpha(), "%s %s preserves alpha" % [expected_forms[form], state])
			var previous_frame_data := PackedByteArray()
			for frame in 4:
				var frame_texture := HeroArtService.animation_frame(form, state, frame)
				var image := frame_texture.get_image() if frame_texture != null else Image.new()
				check(image.get_width() == 256 and image.get_height() == 256, "%s %s frame %d crops cleanly" % [expected_forms[form], state, frame])
				check(image.get_used_rect().size.x > 0 and image.get_used_rect().size.y > 0, "%s %s frame %d has visible pixels" % [expected_forms[form], state, frame])
				if state != "idle" and frame > 0:
					check(image.get_data() != previous_frame_data, "%s %s animation changes between frames" % [expected_forms[form], state])
				previous_frame_data = image.get_data()
		var portrait := HeroArtService.texture_for(form, "portrait")
		check(portrait != null and portrait.get_width() == 256 and portrait.get_height() == 256, "%s portrait loads at expected size" % expected_forms[form])
		if portrait != null:
			check(portrait.get_image().detect_alpha(), "%s portrait preserves alpha" % expected_forms[form])
			check(portrait.get_image().get_used_rect().size.x > 0, "%s portrait has visible pixels" % expected_forms[form])
	var report := HeroArtService.validation_report()
	check(report.is_empty(), "all evolution art validates")
	var profile := SaveData.new()
	var battle := BattleController.new()
	battle.profile = profile
	for form in expected_forms.size():
		profile.heroes["knight"]["evolution"] = form
		check(PixelBattleArt.is_active(battle), "%s keeps the converted pixel battle presentation" % expected_forms[form])
		check(HeroArtService.animation_frame(form, "idle", 0) != null, "%s idle is runtime-addressable" % expected_forms[form])
	check(HeroArtService.animation_frame_count("run") == 4, "run animation has four frames")
	check(HeroArtService.animation_fps("idle") > 0.0 and HeroArtService.animation_fps("hit") > 0.0, "battle states have presentation frame rates")
	check(HeroArtService.metadata(0).scale == 0.675 and HeroArtService.metadata(4).scale == 0.7875, "existing evolution scale progression is preserved")
	battle.free()
	print("HERO ART SMOKE: ", "FAIL (%d)" % failures if failures else "PASS")
	quit(1 if failures else 0)
