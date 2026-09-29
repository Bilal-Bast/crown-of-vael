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
	add_child(_label("COMPANION ROSTER", 32, Color("e9c87d")))
	for id in CompanionData.COMPANIONS:
		var owned := profile.companions.has(id)
		var record: Dictionary = profile.companions.get(id, {})
		var rarity := int(record.get("rarity", 0))
		var card := _panel(EquipmentData.COLORS[rarity] if owned else Color("52605c"))
		add_child(card)
		var box := VBoxContainer.new()
		card.add_child(box)
		box.add_child(_label("%s  %s  •  %s" % [CompanionData.COMPANIONS[id]["icon"], CompanionData.display_name(id, record), EquipmentData.RARITIES[rarity] if owned else "LOCKED"], 31, EquipmentData.COLORS[rarity] if owned else Color("aebdb4")))
		if owned:
			box.add_child(_label("Level %d  •  %d stars  •  Evolution %d" % [record["level"], record["stars"], record["evolution"]], 28, Color("e9e8d7")))
			box.add_child(_label("ATK %.1f  •  %.2f attacks/s  •  %s" % [CompanionData.attack(id, record), CompanionData.attack_speed(id, record), CompanionData.passive_text(id, record)], 27, Color("a9d6ad")))
			var select := _button("SELECT" if selected_id != id else "SELECTED")
			select.disabled = selected_id == id
			select.pressed.connect(_select.bind(id))
			box.add_child(select)
		else:
			box.add_child(_label("Summon a copy to unlock. Evolution path locked." if id != "wolf" else "Summon a copy to unlock the Wolf evolution line.", 27, Color("aebdb4")))

func _build_detail() -> void:
	var record: Dictionary = profile.companions[selected_id]
	var panel := _panel(EquipmentData.COLORS[int(record["rarity"])])
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
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
