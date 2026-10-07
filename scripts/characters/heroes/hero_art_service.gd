class_name HeroArtService
extends RefCounted

## Centralized optional Knight evolution art lookup. Missing art returns null so
## callers can keep using their existing procedural rendering safely.
const FORMS := ["squire", "knight", "royal_knight", "paladin", "divine_paladin"]
const TITLES := ["Squire", "Knight", "Royal Knight", "Paladin", "Divine Paladin"]
const FRAME_COLORS := [Color("aeb8b4"), Color("7899bd"), Color("839bc5"), Color("e6d79a"), Color("f7d56e")]
const FORM_META := [
	{"scale": 0.675, "offset": Vector2.ZERO, "portrait_scale": 1.0, "attack_duration": 0.26, "hit_duration": 0.30, "aura": 0.0},
	{"scale": 0.705, "offset": Vector2.ZERO, "portrait_scale": 1.0, "attack_duration": 0.26, "hit_duration": 0.30, "aura": 0.0},
	{"scale": 0.735, "offset": Vector2.ZERO, "portrait_scale": 1.0, "attack_duration": 0.26, "hit_duration": 0.30, "aura": 0.0},
	{"scale": 0.765, "offset": Vector2.ZERO, "portrait_scale": 1.0, "attack_duration": 0.26, "hit_duration": 0.30, "aura": 0.35},
	{"scale": 0.7875, "offset": Vector2.ZERO, "portrait_scale": 1.0, "attack_duration": 0.26, "hit_duration": 0.30, "aura": 0.62},
]
const BASE := "res://assets/characters/heroes/standard/knight"
const OTHER_HEROES := ["mage", "ranger", "assassin", "necromancer"]
const OTHER_FRAME_COLORS := {"mage": Color("b46e9f"), "ranger": Color("86a66b"), "assassin": Color("9876b9"), "necromancer": Color("7e6e9e")}
const OTHER_BASES := {"mage": "res://assets/characters/heroes/standard/mage", "ranger": "res://assets/characters/heroes/standard/ranger", "assassin": "res://assets/characters/heroes/standard/assassin", "necromancer": "res://assets/characters/heroes/standard/necromancer"}
const SQUIRE_FILES := {"idle": "squire_idle.png", "run": "squire_run.png", "attack": "squire_attack.png", "guard": "squire_guard.png", "hit": "squire_hit.png", "portrait": "squire_portrait.png"}
const STANDARD_FILES := {"idle": "idle.png", "run": "run.png", "attack": "attack.png", "guard": "guard.png", "hit": "hit.png", "portrait": "portrait.png", "skill": "skill.png", "death": "death.png", "evolution_fx": "evolution_fx.png", "aura": "aura.png"}
static var _texture_cache: Dictionary = {}
static var _load_counts: Dictionary = {}
static var _resolved_paths: Dictionary = {}
static var _frame_cache: Dictionary = {}

static func form_folder(evolution: int) -> String:
	return FORMS[clampi(evolution, 0, FORMS.size() - 1)]

static func form_path(evolution: int) -> String:
	return "%s/%s" % [BASE, form_folder(evolution)]

static func asset_path(evolution: int, slot: String) -> String:
	var files: Dictionary = SQUIRE_FILES if clampi(evolution, 0, 4) == 0 else STANDARD_FILES
	if not files.has(slot):
		return ""
	return "%s/%s" % [form_path(evolution), files[slot]]

static func resolve_path(evolution: int, slot: String) -> String:
	var cache_key := "%d:%s" % [clampi(evolution, 0, 4), slot]
	if _resolved_paths.has(cache_key):
		return str(_resolved_paths[cache_key])
	var path := asset_path(evolution, slot)
	var resolved := path if not path.is_empty() and ResourceLoader.exists(path, "Texture2D") else ""
	_resolved_paths[cache_key] = resolved
	return resolved

static func texture_for(evolution: int, slot: String) -> Texture2D:
	var path := resolve_path(evolution, slot)
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	_load_counts[path] = int(_load_counts.get(path, 0)) + 1
	var texture := ResourceLoader.load(path, "Texture2D") as Texture2D
	_texture_cache[path] = texture
	return texture

static func asset_path_for_hero(hero_id: String, evolution: int, slot: String) -> String:
	if hero_id == "knight":
		return asset_path(evolution, slot)
	if not OTHER_BASES.has(hero_id) or slot not in STANDARD_FILES:
		return ""
	return "%s/%s" % [OTHER_BASES[hero_id], STANDARD_FILES[slot]]

