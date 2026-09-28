class_name Battlefield
extends Control

const SKY := Color("b9d5c5")
const GROUND := Color("738e65")

var battle: BattleController
var floaters: Array[Dictionary] = []
var impacts: Array[Dictionary] = []
var deaths: Array[Dictionary] = []
var flashes: Dictionary = {}
var lunges: Dictionary = {}
var companion_lunges: Dictionary = {}
var hero_lunge := 0.0
var hero_bash := false
var shake_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_battle(value: BattleController) -> void:
	battle = value
	battle.changed.connect(queue_redraw)
	battle.damage_popup.connect(_on_damage_popup)
	battle.attack_started.connect(_on_attack_started)
	battle.enemy_defeated.connect(_on_enemy_defeated)
	battle.companion_attack.connect(_on_companion_attack)
	battle.artifact_proc.connect(_on_artifact_proc)
	queue_redraw()

func _process(delta: float) -> void:
	hero_lunge = maxf(0.0, hero_lunge - delta)
	shake_time = maxf(0.0, shake_time - delta)
	for key in lunges.keys():
		lunges[key] = maxf(0.0, float(lunges[key]) - delta)
	for key in companion_lunges.keys():
		companion_lunges[key] = maxf(0.0, float(companion_lunges[key]) - delta)
		if float(companion_lunges[key]) <= 0.0:
			companion_lunges.erase(key)
	for key in flashes.keys():
		flashes[key] = maxf(0.0, float(flashes[key]) - delta)
	for group in [floaters, impacts, deaths]:
		for i in range(group.size() - 1, -1, -1):
			group[i]["age"] = float(group[i]["age"]) + delta
			if float(group[i]["age"]) >= float(group[i]["life"]):
				group.remove_at(i)
	if hero_lunge > 0.0 or shake_time > 0.0 or not floaters.is_empty() or not impacts.is_empty() or not deaths.is_empty() or not companion_lunges.is_empty():
		queue_redraw()

func _on_companion_attack(slot: int, target: int, amount: int) -> void:
	companion_lunges[slot] = 0.24
	floaters.append({"pos": _enemy_position(target) + Vector2(0, -130), "text": "ALLY %d" % amount, "color": Color("a9e5c4"), "age": 0.0, "life": 0.8, "size": 23, "centered": true})
	queue_redraw()

func _on_artifact_proc(label: String, color: Color) -> void:
	floaters.append({"pos": _hero_position() + Vector2(0, -190), "text": label, "color": color, "age": 0.0, "life": 1.1, "size": 28, "centered": true})
	queue_redraw()

func _on_attack_started(attacker_index: int, _target_index: int) -> void:
	if attacker_index < 0:
		hero_lunge = 0.26 if attacker_index == -2 else 0.19
		hero_bash = attacker_index == -2
	else:
		lunges[attacker_index] = 0.18
	queue_redraw()

func _on_damage_popup(target_index: int, amount: int, critical: bool, bash: bool) -> void:
	var pos := _hero_position() if target_index < 0 else _enemy_position(target_index)
	var text_value := str(amount)
	if critical:
		text_value = "CRIT %d!" % amount
	elif bash:
		text_value = "BASH %d!" % amount
	floaters.append({"pos": pos + Vector2(0, -100), "text": text_value, "color": Color("ffdf72") if critical else (Color("9de8f2") if bash else (Color("ffb4a0") if target_index < 0 else Color.WHITE)), "age": 0.0, "life": 0.9, "size": 35 if critical or bash else 28})
	impacts.append({"pos": pos + Vector2(0, -56), "age": 0.0, "life": 0.30, "strong": critical or bash})
	flashes[target_index] = 0.16
	if bash:
		shake_time = 0.28
	queue_redraw()

