class_name SummonService
extends RefCounted

var profile: SaveData
var ad_provider: RewardedAdService

func _init(new_profile: SaveData, provider: RewardedAdService = null) -> void:
	profile = new_profile
	ad_provider = provider if provider != null else RewardedAdService.new()

static func local_day() -> String:
	var date := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [date["year"], date["month"], date["day"]]

func can_summon(banner: String, count: int, source: String = "gems", day: String = "") -> bool:
	if not SummonData.BANNERS.has(banner) or not profile.banners.has(banner):
		return false
	var state: Dictionary = profile.banners[banner]
	var today := day if day != "" else local_day()
	match source:
		"gems": return SummonData.COSTS.has(count) and (profile.summon_tickets.get(banner, 0) >= count or profile.gems >= int(SummonData.COSTS[count]))
		"ticket": return count > 0 and int(profile.summon_tickets.get(banner, 0)) >= count
		"daily": return count == 1 and state.get("free_day", "") != today
		"ad": return count == 1 and (state.get("ad_day", "") != today or int(state.get("ad_count", 0)) < SummonData.AD_DAILY_LIMIT)
	return false

func summon(banner: String, count: int, source: String = "gems", day: String = "") -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if not can_summon(banner, count, source, day):
		return results
	var today := day if day != "" else local_day()
	var state: Dictionary = profile.banners[banner]
	if source == "ad" and not ad_provider.show_rewarded_ad():
		return results
	if source == "gems":
		if int(profile.summon_tickets.get(banner, 0)) >= count:
			profile.summon_tickets[banner] = int(profile.summon_tickets[banner]) - count
		else:
			profile.gems -= int(SummonData.COSTS[count])
	elif source == "ticket":
		profile.summon_tickets[banner] = int(profile.summon_tickets[banner]) - count
	elif source == "daily":
		state["free_day"] = today
	else:
		state["ad_count"] = 0 if state.get("ad_day", "") != today else int(state.get("ad_count", 0))
		state["ad_day"] = today
		state["ad_count"] = int(state["ad_count"]) + 1
	for i in count:
		state["pity"] = int(state["pity"]) + 1
		var rarity := SummonData.roll_rarity(int(state["level"]), banner)
		if int(state["pity"]) >= SummonData.PITY_LIMIT:
			rarity = maxi(rarity, 4)
			state["pity"] = 0
		var reward: Dictionary
		if banner == "equipment":
			reward = EquipmentData.summon_item(rarity)
			profile.inventory.append(reward)
		elif banner == "skills":
			var keys := SkillData.SKILLS.keys()
			var id := str(keys[randi_range(0, keys.size() - 1)])
			profile.add_skill_copy(id, rarity)
			reward = {"kind": id, "rarity": rarity}
		elif banner == "companions":
			var keys := CompanionData.COMPANIONS.keys()
			var id := str(keys[randi_range(0, keys.size() - 1)])
			profile.add_companion_copy(id, rarity)
			profile.companion_essence += 2
			if rarity >= 4:
				profile.companion_crests += 1
			reward = {"kind": id, "rarity": rarity}
		else:
			var keys := ArtifactData.ARTIFACTS.keys()
			var id := str(keys[randi_range(0, keys.size() - 1)])
			profile.add_artifact_copy(id, rarity)
			profile.artifact_dust += 2
			reward = {"kind": id, "rarity": rarity}
		results.append(reward)
		var tracker := ProgressionService.new(profile)
		tracker.report("summon_performed")
		if rarity >= 4:
			tracker.report("summon_rarity_%d" % rarity)
			tracker.report("summon_%s_rarity_%d" % [banner, rarity])
		state["exp"] = int(state["exp"]) + SummonData.EXP_PER_SUMMON
		while int(state["level"]) < SummonData.MAX_LEVEL and int(state["exp"]) >= SummonData.exp_to_next(int(state["level"])):
			state["exp"] = int(state["exp"]) - SummonData.exp_to_next(int(state["level"]))
			state["level"] = int(state["level"]) + 1
		if int(state["level"]) >= SummonData.MAX_LEVEL:
			state["exp"] = 0
	profile.save()
	return results
