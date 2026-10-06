class_name PixelUiIcons
extends RefCounted

static var _cache: Dictionary = {}
static var _nav_cache: Dictionary = {}
static var _equipment_rarity_cache: Dictionary = {}
static var _gold_coin_cache: Texture2D
static var _gem_cache: Texture2D

const EQUIPMENT_RARITY_ATLASES := {
	"weapon": preload("res://assets/pixel_ui/equipment/rarity_atlas/weapon.png"),
	"helmet": preload("res://assets/pixel_ui/equipment/rarity_atlas/helmet.png"),
	"armor": preload("res://assets/pixel_ui/equipment/rarity_atlas/armor.png"),
	"gloves": preload("res://assets/pixel_ui/equipment/rarity_atlas/gloves.png"),
	"boots": preload("res://assets/pixel_ui/equipment/rarity_atlas/boots.png"),
	"necklace": preload("res://assets/pixel_ui/equipment/rarity_atlas/necklace.png"),
	"ring": preload("res://assets/pixel_ui/equipment/rarity_atlas/ring.png"),
}

const NAV_PATTERNS := {
	"Battle": ["...#....#...", "..##....##..", ".###....###.", "..##....##..", "...##..##...", "....####....", "...##..##...", "..##....##..", ".##......##.", "##........##", "............", "............"],
	"Heroes": ["....####....", "...######...", "...######...", "....####....", ".....##.....", "...######...", "..########..", ".##########.", "############", "............", "............", "............"],
	"Equipment": ["...######...", "..########..", ".##########.", "##..####..##", "##..####..##", ".##########.", "...######...", "....####....", "....####....", "............", "............", "............"],
	"Summon": ["...######...", "..##....##..", ".##......##.", "##...##...##", "##..####..##", "##..####..##", "##...##...##", ".##......##.", "..##....##..", "...######...", "............", "............"],
	"Adventure": ["############", "##...##...##", "##..###...##", "##.####...##", "##...##...##", "##...##...##", "##...###..##", "##...####.##", "##...##...##", "############", "............", "............"],
	"Skills": ["############", "###########.", "##########..", "###########.", "############", "##..########", "##...#######", "##....######", "##...#######", "############", "............", "............"],
	"Quests": [".##########.", "##........##", "##.######.##", "##.#....#.##", "##.#.##.#.##", "##.#....#.##", "##.######.##", "##........##", ".##########.", "....####....", "....####....", "............"],
	"Login": [".##########.", "############", "##..####..##", "##..####..##", "############", "##...##...##", "##...##...##", "############", ".##########.", "............", "............", "............"],
	"Pass": ["....####....", "...######...", "..########..", "...######...", "....####....", ".....##.....", "....####....", "...######...", "..########..", "............", "............", "............"],
	"Shop": ["############", "##........##", "##.######.##", "##.######.##", "############", "##........##", "##.######.##", "##.######.##", "############", "............", "............", "............"],
	"Account": ["....####....", "...######...", "...######...", "....####....", ".....##.....", "..########..", ".##########.", "############", "############", "............", "............", "............"],
	"Social": ["..###...###..", ".#####.#####.", ".#####.#####.", "..###...###..", "...##...##...", "#############", "#############", ".###########.", "..#########..", "............", "............", "............"],
	"Settings": ["....####....", "..##.##.##..", ".##..##..##.", "##...##...##", "############", "##...##...##", ".##..##..##.", "..##.##.##..", "....####....", "............", "............", "............"],
}
const NAV_COLORS := {"Battle":Color("e9c87d"), "Heroes":Color("d79ba3"), "Equipment":Color("b9d7e2"), "Summon":Color("be9ce2"), "Adventure":Color("a4c99d"), "Skills":Color("b8a0df"), "Quests":Color("e4c77d"), "Login":Color("9bd6d2"), "Pass":Color("e4ba71"), "Shop":Color("d7a86c"), "Account":Color("aac8d0"), "Social":Color("90c8a7"), "Settings":Color("b8c0c4")}

static func equipment(slot: String, rarity: int = -1) -> Texture2D:
	if rarity >= 0:
		return _equipment_rarity_icon(slot, rarity)
	return _load_icon("equipment", slot.to_lower())

static func item(kind: String, rarity: int = -1) -> Texture2D:
	var slot := str(EquipmentData.ITEMS.get(kind, {}).get("slot", "Weapon"))
	return equipment(slot, rarity)

static func _equipment_rarity_icon(slot: String, rarity: int) -> Texture2D:
	var slot_key := slot.to_lower()
	if not EQUIPMENT_RARITY_ATLASES.has(slot_key):
		return _load_icon("equipment", slot_key)
	var atlas := EQUIPMENT_RARITY_ATLASES[slot_key] as Texture2D
	if atlas == null:
		return _load_icon("equipment", slot_key)
	var safe_rarity := clampi(rarity, 0, EquipmentData.RARITIES.size() - 1)
	var key := "%s:%d" % [slot_key, safe_rarity]
	if _equipment_rarity_cache.has(key):
		return _equipment_rarity_cache[key] as Texture2D
	var atlas_size := Vector2i(atlas.get_width(), atlas.get_height())
	var left := roundi(float(safe_rarity % 4) * atlas_size.x / 4.0)
	var right := roundi(float(safe_rarity % 4 + 1) * atlas_size.x / 4.0)
	var top := roundi(float(safe_rarity / 4) * atlas_size.y / 2.0)
	var bottom := roundi(float(safe_rarity / 4 + 1) * atlas_size.y / 2.0)
	var icon := AtlasTexture.new()
	icon.atlas = atlas
	icon.region = Rect2i(left, top, right - left, bottom - top)
	_equipment_rarity_cache[key] = icon
	return icon

static func skill(id: String) -> Texture2D:
	return _load_icon("skills", id)

static func artifact(id: String) -> Texture2D:
	return _load_icon("artifacts", id)

static func navigation(id: String) -> Texture2D:
	if _nav_cache.has(id):
		return _nav_cache[id] as Texture2D
	if not NAV_PATTERNS.has(id):
		return null
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var pattern: Array = NAV_PATTERNS[id]
	var accent: Color = NAV_COLORS[id]
	for y in pattern.size():
		for x in pattern[y].length():
			if pattern[y].substr(x, 1) != "#":
				continue
			for py in 2:
				for px in 2:
					image.set_pixel(4 + x * 2 + px, 4 + y * 2 + py, accent.darkened(0.4) if x == 0 or x == 11 or y == 0 or y == 11 else accent)
	var texture := ImageTexture.create_from_image(image)
	_nav_cache[id] = texture
	return texture

static func gold_coin() -> Texture2D:
	if _gold_coin_cache != null:
		return _gold_coin_cache
	_gold_coin_cache = _load_icon("currency", "gold")
	return _gold_coin_cache

static func gems() -> Texture2D:
	if _gem_cache == null:
		_gem_cache = _load_icon("currency", "gem")
	return _gem_cache

static func _load_icon(category: String, id: String) -> Texture2D:
	var key := "%s/%s" % [category, id]
	if _cache.has(key):
		return _cache[key] as Texture2D
	var path := "res://assets/pixel_ui/%s/%s.png" % [category, id]
	var texture := load(path) as Texture2D
	if texture != null:
		_cache[key] = texture
	return texture