func _on_enemy_defeated(target_index: int, gold: int, exp: int) -> void:
	var pos := _enemy_position(target_index)
	deaths.append({"pos": pos + Vector2(0, -50), "age": 0.0, "life": 0.6})
	floaters.append({"pos": pos + Vector2(0, -140), "text": "+%d GOLD  +%d EXP" % [gold, exp], "color": Color("ffe79c"), "age": 0.0, "life": 1.25, "size": 22})
	queue_redraw()

func show_equipment_drop(item_name: String, rarity_color: Color) -> void:
	floaters.append({"pos": Vector2(size.x * 0.5, size.y * 0.45), "text": "LOOT: %s" % item_name, "color": rarity_color, "age": 0.0, "life": 2.2, "size": 30, "centered": true})
	queue_redraw()

func show_level_up(level: int, gem_bonus: int) -> void:
	var note := "SQUIRE LEVEL %d!" % level
	if gem_bonus > 0:
		note += "  +%d GEMS" % gem_bonus
	floaters.append({"pos": Vector2(size.x * 0.5, size.y * 0.28), "text": note, "color": Color("f7e9af"), "age": 0.0, "life": 2.0, "size": 39, "centered": true})
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var unit := minf(w / 1000.0, h / 650.0)
	_draw_landscape(w, h)
	var shake := Vector2(randf_range(-7, 7), randf_range(-4, 4)) * unit * (shake_time / 0.28) if shake_time > 0.0 else Vector2.ZERO
	var hero_pos := _hero_position() + shake
	if hero_lunge > 0.0:
		hero_pos.x += sin((1.0 - hero_lunge / (0.26 if hero_bash else 0.19)) * PI) * (75.0 if hero_bash else 49.0) * unit
	_draw_companions(unit)
	_draw_hero(hero_pos, unit, float(flashes.get(-1, 0.0)) > 0.0)
	if battle != null:
		for i in battle.enemies.size():
			var enemy: Dictionary = battle.enemies[i]
			if float(enemy["current_hp"]) <= 0.0:
				continue
			var pos := _enemy_position(i) + shake
			var lunge := float(lunges.get(i, 0.0))
			if lunge > 0.0:
				pos.x -= sin((1.0 - lunge / 0.18) * PI) * 24.0 * unit
			_draw_enemy(pos, enemy, unit, float(flashes.get(i, 0.0)) > 0.0)
	_draw_effects(unit)
	_draw_artifact_indicators(unit)

