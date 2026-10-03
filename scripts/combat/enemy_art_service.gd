class_name EnemyArtService
extends RefCounted

## Optional enemy and regional art lookup. Null textures leave callers free to
## use their existing procedural visuals. Region folders can be added without
## changing battle rendering.
const ENEMY_REGION_FOLDERS := {1: "greenvale", 2: "whispering_forest", 3: "ashen_highlands", 4: "frostfang_mountains", 5: "sunken_marshes", 6: "crimson_desert", 7: "ruined_kingdom", 8: "shadowlands", 9: "dragon_peaks", 10: "demon_realm"}
const BACKGROUND_REGION_FOLDERS := {1: "greenvale_outskirts", 2: "whispering_forest", 3: "ashen_highlands", 4: "frostfang_mountains", 5: "sunken_marshes", 6: "crimson_desert", 7: "ruined_kingdom", 8: "shadowlands", 9: "dragon_peaks", 10: "demon_realm"}
const GREENVALE_ENEMIES := {
	"Goblin": "goblin",
	"Skeleton": "skeleton",
	"Corrupted Wolf": "corrupted_wolf",
	"Goblin Archer": "goblin_archer",
	"Goblin Spearman": "goblin_spearman",
	"Bandit": "bandit",
	"Goblin Captain": "goblin_captain",
	"Armored Skeleton": "armored_skeleton",
	"Goblin Warlord": "goblin_warlord",
}
const REGION_ENEMIES := {
	1: GREENVALE_ENEMIES,
	2: {"Forest Goblin": "forest_goblin", "Giant Spider": "giant_spider", "Corrupted Boar": "corrupted_boar", "Forest Bandit": "forest_bandit", "Skeleton Archer": "skeleton_archer", "Poison Wolf": "poison_wolf", "Spider Matriarch": "spider_matriarch", "Forest Brute": "forest_brute", "Ancient Treant": "ancient_treant"},
	3: {"Ash Goblin": "ash_goblin", "Fire Imp": "fire_imp", "Charred Skeleton": "charred_skeleton", "Raider": "raider", "Magma Hound": "magma_hound", "Fire Archer": "fire_archer", "Flame Brute": "flame_brute", "Ash Knight": "ash_knight", "Infernal Ogre": "infernal_ogre"},
	4: {"Frost Wolf": "frost_wolf", "Ice Goblin": "ice_goblin", "Frozen Skeleton": "frozen_skeleton", "Snow Bandit": "snow_bandit", "Ice Archer": "ice_archer", "Frost Spirit": "frost_spirit", "Ice Troll": "ice_troll", "Frost Knight": "frost_knight", "Frostfang Giant": "frostfang_giant"},
	5: {"Swamp Goblin": "swamp_goblin", "Plague Rat": "plague_rat", "Bog Skeleton": "bog_skeleton", "Poison Slime": "poison_slime", "Swamp Beast": "swamp_beast", "Cultist": "cultist", "Bog Horror": "bog_horror", "Plague Knight": "plague_knight", "Marsh Hydra": "marsh_hydra"},
	6: {"Desert Raider": "desert_raider", "Sand Scorpion": "sand_scorpion", "Desert Skeleton": "desert_skeleton", "Fire Cultist": "fire_cultist", "Sand Wolf": "sand_wolf", "Tomb Archer": "tomb_archer", "Sand Golem": "sand_golem", "Crimson Champion": "crimson_champion", "Ancient Sand Wyrm": "ancient_sand_wyrm"},
	7: {"Fallen Knight": "fallen_knight", "Corrupted Soldier": "corrupted_soldier", "Undead Guard": "undead_guard", "Dark Archer": "dark_archer", "Armored Ghoul": "armored_ghoul", "War Beast": "war_beast", "Royal Executioner": "royal_executioner", "Fallen Champion": "fallen_champion", "Corrupted King": "corrupted_king"},
	8: {"Shadow Hound": "shadow_hound", "Shade": "shade", "Dark Mage": "dark_mage", "Phantom Archer": "phantom_archer", "Shadow Knight": "shadow_knight", "Void Spawn": "void_spawn", "Void Reaper": "void_reaper", "Shadow Champion": "shadow_champion", "Lord of Shadows": "lord_of_shadows"},
	9: {"Drake": "drake", "Dragon Cultist": "dragon_cultist", "Flame Drake": "flame_drake", "Storm Drake": "storm_drake", "Dragon Knight": "dragon_knight", "Wyvern": "wyvern", "Elder Wyvern": "elder_wyvern", "Dragon Champion": "dragon_champion", "Ancient Dragon": "ancient_dragon"},
	10: {"Lesser Demon": "lesser_demon", "Demon Archer": "demon_archer", "Hellhound": "hellhound", "Demon Knight": "demon_knight", "Infernal Mage": "infernal_mage", "Corrupted Giant": "corrupted_giant", "Demon Champion": "demon_champion", "Infernal Reaper": "infernal_reaper", "Demon Lord": "demon_lord"},
}
const REQUIRED_STATES := ["idle", "attack", "hit"]
const SLOT_FILES := {"idle": "idle.png", "attack": "attack.png", "hit": "hit.png", "portrait": "portrait.png", "death": "death.png"}
const BASE := "res://assets"
const ENEMY_META := {
	"Goblin": {"scale": 0.82, "offset": Vector2.ZERO, "attack_duration": 0.26, "hit_duration": 0.22, "ranged_offset": Vector2(40, -86)},
	"Skeleton": {"scale": 0.84, "offset": Vector2.ZERO, "attack_duration": 0.27, "hit_duration": 0.23, "ranged_offset": Vector2(40, -86)},
	"Corrupted Wolf": {"scale": 0.80, "offset": Vector2(0, 12), "attack_duration": 0.23, "hit_duration": 0.20, "ranged_offset": Vector2(46, -55)},
	"Goblin Archer": {"scale": 0.78, "offset": Vector2.ZERO, "attack_duration": 0.30, "hit_duration": 0.22, "ranged_offset": Vector2(28, -105)},
	"Goblin Spearman": {"scale": 0.78, "offset": Vector2.ZERO, "attack_duration": 0.28, "hit_duration": 0.22, "ranged_offset": Vector2(52, -86)},
	"Bandit": {"scale": 0.82, "offset": Vector2.ZERO, "attack_duration": 0.27, "hit_duration": 0.22, "ranged_offset": Vector2(38, -90)},
	"Goblin Captain": {"scale": 0.88, "offset": Vector2.ZERO, "attack_duration": 0.30, "hit_duration": 0.25, "ranged_offset": Vector2(40, -94)},
	"Armored Skeleton": {"scale": 0.88, "offset": Vector2.ZERO, "attack_duration": 0.30, "hit_duration": 0.25, "ranged_offset": Vector2(42, -94)},
	"Goblin Warlord": {"scale": 0.92, "offset": Vector2(0, -3), "attack_duration": 0.34, "hit_duration": 0.28, "ranged_offset": Vector2(54, -125)},
}
const BODY_META := {
	"Fire Imp": {"scale": 0.72, "offset": Vector2(0, -12)}, "Flame Brute": {"scale": 1.02, "offset": Vector2(0, -10)}, "Ash Knight": {"scale": 0.98, "offset": Vector2(0, -8)},
	"Giant Spider": {"scale": 0.62, "offset": Vector2(0, 34)}, "Corrupted Boar": {"scale": 0.66, "offset": Vector2(0, 30)},
	"Magma Hound": {"scale": 0.66, "offset": Vector2(0, 28)}, "Frost Wolf": {"scale": 0.66, "offset": Vector2(0, 28)}, "Sand Wolf": {"scale": 0.66, "offset": Vector2(0, 28)}, "Shadow Hound": {"scale": 0.66, "offset": Vector2(0, 28)}, "Hellhound": {"scale": 0.68, "offset": Vector2(0, 28)}, "Poison Wolf": {"scale": 0.66, "offset": Vector2(0, 28)},
	"Plague Rat": {"scale": 0.59, "offset": Vector2(0, 36)}, "Poison Slime": {"scale": 0.55, "offset": Vector2(0, 42)}, "Sand Scorpion": {"scale": 0.64, "offset": Vector2(0, 35)},
	"Drake": {"scale": 0.72, "offset": Vector2(0, 22)}, "Flame Drake": {"scale": 0.72, "offset": Vector2(0, 22)}, "Storm Drake": {"scale": 0.72, "offset": Vector2(0, 22)}, "Wyvern": {"scale": 0.73, "offset": Vector2(0, 22)},
	"Frost Spirit": {"scale": 0.72, "offset": Vector2(0, -8)}, "Shade": {"scale": 0.72, "offset": Vector2(0, -8)}, "Void Spawn": {"scale": 0.74, "offset": Vector2(0, -6)},
	"Spider Matriarch": {"scale": 0.68, "offset": Vector2(0, 35)}, "Elder Wyvern": {"scale": 0.76, "offset": Vector2(0, 22)},
	"Ancient Treant": {"scale": 1.08, "offset": Vector2(0, -13)}, "Infernal Ogre": {"scale": 1.04, "offset": Vector2(0, -7)}, "Frostfang Giant": {"scale": 1.08, "offset": Vector2(0, -12)}, "Marsh Hydra": {"scale": 0.94, "offset": Vector2(0, 16)}, "Ancient Sand Wyrm": {"scale": 0.98, "offset": Vector2(0, 15)}, "Corrupted King": {"scale": 1.0, "offset": Vector2(0, -7)}, "Lord of Shadows": {"scale": 1.04, "offset": Vector2(0, -12)}, "Ancient Dragon": {"scale": 1.03, "offset": Vector2(0, 10)}, "Demon Lord": {"scale": 1.08, "offset": Vector2(0, -12)},
	"Armored Ghoul": {"scale": 0.76, "offset": Vector2(0, 18)}, "War Beast": {"scale": 0.74, "offset": Vector2(0, 24)}, "Royal Executioner": {"scale": 1.04, "offset": Vector2(0, -8)}, "Fallen Champion": {"scale": 0.98, "offset": Vector2(0, -5)},
}
# Source sprites in this set look right; campaign enemies stand to the hero's right.
# Frontal and already left-facing art deliberately remain unflipped.
const FLIP_H_ENEMIES := [
	"Corrupted Boar", "Poison Wolf", "Magma Hound", "Fire Archer",
	"Frost Wolf", "Swamp Beast", "Plague Rat", "Sand Scorpion",
	"Sand Wolf", "Tomb Archer", "Ancient Sand Wyrm",
	"Shadow Hound", "Drake", "Elder Wyvern", "Storm Drake", "Wyvern",
	"Hellhound", "Demon Archer", "Lesser Demon",
]
static var _resolved_paths: Dictionary = {}
static var _texture_cache: Dictionary = {}
static var _load_counts: Dictionary = {}

