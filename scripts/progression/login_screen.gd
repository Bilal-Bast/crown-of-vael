class_name LoginScreen
extends VBoxContainer

var profile: SaveData
var service: ProgressionService
var on_change: Callable
var notice := ""

func configure(value: SaveData, callback: Callable) -> void:
	profile = value
	service = ProgressionService.new(profile)
	on_change = callback
	refresh()

func refresh() -> void:
	if profile == null: return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	add_child(_label("LOGIN REWARDS", 42, Color("ffd166")))
	add_child(_label("Claim once per local day. Missed days do not break your sequence.", 26, Color("b8cbe2")))
	if notice != "":
		var glow := _label("✦ " + notice, 28, Color("ffd166"))
		add_child(glow)
		glow.modulate.a = 0.2
		create_tween().tween_property(glow, "modulate:a", 1.0, 0.28)
	var today := CalendarService.day()
	var daily := _button("DAY %d OF 7  •  %s" % [profile.daily_login_index + 1, _reward_text(ProgressionData.login_reward(profile.daily_login_index))])
	daily.clip_text = true
	daily.disabled = profile.last_login_reward_date == today
	daily.pressed.connect(_claim_daily)
	add_child(daily)
	var bonus := _button("SIMULATED AD  •  BONUS REWARD")
	bonus.disabled = profile.daily_bonus_ad_claim == today
	bonus.pressed.connect(_claim_bonus)
	add_child(bonus)
	add_child(_label("28-DAY LOGIN CALENDAR", 34, Color("ffd166")))
	var grid := GridContainer.new()
	grid.columns = 4
	add_child(grid)
	for index in 28:
		var claimed := index < profile.monthly_login_index
		var current := index == profile.monthly_login_index
		var state := "CLAIMED" if claimed else "TODAY" if current and profile.last_monthly_reward_date != today else "UPCOMING"
		var reward: Dictionary = ProgressionData.login_reward(index, true)
		var short_parts := PackedStringArray()
		for key in reward: short_parts.append("%s %d" % [str(key).replace("enhancement_stones", "Stones").replace("companion_essence", "Essence").replace("companion_crests", "Crests").replace("artifact_dust", "Dust").replace("evolution_crests", "Crests").replace("hero_pieces", "Pieces").capitalize(), int(reward[key])])
		var card := _button("DAY %d\n%s\n%s" % [index + 1, ", ".join(short_parts), state])
		card.tooltip_text = _reward_text(reward)
		card.clip_text = true
		card.custom_minimum_size.y = 148
		card.disabled = not current or profile.last_monthly_reward_date == today
		card.pressed.connect(_claim_monthly)
		grid.add_child(card)

func _claim_daily() -> void:
	var gems_before := profile.gems
	if service.claim_login():
		notice = ("Gems! " if profile.gems > gems_before else "") + "Daily reward claimed!"
		refresh()
		if on_change.is_valid(): on_change.call()

func _claim_monthly() -> void:
	var gems_before := profile.gems
	if service.claim_monthly():
		notice = ("Gems! " if profile.gems > gems_before else "") + "Calendar reward claimed!"
		refresh()
		if on_change.is_valid(): on_change.call()

func _claim_bonus() -> void:
	if MonetizationService.new(profile).claim_daily_bonus():
		notice = "Bonus reward claimed!"
		refresh()
		if on_change.is_valid(): on_change.call()

func _reward_text(reward: Dictionary) -> String:
	var parts := PackedStringArray()
	for key in reward: parts.append("%d %s" % [int(reward[key]), str(key).replace("_", " ").capitalize()])
	return ", ".join(parts)

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 76
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 23)
	button.clip_text = true
	return button
