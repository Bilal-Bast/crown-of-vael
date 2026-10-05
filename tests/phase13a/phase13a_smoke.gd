extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for id in CompanionData.COMPANIONS:
		_check_frame(id, 0)
	for evolution in range(4):
		_check_frame("wolf", evolution)
	for id in ["blood_crown", "hourglass_arkon", "dragon_heart", "dragon_fang", "dragon_eye", "guardian_sigil", "phoenix_feather"]:
		var icon := PixelUiIcons.artifact(id)
		_check(icon != null and icon.get_width() > 0 and icon.get_height() > 0, "artifact icon: " + id)
	for slot in EquipmentData.SLOTS:
		var icon := PixelUiIcons.equipment(slot)
		_check(icon != null and icon.get_width() > 0 and icon.get_height() > 0, "equipment icon: " + slot)
	for id in CompanionData.COMPANIONS:
		_check(CompanionPixelArt.hover_height(id) >= 0.0 and CompanionPixelArt.hover_height(id) <= 64.0, "valid companion hover metadata: " + id)
	for id in ["wolf", "dire_wolf", "shadow_wolf", "fenrir"]:
		_check(CompanionPixelArt.battle_flip_h(id), "wolf-line battle facing: " + id)
	for id in ["fairy", "young_dragon", "griffin", "archer_companion", "cleric_companion", "apprentice_mage"]:
		_check(not CompanionPixelArt.battle_flip_h(id), "unrelated battle facing unchanged: " + id)
	_check(CompanionPixelArt.scale_for("wolf") > 0.0 and CompanionPixelArt.scale_for("wolf") < 1.0, "wolf presentation scale")
	_check(CompanionPixelArt.scale_for("fairy") > 0.0 and CompanionPixelArt.scale_for("fairy") < 1.0, "fairy presentation scale")
	print("PHASE 13A PIXEL PRESENTATION SMOKE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _check_frame(id: String, evolution: int) -> void:
	var idle := CompanionPixelArt.frame(id, evolution, "idle")
	var attack := CompanionPixelArt.frame(id, evolution, "attack")
	_check(idle != null and idle.atlas != null and idle.region.size.x == 512 and idle.region.size.y > 0, "idle atlas frame: %s:%d" % [id, evolution])
	_check(attack != null and attack.region.position.x == 512, "attack atlas frame: %s:%d" % [id, evolution])
	if idle != null:
		var image := idle.get_image()
		var transparent := 0
		var visible := 0
		for y in range(0, image.get_height(), 8):
			for x in range(0, image.get_width(), 8):
				if image.get_pixel(x, y).a < 0.05:
					transparent += 1
				elif image.get_pixel(x, y).a > 0.95:
					visible += 1
		_check(transparent > 0 and visible > 0, "transparent and visible sprite pixels: %s:%d" % [id, evolution])

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("Phase 13A: " + label)
