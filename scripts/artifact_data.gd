class_name ArtifactData
extends RefCounted

const ARTIFACTS := {
	"blood_crown": {"name": "Blood Crown", "icon": "♛", "owned_stat": "crit_damage", "owned_value": 0.04, "effect": "crit_heal", "effect_value": 0.04, "effect_text": "Critical hits restore HP."},
	"hourglass_arkon": {"name": "Hourglass of Arkon", "icon": "⌛", "owned_stat": "speed", "owned_value": 0.02, "effect": "cooldown_rate", "effect_value": 0.12, "effect_text": "Active skills recover faster."},
	"dragon_heart": {"name": "Dragon Heart", "icon": "♥", "owned_stat": "hp", "owned_value": 20.0, "effect": "attack_burst", "effect_value": 1.0, "effect_text": "Every 20 hero attacks burns all enemies.", "set": "dragon_relics"},
	"dragon_fang": {"name": "Dragon Fang", "icon": "◆", "owned_stat": "atk", "owned_value": 3.0, "effect": "crit_damage", "effect_value": 0.12, "effect_text": "Critical strikes hit harder.", "set": "dragon_relics"},
	"dragon_eye": {"name": "Dragon Eye", "icon": "◉", "owned_stat": "crit_chance", "owned_value": 0.01, "effect": "crit_extra", "effect_value": 0.15, "effect_text": "Critical hits may strike again.", "set": "dragon_relics"},
	"guardian_sigil": {"name": "Guardian Sigil", "icon": "▣", "owned_stat": "armor", "owned_value": 1.0, "effect": "periodic_guard", "effect_value": 8.0, "effect_text": "Periodically gain Armor."},
	"phoenix_feather": {"name": "Phoenix Feather", "icon": "✦", "owned_stat": "healing_bonus", "owned_value": 0.04, "effect": "revive", "effect_value": 0.25, "effect_text": "Once per battle, survive a fatal hit."}
}
const SETS := {
	"dragon_relics": {"name": "DRAGON RELICS", "pieces": ["dragon_fang", "dragon_eye", "dragon_heart"], "bonuses": {2: {"crit_damage": 0.10}, 3: {"fire_burst_bonus": 0.50}}}
}
const MAX_ACTIVE_SLOTS := 2
const FUTURE_SLOTS := 6

static func level_cost(level: int) -> Dictionary:
	return {"gold": 30 * level, "dust": 4 * level, "copies": 2 ** level}

static func scale(level: int) -> float:
	return 1.0 + (level - 1) * 0.25

static func owned_value(id: String, record: Dictionary) -> float:
	return float(ARTIFACTS[id]["owned_value"]) * scale(int(record.get("level", 1)))

static func owned_text(id: String, record: Dictionary) -> String:
	var stat := str(ARTIFACTS[id]["owned_stat"])
	var label := stat.replace("_", " ").capitalize()
	var value := owned_value(id, record)
	if stat in ["crit_damage", "crit_chance", "healing_bonus"]:
		return "+%.1f%% %s" % [value * 100.0, label]
	if stat == "speed":
		return "+%.2f attacks/s" % value
	return "+%.1f %s" % [value, label]

static func effect_value(id: String, record: Dictionary) -> float:
	return float(ARTIFACTS[id]["effect_value"]) * scale(int(record.get("level", 1)))

static func set_count(id: String, equipped: Array[String]) -> int:
	var count := 0
	for piece in SETS[id]["pieces"]:
		if equipped.has(piece):
			count += 1
	return count

static func owned_stats(artifacts: Dictionary) -> Dictionary:
	var stats := {}
	for id in artifacts:
		if not ARTIFACTS.has(id):
			continue
		var stat := str(ARTIFACTS[id]["owned_stat"])
		stats[stat] = float(stats.get(stat, 0.0)) + owned_value(id, artifacts[id])
	return stats

static func equipped_stats(artifacts: Dictionary, equipped: Array[String]) -> Dictionary:
	var stats := {}
	for id in equipped:
		if id == "" or not artifacts.has(id):
			continue
		var effect := str(ARTIFACTS[id]["effect"])
		if effect == "crit_damage":
			stats["crit_damage"] = float(stats.get("crit_damage", 0.0)) + effect_value(id, artifacts[id])
	for set_id in SETS:
		var count := set_count(set_id, equipped)
		for threshold in SETS[set_id]["bonuses"]:
			if count >= int(threshold):
				var bonus: Dictionary = SETS[set_id]["bonuses"][threshold]
				for stat in bonus:
					stats[stat] = float(stats.get(stat, 0.0)) + float(bonus[stat])
	return stats
