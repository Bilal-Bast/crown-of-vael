extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if value:
		return
	failures += 1
	push_error("PHASE 12A: " + label)

func _run() -> void:
	HeroArtService.clear_cache_for_tests()
	var expected := ["squire", "knight", "royal_knight", "paladin", "divine_paladin"]
	for stage in expected.size():
		check(HeroArtService.form_folder(stage) == expected[stage], "evolution %d maps to folder" % stage)
		check(HeroArtService.form_path(stage).ends_with("/" + expected[stage]), "evolution %d folder path" % stage)
	for slot in ["idle", "attack", "guard", "portrait"]:
		check(HeroArtService.texture_for(0, slot) != null, "Squire %s asset loads" % slot)
	check(HeroArtService.resolve_path(0, "idle") == "res://assets/heroes/knight/squire/squire_idle.png", "Squire legacy filename preserved")
	for slot in ["idle", "attack", "guard", "portrait"]:
		check(HeroArtService.texture_for(1, slot) != null, "Knight %s asset loads" % slot)
		check(HeroArtService.resolve_path(1, slot) == "res://assets/heroes/knight/knight/%s.png" % slot, "Knight %s resolves real asset path" % slot)
	for slot in ["idle", "attack", "guard", "portrait"]:
		check(HeroArtService.texture_for(2, slot) != null, "Royal Knight %s asset loads" % slot)
		check(HeroArtService.resolve_path(2, slot) == "res://assets/heroes/knight/royal_knight/%s.png" % slot, "Royal Knight %s resolves real asset path" % slot)
	check(HeroArtService.texture_for(3, "idle") == null, "missing Paladin art returns procedural fallback signal")
	check(HeroArtService.texture_for(4, "portrait") == null, "missing Divine Paladin portrait returns fallback signal")
	check(HeroArtService.resolve_path(3, "attack").is_empty(), "missing battle state path is empty")
	var squire_path := HeroArtService.asset_path(0, "idle")
	for i in 100:
		HeroArtService.texture_for(0, "idle")
	check(HeroArtService.cached_load_count(squire_path) == 1, "repeated battle lookup loads texture once")
	var report := HeroArtService.validation_report()
	check(report.size() >= 8, "validation reports remaining missing evolution slots without failing")
	var profile := SaveData.new()
	profile.heroes["knight"]["evolution"] = 1
	var battle := BattleController.new()
	battle.profile = profile
	var field := Battlefield.new()
	field.battle = battle
	var gold_before := profile.gold
	battle.active = true
	var run_time_before := battle.run_time
	var boss_time_before := battle.boss_time
	field._on_attack_started(-1, 0)
	check(field.hero_visual_state == "idle", "attack visual doesn't drive combat until frame update")
	field._process(0.01)
	check(field.hero_visual_state == "attack", "idle to attack visual state")
	check(field.hero_attack_art_time > 0.0, "attack visual timer active")
	check(HeroArtService.texture_for(1, field.hero_visual_state) != null, "Knight attack state uses supplied attack art")
	field._process(0.30)
	check(field.hero_visual_state == "idle", "attack visual returns to idle")
	field._on_damage_popup(-1, 1, false, false)
	field._process(0.01)
	check(field.hero_visual_state == "guard", "idle to guard visual state")
	check(HeroArtService.texture_for(1, field.hero_visual_state) != null, "Knight guard state uses supplied guard art")
	field._process(0.31)
	check(field.hero_visual_state == "idle", "guard visual returns to idle")
	profile.heroes["knight"]["evolution"] = 2
	field._on_attack_started(-1, 0)
	field._process(0.01)
	check(HeroArtService.texture_for(2, field.hero_visual_state) != null, "Royal Knight attack state uses supplied attack art")
	field._on_damage_popup(-1, 1, false, false)
	field._process(0.01)
	check(HeroArtService.texture_for(2, field.hero_visual_state) != null, "Royal Knight guard state uses supplied guard art")
	field._on_attack_started(-2, 0)
	check(field.hero_bash and field.shake_time > 0.0 and field.hero_lunge == 0.26, "Shield Bash visual emphasis")
	check(profile.gold == gold_before, "visual events do not grant rewards or alter economy")
	check(battle.active and battle.run_time == run_time_before and battle.boss_time == boss_time_before, "visual transitions leave combat timers unchanged")
	check(HeroArtService.frame_color(4) != HeroArtService.frame_color(0), "evolution frame accents vary by form")
	var portrait := HeroPortrait.new()
	portrait.hero_id = "knight"
	portrait.evolution = 3
	portrait.locked_preview = true
	check(portrait.evolution == 3 and portrait.locked_preview, "locked evolution preview state supported")
	portrait.free()
	field.free()
	battle.free()
	HeroArtService.clear_cache_for_tests()
	print("PHASE 12A ART VALIDATION:")
	for warning in report:
		print("  WARNING: ", warning)
	print("PHASE 12A SMOKE: ", "FAIL (%d)" % failures if failures else "PASS")
	quit(1 if failures else 0)
