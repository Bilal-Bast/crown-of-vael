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
const CrownUI = preload("res://scripts/ui/crown_ui.gd")
const NAV_ICON_FILES := {
	"Heroes": "heroes", "Companions": "companions", "Equipment": "equipment", "Skills": "skills", "Summon": "summon",
	"Adventure": "adventure", "Artifacts": "artifacts", "Quests": "quests", "Login": "login", "Pass": "pass",
	"Shop": "shop", "Account": "account", "Social": "social", "Settings": "settings"
}

const INK := Color("111014")
const PANEL := Color("252329")
const EDGE := Color("7b7159")
const GOLD := Color("e9c87d")
const PALE := Color("e9e8d7")
const MUTED := Color("aebdb4")

var profile: SaveData
var battle: BattleController
var battlefield: Battlefield
var battlefield_host: Control
var feature_panel: PanelContainer
var feature_header: HBoxContainer
var feature_title_label: Label
var feature_screens: VBoxContainer
var feature_close_button: Button
var pixel_battle_background: TextureRect
var skill_bar: SkillBar
var battle_area: Control
var battle_lower_scroll: ScrollContainer
var battle_lower_content: VBoxContainer
var upgrade_panel: PanelContainer
var upgrade_list_scroll: ScrollContainer
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
var stage_panel: PanelContainer
var currency_panel: PanelContainer
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
var gold_text: Label
var gems_text: Label
var power_text: Label
var battle_hero_level_text: Label
var battle_hero_hp_text: Label
var battle_hero_hp_bar: ProgressBar
var hero_level_text: Label
var hero_hp_text: Label
var battle_hero_portrait: HeroPortrait
var hero_stats_text: Label
var exp_bar: ProgressBar
var tutorial_text: Label
var action_button: Button
var upgrade_buttons: Dictionary = {}
var upgrade_ranks: Dictionary = {}
var upgrade_values: Dictionary = {}
var upgrade_costs: Dictionary = {}
var upgrade_actions: Dictionary = {}
var upgrade_coins: Dictionary = {}
var upgrade_mode_buttons: Dictionary = {}
var upgrade_purchase_mode := "x1"
var skill_auto_button: Button
var nav_buttons: Dictionary = {}
var selected_tab := "Battle"
var transition_id := 0
var tab_transition: Tween
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
	CrownUI.apply_screen_scale(self, profile.reduced_effects)
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
	if what == NOTIFICATION_RESIZED:
		if battlefield_host != null:
			_update_battlefield_height()
		if is_node_ready():
			CrownUI.apply_screen_scale(self, profile.reduced_effects)
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
	_apply_ui_theme()
	var backdrop := ColorRect.new()
	backdrop.color = Color("111014")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18
	root.offset_right = -18
	root.offset_top = 0
	root.offset_bottom = -10
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	_build_top_bar()
	_build_stage_card()

	battle_area = Control.new()
	battle_area.name = "BattleTopSection"
	battle_area.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(battle_area)

	feature_panel = _panel()
	feature_panel.name = "FeatureDrawer"
	feature_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(feature_panel)
	var feature_box := VBoxContainer.new()
	feature_box.add_theme_constant_override("separation", 4)
	feature_panel.add_child(feature_box)
	feature_header = HBoxContainer.new()
	feature_header.custom_minimum_size.y = 88
	feature_header.visible = false
	feature_header.add_theme_constant_override("separation", 8)
	feature_box.add_child(feature_header)
	feature_title_label = _label("BATTLE", 30, GOLD)
	feature_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feature_title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	feature_header.add_child(feature_title_label)
	feature_close_button = Button.new()
	feature_close_button.text = "×"
	feature_close_button.custom_minimum_size = Vector2(88, 80)
	feature_close_button.tooltip_text = "Close feature"
	feature_close_button.pressed.connect(_select_tab.bind("Battle"))
	feature_header.add_child(feature_close_button)
	feature_screens = VBoxContainer.new()
	feature_screens.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feature_screens.add_theme_constant_override("separation", 0)
	feature_box.add_child(feature_screens)
	_build_battle_area()

	placeholder_area = _panel()
	placeholder_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	placeholder_area.visible = false
	feature_screens.add_child(placeholder_area)
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
	heroes_area = _screen_scroll(feature_screens)
	heroes_screen = HeroesScreenScript.new()
	heroes_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heroes_screen.add_theme_constant_override("separation", 12)
	heroes_area.add_child(heroes_screen)
	heroes_screen.configure(profile, battle, _on_hero_changed, _retreat_for_hero)
	equipment_area = _screen_scroll(feature_screens)
	equipment_content = _screen_content(equipment_area)
	skills_area = _screen_scroll(feature_screens)
	skills_screen = SkillsScreenScript.new()
	skills_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skills_screen.add_theme_constant_override("separation", 12)
	skills_area.add_child(skills_screen)
	skills_screen.configure(profile, battle, _on_skills_changed)
	summon_area = _screen_scroll(feature_screens)
	summon_screen = SummonScreenScript.new()
	summon_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summon_screen.add_theme_constant_override("separation", 12)
	summon_area.add_child(summon_screen)
	summon_screen.configure(profile, _on_summon_changed, _select_tab)
	companions_area = _screen_scroll(feature_screens)
	companions_screen = CompanionsScreenScript.new()
	companions_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	companions_screen.add_theme_constant_override("separation", 12)
	companions_area.add_child(companions_screen)
	companions_screen.configure(profile, battle, _on_build_changed, _select_tab.bind("Summon"))
	artifacts_area = _screen_scroll(feature_screens)
	artifacts_screen = ArtifactsScreenScript.new()
	artifacts_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	artifacts_screen.add_theme_constant_override("separation", 12)
	artifacts_area.add_child(artifacts_screen)
	artifacts_screen.configure(profile, battle, _on_build_changed, _select_tab.bind("Summon"))
	adventure_area = _screen_scroll(feature_screens)
	adventure_screen = AdventureScreenScript.new()
	adventure_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	adventure_screen.add_theme_constant_override("separation", 14)
	adventure_area.add_child(adventure_screen)
	adventure_screen.configure(profile, _start_pve, _return_campaign, _select_campaign_stage)
	adventure_screen.tutorial_feature_opened.connect(_show_feature_for_tab)
	quests_area = _screen_scroll(feature_screens)
	quests_screen = QuestsScreenScript.new()
	quests_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quests_area.add_child(quests_screen)
	quests_screen.configure(profile, _on_progression_claimed)
	login_area = _screen_scroll(feature_screens)
	login_screen = LoginScreenScript.new()
	login_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	login_area.add_child(login_screen)
	login_screen.configure(profile, _on_progression_claimed)
	battle_pass_area = _screen_scroll(feature_screens)
	battle_pass_screen = BattlePassScreenScript.new()
	battle_pass_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_pass_area.add_child(battle_pass_screen)
	battle_pass_screen.configure(profile, _on_progression_claimed)
	shop_area = _screen_scroll(feature_screens)
	shop_screen = ShopScreenScript.new()
	shop_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_area.add_child(shop_screen)
	shop_screen.configure(profile, _on_progression_claimed)
	account_area = _screen_scroll(feature_screens)
	account_screen = AccountScreenScript.new()
	account_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	account_area.add_child(account_screen)
	account_screen.configure(profile, _on_account_social_changed)
	social_area = _screen_scroll(feature_screens)
	social_screen = SocialScreenScript.new()
	social_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	social_area.add_child(social_screen)
	social_screen.configure(profile, _on_account_social_changed)
	social_screen.tutorial_feature_opened.connect(_show_feature_for_tab)
	settings_area = _screen_scroll(feature_screens)
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
	scroll.custom_minimum_size = Vector2(0, 240)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

