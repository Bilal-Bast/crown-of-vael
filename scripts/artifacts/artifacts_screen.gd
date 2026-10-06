class_name ArtifactsScreen
extends VBoxContainer

const CrownUI = preload("res://scripts/ui/crown_ui.gd")

var profile: SaveData
var battle: BattleController
var on_change: Callable
var on_back: Callable
var selected_id := ""

func configure(new_profile: SaveData, new_battle: BattleController, changed: Callable, back: Callable) -> void:
	profile = new_profile
	battle = new_battle
	on_change = changed
	on_back = back
	refresh()

func refresh() -> void:
	if profile == null:
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var heading := _panel(Color("efc36b"))
	CrownUI.style_ornate_panel(heading)
	add_child(heading)
	var head := VBoxContainer.new()
	heading.add_child(head)
	head.add_child(_label("ARTIFACT VAULT", 38, Color("ffd166")))
	head.add_child(_label("Dust %d  •  Gold %d  •  Owned bonuses are always active" % [profile.artifact_dust, profile.gold], 29, Color("f3f7ff")))
	head.add_child(_label("Summons grant Dust and duplicate level progress.", 27, Color("68e69a")))
	head.add_child(_label("Select an owned relic, then tap an active slot.", 27, Color("b8cbe2")))
	var back := _button("BACK TO SUMMONS")
	back.pressed.connect(on_back)
	head.add_child(back)
	add_child(_label("EQUIPPED ARTIFACTS", 32, Color("ffd166")))
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	add_child(slots)
	for index in ArtifactData.FUTURE_SLOTS:
		var id := profile.equipped_artifact_slots[index]
		var short_name := "LOCKED" if index >= profile.artifact_slot_limit() else ("EMPTY" if id == "" else str(id).split("_")[-1].to_upper())
		if index == 2 and profile.artifact_slot_limit() < 3:
			short_name = "FLOOR 20"
		var button := _button("%d\n%s" % [index + 1, short_name])
		if id != "":
			button.icon = PixelUiIcons.artifact(id)
			button.expand_icon = true
			button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.custom_minimum_size.y = 107
		button.disabled = index >= profile.artifact_slot_limit()
		CrownUI.style_tab(button, id != "", Color("d09548"))
		button.pressed.connect(_slot_pressed.bind(index))
		slots.add_child(button)
	if profile.artifact_slot_limit() < 3:
		add_child(_label("Slot 3 unlocks at Tower Floor 20.", 27, Color("d8a399")))
	var count := ArtifactData.set_count("dragon_relics", profile.equipped_artifact_slots)
	var set_panel := _panel(Color("d09548"))
	add_child(set_panel)
	var set_box := VBoxContainer.new()
	set_panel.add_child(set_box)
	set_box.add_child(_label("DRAGON RELICS  •  %d/3 EQUIPPED" % count, 30, Color("ffd166")))
	set_box.add_child(_label("2 pieces: +10%% Crit Damage %s" % ["ACTIVE" if count >= 2 else "LOCKED"], 27, Color("b8cbe2")))
	set_box.add_child(_label("3 pieces: +50%% fire burst damage %s" % ["ACTIVE" if count >= 3 else ("LOCKED UNTIL TOWER 20" if profile.artifact_slot_limit() < 3 else "INACTIVE")], 27, Color("b8cbe2")))
	if selected_id != "" and profile.artifacts.has(selected_id):
		_build_detail()
	add_child(_label("RELIC COLLECTION", 32, Color("ffd166")))
	if profile.artifacts.is_empty():
		add_child(_label("No artifacts discovered yet. Explore modes or summon to find relics.", 29, Color("b8cbe2")))
	var grid := GridContainer.new()
	grid.name = "ArtifactCollection"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	add_child(grid)
	for id in ArtifactData.ARTIFACTS:
		var data: Dictionary = ArtifactData.ARTIFACTS[id]
		var owned := profile.artifacts.has(id)
		var record: Dictionary = profile.artifacts.get(id, {})
		var rarity := int(record.get("rarity", 2))
		var card := Button.new()
		card.custom_minimum_size = Vector2(320, 255)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_card(card, EquipmentData.COLORS[rarity] if owned else Color("52605c"), selected_id == id)
		var contents := VBoxContainer.new()
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.alignment = BoxContainer.ALIGNMENT_CENTER
		contents.add_theme_constant_override("separation", 1)
		card.add_child(contents)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(0, 165)
		icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = PixelUiIcons.artifact(id)
		contents.add_child(icon)
		var title := _label(data["name"], 22, EquipmentData.COLORS[rarity] if owned else Color("9da7a2"))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.clip_text = true
		contents.add_child(title)
		var level_label := _label(("LV %d" % record["level"]) if owned else "LOCKED", 19, Color("c2c9bd"))
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		contents.add_child(level_label)
		card.pressed.connect(_select.bind(id))
		grid.add_child(card)

func _build_detail() -> void:
	var record: Dictionary = profile.artifacts[selected_id]
	var data: Dictionary = ArtifactData.ARTIFACTS[selected_id]
	var panel := _panel(EquipmentData.COLORS[int(record["rarity"])])
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	var relic_icon := TextureRect.new()
	relic_icon.custom_minimum_size = Vector2(96, 96)
	relic_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	relic_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	relic_icon.texture = PixelUiIcons.artifact(selected_id)
	box.add_child(relic_icon)
	box.add_child(_label("SELECTED: %s" % data["name"], 32, Color("ffd166")))
	box.add_child(_label("OWNED BONUS  •  %s" % ArtifactData.owned_text(selected_id, record), 28, Color("68e69a")))
	box.add_child(_label("EQUIPPED EFFECT  •  %s  (power %.2f)" % [data["effect_text"], ArtifactData.effect_value(selected_id, record)], 28, Color("f3f7ff")))
	var cost := ArtifactData.level_cost(int(record["level"]))
	var upgrade := _button("LEVEL UP  •  %d/%d COPIES + %d GOLD + %d DUST" % [record["duplicates"], cost["copies"], cost["gold"], cost["dust"]])
	upgrade.disabled = int(record["duplicates"]) < int(cost["copies"]) or profile.gold < int(cost["gold"]) or profile.artifact_dust < int(cost["dust"]) or int(record["level"]) >= 99
	upgrade.pressed.connect(_level)
	box.add_child(upgrade)

func _select(id: String) -> void:
	selected_id = id
	refresh()

func _slot_pressed(slot: int) -> void:
	if profile.equipped_artifact_slots[slot] == selected_id:
		profile.unequip_artifact(slot)
	elif profile.artifacts.has(selected_id):
		profile.equip_artifact(selected_id, slot)
	_changed()

func _level() -> void:
	if profile.level_artifact(selected_id):
		_changed()

func _changed() -> void:
	if battle.active:
		battle.refresh_hero_stats()
	refresh()
	if on_change.is_valid():
		on_change.call()

func _panel(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	CrownUI.style_panel(panel, color)
	return panel

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 82
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 27)
	CrownUI.set_button_role(button)
	return button

func _style_card(button: Button, border: Color, selected: bool) -> void:
	CrownUI.style_card(button, border, selected)
