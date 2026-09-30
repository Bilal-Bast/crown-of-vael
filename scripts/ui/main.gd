extends Control

const BattleScript = preload("res://scripts/combat/battle_controller.gd")
const BattlefieldScript = preload("res://scripts/combat/battlefield.gd")
const SkillBarScript = preload("res://scripts/skills/skill_bar.gd")
const SkillsScreenScript = preload("res://scripts/skills/skills_screen.gd")
const SummonScreenScript = preload("res://scripts/summons/summon_screen.gd")
const CompanionsScreenScript = preload("res://scripts/companions/companions_screen.gd")
const ArtifactsScreenScript = preload("res://scripts/artifacts/artifacts_screen.gd")
const HeroPortraitScript = preload("res://scripts/heroes/hero_portrait.gd")
const AdventureScreenScript = preload("res://scripts/adventure/adventure_screen.gd")
const HeroesScreenScript = preload("res://scripts/heroes/heroes_screen.gd")
const QuestsScreenScript = preload("res://scripts/progression/quests_screen.gd")
const LoginScreenScript = preload("res://scripts/progression/login_screen.gd")
const BattlePassScreenScript = preload("res://scripts/monetization/battle_pass_screen.gd")
const ShopScreenScript = preload("res://scripts/monetization/shop_screen.gd")
const AccountScreenScript = preload("res://scripts/online/account_screen.gd")
const SocialScreenScript = preload("res://scripts/online/social_screen.gd")
const SettingsScreenScript = preload("res://scripts/ui/settings_screen.gd")
const IdleRewardServiceScript = preload("res://scripts/progression/idle_reward_service.gd")
const TutorialServiceScript = preload("res://scripts/progression/tutorial_service.gd")
const NumberFormatScript = preload("res://scripts/core/number_format.gd")

const INK := Color("172425")
const PANEL := Color("253739")
const EDGE := Color("7b7159")
const GOLD := Color("e9c87d")
const PALE := Color("e9e8d7")
const MUTED := Color("aebdb4")

var profile: SaveData
var battle: BattleController
var battlefield: Battlefield
var battlefield_host: Control
var pixel_battle_background: TextureRect
var skill_bar: SkillBar
var battle_area: VBoxContainer
var placeholder_area: PanelContainer
var placeholder_title: Label
var heroes_area: ScrollContainer
var equipment_area: ScrollContainer
var skills_area: ScrollContainer
var summon_area: ScrollContainer
var companions_area: ScrollContainer
var artifacts_area: ScrollContainer
var adventure_area: ScrollContainer
var quests_area: ScrollContainer
var login_area: ScrollContainer
var battle_pass_area: ScrollContainer
var shop_area: ScrollContainer
var account_area: ScrollContainer
var social_area: ScrollContainer
var settings_area: ScrollContainer
var battle_pass_screen: BattlePassScreen
var shop_screen: ShopScreen
var account_screen: AccountScreen
var social_screen: SocialScreen
var settings_screen: SettingsScreen
var cloud_sync_timer: Timer
var quests_screen: QuestsScreen
var login_screen: LoginScreen
var login_popup: PopupPanel
var adventure_screen: AdventureScreen
var pve_service: PveService
var current_run := {}
var road_row: HBoxContainer
var road_track: HBoxContainer
var stage_panel: PanelContainer
var skills_screen: SkillsScreen
var heroes_screen: HeroesScreen
var summon_screen: SummonScreen
var companions_screen: CompanionsScreen
var artifacts_screen: ArtifactsScreen
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
var battle_hero_portrait: HeroPortrait
var hero_stats_text: Label
var exp_bar: ProgressBar
var message_text: Label
var tutorial_text: Label
var action_button: Button
var upgrade_buttons: Dictionary = {}
var nav_buttons: Dictionary = {}
var selected_tab := "Battle"
var transition_id := 0
var idle_rewards: IdleRewardService
var tutorials: TutorialService
var tutorial_popup: PopupPanel
var tutorial_title: Label
var tutorial_body: Label
var tutorial_next: Button
var tutorial_skip: Button
var offline_popup: Control
var offline_body: Label
var offline_ad_button: Button
var power_help_dialog: AcceptDialog
var active_feature_tip := ""
var onboarding_upgrade_dismissed := false
var exit_confirmation: ConfirmationDialog

func _ready() -> void:
	var test_save_path := OS.get_environment("VAEL_SAVE_PATH")
	profile = SaveData.load_from(test_save_path) if not test_save_path.is_empty() else SaveData.load_profile()
	tutorials = TutorialServiceScript.new(profile)
	idle_rewards = IdleRewardServiceScript.new(profile)
	idle_rewards.prepare(int(Time.get_unix_time_from_system()))
	var audio := get_node_or_null("/root/AudioService")
	if audio != null:
		audio.apply_settings(profile.audio_settings)
		audio.set_music("home")
	ProgressionService.new(profile).refresh()
	if profile.offline_last_claim == 0:
		profile.offline_last_claim = int(Time.get_unix_time_from_system())
		profile.save()
	pve_service = PveService.new(profile)
	battle = BattleScript.new()
	add_child(battle)
	battle.changed.connect(_refresh_ui)
	battle.message.connect(_show_message)
	battle.stage_cleared.connect(_on_stage_cleared)
	battle.battle_lost.connect(_on_battle_lost)
	battle.mode_finished.connect(_on_mode_finished)
	battle.equipment_dropped.connect(_on_equipment_dropped)
	battle.hero_leveled.connect(_on_hero_leveled)
	battle.skill_cast.connect(_on_skill_cast)
	battle.companion_attack.connect(_on_companion_attack)
	_build_ui()
	cloud_sync_timer = Timer.new()
	cloud_sync_timer.one_shot = true
	cloud_sync_timer.wait_time = 4.0
	cloud_sync_timer.timeout.connect(_auto_cloud_sync)
	add_child(cloud_sync_timer)
	if profile.campaign_complete:
		_show_message("Infernal campaign complete.")
		_refresh_ui()
	elif profile.stage == 20 and profile.boss_retry_required:
		_show_message("The region boss awaits. Tap Retry Boss to begin.")
		_refresh_ui()
	else:
		battle.start(profile)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_back_request()
		return
	if profile == null: return
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED]:
		profile.offline_last_claim = maxi(profile.offline_last_claim, int(Time.get_unix_time_from_system()))
		profile.save()
		if str(profile.account_meta.get("account_type", "Guest")) == "Linked": AccountService.new(profile).sync_now()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		idle_rewards.prepare(int(Time.get_unix_time_from_system()))
		_show_offline_popup()

