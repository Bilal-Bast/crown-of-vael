class_name SkillsScreen
extends VBoxContainer

const CrownUI = preload("res://scripts/ui/crown_ui.gd")

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
	CrownUI.style_ornate_panel(intro)
	add_child(intro)
	var intro_box := VBoxContainer.new()
	intro.add_child(intro_box)
	intro_box.add_child(_label("SKILL GRIMOIRE", 36, Color("ffd166")))
	intro_box.add_child(_label("Select an owned skill, then tap a slot. Tap it again to unequip.", 29, Color("b8cbe2")))
	var selected_name := str(SkillData.SKILLS[selected_id]["name"]) if SkillData.SKILLS.has(selected_id) else "None"
	intro_box.add_child(_label("SELECTED: %s" % selected_name, 30, Color("68e69a")))
	add_child(_label("ACTIVE SKILLS", 33, Color("ffd166")))
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
		CrownUI.style_tab(button, id != "", Color("b38aff"))
		button.pressed.connect(_slot_pressed.bind(index))
		slots.add_child(button)
	var ultimate := _panel()
	add_child(ultimate)
	ultimate.add_child(_label("ULTIMATE SLOT  •  LOCKED  •  Unlocks later", 29, Color("b8cbe2")))
	if SkillData.SKILLS.has(selected_id):
		_build_selected_detail()
	add_child(_label("SKILL COLLECTION  •  %d / %d" % [profile.skills.size(), SkillData.SKILLS.size()], 33, Color("ffd166")))
	var grid := GridContainer.new()
	grid.name = "SkillCollection"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	add_child(grid)
	for id in SkillData.SKILLS:
		var data: Dictionary = SkillData.SKILLS[id]
		var owned := profile.skills.has(id)
		var record: Dictionary = profile.skills.get(id, {})
		var rarity := int(record.get("rarity", data["rarity"]))
		var status: String = "LEVEL %d | %s" % [int(record.get("level", 1)), EquipmentData.RARITIES[rarity]] if owned else "LOCKED | " + EquipmentData.RARITIES[rarity]
		var button := CrownUI.create_collection_card(EquipmentData.COLORS[rarity], selected_id == id, not owned, PixelUiIcons.skill(id), str(data["name"]), status, Vector2(320, 255), 165)
		button.pressed.connect(_select.bind(id))
		grid.add_child(button)

func _build_selected_detail() -> void:
	var data: Dictionary = SkillData.SKILLS[selected_id]
	var owned := profile.skills.has(selected_id)
	var record: Dictionary = profile.skills.get(selected_id, {})
	var rarity := int(record.get("rarity", data["rarity"]))
	var panel := _panel(EquipmentData.COLORS[rarity])
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(144, 144)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = PixelUiIcons.skill(selected_id)
	row.add_child(icon)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail)
	detail.add_child(_label(data["name"], 33, EquipmentData.COLORS[rarity]))
	detail.add_child(_label(("LEVEL %d  •  %.0fS COOLDOWN" % [record["level"], data["cooldown"]]) if owned else ("LOCKED  •  %.0fS COOLDOWN" % data["cooldown"]), 25, Color("f3f7ff")))
	detail.add_child(_label("%s  •  %s" % [data["description"], SkillData.effect_text(selected_id, int(record.get("level", 1)))], 24, Color("b8cbe2")))
	if owned:
		detail.add_child(_label("COPIES %d / %d  •  NEXT: %s" % [record["duplicates"], SkillData.copies_to_level(int(record["level"])), SkillData.effect_text(selected_id, int(record["level"]) + 1)], 23, Color("68e69a")))
	else:
		detail.add_child(_label("Summon a copy to unlock this skill.", 24, Color("d8a399")))

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
	CrownUI.style_panel(panel, border)
	return panel

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
