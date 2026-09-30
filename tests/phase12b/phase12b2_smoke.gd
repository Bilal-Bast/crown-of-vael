extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error("PHASE 12B.2: " + label)

func _run() -> void:
	EnemyArtService.clear_cache_for_tests()
	for region in range(2, 11):
		var info: Dictionary = CampaignData.REGIONS[region - 1]
		var expected: Array = info["enemies"] + info["elites"] + [info["boss"]]
		check(EnemyArtService.ENEMY_REGION_FOLDERS.has(region), "region %d enemy folder mapped" % region)
		check(EnemyArtService.BACKGROUND_REGION_FOLDERS.has(region), "region %d background folder mapped" % region)
		for id in expected:
			var enemy_id := str(id)
			var folder := EnemyArtService.enemy_folder(enemy_id, region)
			check(not folder.is_empty(), "%s folder mapped" % enemy_id)
			var idle := EnemyArtService.texture_for(enemy_id, "idle", region)
			check(idle != null, "%s idle texture loads" % enemy_id)
			if idle != null:
				check(idle.get_image().detect_alpha(), "%s preserves alpha" % enemy_id)
				check(idle.get_width() <= 768 and idle.get_height() <= 768, "%s mobile texture cap" % enemy_id)
			var path := EnemyArtService.enemy_path(enemy_id, "idle", region)
			for i in 4:
				EnemyArtService.texture_for(enemy_id, "idle", region)
			check(EnemyArtService.cached_load_count(path) == 1, "%s texture cached" % enemy_id)
			check(EnemyArtService.texture_for(enemy_id, "attack", region) == null, "%s missing attack falls back" % enemy_id)
			check(EnemyArtService.texture_for(enemy_id, "hit", region) == null, "%s missing hit falls back" % enemy_id)
			check(EnemyArtService.presentation_texture_for(enemy_id, "attack", region) == idle, "%s attack keeps idle art" % enemy_id)
			check(EnemyArtService.presentation_texture_for(enemy_id, "hit", region) == idle, "%s hit keeps idle art" % enemy_id)
		var background := EnemyArtService.background_texture(region)
		check(background != null, "region %d background loads" % region)
		if background != null:
			check(background.get_width() <= 1536 and background.get_height() <= 1536, "region %d background mobile cap" % region)
		check(EnemyArtService.background_texture(region, true) == background, "region %d boss background falls back" % region)
		var bg_path := EnemyArtService.background_path(region)
		for i in 4:
			EnemyArtService.background_texture(region)
		check(EnemyArtService.cached_load_count(bg_path) == 1, "region %d background cached" % region)
	check(EnemyArtService.texture_for("Forest Goblin", "idle", 3) == null, "region mappings are isolated")
	check(EnemyArtService.presentation_texture_for("Unknown Beast", "attack", 2) == null, "missing idle art uses procedural fallback")
	for enemy_id in ["Poison Wolf", "Fire Archer", "Ancient Sand Wyrm", "Elder Wyvern", "Hellhound"]:
		check(bool(EnemyArtService.metadata(enemy_id).get("flip_h", false)), "%s faces hero" % enemy_id)
	for enemy_id in ["Ancient Treant", "Marsh Hydra", "Ancient Dragon", "Demon Lord"]:
		check(not bool(EnemyArtService.metadata(enemy_id).get("flip_h", false)), "%s keeps source orientation" % enemy_id)
	print("PHASE 12B.2: ", "FAIL (%d)" % failures if failures else "PASS")
	quit(1 if failures else 0)