func _draw_companions(unit: float) -> void:
	if battle == null or battle.profile == null:
		return
	for slot in 4:
		var id := battle.profile.equipped_companion_slots[slot]
		if id == "" or not battle.profile.companions.has(id):
			continue
		var record: Dictionary = battle.profile.companions[id]
		var data: Dictionary = CompanionData.COMPANIONS[id]
		var pos := Vector2(size.x * (0.09 + slot * 0.105), size.y * (0.66 if slot % 2 == 0 else 0.76))
		var lunge := float(companion_lunges.get(slot, 0.0))
		if lunge > 0.0:
			pos.x += sin((1.0 - lunge / 0.24) * PI) * 42.0 * unit
		var color: Color = EquipmentData.COLORS[int(record["rarity"])]
		if id == "wolf":
			match int(record["evolution"]):
				1: color = Color("8195ae")
				2: color = Color("725189")
				3: color = Color("9ce9e8")
		draw_set_transform(pos, 0.0, Vector2.ONE * unit * 1.20)
		match str(data["visual"]):
			"fairy":
				draw_circle(Vector2(-19, -38), 27, Color(color, 0.55))
				draw_circle(Vector2(19, -38), 27, Color(color, 0.55))
				draw_circle(Vector2(0, -44), 20, color)
			"humanoid":
				draw_rect(Rect2(-18, -60, 36, 54), color.darkened(0.35))
				draw_circle(Vector2(0, -73), 20, Color("d9b999"))
			"dragon":
				draw_colored_polygon(PackedVector2Array([Vector2(-47, -35), Vector2(-10, -88), Vector2(0, -40), Vector2(36, -84), Vector2(48, -25)]), color.darkened(0.25))
				draw_circle(Vector2(0, -48), 24, color)
			_:
				draw_ellipse_placeholder(Vector2(0, -30), Vector2(38, 25), color)
				draw_circle(Vector2(-24, -58), 21, color)
				draw_colored_polygon(PackedVector2Array([Vector2(-37, -67), Vector2(-36, -94), Vector2(-18, -71)]), color)
		if id == "wolf" and int(record["evolution"]) > 0:
			draw_arc(Vector2(-12, -52), 30 + int(record["evolution"]) * 7, PI, TAU, 12, Color("b9a6eb"), 5)
		draw_string(ThemeDB.fallback_font, Vector2(-20, 2), str(data["icon"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
		draw_set_transform(Vector2.ZERO)

func _draw_artifact_indicators(unit: float) -> void:
	if battle == null or battle.profile == null:
		return
	for slot in ArtifactData.MAX_ACTIVE_SLOTS:
		var id := battle.profile.equipped_artifact_slots[slot]
		if id == "" or not battle.profile.artifacts.has(id):
			continue
		var pos := Vector2(16 + slot * 68, 18)
		draw_rect(Rect2(pos, Vector2(56, 50)), Color("253739"), true)
		draw_rect(Rect2(pos, Vector2(56, 50)), EquipmentData.COLORS[int(battle.profile.artifacts[id]["rarity"])], false, 3.0)
		draw_string(ThemeDB.fallback_font, pos + Vector2(13, 35), str(ArtifactData.ARTIFACTS[id]["icon"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("efcf8e"))

func _draw_landscape(w: float, h: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), SKY)
	draw_circle(Vector2(w * 0.8, h * 0.15), 62, Color("e8e6b5"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, h * 0.6), Vector2(w * 0.15, h * 0.32), Vector2(w * 0.32, h * 0.59), Vector2(w * 0.53, h * 0.36), Vector2(w * 0.76, h * 0.58), Vector2(w, h * 0.4), Vector2(w, h * 0.78), Vector2(0, h * 0.78)]), Color("91b69d"))
	for i in 6:
		var x := w * (0.06 + i * 0.18)
		var y := h * (0.47 + (i % 2) * 0.04)
		draw_rect(Rect2(x - 7, y, 14, h * 0.24), Color("6c7656"))
		draw_circle(Vector2(x, y), 35, Color("668f72"))
		draw_circle(Vector2(x - 18, y + 8), 27, Color("729b78"))
	draw_rect(Rect2(0, h * 0.72, w, h * 0.28), GROUND)
	draw_line(Vector2(0, h * 0.72), Vector2(w, h * 0.72), Color("527655"), 5)
	for i in 9:
		var x := w * (0.04 + i * 0.12)
		draw_line(Vector2(x, h * 0.88), Vector2(x + 7, h * 0.86), Color("a6bb79"), 3)
	draw_rect(Rect2(Vector2.ZERO, size), Color("19332e", 0.08), false, 5)

func _hero_position() -> Vector2:
	return Vector2(size.x * 0.24, size.y * 0.72)

func _enemy_position(index: int) -> Vector2:
	if battle != null and battle.stage == 10:
		return Vector2(size.x * 0.75, size.y * 0.71)
	return Vector2(size.x * (0.59 + (index % 3) * 0.14), size.y * (0.54 + int(index / 3) * 0.20))

func _draw_hero(pos: Vector2, unit: float, flash: bool) -> void:
	draw_set_transform(pos, 0.0, Vector2.ONE * unit)
	draw_ellipse_placeholder(Vector2(0, 21), Vector2(47, 12), Color("334e3a", 0.35))
	# Boots and plain trousers.
	draw_rect(Rect2(-27, -25, 20, 64), Color("514a3d"))
	draw_rect(Rect2(7, -25, 20, 64), Color("514a3d"))
	draw_rect(Rect2(-31, 28, 25, 13), Color("342d2a"))
	draw_rect(Rect2(5, 28, 27, 13), Color("342d2a"))
	# Linen tunic, leather vest and belt; no plate armor.
	draw_colored_polygon(PackedVector2Array([Vector2(-36, -100), Vector2(32, -100), Vector2(27, -24), Vector2(-33, -24)]), Color("d8cfaa"))
	draw_colored_polygon(PackedVector2Array([Vector2(-25, -96), Vector2(23, -96), Vector2(19, -28), Vector2(-22, -28)]), Color("6d7861"))
	draw_rect(Rect2(-27, -50, 52, 10), Color("745332"))
	draw_circle(Vector2(1, -45), 5, Color("d7b578"))
	# Exposed arms and young face.
	draw_line(Vector2(-30, -88), Vector2(-43, -52), Color("ddb792"), 15)
	draw_line(Vector2(26, -88), Vector2(41, -58), Color("ddb792"), 15)
	draw_circle(Vector2(0, -126), 25, Color("e4bf9a"))
	draw_colored_polygon(PackedVector2Array([Vector2(-26, -132), Vector2(-21, -153), Vector2(-5, -160), Vector2(21, -151), Vector2(27, -131), Vector2(14, -142), Vector2(-7, -138)]), Color("1c2223"))
	draw_circle(Vector2(-8, -126), 2, Color("26302a"))
	draw_circle(Vector2(8, -126), 2, Color("26302a"))
	# Simple iron sword and small wooden shield.
	draw_line(Vector2(40, -59), Vector2(81, -141), Color("b9c5c7"), 10)
	draw_line(Vector2(38, -66), Vector2(55, -58), Color("7c5938"), 7)
	draw_colored_polygon(PackedVector2Array([Vector2(-64, -84), Vector2(-34, -92), Vector2(-27, -69), Vector2(-34, -42), Vector2(-52, -31), Vector2(-68, -52)]), Color("785337"))
	draw_line(Vector2(-56, -78), Vector2(-48, -40), Color("b99059"), 4)
	draw_circle(Vector2(-48, -65), 6, Color("c8b88b"))
	if flash:
		draw_circle(Vector2(0, -91), 45, Color(1, 1, 1, 0.5))
	var ratio := battle.hero_hp / float(battle.hero["hp"]) if battle != null and not battle.hero.is_empty() else 1.0
	_draw_hp_bar(Vector2(-57, -190), 114, ratio, Color("65d78c"))
	draw_string(ThemeDB.fallback_font, Vector2(-43, -202), "SQUIRE", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("1d3030"))
	draw_set_transform(Vector2.ZERO)

func _draw_enemy(pos: Vector2, enemy: Dictionary, unit: float, flash: bool) -> void:
	var kind := str(enemy["kind"])
	var boss := kind == "Goblin Warlord"
	var actor_scale := unit * (1.65 if boss else 1.0)
	draw_set_transform(pos, 0.0, Vector2.ONE * actor_scale)
	draw_ellipse_placeholder(Vector2(0, 15), Vector2(39, 10), Color("314d37", 0.33))
	match kind:
		"Skeleton": _draw_skeleton()
		"Corrupted Wolf": _draw_wolf()
		"Goblin Archer": _draw_archer()
		"Goblin Warlord": _draw_warlord()
		_: _draw_goblin()
	if flash:
		draw_circle(Vector2(0, -62), 47, Color(1, 1, 1, 0.55))
	var bar_width := 125.0 if boss else 85.0
	_draw_hp_bar(Vector2(-bar_width * 0.5, -151 if boss else -116), bar_width, float(enemy["current_hp"]) / float(enemy["hp"]), Color("eb6f67"))
	if boss:
		draw_string(ThemeDB.fallback_font, Vector2(-76, -163), "WARLORD", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("2b2924"))
	draw_set_transform(Vector2.ZERO)

func _draw_goblin() -> void:
	var skin := Color("78b05e")
	draw_line(Vector2(-12, -28), Vector2(-16, 24), Color("5e6940"), 13)
	draw_line(Vector2(12, -28), Vector2(17, 24), Color("5e6940"), 13)
	draw_rect(Rect2(-26, -80, 51, 56), Color("805c3d"))
	draw_circle(Vector2(0, -97), 28, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-22, -102), Vector2(-56, -119), Vector2(-34, -84)]), skin)
	draw_colored_polygon(PackedVector2Array([Vector2(22, -102), Vector2(55, -119), Vector2(34, -84)]), skin)
	draw_circle(Vector2(-10, -98), 4, Color("3a332b"))
	draw_circle(Vector2(10, -98), 4, Color("3a332b"))
	draw_line(Vector2(25, -71), Vector2(49, -37), Color("735c42"), 10)
	draw_line(Vector2(49, -37), Vector2(69, -68), Color("b9b6a7"), 6)