func _build_top_bar() -> void:
	var panel := PanelContainer.new()
	panel.name = "TopCurrencyPanel"
	currency_panel = panel
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	top_style.set_content_margin_all(0.0)
	panel.add_theme_stylebox_override("panel", top_style)
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 10.0
	panel.offset_right = -10.0
	panel.offset_top = 5.0
	panel.offset_bottom = 98.0
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation", 5)
	box.add_child(metrics)
	gold_text = _metric(metrics, "GOLD", GOLD)
	gems_text = _metric(metrics, "GEMS", Color("a5dded"))
	power_text = _metric(metrics, "POWER", Color("d9e9ca"))
	var hero_status := HBoxContainer.new()
	hero_status.add_theme_constant_override("separation", 8)
	box.add_child(hero_status)
	battle_hero_level_text = _label("KNIGHT  •  LEVEL 1", 22, PALE)
	battle_hero_level_text.add_theme_font_size_override("font_size", 22)
	hero_status.add_child(battle_hero_level_text)
	battle_hero_hp_bar = ProgressBar.new()
	battle_hero_hp_bar.custom_minimum_size = Vector2(0, 18)
	battle_hero_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_hero_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	battle_hero_hp_bar.show_percentage = false
	hero_status.add_child(battle_hero_hp_bar)
	battle_hero_hp_text = _label("HP 0 / 0", 22, Color("9fd49f"))
	battle_hero_hp_text.add_theme_font_size_override("font_size", 22)
	battle_hero_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hero_status.add_child(battle_hero_hp_text)

func _metric(parent: HBoxContainer, heading: String, value_color: Color) -> Label:
	var metric_panel := PanelContainer.new()
	var capsule := StyleBoxFlat.new()
	capsule.bg_color = Color("101820", 0.60)
	var capsule_edge := value_color
	capsule_edge.a = 0.78
	capsule.border_color = capsule_edge
	capsule.set_border_width_all(2)
	capsule.set_corner_radius_all(14)
	capsule.content_margin_left = 10
	capsule.content_margin_right = 10
	capsule.content_margin_top = 3
	capsule.content_margin_bottom = 3
	metric_panel.add_theme_stylebox_override("panel", capsule)
	metric_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metric_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(metric_panel)
	var value_row := HBoxContainer.new()
	value_row.alignment = BoxContainer.ALIGNMENT_CENTER
	value_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_row.add_theme_constant_override("separation", 5)
	metric_panel.add_child(value_row)
	metric_panel.tooltip_text = heading
	var currency_icon: Texture2D = PixelUiIcons.gold_coin() if heading == "GOLD" else (PixelUiIcons.gems() if heading == "GEMS" else PixelUiIcons.navigation("Battle"))
	if currency_icon != null:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = currency_icon
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		value_row.add_child(icon)
	var value := _label("0", 28, value_color)
	value.add_theme_font_size_override("font_size", 28)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_row.add_child(value)
	return value