func _handle_back_request() -> void:
	if login_popup != null and login_popup.visible:
		login_popup.hide()
		return
	if power_help_dialog != null and power_help_dialog.visible:
		power_help_dialog.hide()
		return
	if tutorial_popup != null and tutorial_popup.visible:
		tutorial_popup.hide()
		return
	if offline_popup != null and offline_popup.visible:
		offline_popup.hide()
		return
	if selected_tab == "Adventure" and adventure_screen != null and str(adventure_screen.get("view")) != "hub":
		adventure_screen._open("hub")
		return
	if selected_tab == "Heroes" and heroes_screen != null and str(heroes_screen.get("view")) != "roster":
		heroes_screen._back()
		return
	if selected_tab != "Battle":
		_select_tab("Battle")
		return
	if exit_confirmation == null:
		exit_confirmation = ConfirmationDialog.new()
		exit_confirmation.title = "Leave Crown of Vael?"
		exit_confirmation.dialog_text = "Your progress is saved automatically."
		exit_confirmation.ok_button_text = "EXIT"
		exit_confirmation.confirmed.connect(get_tree().quit)
		add_child(exit_confirmation)
	exit_confirmation.popup_centered()

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
	heroes_screen = HeroesScreenScript.new()
	heroes_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heroes_screen.add_theme_constant_override("separation", 12)
	heroes_area.add_child(heroes_screen)
	heroes_screen.configure(profile, battle, _on_hero_changed, _retreat_for_hero)
	equipment_area = _screen_scroll(root)
	equipment_content = _screen_content(equipment_area)
	skills_area = _screen_scroll(root)
	skills_screen = SkillsScreenScript.new()
	skills_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skills_screen.add_theme_constant_override("separation", 12)
	skills_area.add_child(skills_screen)
	skills_screen.configure(profile, battle, _on_skills_changed)
	summon_area = _screen_scroll(root)
	summon_screen = SummonScreenScript.new()
	summon_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summon_screen.add_theme_constant_override("separation", 12)
	summon_area.add_child(summon_screen)
	summon_screen.configure(profile, _on_summon_changed, _select_tab)
	companions_area = _screen_scroll(root)
	companions_screen = CompanionsScreenScript.new()
	companions_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	companions_screen.add_theme_constant_override("separation", 12)
	companions_area.add_child(companions_screen)
	companions_screen.configure(profile, battle, _on_build_changed, _select_tab.bind("Summon"))
	artifacts_area = _screen_scroll(root)
	artifacts_screen = ArtifactsScreenScript.new()
	artifacts_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	artifacts_screen.add_theme_constant_override("separation", 12)
	artifacts_area.add_child(artifacts_screen)
	artifacts_screen.configure(profile, battle, _on_build_changed, _select_tab.bind("Summon"))
	adventure_area = _screen_scroll(root)
	adventure_screen = AdventureScreenScript.new()
	adventure_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	adventure_screen.add_theme_constant_override("separation", 14)
	adventure_area.add_child(adventure_screen)
	adventure_screen.configure(profile, _start_pve, _return_campaign, _select_campaign_stage)
	adventure_screen.tutorial_feature_opened.connect(_show_feature_for_tab)
	quests_area = _screen_scroll(root)
	quests_screen = QuestsScreenScript.new()
	quests_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quests_area.add_child(quests_screen)
	quests_screen.configure(profile, _on_progression_claimed)
	login_area = _screen_scroll(root)
	login_screen = LoginScreenScript.new()
	login_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	login_area.add_child(login_screen)
	login_screen.configure(profile, _on_progression_claimed)
	battle_pass_area = _screen_scroll(root)
	battle_pass_screen = BattlePassScreenScript.new()
	battle_pass_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_pass_area.add_child(battle_pass_screen)
	battle_pass_screen.configure(profile, _on_progression_claimed)
	shop_area = _screen_scroll(root)
	shop_screen = ShopScreenScript.new()
	shop_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_area.add_child(shop_screen)
	shop_screen.configure(profile, _on_progression_claimed)
	account_area = _screen_scroll(root)
	account_screen = AccountScreenScript.new()
	account_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	account_area.add_child(account_screen)
	account_screen.configure(profile, _on_account_social_changed)
	social_area = _screen_scroll(root)
	social_screen = SocialScreenScript.new()
	social_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	social_area.add_child(social_screen)
	social_screen.configure(profile, _on_account_social_changed)
	social_screen.tutorial_feature_opened.connect(_show_feature_for_tab)
	settings_area = _screen_scroll(root)
	settings_screen = SettingsScreenScript.new()
	settings_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_area.add_child(settings_screen)
	settings_screen.configure(profile, _on_settings_changed)
	_build_navigation(root)
	_build_guidance_popups()
	_refresh_progression_screens()
	call_deferred("_show_onboarding_or_offline")

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
	var power_help := Button.new()
	power_help.text = "?"
	power_help.custom_minimum_size = Vector2(54, 54)
	power_help.pressed.connect(_show_power_help)
	metrics.add_child(power_help)

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
	stage_panel = panel
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
	region_text = _label(str(CampaignData.REGIONS[0]["name"]), 30, Color("a9d6ad"))
	box.add_child(region_text)
	wave_text = _label("", 29, MUTED)
	box.add_child(wave_text)
	road_row = HBoxContainer.new()
	box.add_child(road_row)
	road_text = _label("", 25, GOLD)
	road_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	road_row.add_child(road_text)
	road_row.add_child(_label("5 E  10 E  15 E  20 BOSS", 23, Color("d8a399")))
	road_track = HBoxContainer.new()
	road_track.add_theme_constant_override("separation", 6)
	box.add_child(road_track)
	for i in 20:
		var marker := ColorRect.new()
		marker.color = Color("52605c")
		marker.custom_minimum_size.y = 17
		marker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		road_track.add_child(marker)
		stage_markers.append(marker)

