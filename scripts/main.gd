extends Control

const BattleScript = preload("res://scripts/battle_controller.gd")
const BattlefieldScript = preload("res://scripts/battlefield.gd")
const SkillBadgeScript = preload("res://scripts/skill_badge.gd")

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
	_build_navigation(root)

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
	var stats := GameData.hero_stats(profile.level, profile.upgrades)
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
	placeholder_area.visible = tab_name != "Battle"
	placeholder_title.text = tab_name.to_upper()
	_update_navigation()

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
	if profile.stage == 10:
		profile.campaign_complete = true
		profile.boss_retry_required = false
		profile.save()
		_show_message("Victory! Greenvale Outskirts cleared.")
		_refresh_ui()
		return
	_show_message("Easy 1-%d cleared. Advancing automatically!" % profile.stage)
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
