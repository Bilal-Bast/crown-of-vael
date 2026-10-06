class_name CrownUI
extends RefCounted

const GOLD := Color("ffd166")
const CYAN := Color("55d7ff")
const TEAL := Color("46e0c1")
const VIOLET := Color("b38aff")
const SUCCESS := Color("68e69a")
const DANGER := Color("ff718c")
const TEXT := Color("f3f7ff")
const MUTED := Color("b8cbe2")
const EDGE := Color("5c91c4")
const SURFACE := Color("182a42")
const DEEP := Color("0b1728")

static var _panel_styles: Dictionary = {}
static var _card_styles: Dictionary = {}
static var _health_styles: Dictionary = {}

static func build_theme() -> Theme:
	var shared := Theme.new()
	shared.default_font_size = 24
	shared.set_color("font_color", "Label", TEXT)
	shared.set_color("font_color", "Button", TEXT)
	shared.set_color("font_hover_color", "Button", Color("ffffff"))
	shared.set_color("font_pressed_color", "Button", GOLD)
	shared.set_color("font_disabled_color", "Button", Color("788681"))
	shared.set_color("font_focus_color", "Button", Color("fff0c8"))
	for state in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		shared.set_stylebox(state, "Button", _button_box(EDGE, str(state), false))
	shared.set_stylebox("panel", "PanelContainer", _panel_box(EDGE, false))
	shared.set_stylebox("background", "ProgressBar", _progress_background())
	shared.set_stylebox("fill", "ProgressBar", _progress_fill(GOLD))
	
	_register_button_variant(shared, &"PrimaryActionButton", GOLD)
	_register_button_variant(shared, &"MagicActionButton", VIOLET)
	_register_button_variant(shared, &"TealActionButton", TEAL)
	_register_button_variant(shared, &"DangerActionButton", DANGER)
	_register_button_variant(shared, &"QuietButton", Color("8eb4d4"), true)
	shared.set_type_variation(&"InsetPanel", &"PanelContainer")
	shared.set_stylebox("panel", &"InsetPanel", _panel_box(Color("397daf"), true))
	shared.set_type_variation(&"RewardPanel", &"PanelContainer")
	shared.set_stylebox("panel", &"RewardPanel", _panel_box(GOLD, false, true))
	return shared

static func _register_button_variant(theme: Theme, type_name: StringName, accent: Color, quiet := false) -> void:
	theme.set_type_variation(type_name, &"Button")
	theme.set_color("font_color", type_name, MUTED if quiet else TEXT)
	theme.set_color("font_hover_color", type_name, Color("fff0c8"))
	theme.set_color("font_pressed_color", type_name, Color("fff0c8"))
	theme.set_color("font_disabled_color", type_name, Color("788681"))
	for state in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		theme.set_stylebox(state, type_name, _button_box(accent, str(state), quiet))