func _build_stage_card() -> void:
	var panel := _panel()
	panel.name = "BattleStagePanel"
	stage_panel = panel
	stage_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var stage_style := StyleBoxFlat.new()
	stage_style.bg_color = Color("11161a", 0.36)
	stage_style.border_color = Color("c3a773", 0.52)
	stage_style.set_border_width_all(1)
	stage_style.set_corner_radius_all(10)
	stage_style.content_margin_left = 8
	stage_style.content_margin_right = 8
	stage_style.content_margin_top = 3
	stage_style.content_margin_bottom = 3
	stage_panel.add_theme_stylebox_override("panel", stage_style)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 8)
	panel.add_child(heading)
	stage_text = _label("", 36, PALE)
	stage_text.add_theme_font_size_override("font_size", 30)
	stage_text.clip_text = true
	stage_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(stage_text)
	action_button = Button.new()
	action_button.text = "RETRY"
	action_button.custom_minimum_size = Vector2(118, 42)
	action_button.add_theme_font_size_override("font_size", 20)
	action_button.visible = false
	CrownUI.set_button_role(action_button, &"DangerActionButton")
	action_button.pressed.connect(_on_action_pressed)
	heading.add_child(action_button)

func _build_battle_area() -> void:
	battlefield_host = Control.new()
	battlefield_host.name = "BattlefieldHost"
	battlefield_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_area.add_child(battlefield_host)
	_update_battlefield_height()
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
	var stage_overlay := Control.new()
	stage_overlay.name = "BattleStageOverlay"
	stage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield_host.add_child(stage_overlay)
	stage_overlay.add_child(currency_panel)
	currency_panel.anchor_left = 0.0
	currency_panel.anchor_right = 1.0
	currency_panel.anchor_top = 0.0
	currency_panel.anchor_bottom = 0.0
	currency_panel.offset_top = 0.0
	currency_panel.offset_bottom = 98.0
	stage_panel.anchor_left = 0.12
	stage_panel.anchor_right = 0.88
	stage_panel.anchor_top = 0.0
	stage_panel.anchor_bottom = 0.0
	stage_panel.offset_top = 102.0
	stage_panel.offset_bottom = 255.0
	stage_overlay.add_child(stage_panel)
	var skill_panel := _panel()
	skill_panel.name = "BattleSkillPanel"
	skill_panel.anchor_left = 0.0
	skill_panel.anchor_right = 1.0
	skill_panel.anchor_top = 1.0
	skill_panel.anchor_bottom = 1.0
	skill_panel.offset_left = 8.0
	skill_panel.offset_right = -8.0
	skill_panel.offset_top = -164.0
	skill_panel.offset_bottom = -4.0
	battlefield_host.add_child(skill_panel)
	var skill_margins := MarginContainer.new()
	skill_margins.mouse_filter = Control.MOUSE_FILTER_PASS
	skill_margins.add_theme_constant_override("margin_left", 124)
	skill_margins.add_theme_constant_override("margin_right", 124)
	skill_margins.add_theme_constant_override("margin_top", 0)
	skill_margins.add_theme_constant_override("margin_bottom", 0)
	skill_panel.add_child(skill_margins)
	var skill_box := VBoxContainer.new()
	skill_box.add_theme_constant_override("separation", 0)
	skill_margins.add_child(skill_box)
	var skill_row := HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", 9)
	skill_box.add_child(skill_row)
	skill_auto_button = Button.new()
	skill_auto_button.name = "SkillAutoButton"
	skill_auto_button.custom_minimum_size = Vector2(82, 94)
	skill_auto_button.pressed.connect(_toggle_skill_auto)
	var auto_style := StyleBoxFlat.new()
	auto_style.bg_color = Color("172525")
	auto_style.border_color = Color("7b7159")
	auto_style.set_border_width_all(2)
	auto_style.border_width_bottom = 4
	auto_style.set_corner_radius_all(20)
	skill_auto_button.add_theme_stylebox_override("normal", auto_style)
	skill_auto_button.add_theme_stylebox_override("hover", auto_style)
	skill_auto_button.add_theme_font_size_override("font_size", 21)
	skill_row.add_child(skill_auto_button)
	skill_bar = SkillBarScript.new()
	skill_bar.custom_minimum_size = Vector2(530, 104)
	skill_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_bar.battle = battle
	skill_bar.manual_skill_requested.connect(_on_manual_skill_requested)
	skill_row.add_child(skill_bar)

	battle_lower_scroll = ScrollContainer.new()
	battle_lower_scroll.name = "BattleLowerControlsScroll"
	battle_lower_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_lower_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_lower_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	feature_screens.add_child(battle_lower_scroll)
	battle_lower_content = VBoxContainer.new()
	battle_lower_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battle_lower_scroll.add_child(battle_lower_content)
	upgrade_list_scroll = battle_lower_scroll
	upgrade_panel = _panel()
	upgrade_panel.name = "BattleUpgradesPanel"
	upgrade_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_lower_content.add_child(upgrade_panel)
	var upgrade_box := VBoxContainer.new()
	upgrade_box.add_theme_constant_override("separation", 6)
	upgrade_panel.add_child(upgrade_box)
	var upgrade_heading := HBoxContainer.new()
	upgrade_box.add_child(upgrade_heading)
	var heading_label := _label("BATTLE UPGRADES", 30, GOLD)
	heading_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_heading.add_child(heading_label)
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 4)
	upgrade_heading.add_child(mode_row)
	for mode in ["x1", "x10", "MAX"]:
		var mode_button := Button.new()
		mode_button.name = "UpgradeMode_%s" % mode
		mode_button.text = mode
		mode_button.custom_minimum_size = Vector2(60, 42)
		mode_button.add_theme_font_size_override("font_size", 18)
		mode_button.pressed.connect(_set_upgrade_purchase_mode.bind(mode))
		mode_row.add_child(mode_button)
		upgrade_mode_buttons[mode] = mode_button
	var upgrade_rows := VBoxContainer.new()
	upgrade_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_rows.add_theme_constant_override("separation", 7)
	upgrade_box.add_child(upgrade_rows)
	for stat in GameData.UPGRADEABLE_STATS:
		var card := PanelContainer.new()
		card.name = "UpgradeCard_%s" % stat
		card.custom_minimum_size.y = 150
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color("25313a")
		card_style.border_color = Color("817451")
		card_style.set_border_width_all(2)
		card_style.border_width_bottom = 4
		card_style.set_corner_radius_all(7)
		card_style.set_content_margin_all(7)
		card.add_theme_stylebox_override("panel", card_style)
		upgrade_rows.add_child(card)
		var card_row := HBoxContainer.new()
		card_row.add_theme_constant_override("separation", 9)
		card.add_child(card_row)
		var icon_slot := Control.new()
		icon_slot.custom_minimum_size = Vector2(84, 84)
		icon_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		card_row.add_child(icon_slot)
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = _upgrade_stat_icon(stat)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_slot.add_child(icon)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.alignment = BoxContainer.ALIGNMENT_CENTER
		details.add_theme_constant_override("separation", 0)
		card_row.add_child(details)
		var name_label := _label(_upgrade_stat_label(stat), 35, PALE)
		if stat == "crit_chance": name_label.text = "CRIT CHANCE"
		details.add_child(name_label)
		var rank_label := _label("LV 0", 27, GOLD)
		details.add_child(rank_label)
		var value_label := _label("0", 37, Color("d8dfd4"))
		details.add_child(value_label)
		var button := Button.new()
		button.name = "Upgrade_%s" % stat.capitalize()
		button.custom_minimum_size = Vector2(270, 124)
		button.pressed.connect(_buy_upgrade.bind(stat))
		button.add_theme_stylebox_override("normal", _enhance_button_style())
		button.add_theme_stylebox_override("hover", _enhance_button_style(true))
		button.add_theme_stylebox_override("pressed", _enhance_button_style(true))
		button.add_theme_stylebox_override("disabled", _enhance_button_style(false, true))
		card_row.add_child(button)
		var button_content := VBoxContainer.new()
		button_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button_content.alignment = BoxContainer.ALIGNMENT_CENTER
		button_content.add_theme_constant_override("separation", 0)
		button.add_child(button_content)
		var action_label := _label("ENHANCE", 31, Color("e8e4d5"))
		action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button_content.add_child(action_label)
		upgrade_actions[stat] = action_label
		var price_row := HBoxContainer.new()
		price_row.alignment = BoxContainer.ALIGNMENT_CENTER
		price_row.add_theme_constant_override("separation", 2)
		button_content.add_child(price_row)
		var coin := TextureRect.new()
		coin.custom_minimum_size = Vector2(25, 25)
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin.texture = PixelUiIcons.gold_coin()
		coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		price_row.add_child(coin)
		var cost_label := _label("0", 29, GOLD)
		price_row.add_child(cost_label)
		upgrade_buttons[stat] = button
		upgrade_ranks[stat] = rank_label
		upgrade_values[stat] = value_label
		upgrade_costs[stat] = cost_label
		upgrade_coins[stat] = coin
	_set_upgrade_purchase_mode("x1")
	_update_skill_auto_button()

