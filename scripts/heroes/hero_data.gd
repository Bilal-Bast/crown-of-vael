class_name HeroData
extends RefCounted

const ELEMENTS := ["Physical", "Holy", "Fire", "Ice", "Lightning", "Dark", "Poison"]
const MAX_STARS := 5
const STAR_COSTS := [20, 40, 80, 160]
const CONVERSION_RATE := 5
const HEROES := {
	"knight": {"name": "Knight", "archetype": "Knight", "rarity": 2, "unlock": 0, "role": "Balanced melee defender", "style": "melee", "appearance": "sword_shield", "base": {"hp": 1.0, "atk": 1.0, "armor": 1.0, "speed": 1.0}, "active": {"hp": 0.06, "armor": 3.0}, "owned": {"armor": 0.5}, "element": "Physical", "path": ["Squire", "Knight", "Royal Knight", "Paladin", "Divine Paladin"]},
	"mage": {"name": "Mage", "archetype": "Mage", "rarity": 3, "unlock": 50, "role": "Slow ranged caster and AoE specialist", "style": "magic", "appearance": "robes_staff", "base": {"hp": 0.85, "atk": 0.92, "armor": 0.65, "speed": 0.85}, "active": {"skill_damage": 0.30}, "owned": {"skill_damage": 0.04}, "element": "Fire", "path": ["Apprentice Mage", "Mage", "Archmage", "High Sorcerer", "Arcane Sovereign"]},
	"ranger": {"name": "Ranger", "archetype": "Ranger", "rarity": 3, "unlock": 50, "role": "Fast ranged sustained attacker", "style": "arrow", "appearance": "hood_bow", "base": {"hp": 0.90, "atk": 0.80, "armor": 0.80, "speed": 1.25}, "active": {"speed": 0.22}, "owned": {"speed": 0.03}, "element": "Physical", "path": ["Hunter", "Ranger", "Sharpshooter", "Royal Ranger", "Wind Warden"]},
	"assassin": {"name": "Assassin", "archetype": "Assassin", "rarity": 4, "unlock": 75, "role": "Fast melee critical burst", "style": "dash", "appearance": "twin_blades", "base": {"hp": 0.75, "atk": 1.05, "armor": 0.55, "speed": 1.15}, "active": {"crit_chance": 0.12, "crit_damage": 0.25}, "owned": {"crit_damage": 0.05}, "element": "Poison", "path": ["Cutpurse", "Assassin", "Shadowblade", "Night Reaper", "Phantom Lord"]},
	"necromancer": {"name": "Necromancer", "archetype": "Necromancer", "rarity": 4, "unlock": 100, "role": "Ranged dark mage with companion synergy", "style": "dark_bolt", "appearance": "dark_robes_staff", "base": {"hp": 0.88, "atk": 0.82, "armor": 0.70, "speed": 0.90}, "active": {"companion_damage": 0.35}, "owned": {"companion_damage": 0.05}, "element": "Dark", "path": ["Acolyte", "Necromancer", "Death Caller", "Lich", "Dread Lich"]}
}
const KNIGHT_EVOLUTION := [
	{"level": 20, "crests": 10, "gold": 5000},
	{"level": 40, "crests": 25, "gold": 25000},
	{"level": 70, "crests": 60, "gold": 100000},
	{"level": 100, "crests": 150, "gold": 500000}
]
const EVOLUTION_COSTS := {"knight": KNIGHT_EVOLUTION}
const MILESTONES := {
	"heroes_2": {"name": "Unlock 2 Heroes", "gems": 3, "crests": 1, "pieces": 5},
	"heroes_5": {"name": "Unlock All 5 Heroes", "gems": 8, "crests": 3, "pieces": 15},
	"hero_star_3": {"name": "Reach 3 Stars", "gems": 3, "crests": 2, "pieces": 5},
	"evolve_knight_1": {"name": "Evolve to Knight", "gems": 3, "crests": 1, "pieces": 5},
	"evolve_knight_2": {"name": "Evolve to Royal Knight", "gems": 5, "crests": 2, "pieces": 5},
	"evolve_knight_3": {"name": "Evolve to Paladin", "gems": 6, "crests": 3, "pieces": 10},
	"evolve_knight_4": {"name": "Evolve to Divine Paladin", "gems": 10, "crests": 5, "pieces": 15}
}

static func starter_record(id: String) -> Dictionary:
	return {"unlocked": id == "knight", "pieces": 0, "stars": 1, "evolution": 0}

static func title(id: String, record: Dictionary) -> String:
	return str(HEROES[id]["path"][clampi(int(record.get("evolution", 0)), 0, 4)])

static func element(id: String, record: Dictionary) -> String:
	if id == "knight" and int(record.get("evolution", 0)) >= 3:
		return "Holy"
	return str(HEROES[id]["element"])

static func star_cost(stars: int) -> int:
	return STAR_COSTS[clampi(stars - 1, 0, STAR_COSTS.size() - 1)]

static func evolution_cost(id: String, stage: int) -> Dictionary:
	var costs: Array = EVOLUTION_COSTS.get(id, [])
	return costs[stage] if stage >= 0 and stage < costs.size() else {}

static func passive_scale(record: Dictionary) -> float:
	return 1.0 + (int(record.get("stars", 1)) - 1) * 0.22 + int(record.get("evolution", 0)) * 0.15

static func passive_text(id: String, record: Dictionary, active: bool) -> String:
	var values: Dictionary = HEROES[id]["active" if active else "owned"]
	var parts: Array[String] = []
	for stat in values:
		var value := float(values[stat]) * passive_scale(record)
		var label: String = str({"hp": "HP", "skill_damage": "Skill Damage", "crit_chance": "Crit Chance", "companion_damage": "Companion Damage"}.get(stat, str(stat).replace("_", " ").capitalize()))
		if stat in ["hp", "skill_damage", "crit_chance", "companion_damage"]:
			parts.append("+%.0f%% %s" % [value * 100.0, label])
		elif stat == "crit_damage":
			parts.append("+%.0f%% Crit Damage" % [value * 100.0])
		elif stat == "speed":
			parts.append("+%.2f Attack Speed" % value)
		else:
			parts.append("+%.1f %s" % [value, str(stat).capitalize()])
	return "  •  ".join(parts)

static func apply_stats(stats: Dictionary, profile: SaveData) -> Dictionary:
	var result := stats.duplicate(true)
	var id := profile.selected_hero_id
	var record: Dictionary = profile.heroes[id]
	var data: Dictionary = HEROES[id]
	var base: Dictionary = data["base"]
	var star_scale := 1.0 + (int(record["stars"]) - 1) * 0.04
	var evolution_scale := 1.0 + int(record["evolution"]) * 0.08
	for stat in ["hp", "atk", "armor"]:
		result[stat] = float(result[stat]) * float(base[stat]) * star_scale * evolution_scale
	result["speed"] = float(result["speed"]) * float(base["speed"])
	result["companion_damage"] = float(result.get("companion_damage", 0.0))
	for owned_id in HEROES:
		var owned_record: Dictionary = profile.heroes[owned_id]
		if not bool(owned_record.get("unlocked", false)):
			continue
		var owned: Dictionary = HEROES[owned_id]["owned"]
		for stat in owned:
			result[stat] = float(result.get(stat, 0.0)) + float(owned[stat]) * passive_scale(owned_record)
	var active: Dictionary = data["active"]
	for stat in active:
		var bonus := float(active[stat]) * passive_scale(record)
		if stat == "hp":
			result["hp"] = float(result["hp"]) * (1.0 + bonus)
		else:
			result[stat] = float(result.get(stat, 0.0)) + bonus
	return result
