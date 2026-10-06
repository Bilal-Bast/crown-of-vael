class_name ShopScreen
extends VBoxContainer

const CrownUI = preload("res://scripts/ui/crown_ui.gd")

var profile: SaveData
var service: MonetizationService
var on_change: Callable
var tab := "Featured"
var confirm: ConfirmationDialog
var preview_id := ""

func configure(value: SaveData, callback: Callable) -> void:
	profile = value
	service = MonetizationService.new(profile)
	on_change = callback
	refresh()

func refresh() -> void:
	if profile == null: return
	service.refresh_offers()
	for child in get_children():
		if child == confirm: continue
		remove_child(child)
		child.queue_free()
	add_child(_label("ROYAL SHOP • %d GEMS" % profile.gems, 40))
	add_child(_label("Development purchases and simulated rewarded ads", 25))
	var tabs := GridContainer.new()
	tabs.columns = 3
	add_child(tabs)
	for name in ["Featured", "Gems", "Daily", "Weekly", "Subscription", "Cosmetics"]:
		var button := _button(name)
		CrownUI.style_tab(button, tab == name, Color("c5a566"))
		button.pressed.connect(_select.bind(name))
		tabs.add_child(button)
	match tab:
		"Featured":
			for id in ["starter_pack", "premium_pass", "monthly_subscription"]: _product(id)
			var restore := _button("RESTORE PURCHASES • DEV")
			restore.pressed.connect(_restore)
			add_child(restore)
			add_child(_label("Offline Gold + Hero EXP rewards appear when you return.", 27))
			var boost := _button("SIMULATED AD • +50% GOLD FOR 30 MIN")
			boost.disabled = profile.gold_boost_expiry > int(Time.get_unix_time_from_system()) or profile.ad_usage.get("gold_boost", "") == CalendarService.day()
			boost.pressed.connect(_boost)
			add_child(boost)
		"Gems":
			for id in ["gems_500", "gems_1200", "gems_2500", "gems_6500"]: _product(id)
		"Daily", "Weekly":
			var period := tab.to_lower()
			if period == "daily":
				var free := _button("FREE DAILY OFFER • 1,000 GOLD + 3 STONES")
				free.disabled = profile.ad_usage.get("free_offer", "") == CalendarService.day()
				free.pressed.connect(_free_offer)
				add_child(free)
			if period == "daily": profile.offer_daily_viewed = profile.offer_daily_reset
			else: profile.offer_weekly_viewed = profile.offer_weekly_reset
			profile.save()
			var offers: Array = profile.daily_offers if period == "daily" else profile.weekly_offers
			for index in offers.size():
				var offer: Dictionary = offers[index]
				var parts := PackedStringArray()
				for key in offer.reward: parts.append("%d %s" % [int(offer.reward[key]), str(key).replace("_", " ")])
				var button := _button("%s • %s • %d GEMS • %s" % [offer.name, ", ".join(parts), offer.cost, "SOLD" if offer.bought else "BUY"])
				button.disabled = bool(offer.bought)
				button.pressed.connect(_confirm_offer.bind(period, index))
				add_child(button)
		"Subscription":
			_product("monthly_subscription")
			add_child(_label("100 Gems + 10 Stones + 10 Essence daily • 16h offline cap", 27))
			var claim := _button("CLAIM DAILY SUBSCRIPTION REWARD")
			claim.disabled = not service.subscription_valid() or profile.subscription_last_claim == CalendarService.day()
			claim.pressed.connect(_claim_subscription)
			add_child(claim)
		"Cosmetics":
			add_child(_label("Appearance only • no combat stats", 27))
			if preview_id != "": add_child(_label("PREVIEW • " + str(MonetizationData.COSMETICS[preview_id].name), 28))
			for id in MonetizationData.COSMETICS:
				var item: Dictionary = MonetizationData.COSMETICS[id]
				var owned := profile.owned_cosmetics.has(id)
				var equipped: bool = profile.equipped_cosmetics.get(item.category, "") == id
				var button := _button("%s • %s • %s" % [item.name, item.category, "EQUIPPED" if equipped else "EQUIP" if owned else "PREVIEWING" if preview_id == id else "PREVIEW"])
				button.pressed.connect(_cosmetic.bind(id))
				add_child(button)
	if confirm == null:
		confirm = ConfirmationDialog.new()
		confirm.name = "OfferConfirmation"
		confirm.ok_button_text = "Buy"
		add_child(confirm)

func _product(id: String) -> void:
	var product: Dictionary = MonetizationData.PRODUCTS[id]
	var panel := PanelContainer.new()
	CrownUI.style_panel(panel, Color("c5a566"), false, id == "premium_pass")
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var details := str(product.description)
	for key in product.reward: details += " • %d %s" % [int(product.reward[key]), str(key).replace("_", " ")]
	box.add_child(_label(product.name + " • " + product.price + "\n" + details, 27))
	var button := _button("DEVELOPMENT PURCHASE • " + product.name)
	button.disabled = not bool(product.repeatable) and profile.purchase_entitlements.has(id)
	button.pressed.connect(_purchase.bind(id))
	box.add_child(button)

func _select(name: String) -> void:
	tab = name
	refresh()
	if on_change.is_valid(): on_change.call()

func _purchase(id: String) -> void:
	service.purchase(id)
	refresh()
	if on_change.is_valid(): on_change.call()

func _restore() -> void:
	service.restore_purchases()
	refresh()
	if on_change.is_valid(): on_change.call()

func _confirm_offer(period: String, index: int) -> void:
	var offer: Dictionary = (profile.daily_offers if period == "daily" else profile.weekly_offers)[index]
	confirm.dialog_text = "Buy %s for %d Gems?" % [offer.name, offer.cost]
	for connection in confirm.confirmed.get_connections(): confirm.confirmed.disconnect(connection.callable)
	confirm.confirmed.connect(_buy_offer.bind(period, index))
	confirm.popup_centered()

func _buy_offer(period: String, index: int) -> void:
	service.buy_offer(period, index)
	refresh()
	if on_change.is_valid(): on_change.call()

func _free_offer() -> void:
	service.claim_free_offer()
	refresh()
	if on_change.is_valid(): on_change.call()

func _claim_subscription() -> void:
	service.claim_subscription()
	refresh()
	if on_change.is_valid(): on_change.call()

func _offline(double_reward: bool) -> void:
	service.claim_offline(double_reward)
	refresh()
	if on_change.is_valid(): on_change.call()

func _boost() -> void:
	service.activate_gold_boost()
	refresh()
	if on_change.is_valid(): on_change.call()

func _cosmetic(id: String) -> void:
	if profile.owned_cosmetics.has(id): service.equip_cosmetic(id)
	else: preview_id = id
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
	button.add_theme_font_size_override("font_size", 24)
	button.clip_text = true
	CrownUI.set_button_role(button, &"QuietButton")
	return button
