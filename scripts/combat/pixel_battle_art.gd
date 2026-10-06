class_name PixelBattleArt
extends RefCounted

## Shared pixel-art battle presentation for the converted campaign regions.
const PROTOTYPE_ENABLED := true
const HERO_SHEET := "res://assets/prototype_pixel/heroes/squire/sheet.png"
const HERO_RUN_SHEET := "res://assets/prototype_pixel/heroes/squire/run.png"
const BACKGROUND := "res://assets/prototype_pixel/backgrounds/greenvale/battle.png"
const FOREST_BACKGROUND := "res://assets/prototype_pixel/backgrounds/whispering_forest/battle.png"
const ASHEN_BACKGROUND := "res://assets/prototype_pixel/backgrounds/ashen_highlands/battle_polished.png"
const FROSTFANG_BACKGROUND := "res://assets/prototype_pixel/backgrounds/frostfang_mountains/battle.png"
const SUNKEN_MARSHES_BACKGROUND := "res://assets/prototype_pixel/backgrounds/sunken_marshes/battle.png"
const CRIMSON_DESERT_BACKGROUND := "res://assets/prototype_pixel/backgrounds/crimson_desert/battle.png"
const RUINED_KINGDOM_BACKGROUND := "res://assets/prototype_pixel/backgrounds/ruined_kingdom/battle.png"
const SHADOWLANDS_BACKGROUND := "res://assets/prototype_pixel/backgrounds/shadowlands/battle.png"
const DRAGON_PEAKS_BACKGROUND := "res://assets/prototype_pixel/backgrounds/dragon_peaks/battle.png"
const DEMON_REALM_BACKGROUND := "res://assets/prototype_pixel/backgrounds/demon_realm/battle.png"
const ENEMY_SHEETS := {
	"Goblin": "res://assets/prototype_pixel/enemies/greenvale/goblin/sheet.png",
	"Skeleton": "res://assets/prototype_pixel/enemies/greenvale/skeleton/sheet.png",
	"Corrupted Wolf": "res://assets/prototype_pixel/enemies/greenvale/corrupted_wolf/sheet.png",
	"Goblin Archer": "res://assets/prototype_pixel/enemies/greenvale/goblin_archer/idle.png",
	"Goblin Spearman": "res://assets/prototype_pixel/enemies/greenvale/goblin_spearman/idle.png",
	"Bandit": "res://assets/prototype_pixel/enemies/greenvale/bandit/idle.png",
	"Goblin Captain": "res://assets/prototype_pixel/enemies/greenvale/goblin_captain/idle.png",
	"Armored Skeleton": "res://assets/prototype_pixel/enemies/greenvale/armored_skeleton/idle.png",
	"Goblin Warlord": "res://assets/prototype_pixel/enemies/greenvale/goblin_warlord/idle.png",
}
const FOREST_SHEETS := {
 "Forest Goblin": "forest_goblin", "Giant Spider": "giant_spider", "Corrupted Boar": "corrupted_boar",
 "Forest Bandit": "forest_bandit", "Skeleton Archer": "skeleton_archer", "Poison Wolf": "poison_wolf",
 "Spider Matriarch": "spider_matriarch", "Forest Brute": "forest_brute", "Ancient Treant": "ancient_treant"
}
const ASHEN_SHEETS := {
 "Ash Goblin": "ash_goblin", "Fire Imp": "fire_imp", "Charred Skeleton": "charred_skeleton",
 "Raider": "raider", "Magma Hound": "magma_hound", "Fire Archer": "fire_archer",
 "Flame Brute": "flame_brute", "Ash Knight": "ash_knight", "Infernal Ogre": "infernal_ogre"
}
const FROSTFANG_SHEETS := {
	"Frost Wolf": "frost_wolf", "Ice Goblin": "ice_goblin", "Frozen Skeleton": "frozen_skeleton",
	"Snow Bandit": "snow_bandit", "Ice Archer": "ice_archer", "Frost Spirit": "frost_spirit",
	"Ice Troll": "ice_troll", "Frost Knight": "frost_knight", "Frostfang Giant": "frostfang_giant"
}
const SUNKEN_MARSHES_SHEETS := {
	"Swamp Goblin": "swamp_goblin", "Plague Rat": "plague_rat", "Bog Skeleton": "bog_skeleton",
	"Poison Slime": "poison_slime", "Swamp Beast": "swamp_beast", "Cultist": "cultist",
	"Bog Horror": "bog_horror", "Plague Knight": "plague_knight", "Marsh Hydra": "marsh_hydra"
}
const CRIMSON_DESERT_SHEETS := {
 "Desert Raider": "desert_raider", "Sand Scorpion": "sand_scorpion", "Desert Skeleton": "desert_skeleton",
 "Fire Cultist": "fire_cultist", "Sand Wolf": "sand_wolf", "Tomb Archer": "tomb_archer",
 "Sand Golem": "sand_golem", "Crimson Champion": "crimson_champion", "Ancient Sand Wyrm": "ancient_sand_wyrm"
}
const RUINED_KINGDOM_SHEETS := {
	"Fallen Knight": "fallen_knight", "Corrupted Soldier": "corrupted_soldier", "Undead Guard": "undead_guard",
	"Dark Archer": "dark_archer", "Armored Ghoul": "armored_ghoul", "War Beast": "war_beast",
	"Royal Executioner": "royal_executioner", "Fallen Champion": "fallen_champion", "Corrupted King": "corrupted_king"
}
const SHADOWLANDS_SHEETS := {
	"Shadow Hound": "shadow_hound", "Shade": "shade", "Dark Mage": "dark_mage",
	"Phantom Archer": "phantom_archer", "Shadow Knight": "shadow_knight", "Void Spawn": "void_spawn",
	"Void Reaper": "void_reaper", "Shadow Champion": "shadow_champion", "Lord of Shadows": "lord_of_shadows"
}
const DRAGON_PEAKS_SHEETS := {
	"Drake": "drake", "Dragon Cultist": "dragon_cultist", "Flame Drake": "flame_drake",
	"Storm Drake": "storm_drake", "Dragon Knight": "dragon_knight", "Wyvern": "wyvern",
	"Elder Wyvern": "elder_wyvern", "Dragon Champion": "dragon_champion", "Ancient Dragon": "ancient_dragon"
}
const DEMON_REALM_SHEETS := {
	"Lesser Demon": "lesser_demon", "Demon Archer": "demon_archer", "Hellhound": "hellhound",
	"Demon Knight": "demon_knight", "Infernal Mage": "infernal_mage", "Corrupted Giant": "corrupted_giant",
	"Demon Champion": "demon_champion", "Infernal Reaper": "infernal_reaper", "Demon Lord": "demon_lord"
}
const BODY_PLACEMENT := {
	"Giant Spider": {"width": 1.48, "height": 0.78},
	"Corrupted Boar": {"width": 1.30, "height": 0.82},
	"Poison Wolf": {"width": 1.26, "height": 0.84},
	"Spider Matriarch": {"width": 1.30, "height": 0.78, "offset_x": -0.055},
	"Forest Brute": {"width": 1.05, "height": 0.95, "offset_x": -0.045},
	"Ancient Treant": {"width": 0.95, "height": 0.90},
	"Fire Imp": {"width": 0.82, "height": 0.78, "offset_x": -0.025},
	"Magma Hound": {"width": 1.30, "height": 0.72},
	"Flame Brute": {"width": 1.06, "height": 1.02},
	"Ash Knight": {"width": 0.98, "height": 1.02},
	"Infernal Ogre": {"width": 1.10, "height": 1.08},
	"Frost Wolf": {"width": 1.0, "height": 1.0},
	"Frost Spirit": {"width": 0.80, "height": 0.80},
	"Ice Troll": {"width": 1.0, "height": 1.0},
	"Frost Knight": {"width": 1.0, "height": 1.0},
	"Frostfang Giant": {"width": 1.05, "height": 1.05},
	"Plague Rat": {"width": 0.78, "height": 0.78},
	"Poison Slime": {"width": 0.82, "height": 0.82},
	"Swamp Beast": {"width": 1.0, "height": 1.0},
	"Bog Horror": {"width": 1.05, "height": 1.05},
	"Plague Knight": {"width": 1.02, "height": 1.02},
	"Marsh Hydra": {"width": 1.08, "height": 1.08},
	"Sand Scorpion": {"width": 1.42, "height": 0.76},
	"Sand Wolf": {"width": 1.28, "height": 0.78},
	"Sand Golem": {"width": 1.14, "height": 1.14},
	"Crimson Champion": {"width": 1.08, "height": 1.08},
	"Ancient Sand Wyrm": {"width": 1.44, "height": 0.62},
	"Armored Ghoul": {"width": 0.94, "height": 0.92},
	"War Beast": {"width": 1.40, "height": 0.82},
	"Royal Executioner": {"width": 1.16, "height": 1.14},
	"Fallen Champion": {"width": 1.10, "height": 1.10},
	"Corrupted King": {"width": 0.98, "height": 1.04, "offset_x": -0.08},
	"Shadow Hound": {"width": 1.50, "height": 1.00},
	"Shade": {"width": 1.00, "height": 1.06},
	"Shadow Knight": {"width": 1.18, "height": 1.18},
	"Void Spawn": {"width": 1.22, "height": 1.13},
	"Void Reaper": {"width": 1.32, "height": 1.38},
	"Shadow Champion": {"width": 1.30, "height": 1.32},
	"Lord of Shadows": {"width": 1.48, "height": 1.50},
	"Drake": {"width": 1.48, "height": 0.78},
	"Flame Drake": {"width": 1.48, "height": 0.78},
	"Storm Drake": {"width": 1.42, "height": 0.72},
	"Dragon Cultist": {"width": 0.90, "height": 1.08},
	"Dragon Knight": {"width": 1.08, "height": 1.16},
	"Wyvern": {"width": 1.30, "height": 1.02, "offset_x": -0.04},
	"Elder Wyvern": {"width": 1.42, "height": 1.12, "offset_x": -0.08},
	"Dragon Champion": {"width": 1.30, "height": 1.34},
	"Ancient Dragon": {"width": 1.42, "height": 0.94, "offset_x": -0.04},
	"Hellhound": {"width": 1.42, "height": 0.72},
	"Corrupted Giant": {"width": 1.05, "height": 1.08},
	"Demon Knight": {"width": 1.08, "height": 1.10},
	"Demon Champion": {"width": 1.26, "height": 1.28},
	"Infernal Reaper": {"width": 1.10, "height": 1.30},
	"Demon Lord": {"width": 1.18, "height": 0.97, "contact_y": 214.0}
}
## Explicit clearance above the shared floor for units whose feet never contact it.
## Values are local pixels in the padded 256px sprite frame and scale with the actor.
const HOVER_PLACEMENT := {
	"Fire Imp": 10.0,
	"Frost Spirit": 16.0,
	"Shade": 14.0,
	"Void Spawn": 10.0,
	"Void Reaper": 10.0,
	"Lord of Shadows": 10.0,
	"Wyvern": 12.0,
	"Elder Wyvern": 12.0
}
const ENEMY_ENTRY_ANIMATIONS := {
	"Goblin": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin/entry.png", "frames": 4, "fps": 11.0},
	"Skeleton": {"path": "res://assets/prototype_pixel/enemies/greenvale/skeleton/entry.png", "frames": 4, "fps": 9.0},
	"Corrupted Wolf": {"path": "res://assets/prototype_pixel/enemies/greenvale/corrupted_wolf/entry.png", "frames": 4, "fps": 11.0},
	"Goblin Archer": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_archer/entry.png", "frames": 4, "fps": 11.0},
	"Goblin Spearman": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_spearman/entry.png", "frames": 4, "fps": 10.0},
	"Bandit": {"path": "res://assets/prototype_pixel/enemies/greenvale/bandit/entry.png", "frames": 4, "fps": 12.0},
	"Goblin Captain": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_captain/entry.png", "frames": 4, "fps": 10.0},
	"Armored Skeleton": {"path": "res://assets/prototype_pixel/enemies/greenvale/armored_skeleton/entry.png", "frames": 4, "fps": 8.0},
	"Goblin Warlord": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_warlord/entry.png", "frames": 4, "fps": 8.0},
}
const CHARACTER_ANIMATIONS := {
	"Squire": {
		"idle": {"path": "res://assets/prototype_pixel/heroes/squire/idle.png", "frames": 4, "fps": 7.0},
		"attack": {"path": "res://assets/prototype_pixel/heroes/squire/attack.png", "frames": 6, "fps": 12.0},
		"guard": {"path": "res://assets/prototype_pixel/heroes/squire/guard.png", "frames": 6, "fps": 12.0},
		"hit": {"path": "res://assets/prototype_pixel/heroes/squire/hit.png", "frames": 4, "fps": 12.0},
	},
	"Goblin": {
		"idle": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin/idle.png", "frames": 4, "fps": 8.0},
		"attack": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin/attack.png", "frames": 4, "fps": 11.0},
		"hit": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin/hit.png", "frames": 3, "fps": 11.0},
	},
	"Skeleton": {
		"idle": {"path": "res://assets/prototype_pixel/enemies/greenvale/skeleton/idle.png", "frames": 4, "fps": 7.0},
		"attack": {"path": "res://assets/prototype_pixel/enemies/greenvale/skeleton/attack.png", "frames": 4, "fps": 9.0},
		"hit": {"path": "res://assets/prototype_pixel/enemies/greenvale/skeleton/hit.png", "frames": 3, "fps": 10.0},
	},
	"Corrupted Wolf": {
		"idle": {"path": "res://assets/prototype_pixel/enemies/greenvale/corrupted_wolf/idle.png", "frames": 4, "fps": 8.0},
		"attack": {"path": "res://assets/prototype_pixel/enemies/greenvale/corrupted_wolf/attack.png", "frames": 5, "fps": 12.0},
		"hit": {"path": "res://assets/prototype_pixel/enemies/greenvale/corrupted_wolf/hit.png", "frames": 3, "fps": 11.0},
	},
	"Goblin Archer": {
		"idle": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_archer/idle.png", "frames": 4, "fps": 7.5},
		"attack": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_archer/attack.png", "frames": 5, "fps": 10.0},
		"hit": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_archer/hit.png", "frames": 3, "fps": 11.0},
	},
	"Goblin Spearman": {
		"idle": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_spearman/idle.png", "frames": 4, "fps": 7.5},
		"attack": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_spearman/attack.png", "frames": 5, "fps": 11.0},
		"hit": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_spearman/hit.png", "frames": 3, "fps": 11.0},
	},
	"Bandit": {
		"idle": {"path": "res://assets/prototype_pixel/enemies/greenvale/bandit/idle.png", "frames": 4, "fps": 8.0},
		"attack": {"path": "res://assets/prototype_pixel/enemies/greenvale/bandit/attack.png", "frames": 5, "fps": 12.0},
		"hit": {"path": "res://assets/prototype_pixel/enemies/greenvale/bandit/hit.png", "frames": 3, "fps": 12.0},
	},
	"Goblin Captain": {
		"idle": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_captain/idle.png", "frames": 4, "fps": 7.0},
		"attack": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_captain/attack.png", "frames": 5, "fps": 10.0},
		"hit": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_captain/hit.png", "frames": 3, "fps": 10.0},
	},
	"Armored Skeleton": {
		"idle": {"path": "res://assets/prototype_pixel/enemies/greenvale/armored_skeleton/idle.png", "frames": 4, "fps": 6.5},
		"attack": {"path": "res://assets/prototype_pixel/enemies/greenvale/armored_skeleton/attack.png", "frames": 5, "fps": 9.0},
		"hit": {"path": "res://assets/prototype_pixel/enemies/greenvale/armored_skeleton/hit.png", "frames": 3, "fps": 9.0},
	},
	"Goblin Warlord": {
		"idle": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_warlord/idle.png", "frames": 4, "fps": 6.0},
		"attack": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_warlord/attack.png", "frames": 6, "fps": 9.0},
		"hit": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_warlord/hit.png", "frames": 4, "fps": 10.0},
		"death": {"path": "res://assets/prototype_pixel/enemies/greenvale/goblin_warlord/death.png", "frames": 6, "fps": 9.0},
	},
}
static var _frame_cache: Dictionary = {}
static var _enemy_art_cache: Dictionary = {}

