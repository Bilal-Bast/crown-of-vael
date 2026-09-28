class_name HeroProgress
extends RefCounted

var profile: SaveData

func _init(value: SaveData) -> void:
	profile = value

func select(id: String, in_battle: bool) -> bool:
	if in_battle or not HeroData.HEROES.has(id) or not bool(profile.heroes[id]["unlocked"]):
		return false
	profile.selected_hero_id = id
	profile.save()
	return true

func unlock(id: String) -> bool:
	if not HeroData.HEROES.has(id) or bool(profile.heroes[id]["unlocked"]):
		return false
	var record: Dictionary = profile.heroes[id]
	var cost := int(HeroData.HEROES[id]["unlock"])
	if int(record["pieces"]) < cost:
		return false
	record["pieces"] = int(record["pieces"]) - cost
	record["unlocked"] = true
	_claim_milestones()
	profile.save()
	return true

func star_up(id: String) -> bool:
	if not HeroData.HEROES.has(id):
		return false
	var record: Dictionary = profile.heroes[id]
	var stars := int(record["stars"])
	if not bool(record["unlocked"]) or stars >= HeroData.MAX_STARS:
		return false
	var cost := HeroData.star_cost(stars)
	if int(record["pieces"]) < cost:
		return false
	record["pieces"] = int(record["pieces"]) - cost
	record["stars"] = stars + 1
	_claim_milestones()
	profile.save()
	return true

func can_evolve(id: String) -> bool:
	if not HeroData.HEROES.has(id) or not bool(profile.heroes[id]["unlocked"]):
		return false
	var stage := int(profile.heroes[id]["evolution"])
	var cost := HeroData.evolution_cost(id, stage)
	return not cost.is_empty() and profile.level >= int(cost["level"]) and profile.gold >= int(cost["gold"]) and profile.evolution_crests >= int(cost["crests"])

func evolve(id: String) -> Dictionary:
	if not can_evolve(id):
		return {}
	var record: Dictionary = profile.heroes[id]
	var stage := int(record["evolution"])
	var before := HeroData.title(id, record)
	var old_stats := profile.hero_stats() if profile.selected_hero_id == id else {}
	var cost := HeroData.evolution_cost(id, stage)
	profile.gold -= int(cost["gold"])
	profile.evolution_crests -= int(cost["crests"])
	record["evolution"] = stage + 1
	if id == "knight":
		profile.evolution = stage + 1 # Phase 3–6 compatibility field.
	_claim_milestones()
	profile.save()
	return {"previous": before, "next": HeroData.title(id, record), "before_stats": old_stats, "after_stats": profile.hero_stats() if profile.selected_hero_id == id else {}, "element": HeroData.element(id, record)}

func convert(id: String, copies: int = 1) -> bool:
	if not HeroData.HEROES.has(id) or id == "knight" or copies < 1:
		return false
	var cost := copies * HeroData.CONVERSION_RATE
	if profile.hero_pieces < cost:
		return false
	profile.hero_pieces -= cost
	profile.heroes[id]["pieces"] = int(profile.heroes[id]["pieces"]) + copies
	profile.save()
	return true

func add_pieces(id: String, amount: int) -> void:
	if HeroData.HEROES.has(id) and amount > 0:
		profile.heroes[id]["pieces"] = int(profile.heroes[id]["pieces"]) + amount
		profile.save()

func _claim_milestones() -> void:
	var owned := 0
	var three_stars := false
	for id in HeroData.HEROES:
		if bool(profile.heroes[id]["unlocked"]):
			owned += 1
		if int(profile.heroes[id]["stars"]) >= 3:
			three_stars = true
	var knight_stage := int(profile.heroes["knight"]["evolution"])
	for key in HeroData.MILESTONES:
		if profile.hero_milestones.has(key):
			continue
		var earned: bool = key == "heroes_2" and owned >= 2 or key == "heroes_5" and owned >= 5 or key == "hero_star_3" and three_stars
		for stage in range(1, 5):
			if key == "evolve_knight_%d" % stage and knight_stage >= stage:
				earned = true
		if earned:
			profile.hero_milestones.append(key)
			var reward: Dictionary = HeroData.MILESTONES[key]
			profile.gems += int(reward["gems"])
			profile.evolution_crests += int(reward["crests"])
			profile.hero_pieces += int(reward["pieces"])
