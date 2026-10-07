extends Control

const SaveDataScript = preload("res://scripts/systems/save_data.gd")
const GAME_SCENE_PATH := "res://scenes/main.tscn"
const DEV_SAVE_PATH := "user://crown_of_vael_screen_gallery.save"
const PREVIEW_TABS := ["Battle", "Heroes", "Equipment", "Skills", "Summon", "Settings"]

var game_viewport: SubViewport
var game_root: Control
var screen_buttons: Dictionary = {}
var active_screen := "Battle"

func _ready() -> void:
	_build_interface()
	_create_game_preview()

func _build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("091320")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.name = "ScreenGalleryMargins"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for pair in [[SIDE_LEFT, "left"], [SIDE_TOP, "top"], [SIDE_RIGHT, "right"], [SIDE_BOTTOM, "bottom"]]:
		margin.add_theme_constant_override("margin_%s" % pair[1], 20)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "ScreenGalleryLayout"
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var heading := Label.new()
	heading.text = "SCREEN GALLERY"
	heading.add_theme_font_size_override("font_size", 38)
	heading.add_theme_color_override("font_color", Color("ffd166"))
	layout.add_child(heading)
	var note := Label.new()
	note.text = "Live previews of the production screens · isolated save: user://crown_of_vael_screen_gallery.save"
	note.add_theme_color_override("font_color", Color("b8cbe2"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(note)

	var screen_grid := GridContainer.new()
	screen_grid.name = "ScreenShortcuts"
	screen_grid.columns = 3
	screen_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen_grid.add_theme_constant_override("h_separation", 8)
	screen_grid.add_theme_constant_override("v_separation", 8)
	layout.add_child(screen_grid)
	for screen_name in PREVIEW_TABS:
		var button := Button.new()
		button.text = screen_name.to_upper()
		button.custom_minimum_size = Vector2(0, 60)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 21)
		button.pressed.connect(_show_screen.bind(screen_name))
		screen_grid.add_child(button)
		screen_buttons[screen_name] = button

	var preview_center := CenterContainer.new()
	preview_center.name = "ProductionScreenPreview"
	preview_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(preview_center)
	var aspect := AspectRatioContainer.new()
	aspect.name = "PortraitPreviewFrame"
	aspect.ratio = 1080.0 / 1920.0
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_center.add_child(aspect)
	var preview_frame := PanelContainer.new()
	preview_frame.name = "PreviewFrame"
	preview_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("172941")
	frame_style.border_color = Color("5c91c4")
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(8)
	preview_frame.add_theme_stylebox_override("panel", frame_style)
	aspect.add_child(preview_frame)
	var preview_margin := MarginContainer.new()
	for edge in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		preview_margin.add_theme_constant_override("margin_%s" % ["left" if edge == SIDE_LEFT else "top" if edge == SIDE_TOP else "right" if edge == SIDE_RIGHT else "bottom"], 2)
	preview_frame.add_child(preview_margin)
	var game_container := SubViewportContainer.new()
	game_container.name = "GamePreviewContainer"
	game_container.stretch = true
	game_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_margin.add_child(game_container)
	game_viewport = SubViewport.new()
	game_viewport.name = "GamePreviewViewport"
	game_viewport.size = Vector2i(1080, 1920)
	game_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	game_container.add_child(game_viewport)

func _create_game_preview() -> void:
	var profile: RefCounted = SaveDataScript.load_from(DEV_SAVE_PATH)
	profile.set("save_path", DEV_SAVE_PATH)
	var tutorial_state: Dictionary = profile.get("tutorial_state")
	tutorial_state["completed"] = true
	tutorial_state["skipped"] = true
	profile.set("tutorial_state", tutorial_state)
	profile.call("save")

	var previous_save_path := OS.get_environment("VAEL_SAVE_PATH")
	OS.set_environment("VAEL_SAVE_PATH", DEV_SAVE_PATH)
	var game_scene := load(GAME_SCENE_PATH) as PackedScene
	if game_scene == null:
		push_error("Screen Gallery could not load %s" % GAME_SCENE_PATH)
		OS.set_environment("VAEL_SAVE_PATH", previous_save_path)
		return
	game_root = game_scene.instantiate() as Control
	game_root.name = "ProductionGamePreview"
	game_viewport.add_child(game_root)
	OS.set_environment("VAEL_SAVE_PATH", previous_save_path)
	_show_screen("Battle")

func _show_screen(screen_name: String) -> void:
	active_screen = screen_name
	for name in screen_buttons:
		var button := screen_buttons[name] as Button
		button.disabled = str(name) == screen_name
	if is_instance_valid(game_root):
		game_root.call("_select_tab", screen_name)
