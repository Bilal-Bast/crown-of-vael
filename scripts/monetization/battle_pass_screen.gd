class_name BattlePassScreen
extends VBoxContainer

const CrownUI = preload("res://scripts/ui/crown_ui.gd")

var profile: SaveData
var service: MonetizationService
var on_change: Callable
var premium_view := false

func configure(value: SaveData, callback: Callable) -> void:
	profile = value
	service = MonetizationService.new(profile)
	on_change = callback
	refresh()

func refresh() -> void:
	if profile == null: return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	add_child(_label("BATTLE PASS • SEASON 1", 40))
	add_child(_label("%s to %s  •  Level %d/50  •  %d XP" % [profile.bp_season.start, profile.bp_season.end, profile.bp_season.level, profile.bp_season.xp], 27))
	add_child(_label("Daily quests +%d XP  •  Weekly quests +%d XP" % [MonetizationData.DAILY_QUEST_XP, MonetizationData.WEEKLY_QUEST_XP], 25))
	var row := HBoxContainer.new()
	add_child(row)
	for track in [false, true]:
		var button := _button("PREMIUM" if track else "FREE")
		CrownUI.style_tab(button, premium_view == track, Color("c5a566") if track else Color("7d9d8a"))
		button.pressed.connect(_view.bind(track))
		row.add_child(button)
	var all := _button("CLAIM ALL AVAILABLE")
	CrownUI.set_button_role(all, &"PrimaryActionButton")
	all.pressed.connect(_claim_all)
	add_child(all)
	if not profile.premium_pass_owned:
		var buy := _button("DEV PURCHASE • PREMIUM PASS $4.99")
		buy.pressed.connect(_buy)
		add_child(buy)
	var track_name := "PREMIUM" if premium_view else "FREE"
	add_child(_label(track_name + " REWARDS", 33))
	for level in range(1, 51):
		var reward := MonetizationData.reward(level, premium_view)
		var parts := PackedStringArray()
		for key in reward:
			parts.append(str(reward[key]) + " " + str(key).replace("_", " "))
		var button := _button("%02d  •  %s" % [level, ", ".join(parts)])
		button.tooltip_text = "Requires %d total BP XP" % MonetizationData.total_xp_for_level(level)
		var claimed: Dictionary = profile.bp_season.premium_claimed if premium_view else profile.bp_season.free_claimed
		if claimed.has(str(level)): button.text += "  ✓ CLAIMED"
		elif premium_view and not profile.premium_pass_owned: button.text += "  • LOCKED"
		elif level > int(profile.bp_season.level): button.text += "  • %d XP" % MonetizationData.total_xp_for_level(level)
		else: button.text += "  • CLAIM"
		button.disabled = not service.can_claim_bp(level, premium_view)
		CrownUI.set_button_role(button, &"QuietButton")
		button.pressed.connect(_claim.bind(level, premium_view))
		add_child(button)

func _view(premium: bool) -> void:
	premium_view = premium
	refresh()

func _claim(level: int, premium: bool) -> void:
	if service.claim_bp(level, premium):
		refresh()
		if on_change.is_valid(): on_change.call()

func _claim_all() -> void:
	if service.claim_all_bp() > 0:
		refresh()
		if on_change.is_valid(): on_change.call()

func _buy() -> void:
	if service.purchase("premium_pass"):
		refresh()
		if on_change.is_valid(): on_change.call()

func _label(value: String, size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("e9c87d"))
	return label

func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 72
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 25)
	button.clip_text = true
	return button
