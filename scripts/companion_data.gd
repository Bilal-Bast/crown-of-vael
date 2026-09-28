class_name CompanionData
extends RefCounted

const COMPANIONS := {
	"wolf": {"name": "Wolf", "visual": "beast", "icon": "◆", "atk": 10.0, "speed": 1.25, "passive": "atk", "passive_value": 2.0},
	"dire_wolf": {"name": "Dire Wolf", "visual": "beast", "icon": "◇", "atk": 16.0, "speed": 1.15, "passive": "atk", "passive_value": 3.0},
	"fairy": {"name": "Fairy", "visual": "fairy", "icon": "✦", "atk": 7.0, "speed": 1.50, "passive": "skill_damage", "passive_value": 0.04},
	"young_dragon": {"name": "Young Dragon", "visual": "dragon", "icon": "▲", "atk": 20.0, "speed": 0.85, "passive": "crit_damage", "passive_value": 0.06},
	"griffin": {"name": "Griffin", "visual": "beast", "icon": "✶", "atk": 18.0, "speed": 1.00, "passive": "speed", "passive_value": 0.04},
	"archer_companion": {"name": "Archer Companion", "visual": "humanoid", "icon": "➤", "atk": 12.0, "speed": 1.35, "passive": "boss_damage", "passive_value": 0.05},
	"cleric_companion": {"name": "Cleric Companion", "visual": "humanoid", "icon": "✚", "atk": 8.0, "speed": 1.10, "passive": "healing_bonus", "passive_value": 0.06},
	"apprentice_mage": {"name": "Apprentice Mage", "visual": "humanoid", "icon": "✧", "atk": 13.0, "speed": 1.05, "passive": "skill_damage", "passive_value": 0.05}
}
const STAR_PIECES := [0, 5, 10, 20, 40]
const MAX_STARS := 5
const WOLF_FORMS := ["Wolf", "Dire Wolf", "Shadow Wolf", "Fenrir"]
const WOLF_EVOLUTION := [
	{"level": 5, "stars": 2, "essence": 30, "crests": 1},
	{"level": 10, "stars": 3, "essence": 75, "crests": 2},
	{"level": 20, "stars": 4, "essence": 150, "crests": 3}
]

static func level_cost(level: int) -> Dictionary:
	return {"gold": 15 * level, "essence": 3 * level}

static func star_cost(stars: int) -> int:
	return STAR_PIECES[clampi(stars, 1, MAX_STARS - 1)]

static func display_name(id: String, record: Dictionary) -> String:
	if id == "wolf":
		return WOLF_FORMS[clampi(int(record.get("evolution", 0)), 0, WOLF_FORMS.size() - 1)]
	return str(COMPANIONS[id]["name"])

static func attack(id: String, record: Dictionary) -> float:
	var data: Dictionary = COMPANIONS[id]
	var rarity := int(record.get("rarity", 0))
	var level := int(record.get("level", 1))
	var stars := int(record.get("stars", 1))
	var evolution := int(record.get("evolution", 0))
	return float(data["atk"]) * (1.0 + rarity * 0.18) * (1.0 + (level - 1) * 0.12) * (1.0 + (stars - 1) * 0.20) * (1.0 + evolution * 0.35)

static func attack_speed(id: String, record: Dictionary) -> float:
	return float(COMPANIONS[id]["speed"]) * (1.0 + (int(record.get("stars", 1)) - 1) * 0.04)

static func passive_value(id: String, record: Dictionary) -> float:
	return float(COMPANIONS[id]["passive_value"]) * (1.0 + (int(record.get("stars", 1)) - 1) * 0.25) * (1.0 + int(record.get("evolution", 0)) * 0.35)

static func passive_text(id: String, record: Dictionary) -> String:
	var stat := str(COMPANIONS[id]["passive"])
	var value := passive_value(id, record)
	if stat in ["skill_damage", "crit_damage", "boss_damage", "healing_bonus"]:
		return "+%.0f%% %s" % [value * 100.0, stat.replace("_", " ")]
	if stat == "speed":
		return "+%.2f attacks/s" % value
	return "+%.1f %s" % [value, stat.to_upper()]
