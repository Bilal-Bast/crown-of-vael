extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var low := CampaignData.enemy_stats("demon_lord", 0, 10, 20, 1)
	var high := CampaignData.enemy_stats("demon_lord", 5, 10, 20, 1)
	assert(is_equal_approx(float(low["armor"]), float(high["armor"])), "flat enemy armor must not multiply with HP difficulty scaling")
	assert(float(high["hp"]) > float(low["hp"]) and float(high["atk"]) > float(low["atk"]), "difficulty still scales enemy HP and attack")
	var companion_source := FileAccess.get_file_as_string("res://scripts/companions/companion_runtime.gd")
	assert(companion_source.contains("battle.stage == 20 and str(battle.mode_config.get(\"mode\", \"campaign\")) == \"campaign\""), "companion boss damage is limited to campaign boss stages")
	print("PASS: Phase 14B armor scaling and campaign companion boss damage rules")
	quit()
