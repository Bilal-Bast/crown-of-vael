class_name EquipmentData
extends RefCounted

const SLOTS := ["Weapon", "Helmet", "Armor", "Gloves", "Boots", "Necklace", "Ring"]
const STARTER_KINDS := ["rusted_sword", "worn_helmet", "leather_tunic", "old_gloves", "traveler_boots", "copper_necklace", "iron_ring"]
const RARITIES := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Ancient", "Divine"]
const COLORS := [Color("a6ada4"), Color("79c78b"), Color("78b9ec"), Color("bb86e8"), Color("efc36b"), Color("ed8d6e"), Color("74ded0"), Color("f7e9af")]
const ITEMS := {
	"iron_sword": {"name": "Iron Sword", "slot": "Weapon", "icon": "⚔", "stats": {"atk": 6.000}},
	"iron_helm": {"name": "Iron Helm", "slot": "Helmet", "icon": "♜", "stats": {"hp": 22.000, "armor": 1.200}},
	"iron_plate": {"name": "Iron Plate", "slot": "Armor", "icon": "⬡", "stats": {"hp": 36.000, "armor": 2.400}},
	"iron_gauntlets": {"name": "Iron Gauntlets", "slot": "Gloves", "icon": "✦", "stats": {"atk": 2.500, "crit_chance": 0.012}},
	"iron_boots": {"name": "Iron Boots", "slot": "Boots", "icon": "⌁", "stats": {"hp": 15.000, "speed": 0.045}},
	"iron_amulet": {"name": "Iron Amulet", "slot": "Necklace", "icon": "◇", "stats": {"crit_damage": 0.075}},
	"iron_band": {"name": "Iron Band", "slot": "Ring", "icon": "◈", "stats": {"atk": 2.500, "crit_chance": 0.012}},
	"steel_sword": {"name": "Steel Sword", "slot": "Weapon", "icon": "⚔", "stats": {"atk": 8.400}},
	"steel_helm": {"name": "Steel Helm", "slot": "Helmet", "icon": "♜", "stats": {"hp": 30.800, "armor": 1.680}},
	"steel_plate": {"name": "Steel Plate", "slot": "Armor", "icon": "⬡", "stats": {"hp": 50.400, "armor": 3.360}},
	"steel_gauntlets": {"name": "Steel Gauntlets", "slot": "Gloves", "icon": "✦", "stats": {"atk": 3.500, "crit_chance": 0.017}},
	"steel_boots": {"name": "Steel Boots", "slot": "Boots", "icon": "⌁", "stats": {"hp": 21.000, "speed": 0.063}},
	"steel_amulet": {"name": "Steel Amulet", "slot": "Necklace", "icon": "◇", "stats": {"crit_damage": 0.105}},
	"steel_ring": {"name": "Steel Ring", "slot": "Ring", "icon": "◈", "stats": {"atk": 3.500, "crit_chance": 0.017}},
	"knight_sword": {"name": "Knight Sword", "slot": "Weapon", "icon": "⚔", "stats": {"atk": 11.400}},
	"knight_helm": {"name": "Knight Helm", "slot": "Helmet", "icon": "♜", "stats": {"hp": 41.800, "armor": 2.280}},
	"knight_plate": {"name": "Knight Plate", "slot": "Armor", "icon": "⬡", "stats": {"hp": 68.400, "armor": 4.560}},
	"knight_gauntlets": {"name": "Knight Gauntlets", "slot": "Gloves", "icon": "✦", "stats": {"atk": 4.750, "crit_chance": 0.023}},
	"knight_boots": {"name": "Knight Boots", "slot": "Boots", "icon": "⌁", "stats": {"hp": 28.500, "speed": 0.085}},
	"knight_amulet": {"name": "Knight Amulet", "slot": "Necklace", "icon": "◇", "stats": {"crit_damage": 0.142}},
	"knight_ring": {"name": "Knight Ring", "slot": "Ring", "icon": "◈", "stats": {"atk": 4.750, "crit_chance": 0.023}},
	"royal_sword": {"name": "Royal Sword", "slot": "Weapon", "icon": "⚔", "stats": {"atk": 15.000}},
	"royal_helm": {"name": "Royal Helm", "slot": "Helmet", "icon": "♜", "stats": {"hp": 55.000, "armor": 3.000}},
	"royal_plate": {"name": "Royal Plate", "slot": "Armor", "icon": "⬡", "stats": {"hp": 90.000, "armor": 6.000}},
	"royal_gauntlets": {"name": "Royal Gauntlets", "slot": "Gloves", "icon": "✦", "stats": {"atk": 6.250, "crit_chance": 0.030}},
	"royal_boots": {"name": "Royal Boots", "slot": "Boots", "icon": "⌁", "stats": {"hp": 37.500, "speed": 0.112}},
	"royal_amulet": {"name": "Royal Amulet", "slot": "Necklace", "icon": "◇", "stats": {"crit_damage": 0.188}},
	"royal_ring": {"name": "Royal Ring", "slot": "Ring", "icon": "◈", "stats": {"atk": 6.250, "crit_chance": 0.030}},
	"sacred_sword": {"name": "Sacred Sword", "slot": "Weapon", "icon": "⚔", "stats": {"atk": 19.200}},
	"sacred_helm": {"name": "Sacred Helm", "slot": "Helmet", "icon": "♜", "stats": {"hp": 70.400, "armor": 3.840}},
	"sacred_plate": {"name": "Sacred Plate", "slot": "Armor", "icon": "⬡", "stats": {"hp": 115.200, "armor": 7.680}},
	"sacred_gauntlets": {"name": "Sacred Gauntlets", "slot": "Gloves", "icon": "✦", "stats": {"atk": 8.000, "crit_chance": 0.038}},
	"sacred_boots": {"name": "Sacred Boots", "slot": "Boots", "icon": "⌁", "stats": {"hp": 48.000, "speed": 0.144}},
	"sacred_amulet": {"name": "Sacred Amulet", "slot": "Necklace", "icon": "◇", "stats": {"crit_damage": 0.240}},
	"sacred_ring": {"name": "Sacred Ring", "slot": "Ring", "icon": "◈", "stats": {"atk": 8.000, "crit_chance": 0.038}},
	"rusted_sword": {"name": "Rusted Sword", "slot": "Weapon", "icon": "⚔", "stats": {"atk": 5.0}},
	"worn_helmet": {"name": "Worn Helmet", "slot": "Helmet", "icon": "♜", "stats": {"hp": 18.0, "armor": 1.0}},
	"leather_tunic": {"name": "Leather Tunic", "slot": "Armor", "icon": "⬡", "stats": {"hp": 30.0, "armor": 2.0}},
	"old_gloves": {"name": "Old Gloves", "slot": "Gloves", "icon": "✦", "stats": {"atk": 2.0, "crit_chance": 0.01}},
	"traveler_boots": {"name": "Traveler Boots", "slot": "Boots", "icon": "⌁", "stats": {"hp": 12.0, "speed": 0.04}},
	"copper_necklace": {"name": "Copper Necklace", "slot": "Necklace", "icon": "◇", "stats": {"crit_damage": 0.06}},
	"iron_ring": {"name": "Iron Ring", "slot": "Ring", "icon": "◈", "stats": {"atk": 2.0, "crit_chance": 0.01}}
}
const SUMMON_POOL := [
	["iron_sword","iron_helm","iron_plate","iron_gauntlets","iron_boots","iron_amulet","iron_band"],
	["steel_sword","steel_helm","steel_plate","steel_gauntlets","steel_boots","steel_amulet","steel_ring"],
	["knight_sword","knight_helm","knight_plate","knight_gauntlets","knight_boots","knight_amulet","knight_ring"],
	["royal_sword","royal_helm","royal_plate","royal_gauntlets","royal_boots","royal_amulet","royal_ring"],
	["sacred_sword","sacred_helm","sacred_plate","sacred_gauntlets","sacred_boots","sacred_amulet","sacred_ring"],
]
const STAT_NAMES := {"atk": "ATK", "hp": "HP", "armor": "Armor", "speed": "Attack Speed", "crit_chance": "Crit Chance", "crit_damage": "Crit Damage"}

static func create_item(kind: String, rarity: int = 0, id: String = "") -> Dictionary:
	if not ITEMS.has(kind):
		return {}
	return {"id": id if id != "" else _new_id(), "kind": kind, "rarity": clampi(rarity, 0, RARITIES.size() - 1), "level": 1}

static func summon_item(rarity: int) -> Dictionary:
	var family := randi_range(0, SUMMON_POOL.size() - 1)
	var pool: Array = SUMMON_POOL[family]
	return create_item(str(pool[randi_range(0, pool.size() - 1)]), rarity)

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
