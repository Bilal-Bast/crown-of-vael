extends Control

const BattleScript = preload("res://scripts/battle_controller.gd")
const BattlefieldScript = preload("res://scripts/battlefield.gd")
const SkillBadgeScript = preload("res://scripts/skill_badge.gd")
const HeroPortraitScript = preload("res://scripts/hero_portrait.gd")

const INK := Color("172425")
const PANEL := Color("253739")
const EDGE := Color("7b7159")
const GOLD := Color("e9c87d")
const PALE := Color("e9e8d7")
const MUTED := Color("aebdb4")

var profile: SaveData
var battle: BattleController
var battlefield: Battlefield
var skill_badge: SkillBadge
var battle_area: VBoxContainer
var placeholder_area: PanelContainer
var placeholder_title: Label
var heroes_area: ScrollContainer
var equipment_area: ScrollContainer
var heroes_content: VBoxContainer
var equipment_content: VBoxContainer
var heroes_exp_text: Label
var heroes_exp_bar: ProgressBar
var heroes_level_text: Label
var selected_item_id := ""
var stage_text: Label
var region_text: Label
var wave_text: Label
var boss_text: Label
var gold_text: Label
var gems_text: Label
var power_text: Label
var road_text: Label
var stage_markers: Array[ColorRect] = []
var hero_level_text: Label
var hero_hp_text: Label
var hero_stats_text: Label
var exp_bar: ProgressBar
var message_text: Label
var tutorial_text: Label
var action_button: Button
var upgrade_buttons: Dictionary = {}
var nav_buttons: Dictionary = {}
var selected_tab := "Battle"
var transition_id := 0

func _ready() -> void:
	profile = SaveData.load_profile()
	battle = BattleScript.new()
	add_child(battle)
	battle.changed.connect(_refresh_ui)
	battle.message.connect(_show_message)
	battle.stage_cleared.connect(_on_stage_cleared)
	battle.battle_lost.connect(_on_battle_lost)
	battle.equipment_dropped.connect(_on_equipment_dropped)
	battle.hero_leveled.connect(_on_hero_leveled)
	_build_ui()
	if profile.campaign_complete:
		_show_message("Greenvale Outskirts cleared. More adventures are coming.")
		_refresh_ui()
	elif profile.stage == 10 and profile.boss_retry_required:
		_show_message("The Warlord awaits. Tap Retry Boss to begin.")
		_refresh_ui()
	else:
		battle.start(profile)

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = INK
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_right = -24
	root.offset_top = 22
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 13)
	add_child(root)
	_build_top_bar(root)
	_build_stage_card(root)

	battle_area = VBoxContainer.new()
	battle_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_area.add_theme_constant_override("separation", 12)
	root.add_child(battle_area)
	_build_battle_area()

	placeholder_area = _panel()
	placeholder_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	placeholder_area.visible = false
	root.add_child(placeholder_area)
	var placeholder_box := VBoxContainer.new()
	placeholder_box.alignment = BoxContainer.ALIGNMENT_CENTER
	placeholder_box.add_theme_constant_override("separation", 22)
	placeholder_area.add_child(placeholder_box)
	placeholder_title = _label("", 48, GOLD)
	placeholder_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_box.add_child(placeholder_title)
	var unlock_note := _label("This feature will unlock in a future update.", 30, MUTED)
	unlock_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placeholder_box.add_child(unlock_note)
	heroes_area = _screen_scroll(root)
	heroes_content = _screen_content(heroes_area)
	equipment_area = _screen_scroll(root)
	equipment_content = _screen_content(equipment_area)
	_build_navigation(root)
	_refresh_progression_screens()

func _screen_scroll(root: VBoxContainer) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.visible = false
	root.add_child(scroll)
	return scroll

func _screen_content(scroll: ScrollContainer) -> VBoxContainer:
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	return content

func _build_top_bar(root: VBoxContainer) -> void:
	var panel := _panel()
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	var title := _label("CROWN OF VAEL", 43, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 16)
	box.add_child(metrics)
	gold_text = _metric(metrics, "GOLD", GOLD)
	gems_text = _metric(metrics, "GEMS", Color("a5dded"))
	power_text = _metric(metrics, "POWER", Color("d9e9ca"))

