extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if value:
		return
	failures += 1
	push_error("PHASE 12B: " + label)

func _run() -> void:
	EnemyArtService.clear_cache_for_tests()
	var ids := ["Goblin", "Skeleton", "Corrupted Wolf", "Goblin Archer", "Goblin Spearman", "Bandit", "Goblin Captain", "Armored Skeleton", "Goblin Warlord"]
	var folders := ["goblin", "skeleton", "corrupted_wolf", "goblin_archer", "goblin_spearman", "bandit", "goblin_captain", "armored_skeleton", "goblin_warlord"]
	for i in ids.size():
		check(EnemyArtService.enemy_folder(ids[i]) == folders[i], "%s maps to Greenvale art folder" % ids[i])
		var idle := EnemyArtService.texture_for(ids[i], "idle")
		check(idle != null, "%s idle texture loads" % ids[i])
		if idle != null:
			check(idle.get_image().detect_alpha(), "%s preserves sprite transparency" % ids[i])
			check(idle.get_width() <= 512 and idle.get_height() <= 768, "%s import stays within mobile texture size" % ids[i])
		check(EnemyArtService.texture_for(ids[i], "attack") == null, "%s missing attack art returns procedural fallback signal" % ids[i])
		check(EnemyArtService.texture_for(ids[i], "hit") == null, "%s missing hit art returns procedural fallback signal" % ids[i])
	check(EnemyArtService.texture_for("Unknown Beast", "idle") == null, "unknown enemy returns procedural fallback signal")
	check(EnemyArtService.texture_for("Goblin", "idle", 2) == null, "unintegrated region remains on procedural fallback")
	var goblin_path := EnemyArtService.enemy_path("Goblin", "idle")
	for i in 100: EnemyArtService.texture_for("Goblin", "idle")
	check(EnemyArtService.cached_load_count(goblin_path) == 1, "repeated enemy lookups load texture once")
	var background := EnemyArtService.background_texture(1)
	check(background != null, "Greenvale regular background loads")
	if background != null:
		check(background.get_width() <= 1536, "background import uses mobile-friendly size limit")
	check(EnemyArtService.background_texture(1, true) == background, "missing boss background falls back to Greenvale regular background")
	check(EnemyArtService.background_texture(2) == null, "unintegrated region background keeps procedural fallback")
	var warnings := EnemyArtService.validation_report()
	check(warnings.size() == 19, "validation reports only missing attack/hit states and optional boss background")
	check(EnemyArtService.metadata("Goblin Warlord").scale > EnemyArtService.metadata("Goblin Captain").scale, "boss sprite metadata exceeds elite size")
	var battle := BattleController.new()
	battle.profile = SaveData.new()
	battle.stage = 1
	battle.region = 1
	battle.mode_config = {"mode": "campaign"}
	battle.active = true
	battle.run_time = 4.0
	battle.boss_time = 26.0
	var archer := CampaignData.enemy_stats("Goblin Archer", 0, 1, 1, 1)
	archer["current_hp"] = archer["hp"]
	archer["attack_time"] = 3.0
	battle.enemies.append(archer)
	var field := Battlefield.new()
	field.battle = battle
	field._on_attack_started(0, -1)
	check(field.enemy_visual_state(0) == "attack", "enemy idle to attack state follows combat event")
	check(field.lunges.is_empty(), "ranged archer keeps ranged attack motion")
	check(not field.impacts.is_empty(), "ranged archer retains ranged impact effect")
	field._process(0.40)
	check(field.enemy_visual_state(0) == "idle", "enemy attack state returns to idle")
	field._on_damage_popup(0, 4, false, false)
	check(field.enemy_visual_state(0) == "hit", "enemy hit state follows combat damage event")
	field._process(0.30)
	check(field.enemy_visual_state(0) == "idle", "enemy hit state returns to idle")
	check(battle.run_time == 4.0 and battle.boss_time == 26.0, "enemy art state timers do not alter combat timers")
	var boss := CampaignData.enemy_stats("Goblin Warlord", 0, 1, 20, 1)
	check(str(boss.archetype) == "BOSS", "Goblin Warlord retains boss combat identity")
	check(EnemyArtService.texture_for("Goblin Warlord", "idle") != null, "Goblin Warlord boss art loads")
	field.free()
	battle.free()
	EnemyArtService.clear_cache_for_tests()
	print("PHASE 12B: ", "FAIL (%d)" % failures if failures else "PASS")
	for warning in warnings: print("  ART WARNING: ", warning)
	quit(1 if failures else 0)
