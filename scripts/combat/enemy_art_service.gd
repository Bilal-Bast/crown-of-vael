class_name EnemyArtService
extends RefCounted

## Optional enemy and regional art lookup. Null textures leave callers free to
## use their existing procedural visuals. Region folders can be added without
## changing battle rendering.
const ENEMY_REGION_FOLDERS := {1: "greenvale"}
const BACKGROUND_REGION_FOLDERS := {1: "greenvale_outskirts"}
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
static var _resolved_paths: Dictionary = {}
static var _texture_cache: Dictionary = {}
static var _load_counts: Dictionary = {}

static func enemy_folder(enemy_id: String, region: int = 1) -> String:
	if not ENEMY_REGION_FOLDERS.has(region):
		return ""
	return str(GREENVALE_ENEMIES.get(enemy_id, ""))

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

static func metadata(enemy_id: String) -> Dictionary:
	return ENEMY_META.get(enemy_id, {"scale": 0.82, "offset": Vector2.ZERO, "attack_duration": 0.26, "hit_duration": 0.22, "ranged_offset": Vector2(40, -86)})

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
	for enemy_id in GREENVALE_ENEMIES:
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