func _build_battle_area() -> void:
	battlefield_host = Control.new()
	battlefield_host.custom_minimum_size.y = 390
	battlefield_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_area.add_child(battlefield_host)
	pixel_battle_background = TextureRect.new()
	pixel_battle_background.name = "GreenvalePixelBattleBackground"
	pixel_battle_background.visible = false
	pixel_battle_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pixel_battle_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pixel_battle_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pixel_battle_background.modulate = Color(0.80, 0.84, 0.81, 1.0)
	pixel_battle_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pixel_battle_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battlefield_host.add_child(pixel_battle_background)
	battlefield = BattlefieldScript.new()
	battlefield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battlefield.pixel_background_layer = pixel_battle_background
	battlefield.set_battle(battle)
	battlefield_host.add_child(battlefield)

	var skill_panel := _panel()
	battle_area.add_child(skill_panel)
	var skill_box := VBoxContainer.new()
	skill_box.add_theme_constant_override("separation", 6)
	skill_panel.add_child(skill_box)
	var skill_row := HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", 17)
	skill_box.add_child(skill_row)
	skill_bar = SkillBarScript.new()
	skill_bar.custom_minimum_size = Vector2(530, 112)
	skill_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_bar.battle = battle
	skill_row.add_child(skill_bar)
	var skill_copy := VBoxContainer.new()
	skill_row.add_child(skill_copy)
	skill_copy.add_child(_label("AUTO", 28, GOLD))
	skill_copy.add_child(_label("4 SLOTS", 23, MUTED))
	tutorial_text = _label("AUTO COMBAT  |  Enemies drop Gold + EXP. Upgrade below; stages advance on their own.", 24, Color("a9d6ad"))
	tutorial_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_box.add_child(tutorial_text)

	var hero_panel := _panel()
	battle_area.add_child(hero_panel)
	var hero_box := VBoxContainer.new()
	hero_box.add_theme_constant_override("separation", 5)
	hero_panel.add_child(hero_box)
	var hero_heading := HBoxContainer.new()
	hero_box.add_child(hero_heading)
	battle_hero_portrait = HeroPortraitScript.new()
	battle_hero_portrait.custom_minimum_size = Vector2(58, 70)
	hero_heading.add_child(battle_hero_portrait)
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
	var rows := VBoxContainer.new()
	panel.add_child(rows)
	for tab_row in [["Battle", "Adventure", "Heroes", "Equipment"], ["Skills", "Summon", "Quests", "Login"], ["Pass", "Shop", "Account", "Social"], ["Settings"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		rows.add_child(row)
		for tab_name in tab_row:
			var button := Button.new()
			button.text = tab_name
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.custom_minimum_size.y = 72
			button.add_theme_font_size_override("font_size", 25)
			button.pressed.connect(_select_tab.bind(tab_name))
			button.pressed.connect(_play_audio.bind("button_click", "UI"))
			row.add_child(button)
			nav_buttons[tab_name] = button
	login_popup = PopupPanel.new()
	login_popup.name = "DailyLoginPopup"
	add_child(login_popup)
	_update_navigation()

func _build_guidance_popups() -> void:
	tutorial_popup = PopupPanel.new()
	tutorial_popup.name = "TutorialPopup"
	add_child(tutorial_popup)
	var card := _panel()
	card.custom_minimum_size = Vector2(690, 0)
	tutorial_popup.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	card.add_child(box)
	tutorial_title = _label("", 40, GOLD)
	tutorial_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tutorial_title)
	tutorial_body = _label("", 30, PALE)
	tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(tutorial_body)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)
	tutorial_next = Button.new()
	tutorial_next.custom_minimum_size.y = 132
	tutorial_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_next.add_theme_font_size_override("font_size", 28)
	tutorial_next.pressed.connect(_on_tutorial_next)
	actions.add_child(tutorial_next)
	tutorial_skip = Button.new()
	tutorial_skip.text = "SKIP TUTORIAL"
	tutorial_skip.custom_minimum_size.y = 132
	tutorial_skip.add_theme_font_size_override("font_size", 24)
	tutorial_skip.pressed.connect(_on_tutorial_skip)
	actions.add_child(tutorial_skip)
	offline_popup = Control.new()
	offline_popup.name = "OfflineRewardsPopup"
	offline_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offline_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	offline_popup.visible = false
	add_child(offline_popup)
	var scrim := ColorRect.new()
	scrim.color = Color(0.02, 0.05, 0.06, 0.76)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	offline_popup.add_child(scrim)
	var offline_card := _panel()
	offline_card.custom_minimum_size = Vector2(690, 330)
	offline_card.set_anchors_preset(Control.PRESET_CENTER)
	offline_card.offset_left = -345
	offline_card.offset_right = 345
	offline_card.offset_top = -165
	offline_card.offset_bottom = 165
	offline_card.mouse_filter = Control.MOUSE_FILTER_STOP
	offline_popup.add_child(offline_card)
	var offline_box := VBoxContainer.new()
	offline_box.add_theme_constant_override("separation", 14)
	offline_card.add_child(offline_box)
	var offline_title := _label("WELCOME BACK\nOFFLINE REWARDS", 38, GOLD)
	offline_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offline_box.add_child(offline_title)
	offline_body = _label("", 32, PALE)
	offline_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offline_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	offline_box.add_child(offline_body)
	var claims := HBoxContainer.new()
	claims.add_theme_constant_override("separation", 10)
	offline_box.add_child(claims)
	var claim := Button.new()
	claim.text = "CLAIM"
	claim.custom_minimum_size.y = 132
	claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim.add_theme_font_size_override("font_size", 29)
	claim.pressed.connect(_claim_idle_reward.bind(false))
	claims.add_child(claim)
	offline_ad_button = Button.new()
	offline_ad_button.text = "2× REWARD"
	offline_ad_button.text = "2× REWARD • DEV SIM"
	offline_ad_button.custom_minimum_size.y = 132
	offline_ad_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offline_ad_button.add_theme_font_size_override("font_size", 29)
	offline_ad_button.pressed.connect(_claim_idle_reward.bind(true))
	claims.add_child(offline_ad_button)
	power_help_dialog = AcceptDialog.new()
	power_help_dialog.title = "POWER"
	power_help_dialog.dialog_text = "Power is a summary estimate shaped by hero stats, upgrades, equipment, skills and passives, companions, artifacts, and hero stars or evolution. It helps compare builds but cannot predict every battle outcome."
	add_child(power_help_dialog)