func _update_battlefield_height() -> void:
	if battle_area == null:
		return
	var viewport_height: float = size.y if size.y > 0.0 else get_viewport_rect().size.y
	battle_area.custom_minimum_size.y = maxf(1.0, viewport_height * 0.33 - 8.0)

func _build_navigation(root: VBoxContainer) -> void:
	var panel := _panel()
	panel.name = "BottomNavigationDock"
	root.add_child(panel)
	var primary := HBoxContainer.new()
	primary.add_theme_constant_override("separation", 5)
	panel.add_child(primary)
	for tab_name in ["Heroes", "Companions", "Equipment", "Skills", "Summon"]:
		_add_nav_button(primary, tab_name, false)
	var left_rail := VBoxContainer.new()
	left_rail.name = "FloatingShortcutsLeft"
	left_rail.anchor_right = 0.0
	left_rail.anchor_bottom = 1.0
	left_rail.offset_left = 4
	left_rail.offset_right = 124
	left_rail.offset_top = 0
	left_rail.offset_bottom = 0
	left_rail.add_theme_constant_override("separation", 1)
	left_rail.mouse_filter = Control.MOUSE_FILTER_PASS
	battlefield_host.add_child(left_rail)
	for tab_name in ["Adventure", "Quests", "Login", "Pass", "Shop"]:
		_add_nav_button(left_rail, tab_name, true)
	var right_rail := VBoxContainer.new()
	right_rail.name = "FloatingShortcutsRight"
	right_rail.anchor_left = 1.0
	right_rail.anchor_right = 1.0
	right_rail.anchor_bottom = 1.0
	right_rail.offset_left = -124
	right_rail.offset_right = -4
	right_rail.offset_top = 0
	right_rail.offset_bottom = 0
	right_rail.add_theme_constant_override("separation", 1)
	right_rail.mouse_filter = Control.MOUSE_FILTER_PASS
	battlefield_host.add_child(right_rail)
	for tab_name in ["Artifacts", "Account", "Social", "Settings"]:
		_add_nav_button(right_rail, tab_name, true)
	login_popup = PopupPanel.new()
	login_popup.name = "DailyLoginPopup"
	add_child(login_popup)
	_update_navigation()

