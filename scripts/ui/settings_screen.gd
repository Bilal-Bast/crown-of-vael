class_name SettingsScreen
extends VBoxContainer

var profile: SaveData
var on_change: Callable

func configure(value: SaveData, changed: Callable) -> void:
	profile = value
	on_change = changed
	refresh()

func refresh() -> void:
	for child in get_children():
		child.queue_free()
	add_child(_label("SETTINGS", 38, Color("e9c87d")))
	add_child(_label("Audio levels apply immediately. Missing audio files remain silent.", 24, Color("aebdb4")))
	for key in ["master", "music", "sfx", "ui"]:
		var row := HBoxContainer.new()
		add_child(row)
		var label := _label(key.to_upper(), 26, Color("e9e8d7"))
		label.custom_minimum_size.x = 150
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = float(profile.audio_settings.get(key, 1.0))
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(_set_volume.bind(key))
		row.add_child(slider)
	var mute := CheckButton.new()
	mute.text = "Mute all audio"
	mute.button_pressed = bool(profile.audio_settings.get("muted", false))
	mute.toggled.connect(_set_mute)
	add_child(mute)
	var reduced := CheckButton.new()
	reduced.text = "Reduced combat effects and screen shake"
	reduced.button_pressed = profile.reduced_effects
	reduced.toggled.connect(_set_reduced)
	add_child(reduced)

func _set_volume(value: float, key: String) -> void:
	profile.audio_settings[key] = value
	profile.save()
	_apply_audio()

func _set_mute(value: bool) -> void:
	profile.audio_settings["muted"] = value
	profile.save()
	_apply_audio()

func _set_reduced(value: bool) -> void:
	profile.reduced_effects = value
	profile.save()
	if on_change.is_valid():
		on_change.call()

func _apply_audio() -> void:
	if not is_inside_tree():
		return
	var audio := get_node_or_null("/root/AudioService")
	if audio != null:
		audio.apply_settings(profile.audio_settings)

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
