class_name QuestsScreen
extends VBoxContainer

const GOLD := Color("e9c87d")
const PALE := Color("e9e8d7")
const MUTED := Color("aebdb4")
var profile: SaveData
var service: ProgressionService
var tab := "daily"
var notice := ""
var on_change: Callable

func configure(value: SaveData, callback: Callable) -> void:
	profile = value
	service = ProgressionService.new(profile)
	on_change = callback
	refresh()

func refresh() -> void:
	if profile == null: return
	service.refresh()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	add_child(_label("QUESTS", 42, GOLD))
	if not profile.quest_intro_seen:
		add_child(_label("Complete daily and weekly tasks to earn additional rewards.", 28, PALE))
		profile.quest_intro_seen = true
		profile.save()
	var tabs := HBoxContainer.new()
	add_child(tabs)
	for name in ["daily", "weekly", "achievements"]:
		var button := _button(name.capitalize())
		button.disabled = tab == name
		button.pressed.connect(_switch.bind(name))
		tabs.add_child(button)
	var heading := HBoxContainer.new()
	add_child(heading)
	var score := "ACTIVITY %d / %d" % [profile.daily_activity if tab == "daily" else profile.weekly_activity, 100 if tab == "daily" else 250]
	var subtitle := "Permanent achievements" if tab == "achievements" else score
	var caption := _label(subtitle, 29, GOLD)
	caption.custom_minimum_size.y = 38
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(caption)
	var all := _button("CLAIM ALL")
	all.size_flags_horizontal = Control.SIZE_SHRINK_END
	all.custom_minimum_size.x = 175
	all.pressed.connect(_claim_all)
	heading.add_child(all)
	if notice != "":
		var flyout := _label(notice, 27, GOLD if "✦✦" in notice else PALE)
		add_child(flyout)
		flyout.modulate.a = 0.2
		create_tween().tween_property(flyout, "modulate:a", 1.0, 0.28)
	if tab != "achievements":
		add_child(_label("Resets next local day" if tab == "daily" else "Resets next local Monday", 23, MUTED))
		_build_milestones()
		var entries: Array = ProgressionData.DAILY if tab == "daily" else ProgressionData.WEEKLY
		for entry in entries: _quest(entry)
	else:
		var current := ""
		for entry in ProgressionData.achievements():
			if current != str(entry.category):
				current = str(entry.category)
				add_child(_label(current, 29, GOLD))
			_achievement(entry)

func _build_milestones() -> void:
	var score: int = profile.daily_activity if tab == "daily" else profile.weekly_activity
	var rewards: Dictionary = ProgressionData.DAILY_MILESTONES if tab == "daily" else ProgressionData.WEEKLY_MILESTONES
	var claimed: Dictionary = profile.daily_activity_claimed if tab == "daily" else profile.weekly_activity_claimed
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 22
	bar.max_value = 100 if tab == "daily" else 250
	bar.value = score
	bar.show_percentage = false
	add_child(bar)
	var row := HBoxContainer.new()
	add_child(row)
	for target in rewards:
		var button := _button("%d\n%s" % [target, "CLAIMED" if claimed.has(str(target)) else "CLAIM" if score >= int(target) else "LOCKED"])
		button.disabled = score < int(target) or claimed.has(str(target))
		button.pressed.connect(_claim_milestone.bind(int(target)))
		row.add_child(button)

func _quest(entry: Array) -> void:
	var claimed: Dictionary = profile.daily_claimed if tab == "daily" else profile.weekly_claimed
	var progress := service.progress(entry, tab)
	_card(str(entry[1]), str(entry[2]), str(entry[3]), progress, int(entry[5]), entry[6], claimed.has(str(entry[0])), _claim_quest.bind(str(entry[0])))

func _achievement(entry: Dictionary) -> void:
	_card("✦", str(entry.title), str(entry.description), service.achievement_progress(entry), int(entry.target), entry.reward, profile.achievement_claimed.has(str(entry.id)), _claim_achievement.bind(str(entry.id)))

func _card(icon: String, title: String, description: String, progress: int, target: int, reward: Dictionary, claimed: bool, callback: Callable) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("253739")
	style.border_color = Color("7b7159")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_label("%s  %s" % [icon, title], 31, GOLD))
	box.add_child(_label(description, 25, MUTED))
	var row := HBoxContainer.new()
	box.add_child(row)
	var details := _label("%d / %d   •   %s" % [progress, target, _reward_text(reward)], 25, PALE)
	details.clip_text = true
	details.custom_minimum_size.y = 36
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(details)
	var claim := _button("CLAIM" if progress >= target and not claimed else "CLAIMED" if claimed else "IN PROGRESS")
	claim.size_flags_horizontal = Control.SIZE_SHRINK_END
	claim.custom_minimum_size.x = 190
	claim.disabled = claimed or progress < target
	claim.pressed.connect(callback)
	row.add_child(claim)

func _reward_text(reward: Dictionary) -> String:
	var parts := PackedStringArray()
	for key in reward: parts.append("%d %s" % [int(reward[key]), str(key).replace("_", " ").capitalize()])
	return ", ".join(parts)

func _switch(value: String) -> void:
	tab = value
	notice = ""
	refresh()

func _claim_quest(id: String) -> void:
	var gems_before := profile.gems
	if service.claim_quest(tab, id): _claimed("Quest reward claimed!", profile.gems > gems_before)

func _claim_achievement(id: String) -> void:
	var gems_before := profile.gems
	if service.claim_achievement(id): _claimed("Achievement reward claimed!", profile.gems > gems_before)

func _claim_milestone(target: int) -> void:
	var gems_before := profile.gems
	if service.claim_milestone(tab, target): _claimed("Milestone chest opened!", profile.gems > gems_before)

func _claim_all() -> void:
	var gems_before := profile.gems
	var count := service.claim_all(tab)
	if count > 0: _claimed("%d rewards claimed!" % count, profile.gems > gems_before)

func _claimed(value: String, gems: bool = false) -> void:
	notice = ("✦✦ GEM REWARD  " if gems else "✦ ") + value
	refresh()
	if on_change.is_valid(): on_change.call()

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 65
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 25)
	button.clip_text = true
	return button
