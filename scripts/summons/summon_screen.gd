class_name SummonScreen
extends VBoxContainer

var profile: SaveData
var service: SummonService
var on_change: Callable
var on_open: Callable
var results: Array[Dictionary] = []
var result_banner := ""
var revealing := false
var reveal_token := 0
var notice := ""

func configure(new_profile: SaveData, changed: Callable, open_screen: Callable = Callable()) -> void:
	profile = new_profile
	service = SummonService.new(profile)
	on_change = changed
	on_open = open_screen
	refresh()

func refresh() -> void:
	if profile == null:
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var heading := _panel(Color("9c85ca"))
	add_child(heading)
	var headbox := VBoxContainer.new()
	heading.add_child(headbox)
	headbox.add_child(_label("ARCANE SUMMONING", 37, Color("e9c87d")))
	headbox.add_child(_label("Gems: %d  •  Four independent banners" % profile.gems, 29, Color("e9e8d7")))
	if on_open.is_valid():
		var hub := HBoxContainer.new()
		headbox.add_child(hub)
		for screen_name in ["Companions", "Artifacts"]:
			var open := _button("OPEN %s" % screen_name.to_upper())
			if ProgressionService.new(profile).badge(screen_name):
				var dot := ColorRect.new()
				dot.color = Color("d94f52")
				dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
				dot.anchor_left = 1.0
				dot.anchor_right = 1.0
				dot.offset_left = -22
				dot.offset_right = -8
				dot.offset_top = 8
				dot.offset_bottom = 22
				open.add_child(dot)
			open.pressed.connect(on_open.bind(screen_name))
			hub.add_child(open)
	if notice != "":
		headbox.add_child(_label(notice, 27, Color("d8a399")))
	if not results.is_empty():
		_build_reveal()
	for banner in SummonData.BANNERS:
		_build_banner(banner)
	add_child(_label("FUTURE SUMMONS", 32, Color("e9c87d")))
	for name in ["Heroes"]:
		var locked := _panel(Color("52605c"))
		add_child(locked)
		locked.add_child(_label("%s  •  LOCKED  •  Unlocks later" % name.to_upper(), 29, Color("aebdb4")))

func _build_banner(banner: String) -> void:
	var state: Dictionary = profile.banners[banner]
	var colors := {"equipment": Color("78b9ec"), "skills": Color("bb86e8"), "companions": Color("79c78b"), "artifacts": Color("efc36b")}
	var color: Color = colors[banner]
	var panel := _panel(color)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	box.add_child(_label("%s SUMMON" % banner.to_upper(), 34, color))
	var level := int(state["level"])
	var exp_target := SummonData.exp_to_next(level)
	box.add_child(_label("BANNER LEVEL %d/10  •  EXP %s" % [level, "MAX" if level == 10 else "%d/%d" % [state["exp"], exp_target]], 28, Color("e9e8d7")))
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 16
	bar.show_percentage = false
	bar.max_value = exp_target
	bar.value = exp_target if level == 10 else int(state["exp"])
	box.add_child(bar)
	box.add_child(_label("PITY %d/100  •  100th guarantees Legendary+" % state["pity"], 27, Color("e9c87d")))
	var preview := PackedStringArray()
	var weights := SummonData.rarity_weights(level, banner)
	for rarity in weights.size():
		if int(weights[rarity]) > 0:
			preview.append("%s %.2f%%" % [EquipmentData.RARITIES[rarity], float(weights[rarity]) / 100.0])
	box.add_child(_label("RARITY PREVIEW  •  " + "  •  ".join(preview), 26, Color("aebdb4")))
	var paid := HBoxContainer.new()
	paid.add_theme_constant_override("separation", 8)
	box.add_child(paid)
	for count in [1, 10, 50]:
		var tickets := int(profile.summon_tickets.get(banner, 0))
		var button := _button("%dx\n%d TICKETS" % [count, count] if tickets >= count else "%dx\n%d GEMS" % [count, SummonData.COSTS[count]])
		button.disabled = not service.can_summon(banner, count)
		button.pressed.connect(_summon.bind(banner, count, "gems"))
		paid.add_child(button)
	var free_row := HBoxContainer.new()
	free_row.add_theme_constant_override("separation", 8)
	box.add_child(free_row)
	var daily := _button("DAILY FREE\n%s" % ["READY" if service.can_summon(banner, 1, "daily") else "CLAIMED"])
	daily.disabled = not service.can_summon(banner, 1, "daily")
	daily.pressed.connect(_summon.bind(banner, 1, "daily"))
	free_row.add_child(daily)
	var ad_count := int(state["ad_count"]) if state["ad_day"] == SummonService.local_day() else 0
	var ad := _button("WATCH AD - FREE\nDEV PLACEHOLDER %d/%d" % [ad_count, SummonData.AD_DAILY_LIMIT])
	ad.disabled = not service.can_summon(banner, 1, "ad")
	ad.pressed.connect(_summon.bind(banner, 1, "ad"))
	free_row.add_child(ad)

