class_name SkillsScreen
extends VBoxContainer

var profile: SaveData
var battle: BattleController
var on_change: Callable
var selected_id := "shield_bash"

func configure(new_profile: SaveData, new_battle: BattleController, changed: Callable) -> void:
	profile = new_profile
	battle = new_battle
	on_change = changed
	refresh()

func refresh() -> void:
	if profile == null:
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var intro := _panel()
	add_child(intro)
	var intro_box := VBoxContainer.new()
	intro.add_child(intro_box)
	intro_box.add_child(_label("SKILL GRIMOIRE", 36, Color("e9c87d")))
	intro_box.add_child(_label("Select an owned skill, then tap a slot. Tap it again to unequip.", 29, Color("aebdb4")))
	var selected_name := str(SkillData.SKILLS[selected_id]["name"]) if SkillData.SKILLS.has(selected_id) else "None"
	intro_box.add_child(_label("SELECTED: %s" % selected_name, 30, Color("a9d6ad")))
	add_child(_label("ACTIVE SKILLS", 33, Color("e9c87d")))
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	add_child(slots)
	for index in 4:
		var id := profile.equipped_skill_slots[index]
		var button := Button.new()
		button.text = "%d\n%s" % [index + 1, "EMPTY" if id == "" else SkillData.SKILLS[id]["name"]]
		if id != "":
			button.icon = PixelUiIcons.skill(id)
			button.expand_icon = true
			button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.custom_minimum_size.y = 118
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 25)
		button.pressed.connect(_slot_pressed.bind(index))
		slots.add_child(button)
	var ultimate := _panel()
	add_child(ultimate)
	ultimate.add_child(_label("ULTIMATE SLOT  •  LOCKED  •  Unlocks later", 29, Color("aebdb4")))
	add_child(_label("SKILL INVENTORY", 33, Color("e9c87d")))
	for id in SkillData.SKILLS:
		var data: Dictionary = SkillData.SKILLS[id]
		var owned := profile.skills.has(id)
		var record: Dictionary = profile.skills.get(id, {})
		var rarity := int(record.get("rarity", data["rarity"]))
		var card := _panel(EquipmentData.COLORS[rarity])
		add_child(card)
		var box := VBoxContainer.new()
		card.add_child(box)
		var title_row := HBoxContainer.new()
		title_row.add_theme_constant_override("separation", 12)
		box.add_child(title_row)
		var icon := TextureRect.new()
		icon.texture = PixelUiIcons.skill(id)
		icon.custom_minimum_size = Vector2(72, 72)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		title_row.add_child(icon)
		title_row.add_child(_label("%s  |  %s" % [data["name"], EquipmentData.RARITIES[rarity]], 31, EquipmentData.COLORS[rarity]))
		box.add_child(_label("%s  •  %.0fs cooldown" % ["Level %d" % record["level"] if owned else "LOCKED", data["cooldown"]], 28, Color("e9e8d7")))
		box.add_child(_label("%s  •  %s" % [data["description"], SkillData.effect_text(id, int(record.get("level", 1)))], 27, Color("aebdb4")))
		if owned:
			var level := int(record["level"])
			box.add_child(_label("Copies %d/%d  •  Next: %s" % [record["duplicates"], SkillData.copies_to_level(level), SkillData.effect_text(id, level + 1)], 26, Color("a9d6ad")))
			var button := Button.new()
			button.text = "SELECT" if selected_id != id else "SELECTED"
			button.custom_minimum_size.y = 75
			button.add_theme_font_size_override("font_size", 27)
			button.disabled = selected_id == id
			button.pressed.connect(_select.bind(id))
			box.add_child(button)
		else:
			box.add_child(_label("Summon a copy to unlock.", 27, Color("d8a399")))

func _select(id: String) -> void:
	selected_id = id
	refresh()

func _slot_pressed(index: int) -> void:
	if profile.equipped_skill_slots[index] == selected_id:
		profile.unequip_skill(index)
	elif profile.skills.has(selected_id):
		profile.equip_skill(selected_id, index)
	if battle.active:
		battle.skill_runtime.sync(profile)
	refresh()
	if on_change.is_valid():
		on_change.call()

func _panel(border: Color = Color("7b7159")) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("253739")
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(11)
	style.set_content_margin_all(13)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
