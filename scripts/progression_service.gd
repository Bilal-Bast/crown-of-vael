class_name ProgressionService
extends RefCounted

var profile: SaveData

func _init(value: SaveData) -> void:
	profile = value

func refresh(today: String = "", week: String = "") -> void:
	if CalendarService.reset_periods(profile, today, week):
		profile.save()

func report(event: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	CalendarService.reset_periods(profile)
	for counters in [profile.lifetime_stats, profile.daily_counters, profile.weekly_counters]:
		if event == "endless_wave_reached": counters[event] = maxi(int(counters.get(event, 0)), amount)
		else: counters[event] = int(counters.get(event, 0)) + amount
	if event == "endless_wave_reached":
		profile.lifetime_stats["highest_endless_wave"] = maxi(int(profile.lifetime_stats.get("highest_endless_wave", 0)), amount)
	if event == "tower_floor_cleared":
		profile.lifetime_stats["tower_floor"] = maxi(int(profile.lifetime_stats.get("tower_floor", 0)), profile.tower_highest)
	for period in ["daily", "weekly"]:
		var entries: Array = ProgressionData.DAILY if period == "daily" else ProgressionData.WEEKLY
		var awarded: Dictionary = profile.daily_activity_awarded if period == "daily" else profile.weekly_activity_awarded
		for entry in entries:
			if str(entry[4]) != event or awarded.has(str(entry[0])) or progress(entry, period) < int(entry[5]): continue
			awarded[str(entry[0])] = true
			if period == "daily": profile.daily_activity += 10
			else: profile.weekly_activity += 25

func progress(entry: Array, period: String) -> int:
	var counters: Dictionary = profile.daily_counters if period == "daily" else profile.weekly_counters
	return mini(int(entry[5]), int(counters.get(str(entry[4]), 0)))

func claim_quest(period: String, id: String) -> bool:
	refresh()
	var entries: Array = ProgressionData.DAILY if period == "daily" else ProgressionData.WEEKLY if period == "weekly" else []
	var claimed: Dictionary = profile.daily_claimed if period == "daily" else profile.weekly_claimed
	var active_ids: Array[String] = profile.daily_quest_ids if period == "daily" else profile.weekly_quest_ids
	if not active_ids.has(id): return false
	for entry in entries:
		if str(entry[0]) != id:
			continue
		if claimed.has(id) or progress(entry, period) < int(entry[5]):
			return false
		claimed[id] = true
		grant(entry[6])
		profile.save()
		return true
	return false

func claim_all(period: String) -> int:
	var total := 0
	if period == "achievements":
		for entry in ProgressionData.achievements():
			if claim_achievement(str(entry.id)): total += 1
	else:
		var entries: Array = ProgressionData.DAILY if period == "daily" else ProgressionData.WEEKLY
		for entry in entries:
			if claim_quest(period, str(entry[0])): total += 1
	return total

func claim_milestone(period: String, target: int) -> bool:
	refresh()
	var rewards: Dictionary = ProgressionData.DAILY_MILESTONES if period == "daily" else ProgressionData.WEEKLY_MILESTONES
	var claimed: Dictionary = profile.daily_activity_claimed if period == "daily" else profile.weekly_activity_claimed
	var score: int = profile.daily_activity if period == "daily" else profile.weekly_activity
	if not rewards.has(target) or score < target or claimed.has(str(target)):
		return false
	claimed[str(target)] = true
	grant(rewards[target])
	profile.save()
	return true

func achievement_progress(entry: Dictionary) -> int:
	var key := str(entry.key)
	var value := int(profile.lifetime_stats.get(key, 0))
	if key.begins_with("campaign:"):
		value = 1 if profile.campaign_first_clears.has(key.trim_prefix("campaign:")) else 0
	elif key == "easy_regions":
		value = 0
		for region in range(1, 11):
			if profile.region_rewards_claimed.has("0:%d" % region): value += 1
	elif key == "difficulty_unlocked": value = profile.highest_difficulty_unlocked
	elif key == "heroes_unlocked":
		value = 0
		for record in profile.heroes.values():
			if bool(record.unlocked): value += 1
	elif key == "hero_max_stars":
		for record in profile.heroes.values(): value = maxi(value, int(record.stars))
	elif key == "knight_evolution": value = int(profile.heroes.knight.evolution)
	elif key == "equipment_slots": value = profile.equipped.size()
	elif key == "skills_owned": value = profile.skills.size()
	elif key == "skill_slots":
		for id in profile.equipped_skill_slots:
			if id != "": value += 1
	elif key == "skill_max_level":
		for record in profile.skills.values(): value = maxi(value, int(record.level))
	elif key == "companions_owned": value = profile.companions.size()
	elif key == "companion_slots":
		for id in profile.equipped_companion_slots:
			if id != "": value += 1
	elif key == "companion_max_stars":
		for record in profile.companions.values(): value = maxi(value, int(record.stars))
	elif key == "wolf_evolution" and profile.companions.has("wolf"): value = int(profile.companions.wolf.evolution)
	elif key == "artifacts_owned": value = profile.artifacts.size()
	elif key == "artifact_slots":
		for id in profile.equipped_artifact_slots:
			if id != "": value += 1
	elif key == "artifact_slot_limit": value = profile.artifact_slot_limit()
	elif key == "artifact_max_level":
		for record in profile.artifacts.values(): value = maxi(value, int(record.level))
	elif key == "dragon_set":
		for id in profile.equipped_artifact_slots:
			if id in ["dragon_fang", "dragon_eye", "dragon_heart"]: value += 1
	elif key == "tower_highest": value = profile.tower_highest
	elif key == "boss_rush_best": value = int(profile.boss_rush_state.best_boss)
	elif key == "hero_level": value = profile.level
	elif key == "equipment_owned": value = profile.inventory.size()
	elif key == "collection_total": value = profile.inventory.size() + profile.skills.size() + profile.companions.size() + profile.artifacts.size()
	elif key.begins_with("rarity:"):
		var parts := key.split(":")
		var banner := parts[1]
		var rarity := int(parts[2])
		value = 1 if int(profile.lifetime_stats.get("summon_%s_rarity_%d" % [banner, rarity], 0)) > 0 else 0
		if banner == "equipment":
			for item in profile.inventory:
				if int(item.rarity) >= rarity: value = 1
		elif banner == "skills":
			for record in profile.skills.values():
				if int(record.rarity) >= rarity: value = 1
		elif banner == "companions":
			for record in profile.companions.values():
				if int(record.rarity) >= rarity: value = 1
		elif banner == "artifacts":
			for record in profile.artifacts.values():
				if int(record.rarity) >= rarity: value = 1
	return mini(int(entry.target), value)

func claim_achievement(id: String) -> bool:
	for entry in ProgressionData.achievements():
		if str(entry.id) == id and not profile.achievement_claimed.has(id) and achievement_progress(entry) >= int(entry.target):
			profile.achievement_claimed[id] = true
			grant(entry.reward)
			profile.save()
			return true
	return false

func claim_login() -> bool:
	var today := CalendarService.day()
	if profile.last_login_reward_date == today:
		return false
	grant(ProgressionData.login_reward(profile.daily_login_index))
	profile.daily_login_index = (profile.daily_login_index + 1) % 7
	profile.last_login_reward_date = today
	profile.save()
	return true

func claim_monthly() -> bool:
	var today := CalendarService.day()
	if profile.last_monthly_reward_date == today:
		return false
	grant(ProgressionData.login_reward(profile.monthly_login_index, true))
	profile.monthly_login_index = (profile.monthly_login_index + 1) % 28
	profile.last_monthly_reward_date = today
	profile.save()
	return true

func grant(reward: Dictionary) -> void:
	for key in reward:
		if str(key).ends_with("_ticket"):
			var banner := str(key).trim_suffix("_ticket")
			profile.summon_tickets[banner] = int(profile.summon_tickets.get(banner, 0)) + int(reward[key])
		else:
			profile.set(key, int(profile.get(key)) + int(reward[key]))

func badge(section: String) -> bool:
	match section:
		"Quests":
			for target in ProgressionData.DAILY_MILESTONES:
				if profile.daily_activity >= int(target) and not profile.daily_activity_claimed.has(str(target)): return true
			for target in ProgressionData.WEEKLY_MILESTONES:
				if profile.weekly_activity >= int(target) and not profile.weekly_activity_claimed.has(str(target)): return true
			for period in ["daily", "weekly"]:
				var entries: Array = ProgressionData.DAILY if period == "daily" else ProgressionData.WEEKLY
				var claimed: Dictionary = profile.daily_claimed if period == "daily" else profile.weekly_claimed
				for entry in entries:
					if not claimed.has(str(entry[0])) and progress(entry, period) >= int(entry[5]): return true
			for entry in ProgressionData.achievements():
				if not profile.achievement_claimed.has(str(entry.id)) and achievement_progress(entry) >= int(entry.target): return true
		"Login": return profile.last_login_reward_date != CalendarService.day() or profile.last_monthly_reward_date != CalendarService.day()
		"Heroes":
			for id in HeroData.HEROES:
				var record: Dictionary = profile.heroes[id]
				if not bool(record.unlocked) and int(record.pieces) >= int(HeroData.HEROES[id].unlock): return true
				if bool(record.unlocked) and int(record.stars) < HeroData.MAX_STARS and int(record.pieces) >= HeroData.star_cost(int(record.stars)): return true
				if HeroProgress.new(profile).can_evolve(id): return true
		"Equipment":
			for item in profile.inventory:
				if profile.merge_count(str(item.kind), int(item.rarity), int(item.level)) > 0: return true
		"Summon":
			for banner in SummonData.BANNERS:
				if SummonService.new(profile).can_summon(banner, 1, "daily"): return true
		"Companions":
			for id in profile.companions:
				var record: Dictionary = profile.companions[id]
				if int(record.stars) < CompanionData.MAX_STARS and int(record.pieces) >= CompanionData.star_cost(int(record.stars)): return true
				if int(record.level) < 99:
					var cost: Dictionary = CompanionData.level_cost(int(record.level))
					if profile.gold >= int(cost.gold) and profile.companion_essence >= int(cost.essence): return true
				if id == "wolf" and int(record.evolution) < CompanionData.WOLF_EVOLUTION.size():
					var evolve: Dictionary = CompanionData.WOLF_EVOLUTION[int(record.evolution)]
					if int(record.level) >= int(evolve.level) and int(record.stars) >= int(evolve.stars) and profile.companion_essence >= int(evolve.essence) and profile.companion_crests >= int(evolve.crests): return true
		"Artifacts":
			for record in profile.artifacts.values():
				if int(record.level) >= 99: continue
				var cost: Dictionary = ArtifactData.level_cost(int(record.level))
				if profile.gold >= int(cost.gold) and profile.artifact_dust >= int(cost.dust) and int(record.duplicates) >= int(cost.copies): return true
	return false
