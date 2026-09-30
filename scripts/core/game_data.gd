class_name GameData
extends RefCounted

const MAX_STAGE := 20
const WAVES_PER_STAGE := 3
const ENEMIES_PER_WAVE := 7
const ENEMY_ENTRY_INTERVAL := 0.9
const EVOLUTION_PATH := [
	{"name": "Squire", "level": 1, "crests": 0},
	{"name": "Knight", "level": 20, "crests": 1},
	{"name": "Royal Knight", "level": 40, "crests": 3},
	{"name": "Paladin", "level": 70, "crests": 6},
	{"name": "Divine Paladin", "level": 100, "crests": 10}
]

static func exp_to_next(level: int) -> int:
	return 30 + (level - 1) * 20

static func upgrade_cost(rank: int) -> int:
	return 25 + rank * 20

static func hero_stats(level: int, upgrades: Dictionary, gear: Dictionary = {}) -> Dictionary:
	var stats := {
		"hp": 300.0 + (level - 1) * 35.0 + int(upgrades.get("hp", 0)) * 60.0,
		"atk": 48.0 + (level - 1) * 5.0 + int(upgrades.get("atk", 0)) * 8.0,
		"armor": 8.0 + (level - 1) * 1.0 + int(upgrades.get("armor", 0)) * 2.0,
		"speed": 1.4,
		"crit_chance": 0.15,
		"crit_damage": 1.75,
		"skill_damage": 0.0,
		"companion_damage": 0.0,
		"boss_damage": 0.0,
		"healing_bonus": 0.0,
		"fire_burst_bonus": 0.0
	}
	for stat in gear:
		if stats.has(stat):
			stats[stat] = float(stats[stat]) + float(gear[stat])
	return stats

static func hero_power(stats: Dictionary) -> int:
	return roundi(float(stats["hp"]) * 0.12 + float(stats["atk"]) * 4.0 + float(stats["armor"]) * 6.0 + float(stats["speed"]) * 24.0 + float(stats["crit_chance"]) * 100.0 + float(stats["crit_damage"]) * 15.0 + float(stats.get("skill_damage", 0.0)) * 90.0 + float(stats.get("companion_damage", 0.0)) * 65.0 + float(stats.get("boss_damage", 0.0)) * 60.0 + float(stats.get("healing_bonus", 0.0)) * 45.0 + float(stats.get("fire_burst_bonus", 0.0)) * 50.0)
