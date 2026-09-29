class_name CalendarService
extends RefCounted

static func day() -> String:
	var date := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]

static func week() -> String:
	var date := Time.get_date_dict_from_system()
	var unix := Time.get_unix_time_from_datetime_dict({"year": date.year, "month": date.month, "day": date.day, "hour": 12})
	var weekday := int(date.weekday)
	var monday := unix - ((weekday + 6) % 7) * 86400
	return Time.get_date_string_from_unix_time(int(monday))

static func reset_periods(profile: SaveData, today: String = "", this_week: String = "") -> bool:
	today = day() if today == "" else today
	this_week = week() if this_week == "" else this_week
	var changed := false
	if profile.daily_reset_date != today:
		profile.daily_reset_date = today
		profile.daily_counters.clear()
		profile.daily_claimed.clear()
		profile.daily_activity = 0
		profile.daily_activity_claimed.clear()
		profile.daily_activity_awarded.clear()
		profile.daily_quest_ids.clear()
		for entry in ProgressionData.DAILY: profile.daily_quest_ids.append(str(entry[0]))
		changed = true
	if profile.weekly_reset_week != this_week:
		profile.weekly_reset_week = this_week
		profile.weekly_counters.clear()
		profile.weekly_claimed.clear()
		profile.weekly_activity = 0
		profile.weekly_activity_claimed.clear()
		profile.weekly_activity_awarded.clear()
		profile.weekly_quest_ids.clear()
		for entry in ProgressionData.WEEKLY: profile.weekly_quest_ids.append(str(entry[0]))
		changed = true
	if profile.daily_quest_ids.is_empty():
		for entry in ProgressionData.DAILY: profile.daily_quest_ids.append(str(entry[0]))
		changed = true
	if profile.weekly_quest_ids.is_empty():
		for entry in ProgressionData.WEEKLY: profile.weekly_quest_ids.append(str(entry[0]))
		changed = true
	return changed