func _metric(parent: HBoxContainer, heading: String, value_color: Color) -> Label:
	var cell := VBoxContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(cell)
	var caption := _label(heading, 25, MUTED)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(caption)
	var value := _label("0", 36, value_color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(value)
	return value

func _build_stage_card(root: VBoxContainer) -> void:
	var panel := _panel()
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	var heading := HBoxContainer.new()
	box.add_child(heading)
	stage_text = _label("", 40, PALE)
	stage_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(stage_text)
	boss_text = _label("", 34, Color("ff9f84"))
	heading.add_child(boss_text)
	region_text = _label(GameData.REGION, 30, Color("a9d6ad"))
	box.add_child(region_text)
	wave_text = _label("", 29, MUTED)
	box.add_child(wave_text)
	var road_row := HBoxContainer.new()
	box.add_child(road_row)
	road_text = _label("", 25, GOLD)
	road_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	road_row.add_child(road_text)
	road_row.add_child(_label("WARLORD 1-10", 25, Color("d8a399")))
	var track := HBoxContainer.new()
	track.add_theme_constant_override("separation", 6)
	box.add_child(track)
	for i in 10:
		var marker := ColorRect.new()
		marker.color = Color("52605c")
		marker.custom_minimum_size.y = 17
		marker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		track.add_child(marker)
		stage_markers.append(marker)

func _build_battle_area() -> void:
	battlefield = BattlefieldScript.new()
	battlefield.custom_minimum_size.y = 390
	battlefield.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battlefield.set_battle(battle)
	battle_area.add_child(battlefield)

	var skill_panel := _panel()
	battle_area.add_child(skill_panel)
	var skill_row := HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", 17)
	skill_panel.add_child(skill_row)
	skill_badge = SkillBadgeScript.new()
	skill_badge.custom_minimum_size = Vector2(120, 112)
	skill_badge.battle = battle
	skill_row.add_child(skill_badge)
	var skill_copy := VBoxContainer.new()
	skill_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_row.add_child(skill_copy)
	skill_copy.add_child(_label("SHIELD BASH", 30, GOLD))
	skill_copy.add_child(_label("Auto cast every 8s | Heavy hit + stun", 24, MUTED))
	tutorial_text = _label("AUTO COMBAT  |  Enemies drop Gold + EXP. Upgrade below; stages advance on their own.", 24, Color("a9d6ad"))
	tutorial_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_copy.add_child(tutorial_text)

	var hero_panel := _panel()
	battle_area.add_child(hero_panel)
	var hero_box := VBoxContainer.new()
	hero_box.add_theme_constant_override("separation", 5)
	hero_panel.add_child(hero_box)
	var hero_heading := HBoxContainer.new()
	hero_box.add_child(hero_heading)
	hero_level_text = _label("", 31, PALE)
	hero_level_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_heading.add_child(hero_level_text)
	hero_hp_text = _label("", 29, Color("9ee5aa"))
	hero_heading.add_child(hero_hp_text)
	hero_stats_text = _label("", 27, MUTED)
	hero_box.add_child(hero_stats_text)
	exp_bar = ProgressBar.new()
	exp_bar.custom_minimum_size.y = 13
	exp_bar.show_percentage = false
	hero_box.add_child(exp_bar)
	message_text = _label("", 25, Color("a6dee2"))
	message_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_box.add_child(message_text)
	action_button = Button.new()
	action_button.text = "RETRY BOSS"
	action_button.custom_minimum_size.y = 66
	action_button.add_theme_font_size_override("font_size", 30)
	action_button.pressed.connect(_on_action_pressed)
	hero_box.add_child(action_button)

	var upgrade_panel := _panel()
	battle_area.add_child(upgrade_panel)
	var upgrade_box := VBoxContainer.new()
	upgrade_box.add_theme_constant_override("separation", 8)
	upgrade_panel.add_child(upgrade_box)
	upgrade_box.add_child(_label("SPEND GOLD TO GROW STRONGER", 27, GOLD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	upgrade_box.add_child(row)
	for stat in ["atk", "hp", "armor"]:
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 100
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(_buy_upgrade.bind(stat))
		row.add_child(button)
		upgrade_buttons[stat] = button

func _build_navigation(root: VBoxContainer) -> void:
	var panel := _panel()
	root.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	for tab_name in ["Battle", "Heroes", "Equipment", "Skills", "Summon"]:
		var button := Button.new()
		button.text = tab_name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 120
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(_select_tab.bind(tab_name))
		row.add_child(button)
		nav_buttons[tab_name] = button
	_update_navigation()

func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(13)
	style.content_margin_left = 19
	style.content_margin_right = 19
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _refresh_ui() -> void:
	if stage_text == null:
		return
	var stats := GameData.hero_stats(profile.level, profile.upgrades, profile.gear_stats())
	gold_text.text = str(profile.gold)
	gems_text.text = str(profile.gems)
	power_text.text = str(GameData.hero_power(stats))
	stage_text.text = "EASY  %d-%d" % [1, profile.stage]
	road_text.text = "BOSS ROAD  %d/10" % profile.stage
	for i in stage_markers.size():
		stage_markers[i].color = (Color("d48463") if i == 9 else GOLD) if i < profile.stage else Color("52605c")
	if profile.campaign_complete:
		wave_text.text = "Region complete"
	elif profile.stage == 10:
		wave_text.text = "Boss encounter | Goblin Warlord"
	else:
		wave_text.text = "Wave %d/3  |  %d enemies remaining" % [battle.wave, _living_enemies()]
	boss_text.visible = profile.stage == 10 and battle.active
	boss_text.text = "00:%02d" % ceili(battle.boss_time)
	var hp := battle.hero_hp if battle.active else float(stats["hp"])
	hero_level_text.text = "SQUIRE  |  LEVEL %d" % profile.level
	hero_hp_text.text = "HP %d/%d" % [ceili(hp), roundi(float(stats["hp"]))]
	hero_stats_text.text = "ATK %d    ARMOR %d    SPEED %.2f/s\nCRIT %d%%    CRIT DMG %d%%" % [roundi(float(stats["atk"])), roundi(float(stats["armor"])), float(stats["speed"]), roundi(float(stats["crit_chance"]) * 100), roundi(float(stats["crit_damage"]) * 100)]
	exp_bar.max_value = GameData.exp_to_next(profile.level)
	exp_bar.value = profile.exp
	if heroes_exp_text != null:
		heroes_exp_text.text = "HERO EXP  %d / %d" % [profile.exp, GameData.exp_to_next(profile.level)]
		heroes_exp_bar.max_value = GameData.exp_to_next(profile.level)
		heroes_exp_bar.value = profile.exp
		heroes_level_text.text = "LEVEL %d    POWER %d" % [profile.level, GameData.hero_power(stats)]
	action_button.visible = profile.stage == 10 and profile.boss_retry_required and not battle.active and not profile.campaign_complete
	tutorial_text.visible = profile.stage == 1 and not profile.campaign_complete
	for stat in upgrade_buttons:
		var rank := int(profile.upgrades[stat])
		var cost := GameData.upgrade_cost(rank)
		var button: Button = upgrade_buttons[stat]
		button.text = "%s +%d\n%d GOLD" % [str(stat).to_upper(), rank, cost]
		button.disabled = profile.gold < cost
	skill_badge.queue_redraw()
	battlefield.queue_redraw()

func _living_enemies() -> int:
	var count := 0
	for enemy in battle.enemies:
		if float(enemy["current_hp"]) > 0.0:
			count += 1
	return count

func _show_message(value: String) -> void:
	if message_text != null:
		message_text.text = value

func _select_tab(tab_name: String) -> void:
	selected_tab = tab_name
	battle_area.visible = tab_name == "Battle"
	heroes_area.visible = tab_name == "Heroes"
	equipment_area.visible = tab_name == "Equipment"
	placeholder_area.visible = tab_name in ["Skills", "Summon"]
	placeholder_title.text = tab_name.to_upper()
	if tab_name in ["Heroes", "Equipment"]:
		_refresh_progression_screens()
	_update_navigation()

func _clear_content(content: VBoxContainer) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func _refresh_progression_screens() -> void:
	if heroes_content == null:
		return
	_build_heroes_screen()
	_build_equipment_screen()

func _build_heroes_screen() -> void:
	_clear_content(heroes_content)
	var identity := _panel()
	heroes_content.add_child(identity)
	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 16)
	identity.add_child(identity_row)
	var portrait := HeroPortraitScript.new()
	portrait.custom_minimum_size = Vector2(210, 250)
	identity_row.add_child(portrait)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_row.add_child(box)
	box.add_child(_label("SQUIRE  •  THE FIRST VOW", 36, GOLD))
	box.add_child(_label("Male  •  Black hair  •  Vanguard", 31, PALE))
	heroes_level_text = _label("LEVEL %d    POWER %d" % [profile.level, GameData.hero_power(GameData.hero_stats(profile.level, profile.upgrades, profile.gear_stats()))], 31, Color("a9d6ad"))
	box.add_child(heroes_level_text)
	box.add_child(_label("Evolution Crests: %d  •  Current form: Squire" % profile.evolution_crests, 29, MUTED))
	heroes_exp_text = _label("HERO EXP  %d / %d" % [profile.exp, GameData.exp_to_next(profile.level)], 30, MUTED)
	box.add_child(heroes_exp_text)
	heroes_exp_bar = ProgressBar.new()
	heroes_exp_bar.custom_minimum_size.y = 20
	heroes_exp_bar.show_percentage = false
	heroes_exp_bar.max_value = GameData.exp_to_next(profile.level)
	heroes_exp_bar.value = profile.exp
	box.add_child(heroes_exp_bar)
	var leveling_note := _label("Combat EXP raises base HP, ATK, and Armor. Gold upgrades are account-wide.", 30, MUTED)
	leveling_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(leveling_note)
	_section_title(heroes_content, "THE OATHBOUND PATH")
	for index in GameData.EVOLUTION_PATH.size():
		var tier: Dictionary = GameData.EVOLUTION_PATH[index]
		var card := _panel()
		heroes_content.add_child(card)
		var line := HBoxContainer.new()
		card.add_child(line)
		var sigil := _label("✦" if index == 0 else "◇", 39, GOLD if index == 0 else MUTED)
		sigil.custom_minimum_size.x = 62
		line.add_child(sigil)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(copy)
		copy.add_child(_label(str(tier["name"]).to_upper(), 30, GOLD if index == 0 else PALE))
		copy.add_child(_label("CURRENT FORM" if index == 0 else "Level %d  •  %d Evolution Crest%s" % [tier["level"], tier["crests"], "" if tier["crests"] == 1 else "s"], 29, MUTED))
		line.add_child(_label("ACTIVE" if index == 0 else "LOCKED", 29, Color("a9d6ad") if index == 0 else Color("d8a399")))
	_section_title(heroes_content, "FUTURE HEROES")
	for name in ["Mage", "Ranger", "Assassin", "Necromancer"]:
		var card := _panel()
		heroes_content.add_child(card)
		var copy := VBoxContainer.new()
		card.add_child(copy)
		copy.add_child(_label("♢  %s  •  LOCKED" % name.to_upper(), 29, PALE))
		copy.add_child(_label("Rarity: TBA  •  Hero pieces: TBA", 30, MUTED))
	_section_title(heroes_content, "HERO MILESTONES")
	for threshold in [5, 10, 20]:
		var claimed: bool = profile.milestones.has("level_%d" % threshold)
		var card := _panel()
		heroes_content.add_child(card)
		card.add_child(_label("Reach Level %d  •  2 Gems  •  %s" % [threshold, "CLAIMED" if claimed else "LOCKED"], 29, Color("a9d6ad") if claimed else MUTED))

func _section_title(parent: VBoxContainer, value: String) -> void:
	parent.add_child(_label(value, 33, GOLD))

func _build_equipment_screen() -> void:
	_clear_content(equipment_content)
	var heading := _panel()
	equipment_content.add_child(heading)
	var headbox := VBoxContainer.new()
	heading.add_child(headbox)
	headbox.add_child(_label("ARMORY  •  SQUIRE", 36, GOLD))
	headbox.add_child(_label("%d Gold    •    %d Enhancement Stones" % [profile.gold, profile.enhancement_stones], 30, PALE))
	headbox.add_child(_label("Swipe to browse slots and inventory.", 28, MUTED))
	var selected := profile.get_item(selected_item_id)
	if not selected.is_empty():
		_section_title(equipment_content, "ITEM DETAILS")
		var detail := _panel()
		equipment_content.add_child(detail)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 7)
		detail.add_child(box)
		box.add_child(_label("%s  %s  +%d" % [EquipmentData.ITEMS[selected["kind"]]["icon"], EquipmentData.title(selected), selected["level"]], 30, EquipmentData.COLORS[int(selected["rarity"])]))
		box.add_child(_label(EquipmentData.stat_lines(selected), 31, PALE))
		var slot: String = EquipmentData.ITEMS[selected["kind"]]["slot"]
		var equipped_item := profile.get_item(str(profile.equipped.get(slot, "")))
		var comparison := _label("Equipped: %s" % ("None" if equipped_item.is_empty() else "%s  •  %s" % [EquipmentData.title(equipped_item), EquipmentData.stat_lines(equipped_item)]), 29, MUTED)
		comparison.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(comparison)
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 8)
		box.add_child(actions)
		var is_equipped: bool = profile.equipped.get(slot, "") == selected_item_id
		var equip_action: Callable = _unequip_selected if is_equipped else _equip_selected
		_action(actions, "UNEQUIP" if is_equipped else "EQUIP", equip_action)
		var upgrade := _action(actions, "UPGRADE\n%dG + %d ST" % [EquipmentData.upgrade_gold_cost(selected), EquipmentData.upgrade_stone_cost(selected)], _upgrade_selected)
		upgrade.disabled = profile.gold < EquipmentData.upgrade_gold_cost(selected) or profile.enhancement_stones < EquipmentData.upgrade_stone_cost(selected) or int(selected["level"]) >= 99
		var merges := profile.merge_count(str(selected["kind"]), int(selected["rarity"]), int(selected["level"]))
		var merge := _action(box, "MERGE 5 → 1  •  AVAILABLE %d" % merges, _merge_selected)
		merge.disabled = merges == 0
		box.add_child(_label("Merge requires five copies at the same rarity and level.", 27, MUTED))
	_section_title(equipment_content, "EQUIPPED SLOTS")
	for slot in EquipmentData.SLOTS:
		var item := profile.get_item(str(profile.equipped.get(slot, "")))
		var button := Button.new()
		button.custom_minimum_size.y = 126
		button.add_theme_font_size_override("font_size", 31)
		button.text = "%s    %s" % [slot.to_upper(), "EMPTY" if item.is_empty() else "%s  +%d" % [EquipmentData.title(item), item["level"]]]
		if not item.is_empty():
			_style_rarity(button, int(item["rarity"]))
			button.pressed.connect(_select_item.bind(str(item["id"])))
		equipment_content.add_child(button)
	_section_title(equipment_content, "INVENTORY  •  %d ITEMS" % profile.inventory.size())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	equipment_content.add_child(grid)
	for item in profile.inventory:
		var button := Button.new()
		button.custom_minimum_size = Vector2(485, 132)
		button.add_theme_font_size_override("font_size", 30)
		button.text = "%s  %s\n+%d  %s" % [EquipmentData.ITEMS[item["kind"]]["icon"], EquipmentData.ITEMS[item["kind"]]["name"], item["level"], EquipmentData.RARITIES[int(item["rarity"])] ]
		_style_rarity(button, int(item["rarity"]))
		button.pressed.connect(_select_item.bind(str(item["id"])))
		grid.add_child(button)