func _show_onboarding_or_offline() -> void:
	if tutorials.onboarding_active():
		if not bool(profile.tutorial_state.steps.get("battle", false)):
			_show_onboarding_step("battle")
		elif not bool(profile.tutorial_state.steps.get("upgrade", false)):
			_show_onboarding_step("upgrade")
		elif not bool(profile.tutorial_state.steps.get("waves", false)):
			_show_onboarding_step("waves")
	else:
		_show_startup_reward_popup()

func _show_startup_reward_popup() -> void:
	if not profile.offline_pending_rewards.is_empty():
		_show_offline_popup()
	elif profile.last_login_reward_date != CalendarService.day():
		_show_login_popup()

func _show_onboarding_step(id: String) -> void:
	if tutorial_popup == null or not tutorials.onboarding_active(): return
	active_feature_tip = ""
	tutorial_skip.visible = true
	var step_index := 0
	for index in TutorialServiceScript.STEPS.size():
		if str(TutorialServiceScript.STEPS[index].id) == id: step_index = index
	var step: Dictionary = TutorialServiceScript.STEPS[step_index]
	tutorial_title.text = "FIRST STEPS  •  %s" % str(step.title)
	tutorial_body.text = str(step.body)
	if id == "battle":
		tutorial_next.text = "SHOW ME"
	elif id == "upgrade":
		tutorial_next.text = "REMIND ME LATER"
	else:
		tutorial_next.text = "GOT IT"
	tutorial_next.disabled = false
	_highlight_first_upgrade(id == "upgrade")
	tutorial_popup.popup_centered(Vector2i(720, 360))

func _highlight_first_upgrade(enabled: bool) -> void:
	var button := upgrade_buttons.get("atk") as Button
	if button == null: return
	if not enabled:
		for style_name in ["normal", "hover", "pressed", "disabled"]: button.remove_theme_stylebox_override(style_name)
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("31453a")
	normal.border_color = GOLD
	normal.set_border_width_all(5)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("405744")
	button.add_theme_stylebox_override("hover", hover)

func _on_tutorial_next() -> void:
	if active_feature_tip != "":
		_on_feature_ack()
		tutorial_popup.hide()
		return
	var id := "battle" if tutorial_title.text.ends_with("BATTLE") else "upgrade" if tutorial_title.text.ends_with("UPGRADE") else "waves"
	if id == "battle":
		tutorials.mark_step("battle")
		profile.tutorial_state["current_step"] = "upgrade"
		tutorial_popup.hide()
		if profile.gold >= GameData.upgrade_cost(int(profile.upgrades.get("atk", 0))): _show_onboarding_step("upgrade")
		else: onboarding_upgrade_dismissed = false
	elif id == "upgrade":
		onboarding_upgrade_dismissed = true
		_highlight_first_upgrade(false)
		tutorial_popup.hide()
	else:
		tutorials.mark_step("waves")
		tutorial_popup.hide()
		_show_startup_reward_popup()

func _on_tutorial_skip() -> void:
	tutorials.skip()
	_highlight_first_upgrade(false)
	tutorial_popup.hide()
	_show_startup_reward_popup()