static func is_active(battle: BattleController) -> bool:
	if not PROTOTYPE_ENABLED or battle == null or battle.profile == null:
		return false
	if str(battle.mode_config.get("mode", "campaign")) != "campaign" or battle.region not in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]:
		return false
	set_battle_region(battle.region)
	var hero_id := battle.profile.selected_hero_id
	if hero_id == "knight":
		return int(battle.profile.heroes.get("knight", {}).get("evolution", 0)) in [0, 1, 2, 3, 4]
	return HeroArtService.texture_for_hero(hero_id, 0, "idle") != null

static func enemy_art_active(battle: BattleController, enemy_id: String) -> bool:
	if not PROTOTYPE_ENABLED or battle == null or enemy_id.is_empty():
		return false
	if not _enemy_art_cache.has(enemy_id):
		_enemy_art_cache[enemy_id] = enemy_sheet(enemy_id) != null
	return bool(_enemy_art_cache[enemy_id])

static func hero_sheet() -> Texture2D:
	return load(HERO_SHEET) as Texture2D

static func hero_run_frame(frame: int) -> Texture2D:
	if not ResourceLoader.exists(HERO_RUN_SHEET, "Texture2D"):
		return null
	var sheet := load(HERO_RUN_SHEET) as Texture2D
	if sheet == null or sheet.get_width() != 1536 or sheet.get_height() != 256:
		return null
	var frame_index := posmod(frame, 6)
	var key := "squire_run:%d" % frame_index
	if _frame_cache.has(key):
		return _frame_cache[key] as Texture2D
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(frame_index * 256, 0, 256, 256)
	_frame_cache[key] = atlas
	return atlas

