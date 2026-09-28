class_name GameData
extends RefCounted

const REGION := "Greenvale Outskirts"
const MAX_STAGE := 10
const WAVES_PER_STAGE := 3
const ENEMIES_PER_WAVE := 5
const EVOLUTION_PATH := [
	{"name": "Squire", "level": 1, "crests": 0},
	{"name": "Knight", "level": 20, "crests": 1},
	{"name": "Royal Knight", "level": 40, "crests": 3},
	{"name": "Paladin", "level": 70, "crests": 6},
	{"name": "Divine Paladin", "level": 100, "crests": 10}
]

const ENEMIES := {
	"Goblin": {"hp": 28.0, "atk": 3.0, "speed": 1.15, "gold": 4, "exp": 3, "color": Color("83b761")},
	"Skeleton": {"hp": 34.0, "atk": 4.0, "speed": 1.0, "gold": 5, "exp": 4, "color": Color("d7d5bf")},
	"Corrupted Wolf": {"hp": 40.0, "atk": 5.0, "speed": 1.35, "gold": 6, "exp": 5, "color": Color("9c73aa")},
	"Goblin Archer": {"hp": 26.0, "atk": 6.0, "speed": 0.85, "gold": 7, "exp": 5, "color": Color("a7bf5c")},
	"Goblin Warlord": {"hp": 1250.0, "atk": 24.0, "speed": 0.85, "gold": 100, "exp": 110, "color": Color("d09548")}
}

static func stage_label(stage: int) -> String:
	return "Easy 1-%d" % stage

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

static func enemy_stats(kind: String, stage: int) -> Dictionary:
	var base: Dictionary = ENEMIES[kind]
	var scale := 1.0 + (stage - 1) * 0.27
	if kind == "Goblin Warlord":
		scale = 1.0
	return {
		"kind": kind,
		"hp": float(base["hp"]) * scale,
		"atk": float(base["atk"]) * (1.0 + (stage - 1) * 0.19),
		"speed": float(base["speed"]),
		"gold": int(base["gold"]),
		"exp": int(base["exp"]),
		"color": base["color"]
	}

static func wave_kinds(stage: int, wave: int) -> Array[String]:
	var pool: Array[String] = ["Goblin"]
	if stage >= 2:
		pool.append("Skeleton")
	if stage >= 4:
		pool.append("Corrupted Wolf")
	if stage >= 6:
		pool.append("Goblin Archer")
	var result: Array[String] = []
	for i in ENEMIES_PER_WAVE:
		result.append(pool[(stage + wave + i) % pool.size()])
	return result