func _maybe_show_upgrade_prompt() -> void:
	if tutorials == null or not tutorials.onboarding_active() or not bool(profile.tutorial_state.steps.get("battle", false)) or onboarding_upgrade_dismissed or bool(profile.tutorial_state.steps.get("upgrade", false)) or tutorial_popup != null and tutorial_popup.visible: return
	if profile.gold >= GameData.upgrade_cost(int(profile.upgrades.get("atk", 0))):
		if selected_tab != "Battle": _select_tab("Battle")
		_show_onboarding_step("upgrade")

func _show_feature_for_tab(tab_name: String) -> void:
	if tutorials == null: return
	var id := "Battle Pass" if tab_name == "Pass" else tab_name
	if id == "Summon" and profile.gems < SummonData.COSTS[1] and int(profile.summon_tickets.get("equipment", 0)) <= 0 and not SummonService.new(profile).can_summon("equipment", 1, "daily"): return
	if id == "Equipment" and profile.inventory.is_empty(): return
	if tutorials.feature_seen(id): return
	var copy: Array = tutorials.feature_copy(id)
	if copy.is_empty(): return
	active_feature_tip = id
	tutorial_title.text = str(copy[0])
	tutorial_body.text = str(copy[1])
	tutorial_next.text = "GOT IT"
	tutorial_next.disabled = false
	tutorial_skip.visible = false
	tutorial_popup.popup_centered(Vector2i(720, 360))

func _show_power_help() -> void:
	power_help_dialog.popup_centered(Vector2i(760, 260))

func _show_offline_popup() -> void:
	if offline_popup == null or idle_rewards == null or idle_rewards.profile.offline_pending_rewards.is_empty(): return
	var reward: Dictionary = profile.offline_pending_rewards
	var seconds := int(reward.get("seconds", 0))
	var hours := floori(float(seconds) / 3600.0)
	var minutes := floori(float(seconds % 3600) / 60.0)
	offline_body.text = "Away %dh %dm\nGold  +%s\nHero EXP  +%s" % [hours, minutes, NumberFormatScript.compact(int(reward.get("gold", 0))), NumberFormatScript.compact(int(reward.get("exp", 0)))]
	offline_ad_button.disabled = false
	offline_popup.visible = true

