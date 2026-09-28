class_name EquipmentData
extends RefCounted

const SLOTS := ["Weapon", "Helmet", "Armor", "Gloves", "Boots", "Necklace", "Ring"]
const RARITIES := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Ancient", "Divine"]
const COLORS := [Color("a6ada4"), Color("79c78b"), Color("78b9ec"), Color("bb86e8"), Color("efc36b"), Color("ed8d6e"), Color("74ded0"), Color("f7e9af")]
const ITEMS := {
	"rusted_sword": {"name": "Rusted Sword", "slot": "Weapon", "icon": "⚔", "stats": {"atk": 5.0}},
	"worn_helmet": {"name": "Worn Helmet", "slot": "Helmet", "icon": "♜", "stats": {"hp": 18.0, "armor": 1.0}},
	"leather_tunic": {"name": "Leather Tunic", "slot": "Armor", "icon": "⬡", "stats": {"hp": 30.0, "armor": 2.0}},
	"old_gloves": {"name": "Old Gloves", "slot": "Gloves", "icon": "✦", "stats": {"atk": 2.0, "crit_chance": 0.01}},
	"traveler_boots": {"name": "Traveler Boots", "slot": "Boots", "icon": "⌁", "stats": {"hp": 12.0, "speed": 0.04}},
	"copper_necklace": {"name": "Copper Necklace", "slot": "Necklace", "icon": "◇", "stats": {"crit_damage": 0.06}},
	"iron_ring": {"name": "Iron Ring", "slot": "Ring", "icon": "◈", "stats": {"atk": 2.0, "crit_chance": 0.01}}
}
const STAT_NAMES := {"atk": "ATK", "hp": "HP", "armor": "Armor", "speed": "Attack Speed", "crit_chance": "Crit Chance", "crit_damage": "Crit Damage"}

static func create_item(kind: String, rarity: int = 0, id: String = "") -> Dictionary:
	if not ITEMS.has(kind):
		return {}
	return {"id": id if id != "" else _new_id(), "kind": kind, "rarity": clampi(rarity, 0, RARITIES.size() - 1), "level": 1}

static func _new_id() -> String:
	return "%d_%d" % [Time.get_ticks_usec(), randi()]

static func item_stats(item: Dictionary) -> Dictionary:
	var result := {}
	var base: Dictionary = ITEMS.get(str(item.get("kind", "")), {}).get("stats", {})
	var scale := (1.0 + int(item.get("rarity", 0)) * 0.55) * (1.0 + (int(item.get("level", 1)) - 1) * 0.16)
	for stat in base:
		result[stat] = float(base[stat]) * scale
	return result

static func title(item: Dictionary) -> String:
	var data: Dictionary = ITEMS.get(str(item.get("kind", "")), {})
	return "%s %s" % [RARITIES[clampi(int(item.get("rarity", 0)), 0, 7)], data.get("name", "Unknown")]

static func stat_lines(item: Dictionary) -> String:
	var lines := PackedStringArray()
	var bonuses := item_stats(item)
	for stat in bonuses:
		var value := float(bonuses[stat])
		var amount := str(roundi(value))
		if stat in ["crit_chance", "crit_damage"]:
			amount = "%.1f%%" % (value * 100.0)
		elif stat == "speed":
			amount = "%.2f/s" % value
		lines.append("%s +%s" % [STAT_NAMES.get(stat, stat), amount])
	return "  •  ".join(lines)

static func upgrade_gold_cost(item: Dictionary) -> int:
	return 20 * int(item.get("level", 1)) * (int(item.get("rarity", 0)) + 1)

static func upgrade_stone_cost(item: Dictionary) -> int:
	return int(item.get("level", 1)) + int(item.get("rarity", 0))

static func roll_drop(stage: int, boss: bool) -> Dictionary:
	var chance := 0.75 if boss else 0.04 + stage * 0.003
	if randf() >= chance:
		return {}
	var rarity := 0
	var roll := randf()
	var uncommon := minf(0.12 + stage * 0.018 + (0.23 if boss else 0.0), 0.68)
	var rare := minf(0.015 + stage * 0.005 + (0.13 if boss else 0.0), 0.22)
	if roll < rare:
		rarity = 2
	elif roll < rare + uncommon:
		rarity = 1
	var keys := ITEMS.keys()
	return create_item(str(keys[randi_range(0, keys.size() - 1)]), rarity)