static func enemy_folder(enemy_id: String, region: int = 1) -> String:
	if not ENEMY_REGION_FOLDERS.has(region):
		return ""
	return str((REGION_ENEMIES[region] as Dictionary).get(enemy_id, ""))

static func enemy_path(enemy_id: String, state: String = "idle", region: int = 1) -> String:
	var folder := enemy_folder(enemy_id, region)
	if folder.is_empty() or not SLOT_FILES.has(state):
		return ""
	return "%s/enemies/%s/%s/%s" % [BASE, ENEMY_REGION_FOLDERS[region], folder, SLOT_FILES[state]]

static func resolve_enemy_path(enemy_id: String, state: String = "idle", region: int = 1) -> String:
	var key := "enemy:%d:%s:%s" % [region, enemy_id, state]
	if _resolved_paths.has(key):
		return str(_resolved_paths[key])
	var path := enemy_path(enemy_id, state, region)
	var result := path if not path.is_empty() and ResourceLoader.exists(path, "Texture2D") else ""
	_resolved_paths[key] = result
	return result

static func texture_for(enemy_id: String, state: String = "idle", region: int = 1) -> Texture2D:
	var path := resolve_enemy_path(enemy_id, state, region)
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	_load_counts[path] = int(_load_counts.get(path, 0)) + 1
	var texture := ResourceLoader.load(path, "Texture2D") as Texture2D
	_texture_cache[path] = texture
	return texture

