class_name SkillBadge
extends Control

var battle: BattleController

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.48)
	var cooldown := battle.bash_time if battle != null and battle.active else 8.0
	var ready := clampf(1.0 - cooldown / 8.0, 0.0, 1.0)
	draw_circle(center, 46, Color("172425"))
	draw_arc(center, 49, 0, TAU, 40, Color("596466"), 8)
	draw_arc(center, 49, -PI * 0.5, -PI * 0.5 + TAU * ready, 40, Color("efd085"), 8)
	var shield := PackedVector2Array([
		center + Vector2(-23, -25), center + Vector2(0, -36),
		center + Vector2(23, -25), center + Vector2(19, 8),
		center + Vector2(0, 28), center + Vector2(-19, 8)
	])
	draw_colored_polygon(shield, Color("9bb5bc"))
	draw_line(center + Vector2(0, -29), center + Vector2(0, 20), Color("d9e4df"), 5)
	draw_line(center + Vector2(-13, -11), center + Vector2(13, -11), Color("d9e4df"), 4)
	if cooldown > 0.0:
		draw_string(ThemeDB.fallback_font, center + Vector2(-16, 9), str(ceili(cooldown)), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("16252a"))