func _add_nav_button(parent: Container, tab_name: String, floating: bool) -> void:
	var button := Button.new()
	button.name = "Nav_%s" % tab_name
	button.set_meta("crown_floating_nav", floating)
	button.text = ""
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL if floating else Control.SIZE_SHRINK_CENTER
	button.custom_minimum_size = Vector2.ZERO if floating else Vector2(132, 142)
	if floating:
		button.set_meta("crown_compact_control", true)
	button.tooltip_text = tab_name
	button.pressed.connect(_select_tab.bind(tab_name))
	button.pressed.connect(_play_audio.bind("button_click","UI"))
	button.set_meta("crown_base_minimum_size", button.custom_minimum_size)
	var contents := VBoxContainer.new()
	contents.name = "Contents"
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.alignment = BoxContainer.ALIGNMENT_CENTER
	contents.add_theme_constant_override("separation", 2)
	button.add_child(contents)
	var icon := TextureRect.new()
	icon.name = "NavIcon"
	var icon_slot := Control.new()
	icon_slot.name = "IconSlot"
	icon_slot.custom_minimum_size = Vector2.ZERO if floating else Vector2(96, 96)
	icon_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL if floating else Control.SIZE_SHRINK_CENTER
	icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(icon_slot)
	if floating:
		icon.anchor_left = 0.15
		icon.anchor_right = 0.85
		icon.anchor_top = 0.15
		icon.anchor_bottom = 0.85
	else:
		icon.custom_minimum_size = Vector2(96, 96)
		icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		icon.offset_left = -48.0
		icon.offset_right = 48.0
		icon.offset_top = -48.0
		icon.offset_bottom = 48.0
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.texture = load("res://assets/ui/navigation_icons/%s.png" % NAV_ICON_FILES[tab_name])
	icon_slot.add_child(icon)
	parent.add_child(button)
	nav_buttons[tab_name] = button

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

func _apply_ui_theme() -> void:
	theme = CrownUI.build_theme()

func _button_style(accent: Color, selected: bool, state := "normal") -> StyleBoxFlat:
	return CrownUI.navigation_style(accent, selected, state)

