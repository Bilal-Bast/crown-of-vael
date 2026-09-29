class_name AdventureScreen
extends VBoxContainer

var profile: SaveData
var service: PveService
var on_start: Callable
var on_campaign: Callable
var on_campaign_select: Callable
var view := "hub"
var dungeon_id := "gold"
var map_region := 1
var map_difficulty := 0
var last_run := {}
var last_result := {}

func configure(value: SaveData, start_callback: Callable, campaign_callback: Callable, select_callback: Callable = Callable()) -> void:
	profile = value
	service = PveService.new(profile)
	on_start = start_callback
	on_campaign = campaign_callback
	on_campaign_select = select_callback
	refresh()

func refresh() -> void:
	if profile == null:
		return
	service.refresh_day()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	match view:
		"campaign": _campaign_overview()
		"map": _world_map()
		"stages": _stage_select()
		"dungeons": _dungeons()
		"tiers": _tiers()
		"tower": _tower()
		"boss_rush": _boss_rush()
		"endless": _endless()
		"result": _result()
		_: _hub()

func show_result(run: Dictionary, result: Dictionary) -> void:
	last_run = run.duplicate(true)
	last_result = result.duplicate(true)
	view = "result"
	refresh()

func _hub() -> void:
	_heading("ADVENTURE", "Choose a path. Your current build joins every battle.")
	_card("CAMPAIGN  •  OPEN", "%s • %s" % [CampaignData.label(profile.campaign_difficulty, profile.region, profile.stage), CampaignData.REGIONS[profile.region - 1]["name"]], "200 stages per difficulty • Gems • Gear • Hero EXP", "ENTER", _open.bind("campaign"))
	_card("DUNGEONS  •  OPEN", "Six daily challenges • 2 attempts each", "Gold • Materials • Gear", "EXPLORE", _open.bind("dungeons"))
	_card("PERMANENT TOWER  •  OPEN", "Highest floor %d • next floor %d" % [profile.tower_highest, profile.tower_highest + 1], "First-clear chests • Slot 3 at Floor 20", "ASCEND", _open.bind("tower"))
	_card("BOSS RUSH  •  OPEN", "5 bosses • %d/2 attempts • best %d/5" % [profile.boss_rush_state["remaining"], profile.boss_rush_state["best_boss"]], "Gems • Dust • Essence", "CHALLENGE", _open.bind("boss_rush"))
	_card("ENDLESS SURVIVAL  •  OPEN", "Best wave %d • %d/2 reward runs" % [profile.endless_state["best_wave"], profile.endless_state["reward_remaining"]], "Gold • EXP • Small materials", "SURVIVE", _open.bind("endless"))

func _campaign_overview() -> void:
	_heading("CAMPAIGN", "%s • %s" % [CampaignData.label(profile.campaign_difficulty, profile.region, profile.stage), CampaignData.REGIONS[profile.region - 1]["name"]])
	_back()
	var completed := 0
	for index in CampaignData.REGIONS.size():
		if int(profile.highest_stages.get(CampaignData.region_key(profile.campaign_difficulty, index + 1), 0)) >= 20: completed += 1
	var reward := CampaignData.region_reward(profile.campaign_difficulty, profile.region)
	_card("WORLD PROGRESS", "%d/10 regions complete • %d/200 stages" % [completed, _cleared_count(profile.campaign_difficulty)], "Next region reward: %d Gems • %d Gold • %d Crests" % [reward["gems"], reward["gold"], reward["crests"]], "WORLD MAP", _open.bind("map"))
	var complete := bool(profile.difficulty_completions.get(str(profile.campaign_difficulty), false))
	add_child(_label("%s: %s" % [CampaignData.DIFFICULTIES[profile.campaign_difficulty].to_upper(), "COMPLETE" if complete else "IN PROGRESS"], 30, Color("e9c87d")))
	var continue_button := _button("CONTINUE %s" % CampaignData.label(profile.campaign_difficulty, profile.region, profile.stage).to_upper())
	continue_button.pressed.connect(on_campaign)
	add_child(continue_button)

