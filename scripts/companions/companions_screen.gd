class_name CompanionsScreen
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
	var heading := _panel(Color("79c78b"))
	add_child(heading)
	var head := VBoxContainer.new()
	heading.add_child(head)
	head.add_child(_label("COMPANION HALL", 38, Color("e9c87d")))
	head.add_child(_label("Essence %d  •  Crests %d  •  Gold %d" % [profile.companion_essence, profile.companion_crests, profile.gold], 29, Color("e9e8d7")))
	head.add_child(_label("Summons grant Essence; Legendary+ pulls grant Crests.", 27, Color("a9d6ad")))
	head.add_child(_label("Select an ally, then tap a slot. Tap it again to unequip.", 27, Color("aebdb4")))
	var back := _button("BACK TO SUMMONS")
	back.pressed.connect(on_back)
	head.add_child(back)
	add_child(_label("ACTIVE COMPANIONS  •  4 SLOTS", 32, Color("e9c87d")))
	if profile.companions.is_empty():
		add_child(_label("No companions unlocked yet. Summon companions to add an ally.", 29, Color("aebdb4")))
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	add_child(slots)
	for index in 4:
		var id := profile.equipped_companion_slots[index]
		var button := _button("%d\n%s" % [index + 1, "EMPTY" if id == "" else CompanionData.display_name(id, profile.companions[id])])
		button.custom_minimum_size.y = 110
		button.pressed.connect(_slot_pressed.bind(index))
		slots.add_child(button)
	if selected_id != "" and profile.companions.has(selected_id):
		_build_detail()
	add_child(_label("COMPANION COLLECTION  •  %d / %d" % [profile.companions.size(), CompanionData.COMPANIONS.size()], 32, Color("e9c87d")))
	for id in CompanionData.COMPANIONS:
		var owned := profile.companions.has(id)
		var record: Dictionary = profile.companions.get(id, {})
		var rarity := int(record.get("rarity", 0))
		var grid := get_node_or_null("CompanionCollection") as GridContainer
		if grid == null:
			grid = GridContainer.new()
			grid.name = "CompanionCollection"
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 10)
			grid.add_theme_constant_override("v_separation", 10)
			add_child(grid)
		var card := Button.new()
		card.custom_minimum_size = Vector2(480, 310)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_card(card, EquipmentData.COLORS[rarity] if owned else Color("52605c"), selected_id == id)
		var contents := VBoxContainer.new()
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.alignment = BoxContainer.ALIGNMENT_CENTER
		contents.add_theme_constant_override("separation", 1)
		card.add_child(contents)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(0, 210)
		portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.texture = CompanionPixelArt.frame(id, int(record.get("evolution", 0)), "idle")
		contents.add_child(portrait)
		var name_label := _label(CompanionData.display_name(id, record), 23, EquipmentData.COLORS[rarity] if owned else Color("aebdb4"))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.clip_text = true
		contents.add_child(name_label)
		var level_label := _label(("LV %d  •  ★ %d" % [record["level"], record["stars"]]) if owned else "LOCKED", 19, Color("c2c9bd"))
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		contents.add_child(level_label)
		card.pressed.connect(_select.bind(id))
		grid.add_child(card)

func _build_detail() -> void:
	var record: Dictionary = profile.companions[selected_id]
	var panel := _panel(EquipmentData.COLORS[int(record["rarity"])])
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(144, 144)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.texture = CompanionPixelArt.frame(selected_id, int(record.get("evolution", 0)), "idle")
	box.add_child(portrait)
	box.add_child(_label("SELECTED: %s" % CompanionData.display_name(selected_id, record), 32, Color("e9c87d")))
	box.add_child(_label("Pieces %d  •  %d stars  •  %s" % [record["pieces"], record["stars"], CompanionData.passive_text(selected_id, record)], 28, Color("e9e8d7")))
	var level_cost := CompanionData.level_cost(int(record["level"]))
	var upgrade := _button("LEVEL UP  •  %d GOLD + %d ESSENCE" % [level_cost["gold"], level_cost["essence"]])
	upgrade.disabled = profile.gold < int(level_cost["gold"]) or profile.companion_essence < int(level_cost["essence"]) or int(record["level"]) >= 99
	upgrade.pressed.connect(_level)
	box.add_child(upgrade)
	if int(record["stars"]) < CompanionData.MAX_STARS:
		var pieces := CompanionData.star_cost(int(record["stars"]))
		var star := _button("STAR UP  •  %d/%d PIECES" % [record["pieces"], pieces])
		star.disabled = int(record["pieces"]) < pieces
		star.pressed.connect(_star)
		box.add_child(star)
	if selected_id == "wolf" and int(record["evolution"]) < CompanionData.WOLF_EVOLUTION.size():
		var cost: Dictionary = CompanionData.WOLF_EVOLUTION[int(record["evolution"])]
		var evolve := _button("EVOLVE TO %s  •  LV%d / %d STARS / %d ESSENCE / %d CRESTS" % [CompanionData.WOLF_FORMS[int(record["evolution"]) + 1], cost["level"], cost["stars"], cost["essence"], cost["crests"]])
		evolve.disabled = int(record["level"]) < int(cost["level"]) or int(record["stars"]) < int(cost["stars"]) or profile.companion_essence < int(cost["essence"]) or profile.companion_crests < int(cost["crests"])
		evolve.pressed.connect(_evolve)
		box.add_child(evolve)
	elif selected_id != "wolf":
		box.add_child(_label("Evolution path unlocks later.", 27, Color("aebdb4")))

func _select(id: String) -> void:
	selected_id = id
	refresh()

func _slot_pressed(slot: int) -> void:
	if profile.equipped_companion_slots[slot] == selected_id:
		profile.unequip_companion(slot)
	elif profile.companions.has(selected_id):
		profile.equip_companion(selected_id, slot)
	_changed()

func _level() -> void:
	if profile.level_companion(selected_id):
		_changed()

func _star() -> void:
	if profile.star_companion(selected_id):
		_changed()

func _evolve() -> void:
	if profile.evolve_companion(selected_id):
		_changed()

func _changed() -> void:
	if battle.active:
		battle.companion_runtime.sync(profile)
		battle.refresh_hero_stats()
	refresh()
	if on_change.is_valid():
		on_change.call()

func _panel(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202f39")
	style.border_color = color
	style.set_border_width_all(2)
	style.border_width_bottom = 4
	style.set_corner_radius_all(5)
	style.set_content_margin_all(14)
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

func _style_card(button: Button, border: Color, selected: bool) -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("26353a") if not selected else Color("374640")
		style.border_color = Color("e9c87d") if selected else border
		style.set_border_width_all(3 if selected else 2)
		style.set_corner_radius_all(10)
		style.set_content_margin_all(9)
		button.add_theme_stylebox_override(state, style)
