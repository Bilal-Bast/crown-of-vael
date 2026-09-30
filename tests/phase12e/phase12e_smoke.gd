extends SceneTree

var failures := 0

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/phase12e_lifecycle.save")
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error("PHASE 12E: " + label)

func _run() -> void:
	for resource in ["res://scenes/main.tscn", "res://icon.svg", "res://scripts/core/save_data.gd", "res://scripts/core/audio_service.gd", "res://scripts/combat/combat_vfx_service.gd", "res://assets/heroes/knight/knight/idle.png", "res://assets/enemies/greenvale/goblin/idle.png"]:
		check(ResourceLoader.exists(resource), "required project resource exists: " + resource)
	check(str(ProjectSettings.get_setting("application/config/name")) == "Crown of Vael", "app label")
	check(str(ProjectSettings.get_setting("application/config/version")) == "0.1.0", "version name")
	check(int(ProjectSettings.get_setting("display/window/handheld/orientation")) == 1, "portrait orientation")
	check(str(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "gl_compatibility", "mobile-compatible renderer")
	check(int(ProjectSettings.get_setting("application/run/max_fps")) == 60, "60 FPS cap")
	check(str(ProjectSettings.get_setting("display/window/stretch/aspect")) == "expand", "portrait aspect expands without stretching")
	check(FileAccess.file_exists("res://export_presets.cfg"), "Android presets tracked")
	var preset_text := FileAccess.get_file_as_string("res://export_presets.cfg")
	check(preset_text.contains("com.crownofvael.game") and preset_text.contains("version/code=1") and preset_text.contains("gradle_build/target_sdk=\"36\""), "stable package/version and API 36 AAB config")
	check(not preset_text.contains("release_password=") and not preset_text.contains("release_user="), "no private signing credentials in preset")
	check(not preset_text.contains("permissions/internet=true"), "no unneeded Internet permission while providers are mocks")
	check(root.get_node_or_null("AudioService") != null, "AudioService autoload instantiated")
	var audio = root.get_node("AudioService")
	check(audio.players.size() == 10 and audio.music_players.size() == 2, "shared audio player pools instantiated once")
	check(not audio.play_event("missing_event") and not audio.play_event("sword_swing"), "missing audio paths fail silently")
	var profile := SaveData.new()
	profile.save_path = "res://.godot/phase12e_persist.save"
	profile.stage = 17
	profile.level = 12
	profile.gold = 5632
	profile.gems = 91
	profile.banners.equipment.pity = 7
	profile.tutorial_state.features["Equipment"] = true
	profile.audio_settings.sfx = 0.4
	profile.offline_last_claim = 123456
	profile.save()
	var loaded := SaveData.load_from(profile.save_path)
	check(loaded.stage == 17 and loaded.level == 12 and loaded.gold == 5632 and loaded.gems == 91, "campaign and currency save round trip")
	check(int(loaded.banners.equipment.pity) == 7, "summon pity preserved")
	check(bool(loaded.tutorial_state.features.get("Equipment", false)) and is_equal_approx(float(loaded.audio_settings.sfx), 0.4), "tutorial and audio settings persist")
	check(loaded.offline_last_claim == 123456, "offline reward timestamp persists")
	var legacy_path := "res://.godot/phase12e_legacy.save"
	var legacy_file := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({"stage": 19, "level": 16, "gold": 75000, "gems": 430, "summon_tickets": {"equipment": 3}, "banners": {"equipment": {"pity": 11}}, "inventory": [{"id": "legacy_sword", "kind": "iron_sword", "rarity": 2, "level": 8}], "heroes": {"knight": {"unlocked": true, "stars": 3, "evolution": 2}}, "purchase_entitlements": {"starter_pack": true}, "friends_state": {"friends": ["legacy_friend"]}, "guild_state": {"guild_id": "legacy_guild"}, "pvp_state": {"rating": 1420}}))
	legacy_file.close()
	var migrated := SaveData.load_from(legacy_path)
	check(migrated.stage == 19 and migrated.level == 16 and migrated.gold == 75000 and migrated.gems == 430, "legacy progress and currency migration")
	check(int(migrated.banners.equipment.pity) == 11 and int(migrated.summon_tickets.equipment) == 3, "legacy summon state migration")
	check(migrated.heroes.knight.stars == 3 and migrated.heroes.knight.evolution == 2 and migrated.get_item("legacy_sword").level == 8, "legacy hero and equipment migration")
	check(bool(migrated.purchase_entitlements.starter_pack) and migrated.friends_state.friends == ["legacy_friend"] and migrated.guild_state.guild_id == "legacy_guild" and migrated.pvp_state.rating == 1420, "legacy purchase and social migration")
	check(bool(migrated.tutorial_state.completed) and migrated.offline_pending_rewards.is_empty(), "legacy defaults avoid forced tutorial and phantom idle reward")
	var vfx := CombatVfxService.new()
	vfx.pulse(Vector2.ZERO, Color.WHITE)
	vfx.label(Vector2.ZERO, "1", Color.WHITE)
	vfx.projectile(Vector2.ZERO, Vector2.RIGHT, Color.WHITE)
	vfx.tick(1.0)
	check(vfx.effects.is_empty() and vfx.labels.is_empty() and vfx.projectiles.is_empty(), "transient VFX, labels, and projectiles expire")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	check(main.get("profile") != null and main.get("battle") != null, "main scene and battle services instantiate")
	main.get("tutorial_popup").hide()
	main.get("offline_popup").hide()
	var main_profile := main.get("profile") as SaveData
	main_profile.tutorial_state.completed = true
	for feature in TutorialService.FEATURES: main_profile.tutorial_state.features[feature] = true
	var persistent_children := main.get_child_count()
	for _cycle in 4:
		for tab in ["Battle", "Heroes", "Equipment", "Summon", "Adventure", "Settings", "Battle"]:
			main.call("_select_tab", tab)
	check(main.get_child_count() == persistent_children, "repeated tab changes do not accumulate persistent screen nodes")
	check(audio.players.size() == 10 and audio.music_players.size() == 2, "screen changes do not create additional audio players")
	main.call("_select_tab", "Settings")
	main.call("_handle_back_request")
	check(str(main.get("selected_tab")) == "Battle", "back from a top-level screen returns to Battle")
	main.call("_select_tab", "Adventure")
	var adventure = main.get("adventure_screen")
	adventure.call("_open", "map")
	main.call("_handle_back_request")
	check(str(adventure.get("view")) == "hub", "back from a nested Adventure view returns to hub")
	main.call("_show_onboarding_step", "battle")
	main.call("_handle_back_request")
	check(not bool(main.get("tutorial_popup").visible), "back closes an open tutorial modal")
	main.call("_select_tab", "Battle")
	main.call("_handle_back_request")
	check(bool(main.get("exit_confirmation").visible), "back at root requests exit confirmation")
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(FileAccess.file_exists("res://.godot/phase12e_lifecycle.save"), "pause lifecycle saves locally")
	main.queue_free()
	await process_frame
	print("PHASE 12E SMOKE: %s" % ("FAIL (%d)" % failures if failures else "PASS"))
	quit(1 if failures else 0)