func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	CrownUI.style_panel(panel)
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
	if battle_hero_hp_bar != null and not battle.hero.is_empty():
		var max_hp := maxf(1.0, float(battle.hero.get("hp", 1.0)))
		var current_hp := clampf(float(battle.hero_hp), 0.0, max_hp)
		var hp_ratio := current_hp / max_hp
		battle_hero_level_text.text = "%s  •  LEVEL %d" % [HeroData.title(profile.selected_hero_id, profile.heroes[profile.selected_hero_id]).to_upper(), profile.level]
		battle_hero_hp_bar.max_value = max_hp
		battle_hero_hp_bar.value = current_hp
		battle_hero_hp_bar.add_theme_stylebox_override("fill", CrownUI.health_fill_style(hp_ratio <= 0.30))
		battle_hero_hp_text.text = "HP %s / %s" % [NumberFormatScript.compact(roundi(current_hp)), NumberFormatScript.compact(roundi(max_hp))]
		battle_hero_hp_text.add_theme_color_override("font_color", Color("e08a73") if hp_ratio <= 0.30 else Color("9fd49f"))
	var campaign := str(battle.mode_config.get("mode", "campaign")) == "campaign"
	if campaign:
		var difficulty_name := str(CampaignData.DIFFICULTIES[profile.campaign_difficulty]).to_lower().capitalize()
		stage_text.text = "%s %d-%d" % [difficulty_name, profile.region, profile.stage]
	else:
		stage_text.text = str(PveData.mode_label(battle.mode_config)).to_lower().capitalize()
	var boss_stage := campaign and profile.stage == 20
	var stage_style := stage_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if stage_style != null:
		stage_style.border_color = Color("d6aa66", 0.88) if boss_stage else Color("c3a773", 0.65)
	if skill_auto_button != null:
		_update_skill_auto_button()
	if heroes_exp_text != null:
		heroes_exp_text.text = "HERO EXP  %d / %d" % [profile.exp, GameData.exp_to_next(profile.level)]
		heroes_exp_bar.max_value = GameData.exp_to_next(profile.level)
		heroes_exp_bar.value = profile.exp
		heroes_level_text.text = "LEVEL %d    POWER %d" % [profile.level, profile.power()]
	action_button.visible = campaign and profile.stage == 20 and profile.boss_retry_required and not battle.active and not profile.campaign_complete
	_update_stage_overlay_size()
	for stat in upgrade_buttons:
		var rank := int(profile.upgrades.get(stat, 0))
		var max_rank := GameData.upgrade_max_rank(stat)
		var at_max_rank := rank >= max_rank
		var quote := _upgrade_quote(stat, rank)
		var button: Button = upgrade_buttons[stat]
		upgrade_ranks[stat].text = "LV %d" % rank
		upgrade_values[stat].text = _format_upgrade_stat(stat, float(stats.get(stat, 0.0)))
		upgrade_costs[stat].text = "MAX" if at_max_rank else NumberFormatScript.compact(int(quote["cost"]))
		upgrade_coins[stat].visible = not at_max_rank and int(quote["count"]) > 0
		upgrade_actions[stat].text = "MAX LEVEL" if at_max_rank else "ENHANCE"
		button.disabled = int(quote["count"]) <= 0 or at_max_rank
		upgrade_actions[stat].add_theme_color_override("font_color", Color("99a39c") if button.disabled else Color("e8e4d5"))
		upgrade_costs[stat].add_theme_color_override("font_color", Color("99a39c") if button.disabled else GOLD)
	_maybe_show_upgrade_prompt()
	skill_bar.queue_redraw()
	battlefield.queue_redraw()

func _living_enemies() -> int:
	var count := 0
	for enemy in battle.enemies:
		if float(enemy["current_hp"]) > 0.0:
			count += 1
	return count

func _upgrade_stat_icon(stat: String) -> Texture2D:
	match stat:
		"atk": return PixelUiIcons.equipment("Weapon", 2)
		"hp": return PixelUiIcons.artifact("dragon_heart")
		"armor": return PixelUiIcons.equipment("Armor", 2)
		"speed": return PixelUiIcons.skill("quick_slash")
		"crit_chance": return PixelUiIcons.skill("piercing_strike")
		"crit_damage": return PixelUiIcons.skill("power_strike")
	return null

