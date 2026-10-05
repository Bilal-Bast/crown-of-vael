class_name SummonSanctum
extends Control

## Small integer-grid scene. No particles, shaders, textures, or gameplay state.
var banner := "equipment"
var opening := false
var reduced := false
var accent := Color("dfa75e")
var elapsed := 0.0
const COLORS := {"equipment":Color("dfa75e"), "skills":Color("b89beb"), "companions":Color("82c7a3"), "artifacts":Color("e8c971")}

func _ready() -> void:
	custom_minimum_size.y = 300
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not is_visible_in_tree() or reduced:
		return
	elapsed += delta
	queue_redraw()

func _box(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(x, y, w, h), color)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(320, 100))
	accent = COLORS.get(banner, COLORS.equipment) if not opening else accent
	_box(0, 0, 320, 100, Color("101922"))
	for row in 7:
		for col in 10:
			_box(col * 36 - (18 if row % 2 else 0), row * 13, 34, 11, Color("19232c") if (row + col) % 3 else Color("1d2830"))
	_box(0, 76, 320, 24, Color("202a2f"))
	for i in 8:
		draw_line(Vector2(i * 46 - 26,100),Vector2(160 + (i - 4)*22,76),Color("33403e"),1)
	for y in [83, 95]:
		_box(0,y,320,1,Color("39413d"))
	# Stepped stone arch and recessed chamber.
	for side in [0, 1]:
		var x: int = 89 + side * 130
		_box(x, 20, 14, 59, Color("354047"))
		_box(x+3, 22, 5, 55, Color("4c5657"))
		_box(x-4, 72, 22, 7, Color("53605a"))
	_box(100, 12, 121, 10, Color("4c5657"))
	_box(110, 6, 102, 8, Color("354047"))
	_box(105, 22, 114, 54, Color("11151f"))
	if banner == "equipment":
		_box(128,37,65,34,Color("623f30"))
		_box(137,42,47,26,Color("bd693b"))
		_box(146,47,30,21,Color("f2bc65"))
		_box(118,64,88,7,Color("71828a"))
		_box(128,71,66,5,Color("46535c"))
		_box(145,74,28,12,Color("34404a"))
		_box(35,26,29,4,Color("736a55"))
		for x in [39,50,60]:
			_box(x,30,3,29,Color("b4bdb2")); _box(x-3,54,9,3,accent)
	elif banner == "skills":
		for x in [22, 244]:
			_box(x,20,55,55,Color("392f42"))
			for y in [25,44,63]:
				_box(x,y+12,55,3,Color("8d745d"))
				for book in 7:
					_box(x+4+book*7,y,4,11,accent.darkened(float(book%3)*0.18))
		_box(136,46,23,17,Color("d5caa5")); _box(161,46,23,17,Color("b8ab8f"))
		_box(158,46,3,20,accent)
	elif banner == "companions":
		for x in [13,47,258,293]:
			_box(x,15,8,64,Color("4b4840"))
			for branch in 4:
				_box(x-13+branch*2,5+branch*8,34-branch*2,11,Color("2e5147"))
		for i in 12:
			_box(i*29,73-(i%3)*3,7,10,Color("47705b"))
		_box(143,44,34,6,accent.darkened(0.2))
		_box(148,50,24,22,Color("314d4d"))
	else:
		for x in [30,257]:
			_box(x,38,32,39,Color("5b514a")); _box(x-3,34,38,6,accent.darkened(0.4))
		_box(138,45,44,25,Color("5a414b"))
		_box(134,42,52,6,accent)
		_box(157,48,6,9,Color("faf1c1"))
	_box(123,80,75,4,accent.darkened(0.3))
	_box(137,86,46,2,accent.darkened(0.55))
	# Localized, low-count pixel motes and rarity ring.
	var count := 16 if opening else 7
	for i in count:
		var x := 114 + (i*31)%94
		var y := 69 - (i*13 + int(elapsed*14))%55
		_box(x,y,2 if i%3 else 3,3,accent if i%2 else accent.lightened(0.35))
	if opening:
		var ring := PackedVector2Array()
		for i in range(25):
			var angle := float(i)*TAU/24.0
			ring.append(Vector2(roundf(160+cos(angle)*45),roundf(46+sin(angle)*32)))
		draw_polyline(ring, accent, 2.0, false)
		_box(157,23,6,45,Color(accent,0.45))
