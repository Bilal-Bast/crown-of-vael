extends Control

const CombatVfxServiceScript = preload("res://scripts/combat/combat_vfx_service.gd")

var skill_id := "shield_bash"
var effect_color := Color("9de8f2")
var effects: RefCounted
var pulse_timer := 0.0

func configure(preview_skill_id: String, color: Color) -> void:
	skill_id = preview_skill_id
	effect_color = color
	effects = CombatVfxServiceScript.new()

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if effects == null:
		return
	effects.call("tick", delta)
	pulse_timer -= delta
	if pulse_timer <= 0.0:
		pulse_timer = 0.55
		var center := size * 0.5
		effects.call("skill_effect", skill_id, center, center, effect_color)
	queue_redraw()

func _draw() -> void:
	if effects != null:
		effects.call("draw", self, 0.42, null)
