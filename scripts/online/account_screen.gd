class_name AccountScreen
extends VBoxContainer

const CrownUI = preload("res://scripts/ui/crown_ui.gd")

var profile: SaveData
var service: AccountService
var on_change: Callable
var notice := ""
var conflict_payload: Dictionary = {}
var display_edit: LineEdit
var pending_link_provider := ""

func configure(value: SaveData, callback: Callable) -> void:
	profile = value
	service = AccountService.new(profile)
	on_change = callback
	refresh()

func refresh() -> void:
	if profile == null: return
	for child in get_children(): child.queue_free()
	var heading := PanelContainer.new()
	CrownUI.style_ornate_panel(heading)
	add_child(heading)
	heading.add_child(_label("ACCOUNT  /  CLOUD", 40))
	var meta: Dictionary = profile.account_meta
	var frame_name := "Golden Profile Frame" if profile.owned_cosmetics.has("golden_frame") and profile.equipped_cosmetics.get("Profile Frame", "") == "golden_frame" else "No Frame"
	var profile_row := VBoxContainer.new()
	add_child(profile_row)
	var avatar := HeroPortrait.new()
	avatar.hero_id = profile.selected_hero_id
	avatar.evolution = int(profile.heroes[profile.selected_hero_id].get("evolution", 0))
	avatar.profile_frame = "golden_frame" if frame_name == "Golden Profile Frame" else ""
	avatar.custom_minimum_size = Vector2(100, 120)
	avatar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	profile_row.add_child(avatar)
	var profile_details := _label("Player ID  %s\n%s • %s • %s\nCreated %s\nHero %s • Level %d • Power %d\nCampaign %s %d-%d • Guild %s • PvP %s" % [meta.player_id, meta.display_name, meta.account_type, frame_name, str(meta.created_at).substr(0, 10), HeroData.title(profile.selected_hero_id, profile.heroes[profile.selected_hero_id]), profile.level, profile.power(), CampaignData.DIFFICULTIES[profile.campaign_difficulty], profile.region, profile.stage, "None" if str(meta.guild_id) == "" else meta.guild_id, profile.pvp_state.get("highest_rank", "Bronze")], 27)
	profile_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_row.add_child(profile_details)
	var name_row := HBoxContainer.new()
	add_child(name_row)
	display_edit = LineEdit.new()
	display_edit.text = str(meta.display_name)
	display_edit.placeholder_text = "Display name (3–20 characters)"
	display_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(display_edit)
	var rename := _button("SAVE NAME")
	CrownUI.set_button_role(rename, &"PrimaryActionButton")
	rename.pressed.connect(_rename)
	name_row.add_child(rename)
	if str(meta.account_type) == "Guest":
		add_child(_button("PLAY AS GUEST • LOCAL PROGRESS SAVED"))
		for provider in ["Google", "Apple"]:
			var link := _button("LINK " + provider.to_upper() + " • DEVELOPMENT")
			link.pressed.connect(_link.bind(provider))
			add_child(link)
	else:
		var signout := _button("SIGN OUT • KEEP LOCAL SAVE")
		signout.pressed.connect(_sign_out)
		add_child(signout)
	add_child(_label("Cloud status: %s\nLast local save: %s\nLast cloud sync: %s" % [profile.cloud_meta.get("sync_status", "Local only"), meta.get("last_local_save", "Not saved yet"), profile.cloud_meta.get("last_cloud_sync", "Never")], 25))
	var sync := _button("SYNC NOW")
	CrownUI.set_button_role(sync, &"MagicActionButton")
	sync.pressed.connect(_sync)
	add_child(sync)
	var restore := _button("RESTORE CLOUD SAVE")
	restore.pressed.connect(_restore)
	add_child(restore)
	var purchases := _button("RESTORE PURCHASES")
	purchases.pressed.connect(_restore_purchases)
	add_child(purchases)
	if notice != "": add_child(_label(notice, 25))
	if not conflict_payload.is_empty(): _show_conflict()

func _link(provider: String) -> void:
	var result := service.link(provider)
	if bool(result.get("conflict", false)):
		conflict_payload = result.cloud
		pending_link_provider = provider
		notice = "Cloud save found. Choose which save to keep."
	else: notice = "Account linked." if bool(result.get("ok", false)) else str(result.get("error", "Link failed"))
	refresh()
	if on_change.is_valid(): on_change.call()

func _restore() -> void:
	var result := service.inspect_cloud()
	if bool(result.get("ok", false)):
		conflict_payload = result
		notice = "Choose Local or Cloud after comparing the save summaries."
	else: notice = str(result.get("error", "Restore failed"))
	refresh()

func _show_conflict() -> void:
	var cloud: Dictionary = conflict_payload.get("summary", conflict_payload.get("cloud", {}))
	add_child(_label("SAVE CONFLICT\nLOCAL  •  Level %d • Power %d • %s %d-%d • %s\nCLOUD  •  Level %d • Power %d • %s %s\nCloud save: %s" % [profile.level, profile.power(), CampaignData.DIFFICULTIES[profile.campaign_difficulty], profile.region, profile.stage, profile.account_meta.get("last_local_save", ""), int(cloud.get("level", 0)), int(cloud.get("power", 0)), str(cloud.get("difficulty", "")), str(cloud.get("stage", "")), str(conflict_payload.get("saved_at", ""))], 24))
	for choice in ["Keep Local", "Use Cloud"]:
		var button := _button(choice.to_upper())
		button.pressed.connect(_resolve.bind(choice))
		add_child(button)

func _resolve(choice: String) -> void:
	var result := service.link(pending_link_provider, choice) if pending_link_provider != "" else service.resolve_cloud(choice)
	if bool(result.get("ok", false)) and choice == "Keep Local" and pending_link_provider != "":
		result = service.sync_now()
	notice = "Save choice applied." if bool(result.get("ok", false)) else str(result.get("error", "Could not apply save choice"))
	conflict_payload = {}
	pending_link_provider = ""
	refresh()
	if on_change.is_valid(): on_change.call()

func _sync() -> void:
	var result := service.sync_now()
	notice = "Cloud save synced." if bool(result.get("ok", false)) else str(result.get("error", "Sync failed"))
	refresh()

func _rename() -> void:
	notice = "Display name saved." if service.set_display_name(display_edit.text) else service.last_error
	refresh()
	if on_change.is_valid(): on_change.call()

func _sign_out() -> void:
	notice = "Signed out. Local progress is still saved." if service.sign_out() else service.last_error
	refresh()
	if on_change.is_valid(): on_change.call()

func _restore_purchases() -> void:
	var count := MonetizationService.new(profile).restore_purchases()
	notice = "Restored %d saved entitlements." % count
	refresh()

func _label(value: String, size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("ffd166"))
	return label

func _button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 68
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 23)
	button.clip_text = true
	CrownUI.set_button_role(button, &"QuietButton")
	return button
