class_name HeroPortrait
extends Control

var hero_id := "knight"
var evolution := 0
var locked_preview := false
var profile_frame := ""

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	var scale_factor := minf(size.x / 210.0, size.y / 250.0)
	draw_set_transform(Vector2((size.x - 210.0 * scale_factor) * 0.5, (size.y - 250.0 * scale_factor) * 0.5), 0.0, Vector2.ONE * scale_factor)
	draw_rect(Rect2(0, 0, 210, 250), Color("173034"))
	var border := Color("efcf8e") if profile_frame == "golden_frame" else HeroArtService.frame_color_for_hero(hero_id, evolution)
	draw_rect(Rect2(3, 3, 204, 244), border, false, 5)
	draw_circle(Vector2(160, 42), 28, Color("d9c384", 0.45))
	var portrait_texture := HeroArtService.texture_for_hero(hero_id, evolution, "portrait")
	if portrait_texture != null:
		var aspect := float(portrait_texture.get_width()) / float(portrait_texture.get_height())
		var width := minf(210.0, 250.0 * aspect)
		var height := width / aspect
		draw_texture_rect(portrait_texture, Rect2((210.0 - width) * 0.5, 250.0 - height, width, height), false)
		if locked_preview:
			draw_rect(Rect2(0, 0, 210, 250), Color("10191a", 0.48))
		return
	if hero_id == "knight":
		if locked_preview:
			_draw_variant()
			draw_rect(Rect2(0, 0, 210, 250), Color("10191a", 0.63))
			return
	if hero_id != "knight":
		_draw_variant()
		return
	draw_colored_polygon(PackedVector2Array([Vector2(0, 218), Vector2(45, 166), Vector2(96, 217), Vector2(160, 164), Vector2(210, 224), Vector2(210, 250), Vector2(0, 250)]), Color("425c50"))
	draw_rect(Rect2(62, 184, 30, 57), Color("4d4438"))
	draw_rect(Rect2(121, 184, 30, 57), Color("4d4438"))
	draw_colored_polygon(PackedVector2Array([Vector2(68, 106), Vector2(144, 106), Vector2(159, 196), Vector2(50, 196)]), Color("d2caaa"))
	draw_colored_polygon(PackedVector2Array([Vector2(75, 115), Vector2(137, 115), Vector2(145, 185), Vector2(65, 185)]), Color("617465"))
	draw_circle(Vector2(106, 77), 31, Color("dfb794"))
	draw_colored_polygon(PackedVector2Array([Vector2(74, 72), Vector2(78, 45), Vector2(101, 34), Vector2(132, 42), Vector2(138, 68), Vector2(120, 57), Vector2(96, 58)]), Color("182021"))
	draw_line(Vector2(61, 120), Vector2(43, 175), Color("dfb794"), 16)
	draw_line(Vector2(151, 120), Vector2(172, 168), Color("dfb794"), 16)
	draw_line(Vector2(172, 165), Vector2(195, 47), Color("b7c5c6"), 8)
	draw_line(Vector2(160, 149), Vector2(187, 157), Color("785632"), 8)
	draw_colored_polygon(PackedVector2Array([Vector2(24, 128), Vector2(65, 135), Vector2(72, 187), Vector2(47, 215), Vector2(17, 183)]), Color("805b38"))
	draw_line(Vector2(43, 135), Vector2(46, 198), Color("c6a976"), 5)

func _draw_variant() -> void:
	var color: Color = Color("7288ac") if hero_id == "mage" else (Color("657b55") if hero_id == "ranger" else (Color("55536d") if hero_id == "assassin" else (Color("56436b") if hero_id == "necromancer" else [Color("617465"), Color("8b9aa3"), Color("637eb0"), Color("e5dcc5"), Color("fff4d3")][clampi(evolution, 0, 4)])))
	var accent: Color = Color("85d9ec") if hero_id == "mage" else (Color("e4c58a") if hero_id == "ranger" else (Color("b797cf") if hero_id == "assassin" else (Color("9bdf89") if hero_id == "necromancer" else Color("f4d477"))))
	if hero_id == "knight" and evolution >= 2:
		draw_colored_polygon(PackedVector2Array([Vector2(60, 105), Vector2(152, 105), Vector2(183, 240), Vector2(35, 240)]), Color("8c3d59") if evolution == 2 else Color("f5edda"))
	if hero_id == "knight" and evolution >= 3:
		draw_arc(Vector2(106, 139), 82, 0, TAU, 30, Color("ffe7a5", 0.7), 5)
	draw_rect(Rect2(64, 185, 31, 58), color.darkened(0.4))
	draw_rect(Rect2(117, 185, 31, 58), color.darkened(0.4))
	draw_colored_polygon(PackedVector2Array([Vector2(68, 106), Vector2(144, 106), Vector2(163, 218), Vector2(49, 218)]), color)
	draw_rect(Rect2(74, 119, 65, 57), accent.darkened(0.35), false, 5)
	draw_circle(Vector2(106, 78), 31, Color("dfb794"))
	draw_colored_polygon(PackedVector2Array([Vector2(73, 77), Vector2(76, 47), Vector2(106, 31), Vector2(136, 48), Vector2(139, 78), Vector2(118, 58), Vector2(90, 61)]), color.darkened(0.45) if hero_id != "knight" else Color("22272b"))
	draw_line(Vector2(67, 120), Vector2(42, 181), color.lightened(0.15), 17)
	draw_line(Vector2(145, 120), Vector2(170, 178), color.lightened(0.15), 17)
	if hero_id == "ranger":
		draw_arc(Vector2(172, 115), 61, -PI * 0.48, PI * 0.48, 20, accent, 7)
		draw_line(Vector2(172, 55), Vector2(172, 175), Color("eae4ce"), 3)
	elif hero_id == "assassin":
		draw_line(Vector2(39, 182), Vector2(15, 85), accent, 9)
		draw_line(Vector2(171, 182), Vector2(196, 85), accent, 9)
	elif hero_id == "knight":
		draw_line(Vector2(170, 164), Vector2(198, 38), accent if evolution >= 3 else Color("b7c5c6"), 12)
		draw_colored_polygon(PackedVector2Array([Vector2(20, 129), Vector2(66, 137), Vector2(73, 189), Vector2(47, 218), Vector2(17, 185)]), accent if evolution >= 3 else Color("8b9aa3"))
	else:
		draw_line(Vector2(171, 166), Vector2(190, 41), accent, 8)
		draw_circle(Vector2(190, 39), 12, accent)
