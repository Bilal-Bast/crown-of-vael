extends RefCounted

# Development helper. This script is never instantiated by production scenes.
static func reset_daily(profile: SaveData) -> void:
	profile.daily_reset_date = ""
	ProgressionService.new(profile).refresh()

static func reset_weekly(profile: SaveData) -> void:
	profile.weekly_reset_week = ""
	ProgressionService.new(profile).refresh()

static func complete_quest(profile: SaveData, period: String, id: String) -> void:
	var entries: Array = ProgressionData.DAILY if period == "daily" else ProgressionData.WEEKLY
	for entry in entries:
		if str(entry[0]) == id:
			var counters: Dictionary = profile.daily_counters if period == "daily" else profile.weekly_counters
			counters[str(entry[4])] = int(entry[5])
			profile.save()

static func complete_all(profile: SaveData, period: String) -> void:
	var entries: Array = ProgressionData.DAILY if period == "daily" else ProgressionData.WEEKLY
	for entry in entries: complete_quest(profile, period, str(entry[0]))

static func grant_achievement_progress(profile: SaveData, key: String, amount: int) -> void:
	profile.lifetime_stats[key] = maxi(0, int(profile.lifetime_stats.get(key, 0)) + amount)
	profile.save()

static func reset_login_claim(profile: SaveData) -> void:
	profile.last_login_reward_date = ""
	profile.last_monthly_reward_date = ""
	profile.save()

static func advance_login_day(profile: SaveData) -> void:
	reset_login_claim(profile)
	profile.daily_login_index = (profile.daily_login_index + 1) % 7
	profile.monthly_login_index = (profile.monthly_login_index + 1) % 28
	profile.save()

static func grant_tickets(profile: SaveData, banner: String, amount: int) -> void:
	if profile.summon_tickets.has(banner):
		profile.summon_tickets[banner] = maxi(0, int(profile.summon_tickets[banner]) + amount)
		profile.save()

static func test_badges(profile: SaveData) -> Dictionary:
	var service := ProgressionService.new(profile)
	var result := {}
	for section in ["Quests", "Login", "Heroes", "Equipment", "Summon"]:
		result[section] = service.badge(section)
	return result
