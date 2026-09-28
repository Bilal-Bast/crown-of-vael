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
	var gap := 9.0
	var width := (size.x - gap * 3.0) / 4.0
	for slot in 4:
		var rect := Rect2(slot * (width + gap), 0, width, size.y)
		var id := battle.profile.equipped_skill_slots[slot]
		var ready := id != "" and battle.active and float(battle.skill_runtime.cooldowns.get(id, 1.0)) <= 0.0
		var rarity := int(battle.profile.skills[id]["rarity"]) if id != "" and battle.profile.skills.has(id) else 0
		var border: Color = EquipmentData.COLORS[rarity] if id != "" else Color("52605c")
		draw_rect(rect, Color("182729"), true)
		draw_rect(rect, border, false, 3.0)
		if id == "":
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(20, 56), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color("81918b"))
			continue
		var data: Dictionary = SkillData.SKILLS[id]
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(17, 51), str(data["icon"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 36, border)
		var remaining := float(battle.skill_runtime.cooldowns.get(id, 0.0))
		if not ready and remaining > 0.0:
			var fraction := clampf(remaining / float(data["cooldown"]), 0.0, 1.0)
			draw_rect(Rect2(rect.position.x + 2, rect.end.y - (rect.size.y - 4) * fraction - 2, rect.size.x - 4, (rect.size.y - 4) * fraction), Color(0.02, 0.05, 0.06, 0.65), true)
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(width - 34, 51), str(ceili(remaining)), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
		elif ready:
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, size.y - 9), "READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("a9d6ad"))
		if float(flashes.get(slot, 0.0)) > 0.0:
			draw_rect(rect.grow(2), Color(1.0, 0.9, 0.55, float(flashes[slot]) * 1.5), false, 5.0)