func _draw_skeleton() -> void:
	var bone := Color("ebe4ce")
	draw_line(Vector2(-11, -30), Vector2(-18, 25), bone, 11)
	draw_line(Vector2(11, -30), Vector2(18, 25), bone, 11)
	draw_line(Vector2(0, -80), Vector2(0, -30), bone, 9)
	for i in 3:
		var y := -75 + i * 14
		draw_line(Vector2(-23, y), Vector2(23, y), bone, 6)
	draw_line(Vector2(-18, -76), Vector2(-37, -41), bone, 9)
	draw_line(Vector2(18, -76), Vector2(42, -37), bone, 9)
	draw_circle(Vector2(0, -103), 27, bone)
	draw_rect(Rect2(-15, -91, 30, 12), bone)
	draw_circle(Vector2(-10, -106), 6, Color("34413f"))
	draw_circle(Vector2(10, -106), 6, Color("34413f"))
	draw_line(Vector2(0, -99), Vector2(0, -92), Color("34413f"), 4)

func _draw_wolf() -> void:
	var fur := Color("715675")
	draw_line(Vector2(25, -57), Vector2(66, -91), fur.darkened(0.2), 16)
	draw_colored_polygon(PackedVector2Array([Vector2(-38, -81), Vector2(23, -86), Vector2(47, -61), Vector2(16, -42), Vector2(-42, -43)]), fur)
	for x in [-24, -2, 23, 39]:
		draw_line(Vector2(x, -45), Vector2(x + 5, 16), fur.darkened(0.27), 10)
	draw_circle(Vector2(-42, -93), 24, fur)
	draw_colored_polygon(PackedVector2Array([Vector2(-63, -104), Vector2(-59, -136), Vector2(-40, -111)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(-41, -110), Vector2(-22, -138), Vector2(-23, -100)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(-58, -87), Vector2(-85, -78), Vector2(-60, -68)]), fur.darkened(0.17))
	draw_circle(Vector2(-49, -98), 4, Color("f67b84"))
	draw_line(Vector2(-45, -72), Vector2(-18, -73), Color("bd6b87"), 4)

