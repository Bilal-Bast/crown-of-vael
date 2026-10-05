class_name PixelUiIcons
extends RefCounted

static var _cache: Dictionary = {}

static func equipment(slot: String) -> Texture2D:
	return _load_icon("equipment", slot.to_lower())

static func item(kind: String) -> Texture2D:
	var slot := str(EquipmentData.ITEMS.get(kind, {}).get("slot", "Weapon"))
	return equipment(slot)

static func skill(id: String) -> Texture2D:
	return _load_icon("skills", id)

static func artifact(id: String) -> Texture2D:
	return _load_icon("artifacts", id)

static func _load_icon(category: String, id: String) -> Texture2D:
	var key := "%s/%s" % [category, id]
	if _cache.has(key):
		return _cache[key] as Texture2D
	var path := "res://assets/pixel_ui/%s/%s.png" % [category, id]
	var texture := load(path) as Texture2D
	if texture != null:
		_cache[key] = texture
	return texture