func _build_reveal() -> void:
	var highest_rarity := 0
	for reward in results:
		highest_rarity = maxi(highest_rarity, int(reward["rarity"]))
	var panel := _panel(EquipmentData.COLORS[highest_rarity])
	panel.modulate.a = 0.72
	panel.scale = Vector2(0.92, 0.92) if highest_rarity >= 4 else Vector2(0.96, 0.96)
	var reveal_tween := create_tween()
	reveal_tween.tween_property(panel, "modulate:a", 1.0, 0.22)
	reveal_tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.32 if highest_rarity >= 4 else 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	add_child(panel)
	move_child(panel, 1)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(_label("%s REVEAL  •  %d REWARD%s" % [result_banner.to_upper(), results.size(), "" if results.size() == 1 else "S"], 32, Color("e9c87d")))
	if revealing:
		var portal := _label("✦    ARCANE PORTAL OPENING    ✦", 34, Color("bb86e8"))
		portal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(portal)
		var tween := create_tween()
		tween.tween_property(portal, "modulate:a", 0.2, 0.3)
		tween.tween_property(portal, "modulate:a", 1.0, 0.3)
		var skip := _button("SKIP REVEAL")
		skip.pressed.connect(_skip_reveal)
		box.add_child(skip)
		return
	var grid := GridContainer.new()
	grid.columns = 1 if results.size() == 1 else 3
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	box.add_child(grid)
	for reward in results:
		var rarity := int(reward["rarity"])
		var card := _panel(EquipmentData.COLORS[rarity], rarity)
		card.custom_minimum_size = Vector2(0, 130 if results.size() == 1 else 108)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var name: String = ""
		match result_banner:
			"equipment": name = str(EquipmentData.ITEMS[reward["kind"]]["name"])
			"skills": name = str(SkillData.SKILLS[reward["kind"]]["name"])
			"companions": name = str(CompanionData.COMPANIONS[reward["kind"]]["name"])
			"artifacts": name = str(ArtifactData.ARTIFACTS[reward["kind"]]["name"])
		card.add_child(_label("%s\n%s" % [EquipmentData.RARITIES[rarity].to_upper(), name], 27, EquipmentData.COLORS[rarity]))
	var close := _button("CLOSE RESULTS")
	close.pressed.connect(_close_results)
	box.add_child(close)

func _summon(banner: String, count: int, source: String) -> void:
	var audio := get_node_or_null("/root/AudioService") if is_inside_tree() else null
	if audio != null:
		audio.play_event("summon", "UI")
	var pulled := service.summon(banner, count, source)
	if pulled.is_empty():
		notice = "Summon unavailable. Check Gems or daily allowance."
		refresh()
		return
	results = pulled
	result_banner = banner
	revealing = true
	reveal_token += 1
	var token := reveal_token
	notice = ""
	refresh()
	if on_change.is_valid():
		on_change.call()
	await get_tree().create_timer(0.7 if count == 1 else 1.1).timeout
	if token == reveal_token:
		revealing = false
		refresh()

func _skip_reveal() -> void:
	reveal_token += 1
	revealing = false
	refresh()

func _close_results() -> void:
	results.clear()
	refresh()

func _button(caption: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 98
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 27)
	return button

func _panel(border: Color, rarity: int = 0) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("253739")
	style.border_color = border
	style.set_border_width_all(2 + mini(3, rarity / 2))
	style.set_corner_radius_all(11)
	style.set_content_margin_all(13)
	if rarity >= 2:
		style.shadow_color = Color(border.r, border.g, border.b, 0.18 + rarity * 0.04)
		style.shadow_size = mini(15, rarity * 2)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