func _cleared_count(difficulty: int) -> int:
	var total := 0
	for index in CampaignData.REGIONS.size():
		total += int(profile.highest_stages.get(CampaignData.region_key(difficulty, index + 1), 0))
	return total

func _world_map() -> void:
	_heading("WORLD MAP", "%s • %d/200 stages" % [CampaignData.DIFFICULTIES[map_difficulty].to_upper(), _cleared_count(map_difficulty)])
	var back := _button("BACK TO CAMPAIGN")
	back.pressed.connect(_open.bind("campaign"))
	add_child(back)
	var difficulty_row := HBoxContainer.new()
	add_child(difficulty_row)
	for index in CampaignData.DIFFICULTIES.size():
		var difficulty_button := _button(CampaignData.DIFFICULTIES[index].substr(0, 3).to_upper())
		difficulty_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		difficulty_button.disabled = index > profile.highest_difficulty_unlocked
		difficulty_button.pressed.connect(_choose_difficulty.bind(index))
		difficulty_row.add_child(difficulty_button)
	for index in CampaignData.REGIONS.size():
		var number := index + 1
		var info: Dictionary = CampaignData.REGIONS[index]
		var unlocked := profile.unlocked_region(map_difficulty, number)
		var highest := int(profile.highest_stages.get(CampaignData.region_key(map_difficulty, number), 0))
		var selected := number == profile.world_map_region and map_difficulty == profile.campaign_difficulty
		var marker := "  ◆ %s" % HeroData.title(profile.selected_hero_id, profile.heroes[profile.selected_hero_id]) if number == profile.region and map_difficulty == profile.campaign_difficulty else ""
		var state := "FOG • LOCKED" if not unlocked else ("COMPLETE" if highest >= 20 else "STAGE %d/20" % (highest + 1))
		var title := "%s  %d. %s%s" % [info["icon"], number, info["name"], marker]
		var detail := "%s • %s • BOSS: %s" % [info["theme"], state, info["boss"]]
		_card(title, detail, "●" if selected else "│  path to next region", "STAGES" if unlocked else "FOG", _select_region.bind(number), not unlocked)
		if unlocked and number > 1 and highest == 0:
			var card := get_child(get_child_count() - 1) as Control
			card.modulate.a = 0.35
			create_tween().tween_property(card, "modulate:a", 1.0, 0.45)

func _choose_difficulty(value: int) -> void:
	if value > profile.highest_difficulty_unlocked: return
	map_difficulty = value
	refresh()

func _select_region(number: int) -> void:
	if not profile.unlocked_region(map_difficulty, number): return
	map_region = number
	profile.world_map_region = number
	profile.save()
	_open("stages")

func _stage_select() -> void:
	var info: Dictionary = CampaignData.REGIONS[map_region - 1]
	_heading("%d • %s" % [map_region, info["name"]], "%s • %s" % [CampaignData.DIFFICULTIES[map_difficulty].to_upper(), info["theme"]])
	var back := _button("BACK TO WORLD MAP")
	back.pressed.connect(_open.bind("map"))
	add_child(back)
	for row in 5:
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 8)
		add_child(buttons)
		for column in 4:
			var number := row * 4 + column + 1
			var state := profile.stage_state(map_difficulty, map_region, number)
			var tag := " BOSS" if number == 20 else (" E" if CampaignData.is_elite(number) else "")
			var button := _button("%d%s\n%s" % [number, tag, state.to_upper()])
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.disabled = state == "locked"
			button.pressed.connect(_start_campaign_stage.bind(map_region, number))
			buttons.add_child(button)
	add_child(_label("Elite: 5, 10, 15  •  Region boss: 20", 27, Color("e9c87d")))