static func enemy_sheet(enemy_id: String) -> Texture2D:
	if DEMON_REALM_SHEETS.has(enemy_id):
		return animation_sheet(enemy_id, "idle")
	if FOREST_SHEETS.has(enemy_id):
		return animation_sheet(enemy_id, "idle")
	if ASHEN_SHEETS.has(enemy_id):
		return animation_sheet(enemy_id, "idle")
	if FROSTFANG_SHEETS.has(enemy_id):
		return animation_sheet(enemy_id, "idle")
	if SUNKEN_MARSHES_SHEETS.has(enemy_id):
		return animation_sheet(enemy_id, "idle")
	if CRIMSON_DESERT_SHEETS.has(enemy_id):
		return animation_sheet(enemy_id, "idle")
	if RUINED_KINGDOM_SHEETS.has(enemy_id):
		return animation_sheet(enemy_id, "idle")
	if SHADOWLANDS_SHEETS.has(enemy_id):
		return animation_sheet(enemy_id, "idle")
	if DRAGON_PEAKS_SHEETS.has(enemy_id):
		return animation_sheet(enemy_id, "idle")
	if not ENEMY_SHEETS.has(enemy_id):
		return null
	return load(str(ENEMY_SHEETS[enemy_id])) as Texture2D

static func enemy_entry_frame_count(enemy_id: String) -> int:
	if FOREST_SHEETS.has(enemy_id) or ASHEN_SHEETS.has(enemy_id) or FROSTFANG_SHEETS.has(enemy_id) or SUNKEN_MARSHES_SHEETS.has(enemy_id) or CRIMSON_DESERT_SHEETS.has(enemy_id) or RUINED_KINGDOM_SHEETS.has(enemy_id) or SHADOWLANDS_SHEETS.has(enemy_id) or DRAGON_PEAKS_SHEETS.has(enemy_id) or DEMON_REALM_SHEETS.has(enemy_id):
		return animation_frame_count(enemy_id, "entry")
	return int(ENEMY_ENTRY_ANIMATIONS.get(enemy_id, {}).get("frames", 0))