func _enhance_button_style(highlighted := false, disabled := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("263d37") if not disabled else Color("252e31")
	if highlighted and not disabled: style.bg_color = Color("36554a")
	style.border_color = Color("a89057") if not disabled else Color("59605a")
	style.set_border_width_all(2)
	style.border_width_bottom = 5
	style.set_corner_radius_all(6)
	style.set_content_margin_all(5)
	return style

func _upgrade_stat_label(stat: String) -> String:
	return str({"atk": "ATK", "hp": "HP", "armor": "ARMOR", "speed": "ATTACK SPEED", "crit_chance": "CRIT CHANCE", "crit_damage": "CRIT DAMAGE"}.get(stat, stat.to_upper()))

func _format_upgrade_stat(stat: String, value: float) -> String:
	if stat == "speed":
		return "%.2f/s" % value
	if stat in ["crit_chance", "crit_damage"]:
		return ("%.2f%%" % (value * 100.0)) if stat == "crit_chance" else ("%.0f%%" % (value * 100.0))
	if absf(value - roundf(value)) < 0.05:
		return NumberFormatScript.compact(roundi(value))
	return "%.1f" % value

func _format_upgrade_increase(stat: String, value: float) -> String:
	if stat == "speed":
		return "%.2f/s" % value
	if stat == "crit_chance":
		return "%.2f%%" % (value * 100.0)
	if stat == "crit_damage":
		return "%.0f%%" % (value * 100.0)
	return _format_upgrade_stat(stat, value)

func _show_message(_value: String) -> void:
	# Keep transient event text out of the compact stage badge.
	pass

func _update_stage_overlay_size() -> void:
	if stage_panel == null:
		return
	var retry_visible := action_button != null and action_button.visible
	stage_panel.anchor_left = 0.28 if not retry_visible else 0.06
	stage_panel.anchor_right = 0.72 if not retry_visible else 0.94
	stage_panel.offset_bottom = 154.0 if not retry_visible else 190.0

func _select_tab(tab_name: String) -> void:
	if tab_name != "Battle" and tab_name == selected_tab:
		var selected_button: Button = nav_buttons.get(tab_name) as Button
		if selected_button != null and not bool(selected_button.get_meta("crown_floating_nav", false)):
			tab_name = "Battle"
	selected_tab = tab_name
	stage_panel.visible = true
	battle_area.visible = true
	feature_header.visible = tab_name != "Battle"
	feature_title_label.text = tab_name.to_upper()
	battle_lower_scroll.visible = tab_name == "Battle"
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
	var active_screen: Control = {
		"Battle": battle_lower_scroll, "Heroes": heroes_area, "Equipment": equipment_area,
		"Skills": skills_area, "Summon": summon_area, "Companions": companions_area,
		"Artifacts": artifacts_area, "Adventure": adventure_area, "Quests": quests_area,
		"Login": login_area, "Pass": battle_pass_area, "Shop": shop_area,
		"Account": account_area, "Social": social_area, "Settings": settings_area
	}.get(tab_name)
	if active_screen != null:
		active_screen.modulate.a = 1.0
		if tab_transition != null and tab_transition.is_running():
			tab_transition.kill()
		if not profile.reduced_effects:
			active_screen.modulate.a = 0.0
			tab_transition = create_tween()
			tab_transition.tween_property(active_screen, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
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
	CrownUI.apply_screen_scale(self, profile.reduced_effects)
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
	CrownUI.style_ornate_panel(identity)
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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	row.add_child(_label(value, 32, GOLD))
	var divider := ColorRect.new()
	divider.color = Color("6f6148")
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(divider)

func _build_equipment_screen() -> void:
	_clear_content(equipment_content)
	var heading := _panel()
	CrownUI.style_ornate_panel(heading)
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
		var item_icon := TextureRect.new()
		item_icon.custom_minimum_size = Vector2(112, 112)
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		item_icon.texture = PixelUiIcons.item(str(selected["kind"]), int(selected["rarity"]))
		box.add_child(item_icon)
		box.add_child(_label("%s  +%d" % [EquipmentData.title(selected), selected["level"]], 30, EquipmentData.COLORS[int(selected["rarity"])]))
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
			button.icon = PixelUiIcons.item(str(item["kind"]), int(item["rarity"]))
			button.expand_icon = true
			button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if not item.is_empty():
			_style_rarity(button, int(item["rarity"]), selected_item_id == str(item["id"]))
			button.pressed.connect(_select_item.bind(str(item["id"])))
		else:
			CrownUI.style_tab(button, false, Color("75694f"))
		equipment_content.add_child(button)
	_section_title(equipment_content, "INVENTORY  •  %d ITEMS" % profile.inventory.size())
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	equipment_content.add_child(grid)
	for item in profile.inventory:
		var button := Button.new()
		button.custom_minimum_size = Vector2(320, 260)
		button.text = ""
		_style_rarity(button, int(item["rarity"]), selected_item_id == str(item["id"]))
		var contents := VBoxContainer.new()
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.alignment = BoxContainer.ALIGNMENT_CENTER
		contents.add_theme_constant_override("separation", 1)
		button.add_child(contents)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(0, 170)
		icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = PixelUiIcons.item(str(item["kind"]), int(item["rarity"]))
		contents.add_child(icon)
		var item_name := _label(EquipmentData.ITEMS[item["kind"]]["name"], 22, EquipmentData.COLORS[int(item["rarity"])])
		item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_name.clip_text = true
		contents.add_child(item_name)
		var item_rank := _label("LV %d  •  %s" % [int(item["level"]), EquipmentData.RARITIES[int(item["rarity"])].to_upper()], 18, PALE)
		item_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		contents.add_child(item_rank)
		button.pressed.connect(_select_item.bind(str(item["id"])))
		grid.add_child(button)

func _style_rarity(button: Button, rarity: int, selected := false) -> void:
	CrownUI.style_card(button, EquipmentData.COLORS[rarity], selected)
	button.add_theme_color_override("font_color", EquipmentData.COLORS[rarity])

func _action(parent: Container, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 126
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 30)
	CrownUI.set_button_role(button)
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
	CrownUI.apply_screen_scale(self, profile.reduced_effects)
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
		CrownUI.style_tab(button, selected, GOLD)
		var floating := bool(button.get_meta("crown_floating_nav", false))
		if floating:
			for state in ["normal", "hover", "pressed", "focus", "disabled"]:
				button.add_theme_stylebox_override(state, _floating_nav_style(state, selected))
		var badge := MonetizationService.new(profile).bp_badge() if tab_name == "Pass" else MonetizationService.new(profile).shop_badge() if tab_name == "Shop" else SocialService.new(profile).badge() if tab_name == "Social" else ProgressionService.new(profile).badge(tab_name)
		var icon := button.get_node_or_null("Contents/IconSlot/NavIcon") as TextureRect
		if icon != null:
			icon.modulate = Color("ffdc8a") if selected else Color.WHITE
			var lift := -8.0 if selected and not floating else 0.0
			var icon_size := icon.custom_minimum_size
			var target_top := -icon_size.y * 0.5 + lift
			var target_bottom := icon_size.y * 0.5 + lift
			var target_scale := Vector2.ONE * (1.06 if selected and not floating else 1.0)
			var visual_state := "%s:%s" % [selected, floating]
			if str(icon.get_meta("crown_nav_visual_state", "")) != visual_state:
				icon.set_meta("crown_nav_visual_state", visual_state)
				if not profile.reduced_effects and icon.is_inside_tree():
					var lift_tween := icon.create_tween()
					lift_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					lift_tween.tween_property(icon, "offset_top", target_top, 0.12)
					lift_tween.parallel().tween_property(icon, "offset_bottom", target_bottom, 0.12)
					lift_tween.parallel().tween_property(icon, "scale", target_scale, 0.12)
				else:
					icon.offset_top = target_top
					icon.offset_bottom = target_bottom
					icon.scale = target_scale
		var dot := button.get_node_or_null("BadgeDot") as PanelContainer
		if dot == null:
			dot = PanelContainer.new()
			dot.name = "BadgeDot"
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.anchor_left = 1.0
			dot.anchor_right = 1.0
			dot.offset_left = -34
			dot.offset_right = -6
			dot.offset_top = 6
			dot.offset_bottom = 34
			var badge_style := StyleBoxFlat.new()
			badge_style.bg_color = Color("d94f52")
			badge_style.border_color = Color("f3e4c4")
			badge_style.set_border_width_all(2)
			badge_style.set_corner_radius_all(14)
			badge_style.set_content_margin_all(0)
			dot.add_theme_stylebox_override("panel", badge_style)
			button.add_child(dot)
		dot.visible = badge

func _floating_nav_style(state: String, selected: bool) -> StyleBox:
	if state == "normal" or state == "disabled":
		return StyleBoxEmpty.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e9c87d", 0.18 if state == "hover" or state == "focus" else 0.30)
	style.border_color = Color("e9c87d", 0.55 if selected else 0.30)
	style.set_border_width_all(1)
	style.set_corner_radius_all(24)
	style.set_content_margin_all(0.0)
	return style

func _buy_upgrade(stat: String) -> void:
	var limit := 1 if upgrade_purchase_mode == "x1" else (10 if upgrade_purchase_mode == "x10" else -1)
	var bought := profile.buy_upgrade_ranks(stat, limit)
	if bought > 0:
		_play_audio("upgrade", "UI")
		if battle.active:
			battle.refresh_hero_stats()
		_show_message("%s %s upgraded. Power increased." % [stat.to_upper(), "rank" if bought == 1 else "%d ranks" % bought])
		_refresh_ui()
		_schedule_cloud_sync()
		if stat == "atk" and tutorials != null and tutorials.onboarding_active() and not bool(profile.tutorial_state.steps.get("upgrade", false)):
			tutorials.mark_step("upgrade")
			_show_onboarding_step("waves")

func _upgrade_quote(stat: String, starting_rank: int = -1) -> Dictionary:
	var rank := int(profile.upgrades.get(stat, 0)) if starting_rank < 0 else starting_rank
	var limit := 1 if upgrade_purchase_mode == "x1" else (10 if upgrade_purchase_mode == "x10" else -1)
	var count := 0
	var total_cost := 0
	var remaining := profile.gold
	while limit < 0 or count < limit:
		if rank >= GameData.upgrade_max_rank(stat):
			break
		var cost := GameData.upgrade_cost(rank, stat)
		if remaining < cost:
			break
		remaining -= cost
		total_cost += cost
		rank += 1
		count += 1
	return {"count": count, "cost": total_cost}

func _set_upgrade_purchase_mode(mode: String) -> void:
	if not ["x1", "x10", "MAX"].has(mode):
		return
	upgrade_purchase_mode = mode
	for key in upgrade_mode_buttons:
		var button := upgrade_mode_buttons[key] as Button
		var selected := str(key) == mode
		var style := StyleBoxFlat.new()
		style.bg_color = Color("72542f") if selected else Color("202b30")
		style.border_color = Color("e9c87d") if selected else Color("5f665e")
		style.set_border_width_all(2)
		style.border_width_bottom = 4
		style.set_corner_radius_all(5)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_color_override("font_color", GOLD if selected else PALE)
	_refresh_ui()

func _toggle_skill_auto() -> void:
	battle.skill_runtime.auto_enabled = not battle.skill_runtime.auto_enabled
	_update_skill_auto_button()
	skill_bar.queue_redraw()

func _update_skill_auto_button() -> void:
	if skill_auto_button == null or battle == null:
		return
	var enabled := battle.skill_runtime.auto_enabled
	skill_auto_button.text = "AUTO\n%s" % ("ON" if enabled else "OFF")
	skill_auto_button.add_theme_color_override("font_color", Color("a9d6ad") if enabled else Color("bd8d84"))

func _on_manual_skill_requested(slot: int) -> void:
	if battle != null and battle.active and battle.skill_runtime.manual_cast(slot, battle):
		skill_bar.queue_redraw()

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
