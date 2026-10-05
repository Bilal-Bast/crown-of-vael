class_name ArtifactsScreen
extends VBoxContainer

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
	add_child(heading)
	var head := VBoxContainer.new()
	heading.add_child(head)
	head.add_child(_label("ARTIFACT VAULT", 38, Color("e9c87d")))
	head.add_child(_label("Dust %d  •  Gold %d  •  Owned bonuses are always active" % [profile.artifact_dust, profile.gold], 29, Color("e9e8d7")))
	head.add_child(_label("Summons grant Dust and duplicate level progress.", 27, Color("a9d6ad")))
	head.add_child(_label("Select an owned relic, then tap an active slot.", 27, Color("aebdb4")))
	var back := _button("BACK TO SUMMONS")
	back.pressed.connect(on_back)
	head.add_child(back)
	add_child(_label("EQUIPPED ARTIFACTS", 32, Color("e9c87d")))
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
		button.pressed.connect(_slot_pressed.bind(index))
		slots.add_child(button)
	if profile.artifact_slot_limit() < 3:
		add_child(_label("Slot 3 unlocks at Tower Floor 20.", 27, Color("d8a399")))
	var count := ArtifactData.set_count("dragon_relics", profile.equipped_artifact_slots)
	var set_panel := _panel(Color("d09548"))
	add_child(set_panel)
	var set_box := VBoxContainer.new()
	set_panel.add_child(set_box)
	set_box.add_child(_label("DRAGON RELICS  •  %d/3 EQUIPPED" % count, 30, Color("e9c87d")))
	set_box.add_child(_label("2 pieces: +10%% Crit Damage %s" % ["ACTIVE" if count >= 2 else "LOCKED"], 27, Color("aebdb4")))
	set_box.add_child(_label("3 pieces: +50%% fire burst damage %s" % ["ACTIVE" if count >= 3 else ("LOCKED UNTIL TOWER 20" if profile.artifact_slot_limit() < 3 else "INACTIVE")], 27, Color("aebdb4")))
	if selected_id != "" and profile.artifacts.has(selected_id):
		_build_detail()
	add_child(_label("RELIC COLLECTION", 32, Color("e9c87d")))
	if profile.artifacts.is_empty():
		add_child(_label("No artifacts discovered yet. Explore modes or summon to find relics.", 29, Color("aebdb4")))
	for id in ArtifactData.ARTIFACTS:
		var data: Dictionary = ArtifactData.ARTIFACTS[id]
		var owned := profile.artifacts.has(id)
		var record: Dictionary = profile.artifacts.get(id, {})
		var rarity := int(record.get("rarity", 2))
		var panel := _panel(EquipmentData.COLORS[rarity] if owned else Color("52605c"))
		add_child(panel)
		var box := VBoxContainer.new()
		panel.add_child(box)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		box.add_child(row)
		var item_texture := TextureRect.new()
		item_texture.custom_minimum_size = Vector2(72, 72)
		item_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		item_texture.texture = PixelUiIcons.artifact(id)
		row.add_child(item_texture)
		row.add_child(_label("%s  |  %s" % [data["name"], EquipmentData.RARITIES[rarity] if owned else "LOCKED"], 31, EquipmentData.COLORS[rarity] if owned else Color("aebdb4")))
		if owned:
			box.add_child(_label("Level %d  •  Duplicates %d  •  %s" % [record["level"], record["duplicates"], "DRAGON RELICS" if data.has("set") else "NO SET"], 27, Color("e9e8d7")))
			box.add_child(_label("OWNED: %s  •  EQUIPPED: %s" % [ArtifactData.owned_text(id, record), data["effect_text"]], 27, Color("a9d6ad")))
			var select := _button("SELECT" if selected_id != id else "SELECTED")
			select.disabled = selected_id == id
			select.pressed.connect(_select.bind(id))
			box.add_child(select)
		else:
			box.add_child(_label("Summon a copy to unlock its owned bonus.", 27, Color("aebdb4")))

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
	box.add_child(_label("SELECTED: %s" % data["name"], 32, Color("e9c87d")))
	box.add_child(_label("OWNED BONUS  •  %s" % ArtifactData.owned_text(selected_id, record), 28, Color("a9d6ad")))
	box.add_child(_label("EQUIPPED EFFECT  •  %s  (power %.2f)" % [data["effect_text"], ArtifactData.effect_value(selected_id, record)], 28, Color("e9e8d7")))
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
	var style := StyleBoxFlat.new()
	style.bg_color = Color("253739")
	style.border_color = color
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
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
	return button