static func enemy_entry_fps(enemy_id: String) -> float:
	if FOREST_SHEETS.has(enemy_id) or ASHEN_SHEETS.has(enemy_id) or FROSTFANG_SHEETS.has(enemy_id) or SUNKEN_MARSHES_SHEETS.has(enemy_id) or CRIMSON_DESERT_SHEETS.has(enemy_id) or RUINED_KINGDOM_SHEETS.has(enemy_id) or SHADOWLANDS_SHEETS.has(enemy_id) or DRAGON_PEAKS_SHEETS.has(enemy_id) or DEMON_REALM_SHEETS.has(enemy_id):
		return animation_fps(enemy_id, "entry")
	return float(ENEMY_ENTRY_ANIMATIONS.get(enemy_id, {}).get("fps", 0.0))

static func enemy_entry_frame(enemy_id: String, frame: int) -> Texture2D:
	if FOREST_SHEETS.has(enemy_id) or ASHEN_SHEETS.has(enemy_id) or FROSTFANG_SHEETS.has(enemy_id) or SUNKEN_MARSHES_SHEETS.has(enemy_id) or CRIMSON_DESERT_SHEETS.has(enemy_id) or RUINED_KINGDOM_SHEETS.has(enemy_id) or SHADOWLANDS_SHEETS.has(enemy_id) or DRAGON_PEAKS_SHEETS.has(enemy_id) or DEMON_REALM_SHEETS.has(enemy_id):
		return animation_frame(enemy_id, "entry", frame)
	var config: Dictionary = ENEMY_ENTRY_ANIMATIONS.get(enemy_id, {})
	if config.is_empty() or not ResourceLoader.exists(str(config["path"]), "Texture2D"):
		return null
	var sheet := load(str(config["path"])) as Texture2D
	var frame_count := int(config["frames"])
	if sheet == null or sheet.get_width() != frame_count * 256 or sheet.get_height() != 256:
		return null
	var frame_index := posmod(frame, frame_count)
	var key := "enemy_entry:%s:%d" % [enemy_id, frame_index]
	if _frame_cache.has(key):
		return _frame_cache[key] as Texture2D
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(frame_index * 256, 0, 256, 256)
	_frame_cache[key] = atlas
	return atlas

static func animation_frame_count(character_id: String, state: String) -> int:
	if DEMON_REALM_SHEETS.has(character_id):
		return int(_demon_realm_config(character_id, state).get("frames", 0))
	if FOREST_SHEETS.has(character_id):
		return int(_forest_config(character_id, state).get("frames", 0))
	if ASHEN_SHEETS.has(character_id):
		return int(_ashen_config(character_id, state).get("frames", 0))
	if FROSTFANG_SHEETS.has(character_id):
		return int(_frostfang_config(character_id, state).get("frames", 0))
	if SUNKEN_MARSHES_SHEETS.has(character_id):
		return int(_sunken_marshes_config(character_id, state).get("frames", 0))
	if CRIMSON_DESERT_SHEETS.has(character_id):
		return int(_crimson_desert_config(character_id, state).get("frames", 0))
	if RUINED_KINGDOM_SHEETS.has(character_id):
		return int(_ruined_kingdom_config(character_id, state).get("frames", 0))
	if SHADOWLANDS_SHEETS.has(character_id):
		return int(_shadowlands_config(character_id, state).get("frames", 0))
	if DRAGON_PEAKS_SHEETS.has(character_id):
		return int(_dragon_peaks_config(character_id, state).get("frames", 0))
	return int(CHARACTER_ANIMATIONS.get(character_id, {}).get(state, {}).get("frames", 0))

static func animation_fps(character_id: String, state: String) -> float:
	if DEMON_REALM_SHEETS.has(character_id):
		return float(_demon_realm_config(character_id, state).get("fps", 0.0))
	if FOREST_SHEETS.has(character_id):
		return float(_forest_config(character_id, state).get("fps", 0.0))
	if ASHEN_SHEETS.has(character_id):
		return float(_ashen_config(character_id, state).get("fps", 0.0))
	if FROSTFANG_SHEETS.has(character_id):
		return float(_frostfang_config(character_id, state).get("fps", 0.0))
	if SUNKEN_MARSHES_SHEETS.has(character_id):
		return float(_sunken_marshes_config(character_id, state).get("fps", 0.0))
	if CRIMSON_DESERT_SHEETS.has(character_id):
		return float(_crimson_desert_config(character_id, state).get("fps", 0.0))
	if RUINED_KINGDOM_SHEETS.has(character_id):
		return float(_ruined_kingdom_config(character_id, state).get("fps", 0.0))
	if SHADOWLANDS_SHEETS.has(character_id):
		return float(_shadowlands_config(character_id, state).get("fps", 0.0))
	if DRAGON_PEAKS_SHEETS.has(character_id):
		return float(_dragon_peaks_config(character_id, state).get("fps", 0.0))
	return float(CHARACTER_ANIMATIONS.get(character_id, {}).get(state, {}).get("fps", 0.0))