func _style_rarity(button: Button, rarity: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1c2d30")
	style.border_color = EquipmentData.COLORS[rarity]
	style.set_border_width_all(4)
	style.set_corner_radius_all(9)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_color_override("font_color", EquipmentData.COLORS[rarity])

func _action(parent: Container, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 126
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 30)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _select_item(id: String) -> void:
	selected_item_id = id
	_refresh_progression_screens()
	equipment_area.scroll_vertical = 0

func _equip_selected() -> void:
	if profile.equip(selected_item_id):
		_gear_changed("Equipment changed. Combat stats increased.")

func _unequip_selected() -> void:
	var item := profile.get_item(selected_item_id)
	if not item.is_empty() and profile.unequip(EquipmentData.ITEMS[item["kind"]]["slot"]):
		_gear_changed("Equipment removed.")

func _upgrade_selected() -> void:
	if profile.upgrade_item(selected_item_id):
		_gear_changed("Equipment enhanced!")

func _merge_selected() -> void:
	var item := profile.get_item(selected_item_id)
	if item.is_empty():
		return
	var merged := profile.merge_items(str(item["kind"]), int(item["rarity"]), int(item["level"]))
	if not merged.is_empty():
		selected_item_id = str(merged["id"])
		_gear_changed("Five items merged into %s!" % EquipmentData.title(merged))

func _gear_changed(note: String) -> void:
	if battle.active:
		battle.refresh_hero_stats()
	_show_message(note)
	_refresh_ui()
	_refresh_progression_screens()

func _on_equipment_dropped(item: Dictionary) -> void:
	_show_message("Equipment drop: %s!" % EquipmentData.title(item))
	battlefield.show_equipment_drop(EquipmentData.title(item), EquipmentData.COLORS[int(item["rarity"])] )
	if selected_tab == "Equipment":
		_refresh_progression_screens()

func _on_hero_leveled(new_level: int, gem_bonus: int) -> void:
	battlefield.show_level_up(new_level, gem_bonus)
	if selected_tab == "Heroes":
		_refresh_progression_screens()

func _update_navigation() -> void:
	for tab_name in nav_buttons:
		var button: Button = nav_buttons[tab_name]
		var selected: bool = tab_name == selected_tab
		var style := StyleBoxFlat.new()
		style.bg_color = Color("53624f") if selected else Color("1c2d30")
		style.border_color = GOLD if selected else Color("405153")
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_color_override("font_color", GOLD if selected else MUTED)
		button.add_theme_color_override("font_hover_color", PALE)

func _buy_upgrade(stat: String) -> void:
	if profile.buy_upgrade(stat):
		if battle.active:
			battle.refresh_hero_stats()
		_show_message("%s upgraded! Your power increased." % stat.to_upper())
		_refresh_ui()

func _on_stage_cleared() -> void:
	transition_id += 1
	var this_transition := transition_id
	var gem_reward := profile.record_stage_clear(profile.stage)
	if selected_tab == "Equipment":
		_refresh_progression_screens()
	if profile.stage == 10:
		profile.campaign_complete = true
		profile.boss_retry_required = false
		profile.save()
		_show_message("Victory! Greenvale cleared. +%d Gems, +%d Stones." % [gem_reward, 2 if gem_reward > 0 else 0])
		_refresh_ui()
		return
	_show_message("Easy 1-%d cleared! +%d Gem, +%d Stone." % [profile.stage, gem_reward, 1 if gem_reward > 0 else 0])
	profile.stage += 1
	profile.save()
	_refresh_ui()
	await get_tree().create_timer(1.2).timeout
	if this_transition != transition_id:
		return
	if profile.stage == 10 and profile.boss_retry_required:
		_show_message("The Warlord awaits. Tap Retry Boss to begin.")
		_refresh_ui()
	else:
		battle.start(profile)

func _on_battle_lost(boss_failure: bool) -> void:
	transition_id += 1
	var this_transition := transition_id
	var failed_stage := profile.stage
	profile.stage = maxi(1, profile.stage - 1)
	if boss_failure:
		profile.boss_retry_required = true
	profile.save()
	_show_message("Easy 1-%d failed. Returning to Easy 1-%d." % [failed_stage, profile.stage])
	_refresh_ui()
	await get_tree().create_timer(1.5).timeout
	if this_transition == transition_id:
		battle.start(profile)

func _on_action_pressed() -> void:
	if profile.stage != 10 or not profile.boss_retry_required:
		return
	profile.boss_retry_required = false
	profile.save()
	battle.start(profile)
