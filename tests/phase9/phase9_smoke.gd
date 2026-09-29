extends SceneTree

const PATH := "res://.godot/phase9_smoke.save"
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("PHASE 9: " + label)

func _run() -> void:
	var profile := SaveData.new()
	profile.save_path = PATH
	var service := ProgressionService.new(profile)
	service.refresh()
	check(ProgressionData.DAILY.size() >= 8 and ProgressionData.WEEKLY.size() >= 8, "quest pools")
	service.report("enemy_defeated", 100)
	check(service.progress(ProgressionData.DAILY[0], "daily") == 100, "daily kill progress")
	check(service.claim_quest("daily", "kills"), "daily claim")
	check(not service.claim_quest("daily", "kills"), "daily duplicate claim blocked")
	check(profile.daily_activity == 10, "daily activity")
	service.report("campaign_stage_cleared", 10)
	check(service.claim_quest("daily", "stages") and profile.daily_activity == 20, "second quest activity")
	check(service.claim_milestone("daily", 20) and not service.claim_milestone("daily", 20), "daily milestone once")
	service.report("dungeon_completed", 2)
	check(service.claim_all("daily") == 1, "daily Claim All claims complete only")
	service.report("enemy_defeated", 900)
	check(service.claim_quest("weekly", "kills"), "weekly claim")
	check(profile.weekly_activity == 25, "weekly activity")
	service.report("dungeon_completed", 8)
	check(profile.weekly_activity == 50 and service.claim_milestone("weekly", 50), "weekly activity milestone")
	check(service.achievement_progress(ProgressionData.achievements()[0]) == 1000, "tiered achievement")
	check(service.claim_achievement("enemy_defeated_1000"), "achievement claim")
	check(not service.claim_achievement("enemy_defeated_1000"), "achievement duplicate blocked")
	for category in ProgressionData.ACHIEVEMENT_CATEGORIES:
		var found := false
		for entry in ProgressionData.achievements():
			if str(entry.category) == category: found = true
		check(found, category + " achievement category")
	profile.campaign_first_clears["0:1:20"] = true
	check(_achievement(service, "campaign:0:1:20_1") == 1, "campaign achievement from clear record")
	profile.heroes.knight.stars = 5
	check(_achievement(service, "hero_max_stars_5") == 5, "hero star achievement")
	profile.skills.shield_bash.level = 10
	check(_achievement(service, "skill_max_level_10") == 10, "skill achievement")
	profile.companions.wolf = {"rarity": 4, "level": 1, "stars": 5, "pieces": 0, "evolution": 3}
	check(_achievement(service, "wolf_evolution_3") == 3, "companion achievement")
	profile.artifacts.dragon_fang = {"rarity": 4, "level": 10, "duplicates": 0}
	profile.equipped_artifact_slots[0] = "dragon_fang"
	check(_achievement(service, "artifact_max_level_10") == 10, "artifact achievement")
	profile.tower_highest = 20
	check(_achievement(service, "tower_highest_20") == 20, "Adventure achievement")
	profile.inventory.append(EquipmentData.create_item("rusted_sword", 4))
	check(_achievement(service, "equipment_rarity_4") == 1, "equipment rarity achievement")
	profile.achievement_claimed.clear()
	check(service.claim_all("achievements") > 0 and service.claim_all("achievements") == 0, "achievement Claim All once")
	var lifetime := int(profile.lifetime_stats.enemy_defeated)
	CalendarService.reset_periods(profile, "2099-01-02", "2098-12-29")
	check(profile.daily_counters.is_empty() and profile.weekly_counters.is_empty(), "period resets")
	check(int(profile.lifetime_stats.enemy_defeated) == lifetime and profile.achievement_claimed.has("enemy_defeated_1000"), "lifetime survives reset")
	profile.daily_reset_date = CalendarService.day()
	profile.weekly_reset_week = CalendarService.week()
	check(service.claim_login() and not service.claim_login(), "one daily login claim")
	profile.last_login_reward_date = "2020-01-01"
	profile.daily_login_index = 6
	check(service.claim_login() and profile.daily_login_index == 0, "7-day loop after missed days")
	profile.monthly_login_index = 27
	check(service.claim_monthly() and profile.monthly_login_index == 0, "28-day loop")
	check(not service.claim_monthly(), "one monthly reward per day")
	check(ProgressionData.login_reward(27, true).has("hero_pieces"), "day 28 milestone")
	profile.summon_tickets.equipment = 1
	profile.summon_tickets.skills = 1
	profile.summon_tickets.companions = 1
	profile.summon_tickets.artifacts = 1
	var summons := int(profile.lifetime_stats.get("summon_performed", 0))
	for banner in ["equipment", "skills", "companions", "artifacts"]:
		var before_gems := profile.gems
		var before_pity := int(profile.banners[banner].pity)
		var before_exp := int(profile.banners[banner].exp)
		check(SummonService.new(profile).summon(banner, 1, "ticket").size() == 1, banner + " ticket pull")
		check(int(profile.summon_tickets[banner]) == 0 and profile.gems == before_gems, banner + " ticket no Gems")
		check(int(profile.banners[banner].pity) == before_pity + 1, banner + " pity")
		check(int(profile.banners[banner].exp) > before_exp or int(profile.banners[banner].level) > 1, banner + " banner EXP")
	check(int(profile.lifetime_stats.summon_performed) == summons + 4, "ticket summons counted")
	profile.save()
	var loaded := SaveData.load_from(PATH)
	check(loaded.daily_login_index == profile.daily_login_index and loaded.monthly_login_index == profile.monthly_login_index, "login save")
	check(loaded.achievement_claimed.has("enemy_defeated_1000") and int(loaded.lifetime_stats.enemy_defeated) == lifetime, "statistics save")
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"phase8_version": 1, "gold": 1234, "gems": 17, "level": 8, "stage": 3}))
	file.close()
	var migrated := SaveData.load_from(PATH)
	check(migrated.gold == 1234 and migrated.gems == 17 and migrated.level == 8 and migrated.daily_login_index == 0, "Phase 8 migration")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	(main.get("profile") as SaveData).last_login_reward_date = ""
	check(main.get("quests_screen") != null and main.get("login_screen") != null, "screens instantiated")
	check(main.get("login_popup") != null, "login popup instantiated")
	await process_frame
	check((main.get("login_popup") as PopupPanel).visible, "unclaimed login opens popup")
	print("PHASE 9 SMOKE: ", "FAIL (%d)" % failures if failures else "PASS")
	quit(1 if failures else 0)

func _achievement(service: ProgressionService, id: String) -> int:
	for entry in ProgressionData.achievements():
		if str(entry.id) == id: return service.achievement_progress(entry)
	return -1
