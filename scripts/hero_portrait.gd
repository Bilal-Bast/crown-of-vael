class_name HeroPortrait
extends Control

func _draw() -> void:
	var scale_factor := minf(size.x / 210.0, size.y / 250.0)
	draw_set_transform(Vector2((size.x - 210.0 * scale_factor) * 0.5, (size.y - 250.0 * scale_factor) * 0.5), 0.0, Vector2.ONE * scale_factor)
	draw_rect(Rect2(0, 0, 210, 250), Color("173034"))
	draw_circle(Vector2(160, 42), 28, Color("d9c384", 0.45))
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
