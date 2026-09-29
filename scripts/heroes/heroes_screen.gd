class_name HeroesScreen
extends VBoxContainer

var profile: SaveData
var battle: BattleController
var progress: HeroProgress
var on_change: Callable
var on_retreat: Callable
var selected_id := "knight"
var view := "roster"
var evolution_result := {}
var pending_conversion := 0
var preview_evolution := -1

func configure(value: SaveData, live_battle: BattleController, changed: Callable, retreat: Callable) -> void:
	profile = value
	battle = live_battle
	progress = HeroProgress.new(profile)
	on_change = changed
	on_retreat = retreat
	selected_id = profile.selected_hero_id
	refresh()

func refresh() -> void:
	if profile == null:
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if view == "evolution_result":
		_build_evolution_result()
		return
	_header()
	if view == "detail":
		_build_detail()
	else:
		_build_roster()

func _header() -> void:
	add_child(_label("HEROES  •  SHARED LEVEL %d" % profile.level, 37, Color("e9c87d")))
	add_child(_label("EXP %d/%d  •  Gold %d  •  Crests %d  •  Generic Pieces %d" % [profile.exp, GameData.exp_to_next(profile.level), profile.gold, profile.evolution_crests, profile.hero_pieces], 27, Color("e9e8d7")))
	add_child(_label("Gear, skills, companions, artifacts, and Gold upgrades are shared.", 27, Color("aebdb4")))
	if battle.active:
		var retreat := _button("RETREAT TO SWITCH HERO  •  ENDS CURRENT FIGHT")
		retreat.pressed.connect(on_retreat)
		add_child(retreat)

func _build_roster() -> void:
	add_child(_label("HERO ROSTER", 32, Color("e9c87d")))
	for id in HeroData.HEROES:
		var data: Dictionary = HeroData.HEROES[id]
		var record: Dictionary = profile.heroes[id]
		var owned := bool(record["unlocked"])
		var card_border: Color = HeroArtService.frame_color(int(record["evolution"])) if id == "knight" and owned else (EquipmentData.COLORS[int(data["rarity"])] if owned else Color("586462"))
		var panel := _panel(card_border)
		add_child(panel)
		var box := VBoxContainer.new()
		panel.add_child(box)
		box.add_child(_label("%s  •  %s  •  %s" % [HeroData.title(id, record).to_upper(), EquipmentData.RARITIES[int(data["rarity"])], "SELECTED" if id == profile.selected_hero_id else ("OWNED" if owned else "LOCKED")], 31, EquipmentData.COLORS[int(data["rarity"])]))
		box.add_child(_label("%s  •  %s" % [data["role"], HeroData.element(id, record)], 27, Color("e9e8d7")))
		box.add_child(_label("Stars %d/5  •  Pieces %d%s" % [record["stars"], record["pieces"], " / %d to unlock" % data["unlock"] if not owned else ""], 27, Color("a9d6ad")))
		var button := _button("VIEW HERO")
		button.pressed.connect(_open_detail.bind(id))
		box.add_child(button)
	add_child(_label("MILESTONES", 32, Color("e9c87d")))
	for key in HeroData.MILESTONES:
		var reward: Dictionary = HeroData.MILESTONES[key]
		add_child(_label("%s  •  %s  •  %d Gems + %d Crests + %d Pieces" % [reward["name"], "CLAIMED" if profile.hero_milestones.has(key) else "LOCKED", reward["gems"], reward["crests"], reward["pieces"]], 26, Color("a9d6ad") if profile.hero_milestones.has(key) else Color("aebdb4")))