func _claim_idle_reward(double_reward: bool) -> void:
	var ads: RewardedAdProvider = MonetizationService.new(profile).ads
	var previous_level := profile.level
	var result: Dictionary = idle_rewards.claim(double_reward, int(Time.get_unix_time_from_system()), ads)
	if result.is_empty():
		offline_body.text = "The rewarded ad is unavailable. Claim the base reward instead."
		offline_ad_button.disabled = true
		return
	offline_popup.hide()
	_play_audio("claim_reward", "UI")
	if battle.active: battle.refresh_hero_stats()
	_refresh_ui()
	if profile.level > 1 and selected_tab == "Heroes": _refresh_progression_screens()
	_show_message("Offline rewards claimed: +%s Gold, +%s Hero EXP." % [NumberFormatScript.compact(int(result.gold)), NumberFormatScript.compact(int(result.exp))])
	gold_text.pivot_offset = gold_text.size * 0.5
	var reward_tween := create_tween()
	reward_tween.tween_property(gold_text, "scale", Vector2(1.16, 1.16), 0.12)
	reward_tween.tween_property(gold_text, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if profile.level > previous_level and battlefield != null: battlefield.show_level_up(profile.level, 0)
	if battlefield != null and result.gold > 0:
		battlefield.vfx.label(Vector2(battlefield.size.x * 0.5, battlefield.size.y * 0.45), "+%s GOLD" % NumberFormatScript.compact(int(result.gold)), GOLD, 32, 0.8)
		battlefield.queue_redraw()
	if profile.last_login_reward_date != CalendarService.day(): _show_login_popup()

func _on_feature_ack() -> void:
	if active_feature_tip != "": tutorials.acknowledge_feature(active_feature_tip)
	active_feature_tip = ""
	tutorial_skip.visible = true

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
	var stats := profile.hero_stats()
	gold_text.text = NumberFormatScript.compact(profile.gold)
	gems_text.text = NumberFormatScript.compact(profile.gems)
	power_text.text = NumberFormatScript.compact(profile.power())
	var campaign := str(battle.mode_config.get("mode", "campaign")) == "campaign"
	stage_text.text = CampaignData.label(profile.campaign_difficulty, profile.region, profile.stage).to_upper() if campaign else PveData.mode_label(battle.mode_config)
	region_text.text = CampaignData.REGIONS[profile.region - 1]["name"] if campaign else battle.mode_detail()
	road_row.visible = campaign
	road_track.visible = campaign
	road_text.text = "REGION ROAD  %d/20" % profile.stage
	for i in stage_markers.size():
		stage_markers[i].color = (Color("d48463") if i == 19 else (Color("bf9bcf") if (i + 1) in [5, 10, 15] else GOLD)) if i < profile.stage else Color("52605c")
	if not campaign:
		wave_text.text = "%s  |  %d enemies remaining" % [battle.mode_detail(), _living_enemies()]
	elif profile.campaign_complete:
		wave_text.text = "Region complete"
	elif profile.stage == 20:
		wave_text.text = "BOSS | %s" % CampaignData.REGIONS[profile.region - 1]["boss"]
	else:
		wave_text.text = "Wave %d/3  |  %d enemies remaining" % [battle.wave, _living_enemies()]
	boss_text.visible = campaign and profile.stage == 20 and battle.active
	boss_text.text = "00:%02d" % ceili(battle.boss_time)
	boss_text.add_theme_color_override("font_color", Color("ff786c") if battle.boss_time <= 10.0 else Color("ffb38d"))
	boss_text.add_theme_font_size_override("font_size", 39 if battle.boss_time <= 10.0 else 34)
	var hp := battle.hero_hp if battle.active else float(stats["hp"])
	var hero_id := profile.selected_hero_id
	var hero_record: Dictionary = profile.heroes[hero_id]
	if battle_hero_portrait != null:
		battle_hero_portrait.hero_id = hero_id
		battle_hero_portrait.evolution = int(hero_record.get("evolution", 0))
		battle_hero_portrait.profile_frame = str(profile.equipped_cosmetics.get("Profile Frame", ""))
		battle_hero_portrait.queue_redraw()
	var rarity := int(HeroData.HEROES[hero_id]["rarity"])
	hero_level_text.text = "◆ %s  |  LV %d" % [HeroData.title(hero_id, hero_record).to_upper(), profile.level]
	hero_level_text.add_theme_color_override("font_color", EquipmentData.COLORS[rarity])
	hero_hp_text.text = "HP %s/%s" % [NumberFormatScript.compact(ceili(hp)), NumberFormatScript.compact(ceili(float(stats["hp"])))]
	hero_stats_text.text = "%s  •  %s  |  ATK %d    ARMOR %d    SPEED %.2f/s\nCRIT %d%%    CRIT DMG %d%%" % [EquipmentData.RARITIES[rarity].to_upper(), HeroData.element(hero_id, hero_record).to_upper(), roundi(float(stats["atk"])), roundi(float(stats["armor"])), float(stats["speed"]), roundi(float(stats["crit_chance"]) * 100), roundi(float(stats["crit_damage"]) * 100)]
	exp_bar.max_value = GameData.exp_to_next(profile.level)
	exp_bar.value = profile.exp
	if heroes_exp_text != null:
		heroes_exp_text.text = "HERO EXP  %d / %d" % [profile.exp, GameData.exp_to_next(profile.level)]
		heroes_exp_bar.max_value = GameData.exp_to_next(profile.level)
		heroes_exp_bar.value = profile.exp
		heroes_level_text.text = "LEVEL %d    POWER %d" % [profile.level, profile.power()]
	action_button.visible = campaign and profile.stage == 20 and profile.boss_retry_required and not battle.active and not profile.campaign_complete
	tutorial_text.visible = campaign and profile.region == 1 and profile.stage == 1 and not profile.campaign_complete
	for stat in upgrade_buttons:
		var rank := int(profile.upgrades[stat])
		var cost := GameData.upgrade_cost(rank)
		var button: Button = upgrade_buttons[stat]
		button.text = "%s +%d\n%d GOLD" % [str(stat).to_upper(), rank, cost]
		button.disabled = profile.gold < cost
	_maybe_show_upgrade_prompt()
	skill_bar.queue_redraw()
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
	stage_panel.visible = tab_name not in ["Adventure", "Quests", "Login", "Pass", "Shop", "Account", "Social", "Settings"]
	battle_area.visible = tab_name == "Battle"
	heroes_area.visible = tab_name == "Heroes"
	equipment_area.visible = tab_name == "Equipment"
	skills_area.visible = tab_name == "Skills"
	summon_area.visible = tab_name == "Summon"
	companions_area.visible = tab_name == "Companions"
	artifacts_area.visible = tab_name == "Artifacts"
	adventure_area.visible = tab_name == "Adventure"
	quests_area.visible = tab_name == "Quests"
	login_area.visible = tab_name == "Login"
	battle_pass_area.visible = tab_name == "Pass"
	shop_area.visible = tab_name == "Shop"
	account_area.visible = tab_name == "Account"
	social_area.visible = tab_name == "Social"
	settings_area.visible = tab_name == "Settings"
	placeholder_area.visible = false
	placeholder_title.text = tab_name.to_upper()
	if tab_name in ["Heroes", "Equipment"]:
		_refresh_progression_screens()
	elif tab_name == "Skills":
		skills_screen.refresh()
	elif tab_name == "Summon":
		summon_screen.refresh()
	elif tab_name == "Companions":
		companions_screen.refresh()
	elif tab_name == "Artifacts":
		artifacts_screen.refresh()
	elif tab_name == "Adventure":
		adventure_screen.refresh()
	elif tab_name == "Quests":
		quests_screen.refresh()
	elif tab_name == "Login":
		login_screen.refresh()
	elif tab_name == "Pass":
		battle_pass_screen.refresh()
	elif tab_name == "Shop":
		shop_screen.refresh()
	elif tab_name == "Account":
		account_screen.refresh()
	elif tab_name == "Social":
		social_screen.refresh()
	_update_navigation()
	_show_feature_for_tab(tab_name)

func _show_login_popup() -> void:
	if profile.last_login_reward_date == CalendarService.day(): return
	for child in login_popup.get_children(): child.queue_free()
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(680, 240)
	login_popup.add_child(box)
	box.add_child(_label("DAILY LOGIN  •  DAY %d" % [profile.daily_login_index + 1], 37, GOLD))
	var reward: Dictionary = ProgressionData.login_reward(profile.daily_login_index)
	for key in reward:
		box.add_child(_label("%d %s" % [int(reward[key]), str(key).replace("_", " ").capitalize()], 30, PALE))
	var claim := Button.new()
	claim.text = "CLAIM REWARD"
	claim.custom_minimum_size.y = 82
	claim.custom_minimum_size.y = 130
	claim.pressed.connect(_claim_login_popup)
	box.add_child(claim)
	login_popup.popup_centered()

func _claim_login_popup() -> void:
	if ProgressionService.new(profile).claim_login():
		login_popup.hide()
		login_screen.refresh()
		_on_progression_claimed()

func _on_progression_claimed() -> void:
	_play_audio("claim_reward", "UI")
	_refresh_ui()
	_update_navigation()
	_schedule_cloud_sync()
	_maybe_show_upgrade_prompt()

func _on_account_social_changed() -> void:
	_refresh_ui()
	_update_navigation()
	account_screen.refresh()
	social_screen.refresh()
	_schedule_cloud_sync()

func _schedule_cloud_sync() -> void:
	if cloud_sync_timer == null or str(profile.account_meta.get("account_type", "Guest")) != "Linked": return
	cloud_sync_timer.start()

func _auto_cloud_sync() -> void:
	if str(profile.account_meta.get("account_type", "Guest")) == "Linked":
		var result := AccountService.new(profile).sync_now()
		if selected_tab == "Account": account_screen.refresh()

func _start_pve(config: Dictionary) -> void:
	var run := pve_service.begin(config)
	if run.is_empty():
		adventure_screen.refresh()
		return
	transition_id += 1
	current_run = run
	battle.start_mode(profile, run)
	_select_tab("Battle")

func _return_campaign() -> void:
	transition_id += 1
	current_run = {}
	if profile.campaign_complete:
		battle.active = false
		battle.mode_config = {"mode": "campaign"}
		_refresh_ui()
	else:
		battle.start(profile)
	_select_tab("Battle")

func _select_campaign_stage(difficulty: int, region: int, stage: int) -> void:
	if not profile.select_campaign(difficulty, region, stage): return
	transition_id += 1
	current_run = {}
	battle.start(profile)
	_select_tab("Battle")

func _on_mode_finished(result: Dictionary) -> void:
	if current_run.is_empty():
		current_run = battle.mode_config.duplicate(true)
	var completed := pve_service.complete(current_run, result)
	adventure_screen.show_result(current_run, completed)
	artifacts_screen.refresh()
	_refresh_progression_screens()
	_select_tab("Adventure")
	_refresh_ui()
	_schedule_cloud_sync()

func _clear_content(content: VBoxContainer) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func _refresh_progression_screens() -> void:
	if heroes_screen == null:
		return
	heroes_screen.refresh()
	_build_equipment_screen()

func _on_hero_changed() -> void:
	if battle.active:
		battle.refresh_hero_stats()
	_refresh_ui()
	_schedule_cloud_sync()
	_refresh_progression_screens()
	battlefield.queue_redraw()
	battlefield.show_hero_switch(HeroData.title(profile.selected_hero_id, profile.heroes[profile.selected_hero_id]))
	_show_message("%s joins the battle." % HeroData.title(profile.selected_hero_id, profile.heroes[profile.selected_hero_id]))

func _retreat_for_hero() -> void:
	if not battle.active:
		return
	if str(battle.mode_config.get("mode", "campaign")) == "campaign":
		battle.active = false
		_show_message("At camp. Choose another hero, then return to Campaign.")
	else:
		battle._lose(false)
	heroes_screen.refresh()
	_refresh_ui()

func _build_heroes_screen() -> void:
	_clear_content(heroes_content)
	var identity := _panel()
	heroes_content.add_child(identity)
	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 16)
	identity.add_child(identity_row)
	var portrait := HeroPortraitScript.new()
	portrait.hero_id = profile.selected_hero_id
	portrait.evolution = int(profile.heroes[profile.selected_hero_id].get("evolution", 0))
	portrait.profile_frame = str(profile.equipped_cosmetics.get("Profile Frame", ""))
	portrait.custom_minimum_size = Vector2(210, 250)
	identity_row.add_child(portrait)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_row.add_child(box)
	box.add_child(_label("%s  •  %s" % [HeroData.title(profile.selected_hero_id, profile.heroes[profile.selected_hero_id]).to_upper(), str(HeroData.HEROES[profile.selected_hero_id]["role"]).to_upper()], 36, GOLD))
	box.add_child(_label("Selected hero  •  %s" % HeroData.element(profile.selected_hero_id, profile.heroes[profile.selected_hero_id]), 31, PALE))
	heroes_level_text = _label("LEVEL %d    POWER %d" % [profile.level, profile.power()], 31, Color("a9d6ad"))
	box.add_child(heroes_level_text)
	box.add_child(_label("Evolution Crests: %d  •  Hero Pieces: %d" % [profile.evolution_crests, profile.hero_pieces], 29, MUTED))
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
		copy.add_child(_label("Future hero  •  Generic pieces saved: %d" % profile.hero_pieces, 30, MUTED))
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
	headbox.add_child(_label("ARMORY  •  %s" % HeroData.title(profile.selected_hero_id, profile.heroes[profile.selected_hero_id]).to_upper(), 36, GOLD))
	headbox.add_child(_label("%d Gold    •    %d Enhancement Stones" % [profile.gold, profile.enhancement_stones], 30, PALE))
	headbox.add_child(_label("Swipe to browse slots and inventory.", 28, MUTED))
	if profile.inventory.is_empty():
		var empty := _label("No equipment yet. Battle or summon to obtain gear.", 29, MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		headbox.add_child(empty)
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
	_play_audio("equip", "UI")
	if battle.active:
		battle.refresh_hero_stats()
	_show_message(note)
	_refresh_ui()
	_refresh_progression_screens()
	_schedule_cloud_sync()

func _on_skills_changed() -> void:
	skill_bar.queue_redraw()
	_refresh_ui()
	_schedule_cloud_sync()

func _on_summon_changed() -> void:
	_refresh_ui()
	_refresh_progression_screens()
	skills_screen.refresh()
	companions_screen.refresh()
	artifacts_screen.refresh()
	_schedule_cloud_sync()
	if battle.active:
		battle.refresh_hero_stats()
	if not profile.companions.is_empty() and not tutorials.feature_seen("Companions"):
		_show_feature_for_tab("Companions")
	elif not profile.artifacts.is_empty() and not tutorials.feature_seen("Artifacts"):
		_show_feature_for_tab("Artifacts")

func _on_build_changed() -> void:
	_refresh_ui()
	_refresh_progression_screens()
	_schedule_cloud_sync()
	field_redraw()

func field_redraw() -> void:
	battlefield.queue_redraw()

func _on_equipment_dropped(item: Dictionary) -> void:
	_show_message("Equipment drop: %s!" % EquipmentData.title(item))
	battlefield.show_equipment_drop(EquipmentData.title(item), EquipmentData.COLORS[int(item["rarity"])] )
	if selected_tab == "Equipment":
		_refresh_progression_screens()
	if tutorials != null and not tutorials.feature_seen("Equipment"): _show_feature_for_tab("Equipment")

func _on_hero_leveled(new_level: int, gem_bonus: int) -> void:
	_play_audio("level_up", "SFX")
	battlefield.show_level_up(new_level, gem_bonus)
	if selected_tab == "Heroes":
		_refresh_progression_screens()

func _on_skill_cast(_id: String, _slot: int) -> void:
	ProgressionService.new(profile).report("skill_cast")
	_play_audio("skill_activation")

func _on_companion_attack(_slot: int, _target: int, amount: int) -> void:
	ProgressionService.new(profile).report("companion_damage", amount)

func _on_settings_changed() -> void:
	if battlefield != null:
		battlefield.vfx.reduced = profile.reduced_effects

func _play_audio(event: String, category := "SFX") -> void:
	if not is_inside_tree():
		return
	var audio := get_node_or_null("/root/AudioService")
	if audio != null:
		audio.play_event(event, category)

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
		var badge := MonetizationService.new(profile).bp_badge() if tab_name == "Pass" else MonetizationService.new(profile).shop_badge() if tab_name == "Shop" else SocialService.new(profile).badge() if tab_name == "Social" else ProgressionService.new(profile).badge(tab_name)
		button.text = tab_name
		var dot := button.get_node_or_null("BadgeDot") as ColorRect
		if dot == null:
			dot = ColorRect.new()
			dot.name = "BadgeDot"
			dot.color = Color("d94f52")
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.anchor_left = 1.0
			dot.anchor_right = 1.0
			dot.offset_left = -20
			dot.offset_right = -7
			dot.offset_top = 7
			dot.offset_bottom = 20
			button.add_child(dot)
		dot.visible = badge

func _buy_upgrade(stat: String) -> void:
	if profile.buy_upgrade(stat):
		_play_audio("upgrade", "UI")
		if battle.active:
			battle.refresh_hero_stats()
		_show_message("%s upgraded! Your power increased." % stat.to_upper())
		_refresh_ui()
		_schedule_cloud_sync()
		if stat == "atk" and tutorials != null and tutorials.onboarding_active() and not bool(profile.tutorial_state.steps.get("upgrade", false)):
			tutorials.mark_step("upgrade")
			_show_onboarding_step("waves")

func _on_stage_cleared() -> void:
	_schedule_cloud_sync()
	_maybe_show_upgrade_prompt()
	transition_id += 1
	var this_transition := transition_id
	var cleared_difficulty := profile.campaign_difficulty
	var cleared_region := profile.region
	var cleared_stage := profile.stage
	var gem_reward := profile.record_stage_clear(cleared_stage)
	ProgressionService.new(profile).report("campaign_stage_cleared")
	summon_screen.refresh()
	if selected_tab == "Equipment":
		_refresh_progression_screens()
	profile.selected_replay_stage = 0
	if cleared_stage == 20:
		profile.boss_retry_required = false
		if cleared_region < 10:
			profile.region += 1
			profile.stage = 1
		else:
			if cleared_difficulty < 5:
				profile.campaign_difficulty = cleared_difficulty + 1
				profile.region = 1
				profile.stage = 1
			else:
				profile.campaign_complete = true
	else:
		profile.stage += 1
	profile.world_map_region = profile.region
	profile.save()
	_play_audio("gem_reward", "SFX")
	if gem_reward > 0:
		gems_text.pivot_offset = gems_text.size * 0.5
		var reward_tween := create_tween()
		reward_tween.tween_property(gems_text, "scale", Vector2(1.18, 1.18), 0.12)
		reward_tween.tween_property(gems_text, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_show_message("%s cleared! +%d first-clear Gems." % [CampaignData.label(cleared_difficulty, cleared_region, cleared_stage), gem_reward])
	_refresh_ui()
	if profile.campaign_complete: return
	await get_tree().create_timer(1.2).timeout
	if this_transition != transition_id:
		return
	if profile.stage == 20 and profile.boss_retry_required:
		_show_message("The region boss awaits. Tap Retry Boss to begin.")
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
	_schedule_cloud_sync()
	_show_message("%s failed. Returning to stage %d." % [CampaignData.label(profile.campaign_difficulty, profile.region, failed_stage), profile.stage])
	_refresh_ui()
	await get_tree().create_timer(1.5).timeout
	if this_transition == transition_id:
		battle.start(profile)

func _on_action_pressed() -> void:
	if profile.stage != 20 or not profile.boss_retry_required:
		return
	profile.boss_retry_required = false
	profile.save()
	battle.start(profile)