static func presentation_texture_for(enemy_id: String, state: String = "idle", region: int = 1) -> Texture2D:
	var texture := texture_for(enemy_id, state, region)
	if texture == null and state in ["attack", "hit"]:
		return texture_for(enemy_id, "idle", region)
	return texture

static func metadata(enemy_id: String) -> Dictionary:
	if ENEMY_META.has(enemy_id):
		var greenvale_meta: Dictionary = ENEMY_META[enemy_id].duplicate()
		greenvale_meta["flip_h"] = enemy_id in FLIP_H_ENEMIES
		return greenvale_meta
	var result := {"scale": 0.82, "offset": Vector2.ZERO, "attack_duration": 0.26, "hit_duration": 0.22, "ranged_offset": Vector2(40, -86), "flip_h": enemy_id in FLIP_H_ENEMIES}
	if BODY_META.has(enemy_id):
		result.merge(BODY_META[enemy_id], true)
	return result

static func background_path(region: int = 1, boss: bool = false) -> String:
	if not BACKGROUND_REGION_FOLDERS.has(region):
		return ""
	var folder := str(BACKGROUND_REGION_FOLDERS[region])
	if boss:
		var boss_path := "%s/backgrounds/regions/%s/boss_bg.png" % [BASE, folder]
		if _path_exists_cached("background:%d:boss" % region, boss_path):
			return boss_path
	var regular_path := "%s/backgrounds/regions/%s/battle_bg.png" % [BASE, folder]
	return regular_path if _path_exists_cached("background:%d:regular" % region, regular_path) else ""