func _build_detail() -> void:
	var data: Dictionary = HeroData.HEROES[selected_id]
	var record: Dictionary = profile.heroes[selected_id]
	var owned := bool(record["unlocked"])
	var back := _button("BACK TO HERO ROSTER")
	back.pressed.connect(_back)
	add_child(back)
	var detail_border: Color = HeroArtService.frame_color(int(record["evolution"])) if selected_id == "knight" and owned else (EquipmentData.COLORS[int(data["rarity"])] if owned else Color("586462"))
	var panel := _panel(detail_border)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	var portrait := HeroPortrait.new()
	portrait.hero_id = selected_id
	portrait.evolution = int(record["evolution"])
	portrait.custom_minimum_size = Vector2(205, 245)
	row.add_child(portrait)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label(HeroData.title(selected_id, record).to_upper(), 35, EquipmentData.COLORS[int(data["rarity"])]))
	copy.add_child(_label("%s  •  %s" % [EquipmentData.RARITIES[int(data["rarity"])], HeroData.element(selected_id, record)], 29, Color("e9e8d7")))
	copy.add_child(_label("%s  •  %s" % [data["role"], "SELECTED" if selected_id == profile.selected_hero_id else ("OWNED" if owned else "LOCKED")], 27, Color("aebdb4")))
	copy.add_child(_label("Level %d shared  •  Stars %d/5" % [profile.level, record["stars"]], 27, Color("a9d6ad")))
	box.add_child(_label("BASE STYLE  •  HP %.0f%%  ATK %.0f%%  ARMOR %.0f%%  SPEED %.0f%%" % [float(data["base"]["hp"]) * 100.0, float(data["base"]["atk"]) * 100.0, float(data["base"]["armor"]) * 100.0, float(data["base"]["speed"]) * 100.0], 27, Color("e9e8d7")))
	box.add_child(_label("ACTIVE: %s" % HeroData.passive_text(selected_id, record, true), 28, Color("e9c87d")))
	box.add_child(_label("OWNED: %s" % HeroData.passive_text(selected_id, record, false), 28, Color("a9d6ad")))
	box.add_child(_label("Pieces %d  •  Evolution %d/4" % [record["pieces"], record["evolution"]], 27, Color("e9e8d7")))
	if owned:
		var select := _button("CURRENT HERO" if selected_id == profile.selected_hero_id else "SELECT HERO")
		select.disabled = battle.active or selected_id == profile.selected_hero_id
		select.pressed.connect(_select_hero)
		box.add_child(select)
		var star_cost := HeroData.star_cost(int(record["stars"]))
		var star := _button("STAR UP  •  %d/%d PIECES" % [record["pieces"], star_cost])
		star.disabled = int(record["stars"]) >= HeroData.MAX_STARS or int(record["pieces"]) < star_cost
		star.pressed.connect(_star_up)
		box.add_child(star)
	else:
		var unlock_cost := int(data["unlock"])
		var unlock := _button("UNLOCK  •  %d/%d %s PIECES" % [record["pieces"], unlock_cost, str(data["name"]).to_upper()])
		unlock.disabled = int(record["pieces"]) < unlock_cost
		unlock.pressed.connect(_unlock)
		box.add_child(unlock)
	_build_path(data, record)
	if selected_id == "knight":
		_build_form_preview(record)
	if selected_id != "knight":
		_build_conversion(record)

func _build_form_preview(record: Dictionary) -> void:
	add_child(_label("FORM PREVIEW  •  VISUAL ONLY", 30, Color("e9c87d")))
	var stage := int(record["evolution"]) if preview_evolution < 0 else preview_evolution
	var row := GridContainer.new()
	row.columns = 3
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(row)
	for index in HeroArtService.FORMS.size():
		var button := _button(["SQUIRE", "KNIGHT", "ROYAL KNIGHT", "PALADIN", "DIVINE"][index])
		button.custom_minimum_size = Vector2(0, 48)
		button.add_theme_font_size_override("font_size", 15)
		button.modulate = HeroArtService.frame_color(index)
		button.pressed.connect(_preview_form.bind(index))
		row.add_child(button)
	var preview_row := VBoxContainer.new()
	preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(preview_row)
	var preview := HeroPortrait.new()
	preview.hero_id = "knight"
	preview.evolution = stage
	preview.locked_preview = stage > int(record["evolution"])
	preview.custom_minimum_size = Vector2(155, 180)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_row.add_child(preview)
	var preview_status := _label("%s  •  %s" % [HeroArtService.TITLES[stage].to_upper(), "LOCKED" if stage > int(record["evolution"]) else "AVAILABLE"], 24, HeroArtService.frame_color(stage))
	preview_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_row.add_child(preview_status)

func _preview_form(stage: int) -> void:
	preview_evolution = stage
	refresh()

func _build_path(data: Dictionary, record: Dictionary) -> void:
	add_child(_label("EVOLUTION PATH", 32, Color("e9c87d")))
	var path: Array = data["path"]
	for stage in path.size():
		var status := "CURRENT" if stage == int(record["evolution"]) else ("COMPLETE" if stage < int(record["evolution"]) else "LOCKED")
		add_child(_label("%d. %s  •  %s" % [stage + 1, str(path[stage]).to_upper(), status], 29, Color("a9d6ad") if stage == int(record["evolution"]) else Color("aebdb4")))
	var cost := HeroData.evolution_cost(selected_id, int(record["evolution"]))
	if not cost.is_empty():
		add_child(_label("Next: Level %d  •  %d Crests  •  %d Gold" % [cost["level"], cost["crests"], cost["gold"]], 29, Color("e9e8d7")))
		var evolve := _button("EVOLVE HERO")
		evolve.disabled = battle.active or not progress.can_evolve(selected_id)
		evolve.pressed.connect(_evolve)
		add_child(evolve)
	elif int(record["evolution"]) < path.size() - 1:
		add_child(_label("Future evolution implementation", 28, Color("d8a399")))

