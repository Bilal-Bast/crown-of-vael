class_name SkillBar
extends Control

var battle: BattleController
var flashes := {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if battle != null:
		battle.skill_cast.connect(_on_skill_cast)

func _process(delta: float) -> void:
	for slot in flashes.keys():
		flashes[slot] = maxf(0.0, float(flashes[slot]) - delta)
	queue_redraw()

func _on_skill_cast(_id: String, slot: int) -> void:
	flashes[slot] = 0.35
	queue_redraw()

func _draw() -> void:
	if battle == null or battle.profile == null:
		return
	var gap := 2.0
	var width := (size.x - gap * 3.0) / 4.0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for slot in 4:
		var center := Vector2(slot * (width + gap) + width * 0.5, 46.0)
		var radius := minf(43.0, size.y * 0.39)
		var id := battle.profile.equipped_skill_slots[slot]
		var ready := id != "" and battle.active and float(battle.skill_runtime.cooldowns.get(id, 1.0)) <= 0.0
		var rarity := int(battle.profile.skills[id]["rarity"]) if id != "" and battle.profile.skills.has(id) else 0
		var border: Color = EquipmentData.COLORS[rarity] if id != "" else Color("52605c")
		draw_circle(center + Vector2(0, 3), radius + 2, Color("0b1118"))
		draw_circle(center, radius, Color("17242b"))
		draw_arc(center, radius - 2, 0.0, TAU, 48, border, 4.0, true)
		if id == "":
			draw_string(ThemeDB.fallback_font, center + Vector2(-8, 11), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("81918b"))
			continue
		var data: Dictionary = SkillData.SKILLS[id]
		var icon := PixelUiIcons.skill(id)
		if icon != null:
			draw_texture_rect(icon, Rect2(center - Vector2(31, 31), Vector2(62, 62)), false)
		var remaining := float(battle.skill_runtime.cooldowns.get(id, 0.0))
		if not ready and remaining > 0.0:
			draw_circle(center, radius - 5, Color(0.02, 0.05, 0.06, 0.60))
			draw_string(ThemeDB.fallback_font, center + Vector2(-8, 9), str(ceili(remaining)), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		elif ready:
			draw_string(ThemeDB.fallback_font, center + Vector2(-20, radius + 17), "READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("a9d6ad"))
		if float(flashes.get(slot, 0.0)) > 0.0:
			draw_arc(center, radius + 2, 0.0, TAU, 48, Color(1.0, 0.9, 0.55, float(flashes[slot]) * 1.5), 5.0, true)
