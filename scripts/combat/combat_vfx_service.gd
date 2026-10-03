class_name CombatVfxService
extends RefCounted

## Reusable, bounded transient effects drawn by Battlefield.
const EFFECT_CAP := 36
const LABEL_CAP := 18
var effects: Array[Dictionary] = []
var labels: Array[Dictionary] = []
var shake_time := 0.0
var shake_strength := 0.0
var reduced := false
var projectiles: Array[Dictionary] = []
var boss_banner_time := 0.0
var boss_banner_name := ""
var clear_time := 0.0

func _push(pool: Array[Dictionary], item: Dictionary, cap: int) -> void:
	if pool.size() >= cap:
		pool.remove_at(0)
	pool.append(item)

func pulse(pos: Vector2, color: Color, strength := 1.0, life := 0.34, shape := "burst") -> void:
	_push(effects, {"pos": pos, "color": color, "strength": strength, "life": life, "age": 0.0, "shape": shape}, EFFECT_CAP)

func label(pos: Vector2, text: String, color: Color, size := 28, life := 0.85, critical := false) -> void:
	_push(labels, {"pos": pos, "text": text, "color": color, "size": size, "life": life, "age": 0.0, "critical": critical, "centered": true}, LABEL_CAP)

func projectile(origin: Vector2, destination: Vector2, color: Color, life := 0.22, size := 8.0, style := "orb") -> void:
	if projectiles.size() >= 10:
		projectiles.remove_at(0)
	projectiles.append({"from": origin, "to": destination, "color": color, "size": size * (0.62 if reduced else 1.0), "life": life, "age": 0.0, "style": style})

func skill_effect(skill_id: String, origin: Vector2, target: Vector2, hero_color: Color) -> void:
	var color := hero_color
	var shape := "burst"
	var strength := 1.1
	match skill_id:
		"shield_bash": color = Color("9de8f2"); shape = "shockwave"; strength = 1.8; shake(0.22, 2.2)
		"power_strike": color = Color("ffe6a0"); shape = "slash"; strength = 1.7; shake(0.14, 1.25)
		"whirlwind_slash": color = Color("d5e6ea"); shape = "spin"; strength = 1.3
		"iron_guard": color = Color("9bbbd1"); shape = "guard"; strength = 0.9
		"healing_light": color = Color("a9efae"); shape = "heal"; strength = 0.9
		"battle_cry": color = Color("edca79"); shape = "pulse"; strength = 1.25
	pulse(target if skill_id in ["shield_bash", "power_strike", "quick_slash", "piercing_strike"] else origin, color, strength, 0.42, shape)

func shake(duration: float, strength: float) -> void:
	if reduced:
		return
	shake_time = maxf(shake_time, duration)
	shake_strength = maxf(shake_strength, strength)

func tick(delta: float) -> void:
	shake_time = maxf(0.0, shake_time - delta)
	boss_banner_time = maxf(0.0, boss_banner_time - delta)
	clear_time = maxf(0.0, clear_time - delta)
	_tick_pool(effects, delta)
	_tick_pool(labels, delta)
	_tick_pool(projectiles, delta)
	if shake_time <= 0.0:
		shake_strength = 0.0

func _tick_pool(pool: Array[Dictionary], delta: float) -> void:
	for index in range(pool.size() - 1, -1, -1):
		pool[index]["age"] = float(pool[index]["age"]) + delta
		if float(pool[index]["age"]) >= float(pool[index]["life"]):
			pool.remove_at(index)

