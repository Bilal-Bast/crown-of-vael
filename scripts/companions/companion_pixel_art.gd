class_name CompanionPixelArt
extends RefCounted

const WOLF_ATLAS: Texture2D = preload("res://assets/prototype_pixel/companions/wolf_evolutions.png")
const COMPANION_ATLAS: Texture2D = preload("res://assets/prototype_pixel/companions/companions.png")

const OTHER_ROWS := {
	"fairy": 0, "young_dragon": 1, "griffin": 2,
	"archer_companion": 3, "cleric_companion": 4, "apprentice_mage": 5
}

static func frame(id: String, evolution: int = 0, state: String = "idle") -> AtlasTexture:
	var atlas := WOLF_ATLAS if id in ["wolf", "dire_wolf", "shadow_wolf", "fenrir"] else COMPANION_ATLAS
	var cell := Vector2i(512, 384) if atlas == WOLF_ATLAS else Vector2i(512, 256)
	var row := clampi(evolution, 0, 3) if atlas == WOLF_ATLAS else int(OTHER_ROWS.get(id, -1))
	if row < 0:
		return null
	var col := 1 if state in ["attack", "cast", "special"] else 0
	var result := AtlasTexture.new()
	result.atlas = atlas
	result.region = Rect2i(col * cell.x, row * cell.y, cell.x, cell.y)
	return result

static func hover_height(id: String) -> float:
	return 48.0 if id == "fairy" else (32.0 if id == "young_dragon" else 0.0)

static func scale_for(id: String) -> float:
	return 0.32 if id in ["wolf", "dire_wolf", "shadow_wolf", "fenrir"] else 0.38

static func contact_y(id: String) -> float:
	return 359.0 if id in ["wolf", "dire_wolf", "shadow_wolf", "fenrir"] else 247.0