func _start_campaign_stage(region_number: int, stage_number: int) -> void:
	if on_campaign_select.is_valid():
		on_campaign_select.call(map_difficulty, region_number, stage_number)

func _dungeons() -> void:
	_heading("DUNGEONS", "Two free attempts per dungeon, refreshed by local date.")
	_back()
	for id in PveData.DUNGEONS:
		var data: Dictionary = PveData.DUNGEONS[id]
		_card(str(data["name"]).to_upper(), "%s • Attempts %d/2" % [data["theme"], profile.dungeon_attempts[id]["remaining"]], str(data["reward"]), "SELECT", _select_dungeon.bind(id))

func _extra_dungeon(id: String) -> void:
	if MonetizationService.new(profile).grant_dungeon_attempt(id): refresh()

func _tiers() -> void:
	var data: Dictionary = PveData.DUNGEONS[dungeon_id]
	_heading(str(data["name"]).to_upper(), "Attempts %d/2 • %s" % [profile.dungeon_attempts[dungeon_id]["remaining"], data["reward"]])
	var back := _button("BACK TO DUNGEONS")
	back.pressed.connect(_open.bind("dungeons"))
	add_child(back)
	var extra := _button("SIMULATED AD • +1 DUNGEON ATTEMPT")
	extra.disabled = profile.dungeon_ad_usage.get(dungeon_id, "") == CalendarService.day()
	extra.pressed.connect(_extra_dungeon.bind(dungeon_id))
	add_child(extra)
	for tier in range(1, 6):
		var unlocked := tier <= profile.unlocked_dungeon_tier
		var config := {"mode": "dungeon", "dungeon": dungeon_id, "tier": tier}
		var status := "AVAILABLE" if unlocked else "Unlock after Easy 1-%d" % PveData.TIER_STAGES[tier - 1]
		_card("TIER %d  •  %s" % [tier, status], "Three waves • stronger foes and improved rewards", str(data["reward"]), "BATTLE" if unlocked else "LOCKED", _start.bind(config), not service.can_start(config))

func _tower() -> void:
	_heading("PERMANENT TOWER", "One compact fight per floor. Progress never resets.")
	_back()
	var next := profile.tower_highest + 1
	var slot_note := "ARTIFACT SLOT 3 UNLOCKED" if profile.artifact_slot_limit() >= 3 else "Artifact Slot 3 unlocks at Floor 20"
	_card("NEXT: FLOOR %d" % next, "Elite every 5 floors • Boss every 10", "First-clear Gems, Gold, materials • %s" % slot_note, "FIGHT", _start.bind({"mode": "tower", "floor": next}))
	for floor in range(maxi(1, profile.tower_highest - 3), profile.tower_highest + 1):
		_card("REPLAY FLOOR %d" % floor, "Practice with no first-clear rewards", "Floor %d cleared" % floor, "REPLAY", _start.bind({"mode": "tower", "floor": floor}))
	add_child(_label("MILESTONE CHESTS  •  Floors 10, 20, 30... grant bonus Gems and Evolution Crests.", 29, Color("e9c87d")))

func _boss_rush() -> void:
	_heading("BOSS RUSH", "Five bosses. HP carries forward; 10% heals between fights.")
	_back()
	for index in PveData.BOSS_RUSH.size():
		add_child(_label("%d  •  %s" % [index + 1, PveData.BOSS_RUSH[index]], 31, Color("e9e8d7")))
	_card("ATTEMPTS %d/2" % profile.boss_rush_state["remaining"], "Best boss %d/5 • Full clear %s" % [profile.boss_rush_state["best_boss"], "YES" if profile.boss_rush_state["full_clear"] else "NO"], "Gold • Gems • Essence • Dust", "START RUN", _start.bind({"mode": "boss_rush"}), not service.can_start({"mode": "boss_rush"}))