static func animation_sheet(character_id: String, state: String) -> Texture2D:
	if DEMON_REALM_SHEETS.has(character_id):
		var demon_config := _demon_realm_config(character_id, state)
		if demon_config.is_empty(): return null
		var demon_path := str(demon_config["path"])
		if not ResourceLoader.exists(demon_path, "Texture2D"): return null
		var demon_sheet := load(demon_path) as Texture2D
		if demon_sheet == null or demon_sheet.get_width() != int(demon_config["frames"]) * 256 or demon_sheet.get_height() != 256: return null
		return demon_sheet
	if FOREST_SHEETS.has(character_id):
		var forest_config := _forest_config(character_id, state)
		if forest_config.is_empty():
			return null
		var forest_path := str(forest_config["path"])
		if not ResourceLoader.exists(forest_path, "Texture2D"):
			return null
		var forest_sheet := load(forest_path) as Texture2D
		if forest_sheet == null or forest_sheet.get_width() != int(forest_config["frames"]) * 256 or forest_sheet.get_height() != 256:
			return null
		return forest_sheet
	if ASHEN_SHEETS.has(character_id):
		var ashen_config := _ashen_config(character_id, state)
		if ashen_config.is_empty(): return null
		var ashen_path := str(ashen_config["path"])
		if not ResourceLoader.exists(ashen_path, "Texture2D"): return null
		var ashen_sheet := load(ashen_path) as Texture2D
		if ashen_sheet == null or ashen_sheet.get_width() != int(ashen_config["frames"]) * 256 or ashen_sheet.get_height() != 256: return null
		return ashen_sheet
	if FROSTFANG_SHEETS.has(character_id):
		var frost_config := _frostfang_config(character_id, state)
		if frost_config.is_empty(): return null
		var frost_path := str(frost_config["path"])
		if not ResourceLoader.exists(frost_path, "Texture2D"): return null
		var frost_sheet := load(frost_path) as Texture2D
		if frost_sheet == null or frost_sheet.get_width() != int(frost_config["frames"]) * 256 or frost_sheet.get_height() != 256: return null
		return frost_sheet
	if SUNKEN_MARSHES_SHEETS.has(character_id):
		var marsh_config := _sunken_marshes_config(character_id, state)
		if marsh_config.is_empty(): return null
		var marsh_path := str(marsh_config["path"])
		if not ResourceLoader.exists(marsh_path, "Texture2D"): return null
		var marsh_sheet := load(marsh_path) as Texture2D
		if marsh_sheet == null or marsh_sheet.get_width() != int(marsh_config["frames"]) * 256 or marsh_sheet.get_height() != 256: return null
		return marsh_sheet
	if CRIMSON_DESERT_SHEETS.has(character_id):
		var desert_config := _crimson_desert_config(character_id, state)
		if desert_config.is_empty(): return null
		var desert_path := str(desert_config["path"])
		if not ResourceLoader.exists(desert_path, "Texture2D"): return null
		var desert_sheet := load(desert_path) as Texture2D
		if desert_sheet == null or desert_sheet.get_width() != int(desert_config["frames"]) * 256 or desert_sheet.get_height() != 256: return null
		return desert_sheet
	if RUINED_KINGDOM_SHEETS.has(character_id):
		var kingdom_config := _ruined_kingdom_config(character_id, state)
		if kingdom_config.is_empty(): return null
		var kingdom_path := str(kingdom_config["path"])
		if not ResourceLoader.exists(kingdom_path, "Texture2D"): return null
		var kingdom_sheet := load(kingdom_path) as Texture2D
		if kingdom_sheet == null or kingdom_sheet.get_width() != int(kingdom_config["frames"]) * 256 or kingdom_sheet.get_height() != 256: return null
		return kingdom_sheet
	if SHADOWLANDS_SHEETS.has(character_id):
		var shadow_config := _shadowlands_config(character_id, state)
		if shadow_config.is_empty(): return null
		var shadow_path := str(shadow_config["path"])
		if not ResourceLoader.exists(shadow_path, "Texture2D"): return null
		var shadow_sheet := load(shadow_path) as Texture2D
		if shadow_sheet == null or shadow_sheet.get_width() != int(shadow_config["frames"]) * 256 or shadow_sheet.get_height() != 256: return null
		return shadow_sheet
	if DRAGON_PEAKS_SHEETS.has(character_id):
		var dragon_config := _dragon_peaks_config(character_id, state)
		if dragon_config.is_empty(): return null
		var dragon_path := str(dragon_config["path"])
		if not ResourceLoader.exists(dragon_path, "Texture2D"): return null
		var dragon_sheet := load(dragon_path) as Texture2D
		if dragon_sheet == null or dragon_sheet.get_width() != int(dragon_config["frames"]) * 256 or dragon_sheet.get_height() != 256: return null
		return dragon_sheet
	var config: Dictionary = CHARACTER_ANIMATIONS.get(character_id, {}).get(state, {})
	if config.is_empty() or not ResourceLoader.exists(str(config["path"]), "Texture2D"):
		return null
	var sheet := load(str(config["path"])) as Texture2D
	if sheet == null or sheet.get_width() != int(config["frames"]) * 256 or sheet.get_height() != 256:
		return null
	return sheet

static func animation_frame(character_id: String, state: String, frame: int) -> Texture2D:
	var sheet := animation_sheet(character_id, state)
	if sheet == null:
		return null
	var frame_count := animation_frame_count(character_id, state)
	var frame_index := posmod(frame, frame_count)
	var key := "combat_anim:%s:%s:%d" % [character_id, state, frame_index]
	if _frame_cache.has(key):
		return _frame_cache[key] as Texture2D
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(frame_index * 256, 0, 256, 256)
	_frame_cache[key] = atlas
	return atlas

