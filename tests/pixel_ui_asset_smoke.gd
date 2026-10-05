extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for slot in EquipmentData.SLOTS:
		_check_icon(PixelUiIcons.equipment(slot), "equipment " + slot)
	for kind in EquipmentData.ITEMS:
		_check_icon(PixelUiIcons.item(kind), "item " + kind)
	for id in ArtifactData.ARTIFACTS:
		_check_icon(PixelUiIcons.artifact(id), "artifact " + id)
	for id in SkillData.SKILLS:
		_check_icon(PixelUiIcons.skill(id), "skill " + id)
	print("PIXEL UI ASSET SMOKE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _check_icon(texture: Texture2D, name: String) -> void:
	if texture == null:
		failures += 1
		push_error("Missing pixel asset: " + name)
		return
	var image := texture.get_image()
	if image == null or image.get_size() != Vector2i(96, 96):
		failures += 1
		push_error("Invalid pixel asset dimensions: " + name)
		return
	if image.get_pixel(0, 0).a != 0.0 or image.get_used_rect().size == Vector2i.ZERO:
		failures += 1
		push_error("Asset lacks crisp transparent padding or visible pixels: " + name)
