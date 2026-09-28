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
		"gems": return SummonData.COSTS.has(count) and profile.gems >= int(SummonData.COSTS[count])
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
		profile.gems -= int(SummonData.COSTS[count])
	elif source == "daily":
		state["free_day"] = today
	else:
		state["ad_count"] = 0 if state.get("ad_day", "") != today else int(state.get("ad_count", 0))
		state["ad_day"] = today
		state["ad_count"] = int(state["ad_count"]) + 1
	for i in count:
		state["pity"] = int(state["pity"]) + 1
		var rarity := SummonData.roll_rarity(int(state["level"]))
		if int(state["pity"]) >= SummonData.PITY_LIMIT:
			rarity = maxi(rarity, 4)
			state["pity"] = 0
		var reward: Dictionary
		if banner == "equipment":
			reward = EquipmentData.summon_item(rarity)
			profile.inventory.append(reward)
		else:
			var keys := SkillData.SKILLS.keys()
			var id := str(keys[randi_range(0, keys.size() - 1)])
			profile.add_skill_copy(id, rarity)
			reward = {"kind": id, "rarity": rarity}
		results.append(reward)
		state["exp"] = int(state["exp"]) + SummonData.EXP_PER_SUMMON
		while int(state["level"]) < SummonData.MAX_LEVEL and int(state["exp"]) >= SummonData.exp_to_next(int(state["level"])):
			state["exp"] = int(state["exp"]) - SummonData.exp_to_next(int(state["level"]))
			state["level"] = int(state["level"]) + 1
		if int(state["level"]) >= SummonData.MAX_LEVEL:
			state["exp"] = 0
	profile.save()
	return results