static func animation_duration(character_id: String, state: String, fallback: float) -> float:
	if animation_sheet(character_id, state) == null:
		return fallback
	return float(animation_frame_count(character_id, state)) / animation_fps(character_id, state)

static func enemy_fallback_frame(enemy_id: String, state: String) -> Texture2D:
	var idle := animation_frame(enemy_id, "idle", 0)
	if idle != null:
		return idle
	var legacy := enemy_sheet(enemy_id)
	return frame_texture(legacy, state, "enemy-fallback:%s" % enemy_id) if legacy != null and legacy.get_width() % 3 == 0 else null

static func background_texture() -> Texture2D:
	if _active_region == 10:
		return load(DEMON_REALM_BACKGROUND) as Texture2D
	if _active_region == 8:
		return load(SHADOWLANDS_BACKGROUND) as Texture2D
	if _active_region == 9:
		return load(DRAGON_PEAKS_BACKGROUND) as Texture2D
	if _active_region == 7:
		return load(RUINED_KINGDOM_BACKGROUND) as Texture2D
	if _active_region == 5:
		return load(SUNKEN_MARSHES_BACKGROUND) as Texture2D
	if _active_region == 6:
		return load(CRIMSON_DESERT_BACKGROUND) as Texture2D
	if _active_region == 4:
		return load(FROSTFANG_BACKGROUND) as Texture2D
	if _active_region == 3:
		return load(ASHEN_BACKGROUND) as Texture2D
	if _active_region == 2:
		return load(FOREST_BACKGROUND) as Texture2D
	return load(BACKGROUND) as Texture2D

static var _active_region := 1
static func set_battle_region(region: int) -> void:
	_active_region = region

static func _ruined_kingdom_config(character_id: String, state: String) -> Dictionary:
	if not RUINED_KINGDOM_SHEETS.has(character_id): return {}
	var boss := character_id == "Corrupted King"
	var elite := character_id in ["Royal Executioner", "Fallen Champion"]
	if state == "entrance" and not boss: return {}
	var frames := 4
	if state == "attack": frames = 6 if boss else 5
	elif state == "hit": frames = 4 if elite or boss else 3
	elif state == "death":
		if not boss: return {}
		frames = 6
	elif state not in (["idle", "entry", "entrance"] if boss else ["idle", "entry"]): return {}
	var anim := "entrance" if boss and state in ["entry", "entrance"] else state
	var fps := 7.0 if state == "idle" else (8.0 if state in ["death", "entrance"] or boss and state == "entry" else 11.0)
	return {"path": "res://assets/prototype_pixel/enemies/ruined_kingdom/%s/%s.png" % [RUINED_KINGDOM_SHEETS[character_id], anim], "frames": frames, "fps": fps}

static func _shadowlands_config(character_id: String, state: String) -> Dictionary:
	if not SHADOWLANDS_SHEETS.has(character_id): return {}
	var boss := character_id == "Lord of Shadows"
	var elite := character_id in ["Void Reaper", "Shadow Champion"]
	if state == "entrance" and not boss: return {}
	var frames := 4
	if state == "attack": frames = 6 if boss else 5
	elif state == "hit": frames = 4 if elite or boss else 3
	elif state == "death":
		if not boss: return {}
		frames = 6
	elif state not in (["idle", "entry", "entrance"] if boss else ["idle", "entry"]): return {}
	var anim := "entrance" if boss and state in ["entry", "entrance"] else state
	var fps := 7.0 if state == "idle" else (8.0 if boss and state in ["entry", "entrance", "death"] else 11.0)
	return {"path": "res://assets/prototype_pixel/enemies/shadowlands/%s/%s.png" % [SHADOWLANDS_SHEETS[character_id], anim], "frames": frames, "fps": fps}

static func _dragon_peaks_config(character_id: String, state: String) -> Dictionary:
	if not DRAGON_PEAKS_SHEETS.has(character_id): return {}
	var boss := character_id == "Ancient Dragon"
	var elite := character_id in ["Elder Wyvern", "Dragon Champion"]
	if state == "entrance" and not boss: return {}
	var frames := 4
	if state == "attack": frames = 6 if boss else 5
	elif state == "hit": frames = 4 if elite or boss else 3
	elif state == "death":
		if not boss: return {}
		frames = 6
	elif state not in (["idle", "entry", "entrance"] if boss else ["idle", "entry"]): return {}
	var anim := "entrance" if boss and state in ["entry", "entrance"] else state
	var fps := 7.0 if state == "idle" else (8.0 if boss and state in ["entry", "entrance", "death"] else 11.0)
	return {"path": "res://assets/prototype_pixel/enemies/dragon_peaks/%s/%s.png" % [DRAGON_PEAKS_SHEETS[character_id], anim], "frames": frames, "fps": fps}

static func _demon_realm_config(character_id: String, state: String) -> Dictionary:
	if not DEMON_REALM_SHEETS.has(character_id): return {}
	var boss := character_id == "Demon Lord"
	var elite := character_id in ["Demon Champion", "Infernal Reaper"]
	if state == "entrance" and not boss: return {}
	var frames := 4
	if state == "attack": frames = 6 if boss else 5
	elif state == "hit": frames = 4 if elite or boss else 3
	elif state == "death":
		if not boss: return {}
		frames = 6
	elif state not in (["idle", "entry", "entrance"] if boss else ["idle", "entry"]): return {}
	var anim := "entrance" if boss and state in ["entry", "entrance"] else state
	var fps := 7.0 if state == "idle" else (8.0 if boss and state in ["entry", "entrance", "death"] else 11.0)
	return {"path": "res://assets/prototype_pixel/enemies/demon_realm/%s/%s.png" % [DEMON_REALM_SHEETS[character_id], anim], "frames": frames, "fps": fps}