static func _button_box(accent: Color, state: String, quiet: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var base_fill := Color("112238", 0.91) if quiet else Color("1d3552", 0.95)
	var accent_fill := accent.darkened(0.78)
	style.bg_color = base_fill.lerp(accent_fill, 0.32) if not quiet else base_fill
	if state == "hover" or state == "focus":
		style.bg_color = Color("284968").lerp(accent.darkened(0.55), 0.34)
	elif state == "pressed":
		style.bg_color = Color("10243a")
	elif state == "disabled":
		style.bg_color = Color("172333")
	style.border_color = Color("35536f") if quiet else accent.darkened(0.32)
	if state == "hover" or state == "focus":
		style.border_color = accent.lightened(0.16)
	if state == "disabled":
		style.border_color = Color("344358")
	style.set_border_width_all(1)
	style.border_width_bottom = 2
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 12 if state == "pressed" else 14
	return style

static func _panel_box(border: Color, inset: bool, reward := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102138", 0.94) if inset else (Color("223955", 0.96) if reward else Color("172941", 0.88))
	style.border_color = border
	style.set_border_width_all(2 if reward else 1)
	style.border_width_bottom = 2
	style.set_corner_radius_all(11)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 11
	style.content_margin_bottom = 13
	style.shadow_color = Color(0.005, 0.02, 0.055, 0.36)
	style.shadow_size = 7 if reward else 4
	style.shadow_offset = Vector2(0, 3)
	return style

static func _progress_background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = DEEP
	style.border_color = Color("464148")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style

static func _progress_fill(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style

static func style_panel(panel: PanelContainer, accent := EDGE, inset := false, reward := false) -> void:
	var key := "%s:%s:%s" % [accent.to_html(false), inset, reward]
	if not _panel_styles.has(key):
		_panel_styles[key] = _panel_box(accent, inset, reward)
	panel.add_theme_stylebox_override("panel", _panel_styles[key])

static func style_ornate_panel(panel: PanelContainer) -> void:
	# The old nine-slice frame was designed for title plaques. Stretching it around
	# variable-height content placed its ornament over labels on compact screens.
	# Keep this compatibility helper while using the same clean panel treatment.
	style_panel(panel, GOLD, false, true)

static func style_card(button: Button, accent: Color, selected: bool, disabled := false) -> void:
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		var key := "%s:%s:%s:%s" % [accent.to_html(false), selected, disabled, state]
		if not _card_styles.has(key):
			var style := StyleBoxFlat.new()
			style.bg_color = Color("1d3653", 0.94) if not disabled else Color("18283a", 0.97)
			if state == &"hover" or state == &"focus":
				style.bg_color = Color("2a4a69")
			elif state == &"pressed":
				style.bg_color = Color("11243a")
			style.border_color = GOLD if selected else accent.darkened(0.16)
			style.set_border_width_all(2 if selected else 1)
			style.border_width_bottom = 3 if selected else 2
			style.set_corner_radius_all(12)
			style.content_margin_left = 12
			style.content_margin_right = 12
			style.content_margin_top = 12
			style.content_margin_bottom = 14
			style.shadow_color = Color(1.0, 0.72, 0.24, 0.18) if selected else Color(0, 0.015, 0.04, 0.27)
			style.shadow_size = 6 if selected else 3
			style.shadow_offset = Vector2(0, 2)
			_card_styles[key] = style
		button.add_theme_stylebox_override(state, _card_styles[key])

static func style_tab(button: Button, selected: bool, accent := GOLD) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, navigation_style(accent, selected, state))
	button.add_theme_color_override("font_color", GOLD if selected else MUTED)
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_disabled_color", Color("788681"))

static func create_collection_card(accent: Color, selected: bool, locked: bool, icon_texture: Texture2D, title: String, status: String, card_size := Vector2(320, 255), icon_height := 165) -> Button:
	var card := Button.new()
	card.custom_minimum_size = card_size
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.clip_contents = true
	style_card(card, accent, selected, locked)
	var contents := VBoxContainer.new()
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.alignment = BoxContainer.ALIGNMENT_CENTER
	contents.add_theme_constant_override("separation", 4)
	card.add_child(contents)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(0, icon_height)
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = icon_texture
	contents.add_child(icon)
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.clip_text = true
	title_label.add_theme_font_size_override("font_size", 23)
	title_label.add_theme_color_override("font_color", Color("9da7a2") if locked else accent)
	contents.add_child(title_label)
	var status_label := Label.new()
	status_label.text = status
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.clip_text = true
	status_label.add_theme_font_size_override("font_size", 19)
	status_label.add_theme_color_override("font_color", Color("aebdb4") if locked else Color("c2c9bd"))
	contents.add_child(status_label)
	return card

static func set_button_role(button: Button, role: StringName = &"PrimaryActionButton") -> void:
	button.theme_type_variation = role

static func health_fill_style(low_health: bool) -> StyleBoxFlat:
	var key := "low" if low_health else "normal"
	if not _health_styles.has(key):
		var style := StyleBoxFlat.new()
		style.bg_color = Color("ff718c") if low_health else Color("55e59a")
		style.set_corner_radius_all(5)
		_health_styles[key] = style
	return _health_styles[key]

static func navigation_style(accent: Color, selected: bool, state := "normal") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("284968") if selected else Color("102138", 0.88)
	if state == "hover" or state == "focus":
		style.bg_color = Color("305675")
	elif state == "pressed":
		style.bg_color = Color("10243a")
	elif state == "disabled":
		style.bg_color = Color("172333")
	style.border_color = accent if selected else Color("42617f")
	if state == "hover" or state == "focus":
		style.border_color = GOLD
	if state == "disabled":
		style.border_color = Color("344358")
	style.set_border_width_all(1)
	style.border_width_bottom = 3 if selected else 2
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	return style

static func apply_screen_scale(root: Control, reduced_effects := false) -> void:
	if root == null or not root.is_inside_tree():
		return
	var compact := DisplayServer.window_get_size().x <= 480
	for item in root.find_children("*", "Control", true, false):
		if item is Label or item is Button:
			if not item.has_meta("crown_base_font_size"):
				item.set_meta("crown_base_font_size", item.get_theme_font_size("font_size"))
			var base_font := int(item.get_meta("crown_base_font_size"))
			var target_font := maxi(base_font, 36) if compact and not bool(item.get_meta("crown_no_compact_font_scaling", false)) else base_font
			if item.get_theme_font_size("font_size") != target_font:
				item.add_theme_font_size_override("font_size", target_font)
		if item is Button:
			item.set_meta("crown_reduced_effects", reduced_effects)
			if not item.has_meta("crown_press_feedback_bound"):
				item.button_down.connect(_button_pressed.bind(item))
				item.button_up.connect(_button_released.bind(item))
				item.set_meta("crown_press_feedback_bound", true)
			if reduced_effects:
				_cancel_button_tween(item)
				item.scale = Vector2.ONE
			if not item.has_meta("crown_base_minimum_size"):
				item.set_meta("crown_base_minimum_size", item.custom_minimum_size)
			var base_minimum: Vector2 = item.get_meta("crown_base_minimum_size")
			var target_minimum := Vector2(base_minimum.x, maxf(base_minimum.y, 132.0)) if compact and not bool(item.get_meta("crown_compact_control", false)) else base_minimum
			if item.custom_minimum_size != target_minimum:
				item.custom_minimum_size = target_minimum

static func _button_pressed(button: Button) -> void:
	if not is_instance_valid(button) or bool(button.get_meta("crown_reduced_effects", false)) or button.disabled:
		return
	_animate_button_scale(button, Vector2(0.96, 0.96), 0.055, Tween.TRANS_CUBIC)

static func _button_released(button: Button) -> void:
	if not is_instance_valid(button) or bool(button.get_meta("crown_reduced_effects", false)):
		return
	_animate_button_scale(button, Vector2.ONE, 0.10, Tween.TRANS_BACK)

static func _animate_button_scale(button: Button, target: Vector2, duration: float, transition: Tween.TransitionType) -> void:
	_cancel_button_tween(button)
	button.pivot_offset = button.size * 0.5
	var tween := button.create_tween()
	tween.tween_property(button, "scale", target, duration).set_trans(transition).set_ease(Tween.EASE_OUT)
	button.set_meta("crown_press_tween", tween)

static func _cancel_button_tween(button: Button) -> void:
	var tween: Variant = button.get_meta("crown_press_tween", null)
	if tween is Tween and tween.is_running():
		tween.kill()
