class_name SummonScreen
extends VBoxContainer

var profile: SaveData
var service: SummonService
var on_change: Callable
var on_open: Callable
var results: Array[Dictionary] = []
var result_banner := ""
var selected_banner := "equipment"
var revealing := false
var reveal_token := 0
var notice := ""
var page := 0
var show_odds := false
const PAGE_SIZE := 6
const SANCTUM = preload("res://scripts/summons/summon_sanctum.gd")
const TITLES := {"equipment":"THE EMBER FORGE", "skills":"HALL OF RUNES", "companions":"THE SPIRIT GATE", "artifacts":"VAULT OF THE ANCIENTS"}

func configure(new_profile: SaveData, changed: Callable, open_screen: Callable = Callable()) -> void:
	profile = new_profile
	service = SummonService.new(profile)
	on_change = changed
	on_open = open_screen
	refresh()

func refresh() -> void:
	if profile == null: return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	add_theme_constant_override("separation", 14)
	add_child(_label("THE SUMMONING SANCTUM", 38, Color("eed7a1")))
	add_child(_label("%s Gems  /  A new discovery awaits" % NumberFormat.compact(profile.gems), 29, Color("b9c8cb")))
	if not results.is_empty():
		_build_reveal()
		return
	var tabs := GridContainer.new()
	tabs.columns = 2
	add_child(tabs)
	for banner in SummonData.BANNERS:
		var tab := _button(str(banner).capitalize(), SANCTUM.COLORS[banner])
		tab.disabled = banner == selected_banner
		tab.pressed.connect(func(): selected_banner = banner; show_odds = false; refresh())
		tabs.add_child(tab)
	_build_banner(selected_banner)
	if on_open.is_valid():
		var row := HBoxContainer.new()
		add_child(row)
		for screen_name in ["Companions", "Artifacts"]:
			var open := _button("View " + screen_name)
			open.pressed.connect(on_open.bind(screen_name))
			row.add_child(open)
	if not notice.is_empty(): add_child(_label(notice, 28, Color("ebbd91")))

func _build_banner(banner: String) -> void:
	var state: Dictionary = profile.banners[banner]
	var color: Color = SANCTUM.COLORS[banner]
	var panel := _panel(color)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_label(TITLES[banner], 34, color))
	var scene := SANCTUM.new()
	scene.banner = banner
	scene.reduced = profile.reduced_effects
	box.add_child(scene)
	var level := int(state["level"])
	box.add_child(_label("Banner %d / 10   |   Legendary+ in %d pulls" % [level, SummonData.PITY_LIMIT - int(state["pity"])], 29, Color("eed7a1")))
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 12
	bar.show_percentage = false
	bar.max_value = SummonData.PITY_LIMIT
	bar.value = int(state["pity"])
	box.add_child(bar)
	box.add_child(_label("EXP %s   |   Tickets %d" % ["MAX" if level == 10 else "%d/%d" % [state["exp"], SummonData.exp_to_next(level)], profile.summon_tickets.get(banner,0)], 27, Color("b3c2c4")))
	var free_row := HBoxContainer.new()
	box.add_child(free_row)
	var daily := _button("Daily gift\nREADY" if service.can_summon(banner,1,"daily") else "Daily gift\nClaimed",color)
	daily.disabled = not service.can_summon(banner,1,"daily")
	daily.pressed.connect(_summon.bind(banner,1,"daily"))
	free_row.add_child(daily)
	var used := int(state["ad_count"]) if state["ad_day"] == SummonService.local_day() else 0
	var ad := _button("Rewarded pull\n%d / 3 left" % (3-used),color)
	ad.disabled = not service.can_summon(banner,1,"ad")
	ad.pressed.connect(_summon.bind(banner,1,"ad"))
	free_row.add_child(ad)
	var paid := GridContainer.new()
	paid.columns = 2
	paid.add_theme_constant_override("h_separation", 12)
	paid.add_theme_constant_override("v_separation", 12)
	box.add_child(paid)
	for count in [1,10,30,50]:
		var quote := service.quote(banner,count)
		var cost := "%d Gems" % quote.gems
		if int(quote.tickets) > 0:
			cost = "%d tickets" % quote.tickets + (" + %d Gems" % quote.gems if int(quote.gems) > 0 else "")
		var title := "%dx SUMMON" % count
		if count == 30: title = "30x GRAND SUMMON"
		var button := _button(title + "\n" + cost, color if count == 30 else Color("65757c"))
		button.custom_minimum_size.y = 112
		button.disabled = not service.can_summon(banner,count)
		button.pressed.connect(_summon.bind(banner,count,"gems"))
		paid.add_child(button)
	box.add_child(_label("30x saves 12% | 50x saves 15%\nTickets apply first, with the same batch discount.", 26, Color("a8b9ba")))
	var odds := _button("Hide summon rates" if show_odds else "Summon rates & guarantee")
	odds.pressed.connect(func(): show_odds = not show_odds; refresh())
	box.add_child(odds)
	if show_odds:
		var lines := PackedStringArray()
		var weights := SummonData.rarity_weights(level,banner)
		for rarity in weights.size():
			if int(weights[rarity]) > 0: lines.append("%s %.2f%%" % [EquipmentData.RARITIES[rarity], float(weights[rarity])/100.0])
		box.add_child(_label(" / ".join(lines) + "\nEvery 100th pull guarantees Legendary+. Each banner has its own pity and level.",26,Color("c5ced0")))