static func _ashen_config(character_id: String, state: String) -> Dictionary:
	if not ASHEN_SHEETS.has(character_id): return {}
	if state == "entrance" and character_id != "Infernal Ogre": return {}
	var frames := 4
	if state == "attack": frames = 6 if character_id == "Infernal Ogre" else 5
	elif state == "hit": frames = 4 if character_id in ["Flame Brute", "Ash Knight", "Infernal Ogre"] else 3
	elif state == "death":
		if character_id != "Infernal Ogre": return {}
		frames = 6
	elif state not in ["idle", "entry", "entrance"]: return {}
	return {"path": "res://assets/prototype_pixel/enemies/ashen_highlands/%s/%s.png" % [ASHEN_SHEETS[character_id], state], "frames": frames, "fps": 7.0 if state == "idle" else (8.0 if state in ["death", "entrance"] else 11.0)}

static func _frostfang_config(character_id: String, state: String) -> Dictionary:
	if not FROSTFANG_SHEETS.has(character_id): return {}
	if state == "entrance": state = "entry"
	var frames := 4
	if state == "attack": frames = 6 if character_id == "Frostfang Giant" else 5
	elif state == "hit": frames = 4 if character_id in ["Ice Troll", "Frost Knight", "Frostfang Giant"] else 3
	elif state == "death":
		if character_id != "Frostfang Giant": return {}
		frames = 6
	elif state not in ["idle", "entry"]: return {}
	return {"path": "res://assets/prototype_pixel/enemies/frostfang_mountains/%s/%s.png" % [FROSTFANG_SHEETS[character_id], state], "frames": frames, "fps": 7.0 if state == "idle" else (8.0 if state == "death" else 11.0)}

static func _sunken_marshes_config(character_id: String, state: String) -> Dictionary:
	if not SUNKEN_MARSHES_SHEETS.has(character_id): return {}
	if state == "entrance": state = "entry"
	var frames := 4
	if state == "attack": frames = 6 if character_id == "Marsh Hydra" else 5
	elif state == "hit": frames = 4 if character_id in ["Bog Horror", "Plague Knight", "Marsh Hydra"] else 3
	elif state == "death":
		if character_id != "Marsh Hydra": return {}
		frames = 6
	elif state not in ["idle", "entry"]: return {}
	return {"path": "res://assets/prototype_pixel/enemies/sunken_marshes/%s/%s.png" % [SUNKEN_MARSHES_SHEETS[character_id], state], "frames": frames, "fps": 7.0 if state == "idle" else (8.0 if state == "death" else 11.0)}

static func _crimson_desert_config(character_id: String, state: String) -> Dictionary:
	if not CRIMSON_DESERT_SHEETS.has(character_id): return {}
	if state == "entrance": state = "entry"
	var boss := character_id == "Ancient Sand Wyrm"
	var elite := character_id in ["Sand Golem", "Crimson Champion"]
	var frames := 4
	if state == "attack": frames = 6 if boss else 5
	elif state == "hit": frames = 4 if elite or boss else 3
	elif state == "death":
		if not boss: return {}
		frames = 6
	elif state not in (["idle", "entry", "entrance"] if boss else ["idle", "entry"]): return {}
	var anim := "entrance" if boss and state == "entry" else state
	return {"path": "res://assets/prototype_pixel/enemies/crimson_desert/%s/%s.png" % [CRIMSON_DESERT_SHEETS[character_id], anim], "frames": frames, "fps": 7.0 if state == "idle" else (8.0 if state == "death" else 11.0)}

static func _forest_config(character_id: String, state: String) -> Dictionary:
	if not FOREST_SHEETS.has(character_id):
		return {}
	var frames := 4
	if state == "attack": frames = 5
	elif state == "hit": frames = 3 if character_id not in ["Spider Matriarch", "Forest Brute"] else 4
	elif state == "death":
		if character_id != "Ancient Treant": return {}
		frames = 6
	elif state not in ["idle", "entry", "entrance"]: return {}
	var animation := "entry" if state == "entrance" else state
	var path := "res://assets/prototype_pixel/enemies/whispering_forest/%s/%s.png" % [FOREST_SHEETS[character_id], animation]
	return {"path": path, "frames": frames, "fps": 8.0 if state == "idle" else (9.0 if state in ["death", "entrance"] else 11.0)}

