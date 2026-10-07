class_name ScreenArtCatalog
extends RefCounted

const ATLAS_PATHS := [
	"res://assets/environments/menus/bright_scenes_atlas_01.png",
	"res://assets/environments/menus/bright_scenes_atlas_02.png",
	"res://assets/environments/menus/bright_scenes_atlas_03.png",
	"res://assets/environments/menus/bright_scenes_atlas_04.png",
	"res://assets/environments/menus/bright_scenes_atlas_05.png",
	"res://assets/environments/menus/bright_scenes_atlas_06.png",
	"res://assets/environments/menus/bright_scenes_atlas_07.png",
]

const CELLS := {
	"heroes": Vector2i(0, 0), "equipment": Vector2i(0, 1), "summon": Vector2i(0, 2), "adventure_hub": Vector2i(0, 3),
	"skills": Vector2i(1, 0), "companions": Vector2i(1, 1), "artifacts": Vector2i(1, 2), "quests": Vector2i(1, 3),
	"login": Vector2i(2, 0), "pass": Vector2i(2, 1), "shop": Vector2i(2, 2), "account": Vector2i(2, 3),
	"adventure_campaign": Vector2i(3, 0), "adventure_map": Vector2i(3, 1), "adventure_stages": Vector2i(3, 2), "adventure_dungeons": Vector2i(3, 3),
	"adventure_tiers": Vector2i(4, 0), "adventure_tower": Vector2i(4, 1), "adventure_boss_rush": Vector2i(4, 2), "adventure_endless": Vector2i(4, 3),
	"social": Vector2i(5, 0), "settings": Vector2i(5, 1), "victory": Vector2i(5, 2), "defeat": Vector2i(5, 3),
	"evolution": Vector2i(6, 0), "summon_reveal": Vector2i(6, 1), "offline_rewards": Vector2i(6, 2), "tutorial": Vector2i(6, 3),
}

static var _cache: Dictionary = {}
static var _atlas_cache: Dictionary = {}

static func texture_for(screen_key: String) -> Texture2D:
	if not CELLS.has(screen_key):
		return null
	if _cache.has(screen_key):
		return _cache[screen_key] as Texture2D
	var cell: Vector2i = CELLS[screen_key]
	var atlas: Texture2D = _atlas_cache.get(cell.x) as Texture2D
	if atlas == null:
		atlas = load(ATLAS_PATHS[cell.x]) as Texture2D
		if atlas == null:
			return null
		_atlas_cache[cell.x] = atlas
	var half_width := floori(float(atlas.get_width()) / 2.0)
	var half_height := floori(float(atlas.get_height()) / 2.0)
	var left := cell.y % 2 * half_width
	var top := cell.y / 2 * half_height
	var region_width := atlas.get_width() - left if cell.y % 2 == 1 else half_width
	var region_height := atlas.get_height() - top if cell.y / 2 == 1 else half_height
	var frame := AtlasTexture.new()
	frame.atlas = atlas
	frame.region = Rect2i(left, top, region_width, region_height)
	frame.filter_clip = true
	_cache[screen_key] = frame
	return frame