static func _path_exists_cached(key: String, path: String) -> bool:
	if _resolved_paths.has(key):
		return not str(_resolved_paths[key]).is_empty()
	var result := path if ResourceLoader.exists(path, "Texture2D") else ""
	_resolved_paths[key] = result
	return not result.is_empty()

static func background_texture(region: int = 1, boss: bool = false) -> Texture2D:
	var path := background_path(region, boss)
	if path.is_empty() or not ResourceLoader.exists(path, "Texture2D"):
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	_load_counts[path] = int(_load_counts.get(path, 0)) + 1
	var texture := ResourceLoader.load(path, "Texture2D") as Texture2D
	_texture_cache[path] = texture
	return texture

static func validation_report(region: int = 1) -> Array[String]:
	var warnings: Array[String] = []
	if not BACKGROUND_REGION_FOLDERS.has(region):
		warnings.append("No art folder mapped for region %d" % region)
		return warnings
	for enemy_id in REGION_ENEMIES[region]:
		for state in REQUIRED_STATES:
			if resolve_enemy_path(enemy_id, state, region).is_empty():
				warnings.append("Missing %s art: %s" % [state, enemy_path(enemy_id, state, region)])
	var folder := str(BACKGROUND_REGION_FOLDERS[region])
	if not _path_exists_cached("background:%d:regular" % region, "%s/backgrounds/regions/%s/battle_bg.png" % [BASE, folder]):
		warnings.append("Missing regular background: %s" % background_path(region))
	if not _path_exists_cached("background:%d:boss" % region, "%s/backgrounds/regions/%s/boss_bg.png" % [BASE, folder]):
		warnings.append("Missing optional boss background; regular background fallback will be used")
	return warnings

static func cached_load_count(path: String) -> int:
	return int(_load_counts.get(path, 0))

static func clear_cache_for_tests() -> void:
	_resolved_paths.clear()
	_texture_cache.clear()
	_load_counts.clear()
