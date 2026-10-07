extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var unique_variants := 0
	for slot in EquipmentData.SLOTS:
		var rarity_hashes: Dictionary = {}
		for rarity in EquipmentData.RARITIES.size():
			var icon := PixelUiIcons.equipment(str(slot), rarity)
			_check(icon != null and icon.get_width() > 0 and icon.get_height() > 0, "%s %s art resolves" % [slot, EquipmentData.RARITIES[rarity]])
			if icon == null: continue
			var atlas := icon.atlas as Texture2D
			var atlas_image := atlas.get_image() if atlas != null else null
			if atlas_image == null:
				_check(false, "%s %s atlas image loads" % [slot, EquipmentData.RARITIES[rarity]])
				continue
			var region: Rect2i = icon.region
			var tile := atlas_image.get_region(region)
			_check(_has_visible_pixels(tile), "%s %s tile is visible" % [slot, EquipmentData.RARITIES[rarity]])
			rarity_hashes[hash(tile.get_data())] = true
			unique_variants += 1
		_check(rarity_hashes.size() == EquipmentData.RARITIES.size(), "%s art is distinct across all rarities" % slot)
		var texture := EQUIPMENT_RARITY_TEXTURES.get(str(slot).to_lower()) as Texture2D
		if texture != null:
			var texture_image := texture.get_image()
			_check(texture_image.get_pixel(0, 0).a == 0.0, "%s atlas background is transparent" % slot)
	_check(unique_variants == EquipmentData.SLOTS.size() * EquipmentData.RARITIES.size(), "all equipment rarity variants loaded")
	for id in ArtifactData.ARTIFACTS:
		var artifact := PixelUiIcons.artifact(str(id))
		_check(artifact != null and artifact.get_width() > 0 and artifact.get_height() > 0, "%s artifact art remains available" % id)
	print("EQUIPMENT RARITY ART SMOKE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

const EQUIPMENT_RARITY_TEXTURES := {
	"weapon": preload("res://assets/ui/icons/pixel/equipment/rarity_atlas/weapon.png"),
	"helmet": preload("res://assets/ui/icons/pixel/equipment/rarity_atlas/helmet.png"),
	"armor": preload("res://assets/ui/icons/pixel/equipment/rarity_atlas/armor.png"),
	"gloves": preload("res://assets/ui/icons/pixel/equipment/rarity_atlas/gloves.png"),
	"boots": preload("res://assets/ui/icons/pixel/equipment/rarity_atlas/boots.png"),
	"necklace": preload("res://assets/ui/icons/pixel/equipment/rarity_atlas/necklace.png"),
	"ring": preload("res://assets/ui/icons/pixel/equipment/rarity_atlas/ring.png"),
}

func _has_visible_pixels(image: Image) -> bool:
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.05:
				return true
	return false

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("Rarity art: " + label)
