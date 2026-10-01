extends Node2D

var age := 0.0
var duration := 0.28
var block_size := 4.0

func _ready() -> void:
	visible = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 0
	set_process(false)

func show_impact(at: Vector2, pixel_size: float, lifetime: float = 0.28) -> void:
	position = at.round()
	block_size = maxf(3.0, pixel_size)
	duration = maxf(0.05, lifetime)
	age = 0.0
	visible = true
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	if age >= duration:
		visible = false
		set_process(false)
		return
	queue_redraw()

func _draw() -> void:
	var fade := clampf(1.0 - age / duration, 0.0, 1.0)
	var progress := 1.0 - fade
	var radius := block_size * (2.0 + progress * 8.0)
	var shock_color := Color("ffd56a", fade * 0.86)
	for step in 5:
		var offset := float(step) * radius / 4.0
		for sign in [-1.0, 1.0]:
			draw_rect(Rect2(Vector2(offset * sign, (radius - offset) * sign).round(), Vector2(block_size, block_size)), shock_color)
			draw_rect(Rect2(Vector2(-offset * sign, (radius - offset) * sign).round(), Vector2(block_size, block_size)), shock_color)
	for point in [Vector2(-2, -1), Vector2(-1, -2), Vector2(1, -2), Vector2(2, -1), Vector2(2, 1), Vector2(1, 2), Vector2(-1, 2), Vector2(-2, 1)]:
		draw_rect(Rect2((point * block_size).round(), Vector2(block_size, block_size)), Color("ffd56a", fade))
	draw_rect(Rect2(Vector2(-block_size * 0.5, -block_size * 0.5).round(), Vector2(block_size, block_size)), Color("fff1b5", fade))
