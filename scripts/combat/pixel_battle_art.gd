class_name PixelBattleArt
extends RefCounted

## Reversible Greenvale art-direction prototype. Set PROTOTYPE_ENABLED to false
## to restore the existing illustrated battle presentation everywhere.
const PROTOTYPE_ENABLED := true
const HERO_SHEET := "res://assets/prototype_pixel/heroes/squire/sheet.png"
const HERO_RUN_SHEET := "res://assets/prototype_pixel/heroes/squire/run.png"
const BACKGROUND := "res://assets/prototype_pixel/backgrounds/greenvale/battle.png"
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

static func is_active(battle: BattleController) -> bool:
	if not PROTOTYPE_ENABLED or battle == null or battle.profile == null:
		return false
	if str(battle.mode_config.get("mode", "campaign")) != "campaign" or battle.region != 1:
		return false
	return battle.profile.selected_hero_id == "knight" and int(battle.profile.heroes.get("knight", {}).get("evolution", 0)) == 0

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
	if not ENEMY_SHEETS.has(enemy_id):
		return null
	return load(str(ENEMY_SHEETS[enemy_id])) as Texture2D

static func enemy_entry_frame_count(enemy_id: String) -> int:
	return int(ENEMY_ENTRY_ANIMATIONS.get(enemy_id, {}).get("frames", 0))

static func enemy_entry_fps(enemy_id: String) -> float:
	return float(ENEMY_ENTRY_ANIMATIONS.get(enemy_id, {}).get("fps", 0.0))

static func enemy_entry_frame(enemy_id: String, frame: int) -> Texture2D:
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
	return int(CHARACTER_ANIMATIONS.get(character_id, {}).get(state, {}).get("frames", 0))

static func animation_fps(character_id: String, state: String) -> float:
	return float(CHARACTER_ANIMATIONS.get(character_id, {}).get(state, {}).get("fps", 0.0))

static func animation_sheet(character_id: String, state: String) -> Texture2D:
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
	return load(BACKGROUND) as Texture2D

static func validation_report() -> Array[String]:
	var warnings: Array[String] = []
	var paths: Array[String] = [HERO_SHEET, BACKGROUND, HERO_RUN_SHEET]
	for path in ENEMY_SHEETS.values():
		paths.append(str(path))
	for config in ENEMY_ENTRY_ANIMATIONS.values():
		paths.append(str(config["path"]))
	for character in CHARACTER_ANIMATIONS.values():
		for config in character.values():
			paths.append(str(config["path"]))
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
		if not animation_config.is_empty():
			var animation_texture := load(path) as Texture2D
			if animation_texture.get_width() != int(animation_config["frames"]) * 256 or animation_texture.get_height() != 256:
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
		elif path != BACKGROUND:
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