func _draw_archer() -> void:
	var skin := Color("87ba67")
	draw_line(Vector2(-12, -28), Vector2(-15, 22), Color("4e6540"), 12)
	draw_line(Vector2(12, -28), Vector2(16, 22), Color("4e6540"), 12)
	draw_rect(Rect2(-24, -82, 48, 58), Color("536b45"))
	draw_circle(Vector2(0, -98), 26, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-32, -95), Vector2(-21, -134), Vector2(2, -145), Vector2(28, -122), Vector2(32, -94)]), Color("355b3d"))
	draw_colored_polygon(PackedVector2Array([Vector2(-24, -102), Vector2(-49, -115), Vector2(-30, -84)]), skin)
	draw_circle(Vector2(-8, -98), 3, Color("26382f"))
	draw_circle(Vector2(9, -98), 3, Color("26382f"))
	draw_arc(Vector2(49, -72), 45, -PI * 0.49, PI * 0.49, 22, Color("9a6a3d"), 6)
	draw_line(Vector2(53, -117), Vector2(53, -27), Color("d9d3b8"), 2)
	draw_line(Vector2(19, -72), Vector2(82, -72), Color("c5b892"), 4)
	draw_colored_polygon(PackedVector2Array([Vector2(85, -72), Vector2(70, -81), Vector2(70, -63)]), Color("c9d4d0"))