static func texture_for_hero(hero_id: String, evolution: int, slot: String) -> Texture2D:
	if hero_id == "knight":
		return texture_for(evolution, slot)
	var path := asset_path_for_hero(hero_id, evolution, slot)
	if path.is_empty() or not ResourceLoader.exists(path, "Texture2D"):
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	_load_counts[path] = int(_load_counts.get(path, 0)) + 1
	var texture := ResourceLoader.load(path, "Texture2D") as Texture2D
	_texture_cache[path] = texture
	return texture

static func metadata(evolution: int) -> Dictionary:
	return FORM_META[clampi(evolution, 0, FORM_META.size() - 1)]

static func metadata_for_hero(hero_id: String, evolution: int) -> Dictionary:
	return metadata(evolution) if hero_id == "knight" else {"scale": 0.675, "offset": Vector2.ZERO, "portrait_scale": 1.0, "attack_duration": 0.26, "hit_duration": 0.30, "aura": 0.0}

static func animation_frame(form: int, slot: String, frame: int) -> Texture2D:
	return animation_frame_for_hero("knight", form, slot, frame)

static func animation_frame_for_hero(hero_id: String, form: int, slot: String, frame: int) -> Texture2D:
	var sheet := texture_for_hero(hero_id, form, slot)
	if sheet == null or slot == "portrait":
		return sheet
	var frame_width := sheet.get_width() / 4
	if frame_width <= 0 or sheet.get_height() != 256 or sheet.get_width() != 1024:
		return null
	var frame_index := posmod(frame, 4)
	var key := "%s:%d:%s:%d" % [hero_id, clampi(form, 0, 4), slot, frame_index]
	if _frame_cache.has(key):
		return _frame_cache[key] as Texture2D
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(frame_index * frame_width, 0, frame_width, sheet.get_height())
	_frame_cache[key] = atlas
	return atlas

static func animation_fps(slot: String) -> float:
	return {"idle": 5.0, "run": 9.0, "attack": 12.0, "guard": 8.0, "hit": 10.0}.get(slot, 0.0)

static func animation_frame_count(slot: String) -> int:
	return 4 if slot in ["idle", "run", "attack", "guard", "hit"] else 0

static func frame_color(evolution: int) -> Color:
	return FRAME_COLORS[clampi(evolution, 0, FRAME_COLORS.size() - 1)]

static func frame_color_for_hero(hero_id: String, evolution: int) -> Color:
	return frame_color(evolution) if hero_id == "knight" else OTHER_FRAME_COLORS.get(hero_id, Color("75827d"))

static func validation_report() -> Array[String]:
	var warnings: Array[String] = []
	for evolution in FORMS.size():
		var folder := form_path(evolution)
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(folder)):
			warnings.append("Missing Knight evolution folder: %s" % folder)
			continue
		for slot in ["idle", "run", "attack", "guard", "hit", "portrait"]:
			var resolved := resolve_path(evolution, slot)
			if resolved.is_empty():
				warnings.append("Missing %s art: %s" % [slot, asset_path(evolution, slot)])
				continue
			var image := texture_for(evolution, slot).get_image()
			if slot == "portrait":
				if image.get_width() != 256 or image.get_height() != 256:
					warnings.append("Invalid portrait dimensions: %s" % resolved)
			elif image.get_width() != 1024 or image.get_height() != 256:
				warnings.append("Invalid four-frame %s sheet: %s" % [slot, resolved])
	for hero_id in OTHER_HEROES:
		for slot in ["idle", "run", "attack", "guard", "hit", "portrait"]:
			var path := asset_path_for_hero(hero_id, 0, slot)
			var texture := texture_for_hero(hero_id, 0, slot)
			if texture == null:
				warnings.append("Missing %s art for %s: %s" % [slot, hero_id, path])
				continue
			var image := texture.get_image()
			if slot == "portrait":
				if image.get_width() != 256 or image.get_height() != 256:
					warnings.append("Invalid %s portrait: %s" % [hero_id, path])
			elif image.get_width() != 1024 or image.get_height() != 256:
				warnings.append("Invalid %s four-frame %s sheet: %s" % [hero_id, slot, path])
	return warnings

static func cached_load_count(path: String) -> int:
	return int(_load_counts.get(path, 0))

static func clear_cache_for_tests() -> void:
	_texture_cache.clear()
	_frame_cache.clear()
	_load_counts.clear()
	_resolved_paths.clear()