func _build_conversion(record: Dictionary) -> void:
	add_child(_label("CONVERT GENERIC HERO PIECES", 32, Color("e9c87d")))
	add_child(_label("%d Generic Pieces → 1 %s Piece" % [HeroData.CONVERSION_RATE, HeroData.HEROES[selected_id]["name"]], 28, Color("e9e8d7")))
	if pending_conversion > 0:
		add_child(_label("Confirm conversion: %d Generic → %d %s Pieces?" % [pending_conversion * HeroData.CONVERSION_RATE, pending_conversion, HeroData.HEROES[selected_id]["name"]], 28, Color("e9c87d")))
		var confirm := _button("CONFIRM CONVERSION")
		confirm.pressed.connect(_confirm_conversion)
		add_child(confirm)
		var cancel := _button("CANCEL")
		cancel.pressed.connect(_cancel_conversion)
		add_child(cancel)
	else:
		for count in [1, 10, 50]:
			var button := _button("CONVERT %d  •  COST %d GENERIC" % [count, count * HeroData.CONVERSION_RATE])
			button.disabled = profile.hero_pieces < count * HeroData.CONVERSION_RATE
			button.pressed.connect(_request_conversion.bind(count))
			add_child(button)

func _build_evolution_result() -> void:
	add_child(_label("HERO EVOLVED", 43, Color("f9e9a5")))
	var evolution_row := HBoxContainer.new()
	evolution_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(evolution_row)
	var old_portrait := HeroPortrait.new()
	old_portrait.hero_id = selected_id
	old_portrait.evolution = maxi(0, int(profile.heroes[selected_id]["evolution"]) - 1)
	old_portrait.custom_minimum_size = Vector2(220, 270)
	evolution_row.add_child(old_portrait)
	var new_portrait := HeroPortrait.new()
	new_portrait.hero_id = selected_id
	new_portrait.evolution = int(profile.heroes[selected_id]["evolution"])
	new_portrait.custom_minimum_size = Vector2(260, 320)
	evolution_row.add_child(new_portrait)
	new_portrait.modulate.a = 0.35
	new_portrait.scale = Vector2(0.94, 0.94)
	var reveal := create_tween()
	reveal.tween_property(new_portrait, "modulate:a", 1.0, 0.45)
	reveal.parallel().tween_property(new_portrait, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	add_child(_label("%s  →  %s" % [evolution_result["previous"], evolution_result["next"]], 37, Color("e9c87d")))
	add_child(_label("Element: %s  •  New title earned" % evolution_result["element"], 29, Color("a9d6ad")))
	var before: Dictionary = evolution_result.get("before_stats", {})
	var after: Dictionary = evolution_result.get("after_stats", {})
	if not before.is_empty() and not after.is_empty():
		add_child(_label("HP %.0f → %.0f  •  ATK %.0f → %.0f  •  Armor %.0f → %.0f" % [before["hp"], after["hp"], before["atk"], after["atk"], before["armor"], after["armor"]], 29, Color("e9e8d7")))
	add_child(_label("Active passive improved: %s" % HeroData.passive_text(selected_id, profile.heroes[selected_id], true), 29, Color("e9e8d7")))
	var continue_button := _button("SKIP / CONTINUE")
	continue_button.pressed.connect(_continue_evolution)
	add_child(continue_button)

func _open_detail(id: String) -> void:
	selected_id = id
	view = "detail"
	pending_conversion = 0
	refresh()

func _back() -> void:
	view = "roster"
	pending_conversion = 0
	refresh()

func _select_hero() -> void:
	if progress.select(selected_id, battle.active):
		_changed()

func _unlock() -> void:
	if progress.unlock(selected_id):
		_changed()

func _star_up() -> void:
	if progress.star_up(selected_id):
		_changed()

func _evolve() -> void:
	evolution_result = progress.evolve(selected_id)
	if not evolution_result.is_empty():
		view = "evolution_result"
		_changed()

func _continue_evolution() -> void:
	view = "detail"
	refresh()

func _request_conversion(count: int) -> void:
	pending_conversion = count
	refresh()

func _cancel_conversion() -> void:
	pending_conversion = 0
	refresh()

func _confirm_conversion() -> void:
	if progress.convert(selected_id, pending_conversion):
		pending_conversion = 0
		_changed()

func _changed() -> void:
	refresh()
	if on_change.is_valid():
		on_change.call()

func _panel(border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("253739")
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(11)
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
	button.custom_minimum_size.y = 80
	button.add_theme_font_size_override("font_size", 27)
	return button
