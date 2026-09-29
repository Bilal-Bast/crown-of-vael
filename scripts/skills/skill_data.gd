class_name SkillData
extends RefCounted

const SKILLS := {
	"shield_bash": {"name": "Shield Bash", "icon": "◆", "rarity": 0, "cooldown": 8.0, "effect": "single", "power": 2.25, "stun": 1.25, "description": "Heavy strike and brief stun."},
	"power_strike": {"name": "Power Strike", "icon": "⚔", "rarity": 1, "cooldown": 7.0, "effect": "single", "power": 2.0, "description": "A focused heavy strike."},
	"whirlwind_slash": {"name": "Whirlwind Slash", "icon": "✦", "rarity": 2, "cooldown": 10.0, "effect": "area", "power": 1.2, "description": "Strike every living enemy."},
	"iron_guard": {"name": "Iron Guard", "icon": "▣", "rarity": 1, "cooldown": 12.0, "effect": "defense", "power": 8.0, "duration": 5.0, "description": "Gain temporary Armor."},
	"quick_slash": {"name": "Quick Slash", "icon": "⌁", "rarity": 0, "cooldown": 4.0, "effect": "single", "power": 0.9, "description": "A fast single strike."},
	"battle_cry": {"name": "Battle Cry", "icon": "✶", "rarity": 2, "cooldown": 15.0, "effect": "attack", "power": 0.25, "duration": 6.0, "description": "Gain temporary Attack."},
	"piercing_strike": {"name": "Piercing Strike", "icon": "➤", "rarity": 1, "cooldown": 9.0, "effect": "single", "power": 2.5, "description": "Pierce one enemy."},
	"healing_light": {"name": "Healing Light", "icon": "✚", "rarity": 2, "cooldown": 14.0, "effect": "heal", "power": 0.20, "description": "Restore a share of maximum HP."}
}

static func copies_to_level(level: int) -> int:
	return 2 ** level

# Empty means every hero may equip the skill. Future skills can set hero_tags.
static func hero_tags(id: String) -> Array:
	return SKILLS[id].get("hero_tags", [])

static func strength(id: String, level: int) -> float:
	return float(SKILLS[id]["power"]) * (1.0 + 0.25 * (level - 1))

static func effect_text(id: String, level: int) -> String:
	var data: Dictionary = SKILLS[id]
	var value := strength(id, level)
	match str(data["effect"]):
		"single", "area": return "%.2fx ATK" % value
		"defense": return "+%.1f Armor for %.0fs" % [value, data["duration"]]
		"attack": return "+%d%% ATK for %.0fs" % [roundi(value * 100.0), data["duration"]]
		"heal": return "Heal %d%% max HP" % roundi(value * 100.0)
	return ""
