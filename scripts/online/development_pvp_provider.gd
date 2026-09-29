class_name DevelopmentPvPProvider
extends RefCounted

var fail_next := false
const MOCKS := [
	{"id": "MOCK-VALE-01", "name": "Mira Dawnward", "hero": "ranger", "rating": 850},
	{"id": "MOCK-VALE-02", "name": "Corvin Ashfall", "hero": "mage", "rating": 1050},
	{"id": "MOCK-VALE-03", "name": "Sable Thorn", "hero": "assassin", "rating": 1200},
	{"id": "MOCK-VALE-04", "name": "Edrin Vale", "hero": "necromancer", "rating": 1400},
	{"id": "MOCK-VALE-05", "name": "Bran Ironoak", "hero": "knight", "rating": 1000}
]

func opponents(profile: SaveData, count: int = 3) -> Dictionary:
	if fail_next:
		fail_next = false
		return {"ok": false, "error": "Opponents are unavailable. PvE remains available."}
	var around := MOCKS.duplicate(true)
	var target := int(profile.pvp_state.get("rating", 1000))
	for record in around:
		record["power"] = maxi(100, roundi(float(profile.power()) * float(record.rating) / 1000.0))
		record["rating"] = clampi(int(record.rating), target - 500, target + 500)
		record["rank"] = rank_for_rating(int(record.rating))
		record["frame"] = "golden_frame" if record.id == "MOCK-VALE-02" else ""
		record["snapshot"] = _snapshot(profile, str(record.hero))
	return {"ok": true, "opponents": around.slice(0, mini(count, around.size()))}

func _snapshot(profile: SaveData, hero_id: String) -> Dictionary:
	var record: Dictionary = profile.heroes.get(hero_id, HeroData.starter_record(hero_id)).duplicate(true)
	var stats := GameData.hero_stats(profile.level, profile.upgrades, profile.combat_bonuses())
	var base: Dictionary = HeroData.HEROES[hero_id].base
	var selected: Dictionary = HeroData.HEROES[profile.selected_hero_id].base
	var star_scale := 1.0 + (int(record.get("stars", 1)) - 1) * 0.04
	var evolution_scale := 1.0 + int(record.get("evolution", 0)) * 0.08
	for stat in ["hp", "atk", "armor"]: stats[stat] = float(stats[stat]) / float(selected[stat]) * float(base[stat]) * star_scale * evolution_scale
	stats["speed"] = float(stats["speed"]) / float(selected.speed) * float(base.speed)
	var mock_power := GameData.hero_power(stats)
	return {"hero_id": hero_id, "hero": stats, "evolution": int(record.get("evolution", 0)), "skills": profile.equipped_skill_slots.duplicate(), "companions": profile.equipped_companion_slots.duplicate(), "artifacts": profile.equipped_artifact_slots.duplicate(), "equipment": profile.equipped.duplicate(true), "frame": profile.equipped_cosmetics.get("Profile Frame", ""), "power": mock_power}

static func rank_for_rating(rating: int) -> String:
	if rating >= 2400: return "Master"
	if rating >= 2000: return "Diamond"
	if rating >= 1600: return "Platinum"
	if rating >= 1300: return "Gold"
	if rating >= 1100: return "Silver"
	return "Bronze"