func _endless() -> void:
	_heading("ENDLESS SURVIVAL", "Fight until defeat. Each wave grows stronger.")
	_back()
	var remaining := int(profile.endless_state["reward_remaining"])
	_card("BEST WAVE %d" % profile.endless_state["best_wave"], "%d/2 rewarded runs left today" % remaining, "Gold • EXP • Small materials", "START REWARDED" if remaining > 0 else "PRACTICE • NO REWARDS", _start.bind({"mode": "endless"}))

func _result() -> void:
	var won := bool(last_result.get("won", false))
	_heading("VICTORY" if won else "RUN ENDED", "%s • %s" % [PveData.mode_label(last_run), _run_detail(last_run)])
	add_child(_label("Time %.1fs  •  Enemies %d  •  Damage %d" % [last_result.get("time", 0.0), last_result.get("kills", 0), last_result.get("damage", 0)], 29, Color("e9e8d7")))
	var reward: Dictionary = last_result.get("reward", {})
	var lines: Array[String] = []
	for key in reward:
		if key in ["companion_piece", "artifact_progress", "hero_piece"]:
			lines.append("%s: %s" % [str(key).replace("_", " ").capitalize(), reward[key]])
		elif int(reward[key]) > 0:
			lines.append("%s +%d" % [str(key).replace("_", " ").capitalize(), int(reward[key])])
	for item in last_result.get("equipment", []):
		lines.append("GEAR: %s" % EquipmentData.title(item))
	add_child(_label("REWARDS\n%s" % ("\n".join(lines) if not lines.is_empty() else "None"), 31, Color("e9c87d")))
	if last_run.get("mode", "") == "tower" and last_result.get("first_clear", false):
		add_child(_label("FIRST CLEAR • Milestone chest!" if int(last_run["floor"]) % 10 == 0 else "FIRST CLEAR", 31, Color("a9d6ad")))
	var continue_button := _button("CONTINUE")
	continue_button.pressed.connect(_open.bind("hub"))
	add_child(continue_button)
	if last_run.get("mode", "") != "endless" and service.can_start(last_run):
		var retry := _button("RETRY")
		retry.pressed.connect(_start.bind(last_run))
		add_child(retry)

func _run_detail(run: Dictionary) -> String:
	match str(run.get("mode", "")):
		"dungeon": return "Tier %d" % int(run["tier"])
		"tower": return "Floor %d" % int(run["floor"])
		"boss_rush": return "Boss %d/5" % int(last_result.get("progress", 0))
		"endless": return "Wave %d" % int(last_result.get("progress", 0))
	return ""

func _start(config: Dictionary) -> void:
	if on_start.is_valid():
		on_start.call(config)

func _select_dungeon(id: String) -> void:
	dungeon_id = id
	_open("tiers")

func _open(next: String) -> void:
	if next == "map" and view != "stages": map_difficulty = profile.campaign_difficulty
	view = next
	refresh()

func _back() -> void:
	var button := _button("BACK TO ADVENTURE")
	button.pressed.connect(_open.bind("hub"))
	add_child(button)

func _heading(title: String, subtitle: String) -> void:
	add_child(_label(title, 40, Color("e9c87d")))
	add_child(_label(subtitle, 29, Color("aebdb4")))

func _card(title: String, detail: String, reward: String, action: String, callback: Callable, disabled: bool = false) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("182426") if disabled else Color("253739")
	style.border_color = Color("786947") if not disabled else Color("4a5554")
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_label(title, 34, Color("e9c87d") if not disabled else Color("aebdb4")))
	box.add_child(_label(detail, 28, Color("73827d") if disabled else Color("e9e8d7")))
	box.add_child(_label(reward, 27, Color("6a7774") if disabled else Color("a9d6ad")))
	var button := _button(action)
	button.disabled = disabled
	button.pressed.connect(callback)
	box.add_child(button)

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 78
	button.add_theme_font_size_override("font_size", 28)
	return button