func _build_reveal() -> void:
	var highest := 0
	var discoveries := 0
	for reward in results:
		highest = maxi(highest,int(reward.rarity))
		if bool(reward.get("is_new",false)): discoveries += 1
	var color: Color = EquipmentData.COLORS[highest]
	add_child(_label("%d REWARDS  |  %d NEW DISCOVERIES" % [results.size(), discoveries], 32, color))
	if revealing:
		var scene := SANCTUM.new()
		scene.banner = result_banner
		scene.opening = true
		scene.accent = color
		scene.reduced = profile.reduced_effects
		add_child(scene)
		scene.custom_minimum_size.y = 650
		add_child(_label("The seals are opening...", 36, color))
		var skip := _button("REVEAL ALL",color)
		skip.pressed.connect(_skip_reveal)
		add_child(skip)
		return
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	add_child(grid)
	var start := page * PAGE_SIZE
	for index in range(start,mini(start+PAGE_SIZE,results.size())):
		var reward: Dictionary = results[index]
		var rarity := int(reward.rarity)
		var card := _panel(EquipmentData.COLORS[rarity])
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var box := VBoxContainer.new()
		card.add_child(box)
		var icon := TextureRect.new()
		icon.texture = _reward_icon(reward)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(0,112)
		box.add_child(icon)
		box.add_child(_label(("NEW! " if bool(reward.get("is_new",false)) else "") + EquipmentData.RARITIES[rarity],25,EquipmentData.COLORS[rarity]))
		box.add_child(_label(_reward_name(reward),28,Color("efe7d5")))
		if not profile.reduced_effects:
			card.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_interval(float(index-start)*0.045)
			tween.tween_property(card,"modulate:a",1.0,0.16)
	var pages := ceili(float(results.size())/PAGE_SIZE)
	if pages > 1:
		var pager := HBoxContainer.new()
		add_child(pager)
		for direction in [-1,1]:
			var button := _button("Previous" if direction == -1 else "Next")
			button.disabled = page+direction < 0 or page+direction >= pages
			button.pressed.connect(func(): page += direction; refresh())
			pager.add_child(button)
		add_child(_label("Page %d / %d   |   Rewards %d-%d of %d" % [page+1,pages,start+1,mini(start+PAGE_SIZE,results.size()),results.size()],26,Color("b9c8cb")))
	var close := _button("KEEP EXPLORING", color)
	close.pressed.connect(_close_results)
	add_child(close)

func _reward_name(reward: Dictionary) -> String:
	var data: Dictionary = EquipmentData.ITEMS if result_banner == "equipment" else (SkillData.SKILLS if result_banner == "skills" else (CompanionData.COMPANIONS if result_banner == "companions" else ArtifactData.ARTIFACTS))
	return str(data[reward.kind].name)

func _reward_icon(reward: Dictionary) -> Texture2D:
	match result_banner:
		"equipment": return PixelUiIcons.item(str(reward.kind))
		"artifacts": return PixelUiIcons.artifact(str(reward.kind))
		"companions": return CompanionPixelArt.frame(str(reward.kind),1 if reward.kind == "dire_wolf" else 0)
	return PixelUiIcons.skill(str(reward.kind))

func _summon(banner: String, count: int, source: String) -> void:
	if revealing: return
	var pulled := service.summon(banner,count,source)
	if pulled.is_empty():
		notice = "Not enough Gems or tickets, or today's reward is already claimed."
		refresh()
		return
	results = pulled
	result_banner = banner
	page = 0
	revealing = true
	reveal_token += 1
	var token := reveal_token
	var audio := get_node_or_null("/root/AudioService")
	if audio != null: audio.play_event("summon","UI")
	refresh()
	if get_parent() is ScrollContainer: get_parent().scroll_vertical = 0
	if on_change.is_valid(): on_change.call()
	await get_tree().create_timer(0.15 if profile.reduced_effects else (0.85 if count == 1 else 1.25)).timeout
	if token == reveal_token:
		revealing = false
		refresh()

func _skip_reveal() -> void:
	reveal_token += 1
	revealing = false
	refresh()

func _close_results() -> void:
	reveal_token += 1
	revealing = false
	results.clear()
	refresh()

func _button(caption: String, color := Color("897a60")) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 84
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size",28)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("2c3545") if state == "hover" else Color("192630")
		style.border_color = color.darkened(0.55) if state == "disabled" else color
		style.set_border_width_all(2)
		style.border_width_bottom = 5
		style.set_content_margin_all(10)
		button.add_theme_stylebox_override(state,style)
	button.add_theme_color_override("font_color",Color("e6dfcb"))
	button.add_theme_color_override("font_disabled_color",Color("91a0a7"))
	return button

func _panel(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("18222d")
	style.border_color = color.darkened(0.25)
	style.set_border_width_all(2)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel",style)
	return panel

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
