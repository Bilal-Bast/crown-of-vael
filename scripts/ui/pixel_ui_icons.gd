class_name PixelUiIcons
extends RefCounted

const EQUIPMENT_COLORS := {
	"Weapon": Color("d8d4bb"), "Helmet": Color("b8c8c3"), "Armor": Color("85a8b1"),
	"Gloves": Color("d5a96f"), "Boots": Color("a88a68"), "Necklace": Color("dfc577"), "Ring": Color("eddb95")
}
const ARTIFACT_COLORS := {
	"blood_crown": Color("d95359"), "hourglass_arkon": Color("8dd4cc"), "dragon_heart": Color("e96a43"),
	"dragon_fang": Color("ead9bd"), "dragon_eye": Color("8de185"), "guardian_sigil": Color("6ba4d1"), "phoenix_feather": Color("f0a94b")
}
const EQUIPMENT_FORMS := {"Weapon": 0, "Helmet": 12, "Armor": 2, "Gloves": 3, "Boots": 4, "Necklace": 5, "Ring": 6}
const ARTIFACT_FORMS := {"blood_crown": 1, "hourglass_arkon": 5, "dragon_heart": 7, "dragon_fang": 8, "dragon_eye": 9, "guardian_sigil": 10, "phoenix_feather": 11}
static var _cache: Dictionary = {}

static func equipment(slot: String) -> Texture2D:
	return _icon(EQUIPMENT_COLORS.get(slot, Color.WHITE), int(EQUIPMENT_FORMS.get(slot, 0)))

static func artifact(id: String) -> Texture2D:
	return _icon(ARTIFACT_COLORS.get(id, Color.WHITE), int(ARTIFACT_FORMS.get(id, 0)))

static func _icon(color: Color, form: int) -> Texture2D:
	var cache_key := "%d_%s" % [form, color.to_html()]
	if _cache.has(cache_key):
		return _cache[cache_key]
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var dark := color.darkened(0.48)
	var light := color.lightened(0.30)
	var masks := [
		["........##..", ".......##...", "......##....", ".....##.....", "....##......", "...##.......", "..##........", ".########...", "...##.......", "...##.......", "...##.......", "..####......"], # blade
		["..#..#..#...", ".##########.", "############", "##..####..##", "##..####..##", "############", ".##########.", "..########..", "....####....", "....####....", "....####....", "............"], # crown
		["....####....", "...######...", "..########..", ".##########.", "############", "############", ".##########.", "..########..", "...######...", "....####....", ".....##.....", "............"], # heart/shield
		["..##....##..", "..##....##..", "..########..", "..########..", "...######...", "....####....", "....####....", "....####....", "....####....", "....####....", "...######...", "............"], # gauntlet/cross
		["......##....", ".....####...", ".....####...", ".....####...", ".....####...", ".....####...", "...######...", "...######...", "..########..", "..########..", ".##########.", "............"], # boot/feather
		["....####....", "...######...", "..##....##..", ".##......##.", "##........##", "##........##", ".##......##.", "..##....##..", "...##..##...", "....####....", ".....##.....", "............"], # hourglass/pendant
		["............", "............", "...######...", "..########..", ".##......##.", "##........##", "##........##", ".##......##.", "..########..", "...######...", "............", "............"], # ring
		["..##....##..", ".####..####.", "############", "############", ".##########.", "..########..", "...######...", "....####....", ".....##.....", "............", "............", "............"], # heart
		[".....##.....", ".....##.....", "....####....", "....####....", "...######...", "...######...", "..########..", "..########..", ".##########.", ".##########.", "............", "............"], # fang
		["............", "............", "..########..", ".##......##.", "##...##...##", "##...##...##", "##...##...##", ".##......##.", "..########..", "............", "............", "............"], # dragon eye
		[".....##.....", "....####....", "...######...", "..########..", ".####..####.", "############", ".....##.....", ".....##.....", ".....##.....", ".....##.....", "............", "............"], # guardian sigil
		[".....##.....", "....####....", "...######...", "..########..", ".##########.", "############", "..########..", "...######...", "....####....", ".....##.....", ".....##.....", "......#....."], # phoenix plume
		["....####....", "..########..", ".##########.", "############", "############", "############", "############", ".##########.", "..########..", "...########.", "....######..", ".....####..." ] # helm
	]
	var mask: Array = masks[clampi(form, 0, masks.size() - 1)]
	for gy in mask.size():
		for gx in mask[gy].length():
			if mask[gy].substr(gx, 1) != "#":
				continue
			var pixel_color := light if (gx + gy) % 5 == 0 else (dark if gx in [0, 11] or gy == 10 else color)
			for py in 2:
				for px in 2:
					image.set_pixel(4 + gx * 2 + px, 4 + gy * 2 + py, pixel_color)
	var texture := ImageTexture.create_from_image(image)
	_cache[cache_key] = texture
	return texture