static func validation_report() -> Array[String]:
	var warnings: Array[String] = []
	var active_background := BACKGROUND
	match _active_region:
		2: active_background = FOREST_BACKGROUND
		3: active_background = ASHEN_BACKGROUND
		4: active_background = FROSTFANG_BACKGROUND
		5: active_background = SUNKEN_MARSHES_BACKGROUND
		6: active_background = CRIMSON_DESERT_BACKGROUND
		7: active_background = RUINED_KINGDOM_BACKGROUND
		8: active_background = SHADOWLANDS_BACKGROUND
		9: active_background = DRAGON_PEAKS_BACKGROUND
		10: active_background = DEMON_REALM_BACKGROUND
	var paths: Array[String] = [HERO_SHEET, active_background, HERO_RUN_SHEET]
	for path in ENEMY_SHEETS.values():
		paths.append(str(path))
	for config in ENEMY_ENTRY_ANIMATIONS.values():
		paths.append(str(config["path"]))
	for character in CHARACTER_ANIMATIONS.values():
		for config in character.values():
			paths.append(str(config["path"]))
	if _active_region == 2:
		for character_id in FOREST_SHEETS:
			for state in ["idle", "entry", "attack", "hit", "death"]:
				var config := _forest_config(character_id, state)
				if not config.is_empty():
					paths.append(str(config["path"]))
	if _active_region == 3:
		for character_id in ASHEN_SHEETS:
			for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
				var config := _ashen_config(character_id, state)
				if not config.is_empty(): paths.append(str(config["path"]))
	if _active_region == 4:
		for character_id in FROSTFANG_SHEETS:
			for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
				var config := _frostfang_config(character_id, state)
				if not config.is_empty(): paths.append(str(config["path"]))
	if _active_region == 5:
		for character_id in SUNKEN_MARSHES_SHEETS:
			for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
				var config := _sunken_marshes_config(character_id, state)
				if not config.is_empty(): paths.append(str(config["path"]))
	if _active_region == 6:
		for character_id in CRIMSON_DESERT_SHEETS:
			for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
				var config := _crimson_desert_config(character_id, state)
				if not config.is_empty(): paths.append(str(config["path"]))
	if _active_region == 7:
		for character_id in RUINED_KINGDOM_SHEETS:
			for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
				var config := _ruined_kingdom_config(character_id, state)
				if not config.is_empty(): paths.append(str(config["path"]))
	if _active_region == 8:
		for character_id in SHADOWLANDS_SHEETS:
			for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
				var config := _shadowlands_config(character_id, state)
				if not config.is_empty(): paths.append(str(config["path"]))
	if _active_region == 9:
		for character_id in DRAGON_PEAKS_SHEETS:
			for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
				var config := _dragon_peaks_config(character_id, state)
				if not config.is_empty(): paths.append(str(config["path"]))
	if _active_region == 10:
		for character_id in DEMON_REALM_SHEETS:
			for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
				var config := _demon_realm_config(character_id, state)
				if not config.is_empty(): paths.append(str(config["path"]))
	for path in paths:
		if not ResourceLoader.exists(path, "Texture2D") or load(path) == null:
			warnings.append("Unable to load prototype texture: %s" % path)
			continue
		var animation_config: Dictionary = {}
		for character in CHARACTER_ANIMATIONS.values():
			for config in character.values():
				if str(config["path"]) == path:
					animation_config = config
					break
		if not animation_config.is_empty() or path.contains("/enemies/whispering_forest/") or path.contains("/enemies/ashen_highlands/") or path.contains("/enemies/frostfang_mountains/") or path.contains("/enemies/sunken_marshes/") or path.contains("/enemies/crimson_desert/") or path.contains("/enemies/ruined_kingdom/") or path.contains("/enemies/shadowlands/") or path.contains("/enemies/dragon_peaks/") or path.contains("/enemies/demon_realm/"):
			var animation_texture := load(path) as Texture2D
			var expected_frames := int(animation_config.get("frames", 0))
			for character_id in FOREST_SHEETS:
				for state in ["idle", "entry", "attack", "hit", "death"]:
					var config := _forest_config(character_id, state)
					if not config.is_empty() and str(config["path"]) == path:
						expected_frames = int(config["frames"])
			for character_id in ASHEN_SHEETS:
				for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
					var config := _ashen_config(character_id, state)
					if not config.is_empty() and str(config["path"]) == path:
						expected_frames = int(config["frames"])
			for character_id in FROSTFANG_SHEETS:
				for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
					var config := _frostfang_config(character_id, state)
					if not config.is_empty() and str(config["path"]) == path:
						expected_frames = int(config["frames"])
			for character_id in SUNKEN_MARSHES_SHEETS:
				for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
					var config := _sunken_marshes_config(character_id, state)
					if not config.is_empty() and str(config["path"]) == path:
						expected_frames = int(config["frames"])
			for character_id in CRIMSON_DESERT_SHEETS:
				for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
					var config := _crimson_desert_config(character_id, state)
					if not config.is_empty() and str(config["path"]) == path:
						expected_frames = int(config["frames"])
			for character_id in RUINED_KINGDOM_SHEETS:
				for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
					var config := _ruined_kingdom_config(character_id, state)
					if not config.is_empty() and str(config["path"]) == path:
						expected_frames = int(config["frames"])
			for character_id in SHADOWLANDS_SHEETS:
				for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
					var config := _shadowlands_config(character_id, state)
					if not config.is_empty() and str(config["path"]) == path:
						expected_frames = int(config["frames"])
			for character_id in DRAGON_PEAKS_SHEETS:
				for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
					var config := _dragon_peaks_config(character_id, state)
					if not config.is_empty() and str(config["path"]) == path:
						expected_frames = int(config["frames"])
			for character_id in DEMON_REALM_SHEETS:
				for state in ["idle", "entry", "entrance", "attack", "hit", "death"]:
					var config := _demon_realm_config(character_id, state)
					if not config.is_empty() and str(config["path"]) == path:
						expected_frames = int(config["frames"])
			if animation_texture.get_width() != expected_frames * 256 or animation_texture.get_height() != 256:
				warnings.append("Invalid combat animation sheet: %s" % path)
			continue
		var entry_config: Dictionary = {}
		for config in ENEMY_ENTRY_ANIMATIONS.values():
			if str(config["path"]) == path:
				entry_config = config
				break
		if path == HERO_RUN_SHEET:
			var run_texture := load(path) as Texture2D
			if run_texture.get_width() != 1536 or run_texture.get_height() != 256:
				warnings.append("Invalid six-frame run sheet: %s" % path)
		elif not entry_config.is_empty():
			var entry_texture := load(path) as Texture2D
			if entry_texture.get_width() != int(entry_config["frames"]) * 256 or entry_texture.get_height() != 256:
				warnings.append("Invalid enemy entry sheet: %s" % path)
		elif path not in [BACKGROUND, FOREST_BACKGROUND, ASHEN_BACKGROUND, FROSTFANG_BACKGROUND, SUNKEN_MARSHES_BACKGROUND, CRIMSON_DESERT_BACKGROUND, RUINED_KINGDOM_BACKGROUND, SHADOWLANDS_BACKGROUND, DRAGON_PEAKS_BACKGROUND, DEMON_REALM_BACKGROUND]:
			var texture := load(path) as Texture2D
			if texture.get_width() % 3 != 0 or texture.get_height() <= 0:
				warnings.append("Invalid three-frame sprite sheet: %s" % path)
	return warnings

static func frame_region(sheet: Texture2D, state: String) -> Rect2:
	var frame := 0
	if state == "attack":
		frame = 1
	elif state in ["hit", "guard"]:
		frame = 2
	var frame_width := float(sheet.get_width()) / 3.0
	return Rect2(frame_width * frame, 0.0, frame_width, float(sheet.get_height()))

static func frame_texture(sheet: Texture2D, state: String, cache_key: String) -> Texture2D:
	var key := "%s:%s" % [cache_key, state]
	if _frame_cache.has(key):
		return _frame_cache[key] as Texture2D
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = frame_region(sheet, state)
	_frame_cache[key] = atlas
	return atlas
