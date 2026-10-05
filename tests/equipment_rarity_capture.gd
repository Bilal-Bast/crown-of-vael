extends SceneTree

const OUT := "res://.godot/pixel_ui_rarity_captures"
const COLORS := EquipmentData.COLORS
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if root.get_texture() == null:
		push_error("Graphical viewport unavailable; rarity captures must run without --headless.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var backdrop := ColorRect.new()
	backdrop.color = Color("111e29")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 22)
	outer.add_theme_constant_override("margin_right", 22)
	outer.add_theme_constant_override("margin_top", 24)
	outer.add_theme_constant_override("margin_bottom", 24)
	backdrop.add_child(outer)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	outer.add_child(column)
	var title := Label.new()
	title.text = "EQUIPMENT RARITY FORGE"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("eed7a1"))
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Seven equipment slots  •  eight distinct rarity designs"
	subtitle.add_theme_font_size_override("font_size", 25)
	subtitle.add_theme_color_override("font_color", Color("b9c8cb"))
	column.add_child(subtitle)
	var grid := GridContainer.new()
	grid.columns = EquipmentData.RARITIES.size() + 1
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(grid)
	var slot_header := _label("SLOT", 19, Color("d7c18d"))
	slot_header.custom_minimum_size = Vector2(118, 30)
	grid.add_child(slot_header)
	for rarity in EquipmentData.RARITIES.size():
		var label := _label(EquipmentData.RARITIES[rarity].to_upper(), 17, COLORS[rarity])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(112, 30)
		grid.add_child(label)
	for slot in EquipmentData.SLOTS:
		var name := _label(str(slot).to_upper(), 22, Color("e9e4d4"))
		name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name.custom_minimum_size = Vector2(118, 142)
		grid.add_child(name)
		for rarity in EquipmentData.RARITIES.size():
			var tile := PanelContainer.new()
			var style := StyleBoxFlat.new()
			style.bg_color = Color("1b2933")
			style.border_color = COLORS[rarity].darkened(0.35)
			style.set_border_width_all(2)
			style.set_content_margin_all(5)
			tile.add_theme_stylebox_override("panel", style)
			tile.custom_minimum_size = Vector2(112, 142)
			grid.add_child(tile)
			var icon := TextureRect.new()
			icon.texture = PixelUiIcons.equipment(str(slot), rarity)
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(100, 130)
			tile.add_child(icon)
	DisplayServer.window_set_size(Vector2i(1080, 1920))
	for _i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != Vector2i(1080, 1920):
		failures += 1
		push_error("Invalid equipment rarity overview capture.")
	else:
		var path := OUT + "/equipment_rarity_grid_1080.png"
		if image.save_png(ProjectSettings.globalize_path(path)) == OK:
			print("CAPTURE " + path)
		else:
			failures += 1
			push_error("Failed to save equipment rarity overview.")
	print("EQUIPMENT RARITY CAPTURE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