func draw(canvas: Control, unit: float, battle: BattleController) -> void:
	if battle != null and battle.skill_runtime.defense_time > 0.0:
		var shield_center := Vector2(canvas.size.x * 0.24, canvas.size.y * 0.72 - 92.0 * unit)
		canvas.draw_circle(shield_center, 54.0 * unit, Color(0.53, 0.78, 0.92, 0.08 if reduced else 0.13))
		canvas.draw_arc(shield_center, 60.0 * unit, 0.0, TAU, 28, Color("a8d8ec", 0.35 if reduced else 0.58), 3.0 * unit)
	for effect in effects:
		var ratio := float(effect["age"]) / float(effect["life"])
		var color: Color = effect["color"]
		if reduced:
			color.a *= 0.55
		color.a *= 1.0 - ratio
		var center: Vector2 = effect["pos"]
		var radius := (10.0 + ratio * (58.0 if float(effect["strength"]) > 1.1 else 36.0)) * unit
		var shape := str(effect.get("shape", "burst"))
		var start := -PI * 0.8 if shape in ["slash", "spin"] else 0.0
		var finish := PI * 0.7 if shape == "slash" else TAU
		canvas.draw_arc(center, radius, start, finish, 22, color, (6.0 if shape == "slash" else (5.0 if float(effect["strength"]) > 1.1 else 3.5)) * unit)
		if shape == "heal":
			for mote in 4 if reduced else 7:
				var mote_pos := center + Vector2(sin(float(mote) * 2.1) * 24, -ratio * 92 - mote * 7) * unit
				canvas.draw_circle(mote_pos, 4 * unit, color)
		var rays := 3 if reduced else (8 if float(effect["strength"]) > 1.1 else 6)
		for ray in rays:
			var direction := Vector2.RIGHT.rotated(TAU * ray / rays)
			canvas.draw_line(center + direction * radius * 0.4, center + direction * radius * 0.85, color, 3.0 * unit)
	for projectile_item in projectiles:
		var ratio := clampf(float(projectile_item["age"]) / float(projectile_item["life"]), 0.0, 1.0)
		var origin: Vector2 = projectile_item["from"]
		var destination: Vector2 = projectile_item["to"]
		var pos := origin.lerp(destination, ratio)
		var trail_color: Color = projectile_item["color"]
		trail_color.a = 1.0 - ratio * 0.35
		canvas.draw_line(origin.lerp(destination, maxf(0, ratio - 0.18)), pos, trail_color.darkened(0.15), float(projectile_item["size"]) * 0.65 * unit)
		if str(projectile_item.get("style", "orb")) in ["arrow", "pixel_arrow"]:
			var direction := (destination - origin).normalized()
			var side := Vector2(-direction.y, direction.x)
			if str(projectile_item.get("style", "orb")) == "pixel_arrow":
				var center := pos.round()
				var arrow_scale := maxf(unit, 1.0)
				var corrupted_arrow := trail_color.b > trail_color.r * 1.25
				var fletch_color := Color("d9b7ff") if corrupted_arrow else Color("c66f45")
				var shaft_start := (center - direction * 23.0 * arrow_scale).round()
				var tip := (center + direction * 21.0 * arrow_scale).round()
				canvas.draw_line(shaft_start, tip, Color("241d30") if corrupted_arrow else Color("382b21"), maxf(6.0, 7.0 * arrow_scale))
				canvas.draw_line(shaft_start, tip, Color("f2d293"), maxf(2.0, 3.0 * arrow_scale))
				canvas.draw_colored_polygon(PackedVector2Array([tip, (center + direction * 5.0 * arrow_scale + side * 7.0 * arrow_scale).round(), (center + direction * 5.0 * arrow_scale - side * 7.0 * arrow_scale).round()]), Color("fff1c8"))
				var fletch := (center - direction * 17.0 * arrow_scale).round()
				canvas.draw_line(fletch, (fletch + side * 7.0 * arrow_scale).round(), fletch_color, maxf(3.0, 4.0 * arrow_scale))
				canvas.draw_line(fletch, (fletch - side * 7.0 * arrow_scale).round(), fletch_color, maxf(3.0, 4.0 * arrow_scale))
			else:
				canvas.draw_colored_polygon(PackedVector2Array([pos + direction * 9 * unit, pos - direction * 5 * unit + side * 4 * unit, pos - direction * 5 * unit - side * 4 * unit]), trail_color)
		else:
			canvas.draw_circle(pos, float(projectile_item["size"]) * unit, trail_color)
	if boss_banner_time > 0.0:
		var alpha := minf(1.0, boss_banner_time * 3.5)
		var width := minf(190.0, canvas.size.x - 100.0)
		var text := boss_banner_name.to_upper()
		var font_size := 18
		var text_width := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		canvas.draw_rect(Rect2(Vector2((canvas.size.x - width) * 0.5, 9), Vector2(width, 36)), Color(0.07, 0.08, 0.09, 0.78 * alpha))
		canvas.draw_string(ThemeDB.fallback_font, Vector2((canvas.size.x - text_width) * 0.5, 33), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.82, 0.5, alpha))
	if battle != null and battle.stage == 20 and str(battle.mode_config.get("mode", "campaign")) == "campaign":
		canvas.draw_rect(Rect2(Vector2(canvas.size.x - 83, 9), Vector2(78, 36)), Color(0.07, 0.08, 0.09, 0.78))
		var timer_color := Color("ff8272") if battle.boss_time <= 10.0 else Color("ffe0a0")
		canvas.draw_string(ThemeDB.fallback_font, Vector2(canvas.size.x - 76, 33), "00:%02d" % ceili(battle.boss_time), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, timer_color)
	if clear_time > 0.0:
		var center := Vector2(canvas.size.x * 0.5, canvas.size.y * 0.42)
		canvas.draw_arc(center, (24 + (1.0 - clear_time) * 105) * unit, 0, TAU, 36, Color(1.0, 0.84, 0.48, clear_time), 8 * unit)
		if battle != null and not battle.active:
			var title := "VICTORY!" if battle.stage == 20 else "STAGE CLEAR"
			canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-50, -65), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff0bc", clear_time))