func _draw_warlord() -> void:
	_draw_goblin()
	draw_rect(Rect2(-31, -83, 62, 18), Color("9b7243"))
	draw_colored_polygon(PackedVector2Array([Vector2(-25, -119), Vector2(-24, -148), Vector2(-8, -133), Vector2(0, -154), Vector2(9, -133), Vector2(25, -148), Vector2(26, -119)]), Color("c79b4e"))
	draw_circle(Vector2(0, -132), 6, Color("d86b5d"))
	draw_line(Vector2(52, -55), Vector2(81, -116), Color("665341"), 10)
	draw_colored_polygon(PackedVector2Array([Vector2(70, -124), Vector2(95, -143), Vector2(109, -116), Vector2(91, -96)]), Color("adb1a4"))

func _draw_effects(unit: float) -> void:
	for impact in impacts:
		var age := float(impact["age"])
		var life := float(impact["life"])
		var ratio := age / life
		var pos: Vector2 = impact["pos"]
		var color := Color("ffe5a1") if bool(impact["strong"]) else Color("f4f0d5")
		color.a = 1.0 - ratio
		draw_arc(pos, (12.0 + ratio * (60.0 if bool(impact["strong"]) else 35.0)) * unit, 0, TAU, 20, color, 5 * unit)
		for i in 6:
			var direction := Vector2.RIGHT.rotated(TAU * i / 6.0)
			draw_line(pos + direction * (15 + ratio * 18) * unit, pos + direction * (28 + ratio * 35) * unit, color, 4 * unit)
	for death in deaths:
		var ratio := float(death["age"]) / float(death["life"])
		var color := Color("b7e6a8", 0.7 * (1.0 - ratio))
		draw_arc(death["pos"], (20 + ratio * 85) * unit, 0, TAU, 24, color, 7 * unit)
		for i in 3:
			var coin_color := Color("f5cf72", 1.0 - ratio)
			var coin_pos: Vector2 = death["pos"] + Vector2((i - 1) * (26 + ratio * 32) * unit, (-18 - ratio * (45 + i * 9)) * unit)
			draw_circle(coin_pos, 8 * unit, coin_color)
			draw_circle(coin_pos, 4 * unit, Color("fff0ac", 1.0 - ratio))
	for floater in floaters:
		var ratio := float(floater["age"]) / float(floater["life"])
		var pos: Vector2 = floater["pos"] + Vector2(0, -ratio * 74 * unit)
		var color: Color = floater["color"]
		color.a = 1.0 - ratio
		var font_size := roundi(float(floater["size"]) * unit)
		var x_offset := -ThemeDB.fallback_font.get_string_size(str(floater["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * 0.5 if bool(floater.get("centered", false)) else -70.0 * unit
		draw_string(ThemeDB.fallback_font, pos + Vector2(x_offset, 0), str(floater["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_hp_bar(pos: Vector2, width: float, ratio: float, color: Color) -> void:
	draw_rect(Rect2(pos, Vector2(width, 10)), Color("233934"))
	draw_rect(Rect2(pos + Vector2(2, 2), Vector2((width - 4) * clampf(ratio, 0.0, 1.0), 6)), color)

func draw_ellipse_placeholder(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
