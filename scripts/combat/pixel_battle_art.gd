class_name PixelBattleArt
extends RefCounted

## Reversible Greenvale art-direction prototype. Set PROTOTYPE_ENABLED to false
## to restore the existing illustrated battle presentation everywhere.
const PROTOTYPE_ENABLED := true
const HERO_SHEET := "res://assets/prototype_pixel/heroes/squire/sheet.png"
const BACKGROUND := "res://assets/prototype_pixel/backgrounds/greenvale/battle.png"
const ENEMY_SHEETS := {
	"Goblin": "res://assets/prototype_pixel/enemies/greenvale/goblin/sheet.png",
	"Skeleton": "res://assets/prototype_pixel/enemies/greenvale/skeleton/sheet.png",
	"Corrupted Wolf": "res://assets/prototype_pixel/enemies/greenvale/corrupted_wolf/sheet.png",
}
static var _frame_cache: Dictionary = {}

static func is_active(battle: BattleController) -> bool:
	if not PROTOTYPE_ENABLED or battle == null or battle.profile == null:
		return false
	if str(battle.mode_config.get("mode", "campaign")) != "campaign" or battle.region != 1:
		return false
	return battle.profile.selected_hero_id == "knight" and int(battle.profile.heroes.get("knight", {}).get("evolution", 0)) == 0

static func hero_sheet() -> Texture2D:
	return load(HERO_SHEET) as Texture2D

static func enemy_sheet(enemy_id: String) -> Texture2D:
	if not ENEMY_SHEETS.has(enemy_id):
		return null
	return load(str(ENEMY_SHEETS[enemy_id])) as Texture2D

static func background_texture() -> Texture2D:
	return load(BACKGROUND) as Texture2D

static func validation_report() -> Array[String]:
	var warnings: Array[String] = []
	var paths: Array[String] = [HERO_SHEET, BACKGROUND]
	for path in ENEMY_SHEETS.values():
		paths.append(str(path))
	for path in paths:
		if not ResourceLoader.exists(path, "Texture2D") or load(path) == null:
			warnings.append("Unable to load prototype texture: %s" % path)
			continue
		if path != BACKGROUND:
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
