class_name MonetizationDebug
extends RefCounted

# Called only by development scripts; no controls are added to release UI.
static func grant_bp_xp(profile: SaveData, amount: int) -> void:
	MonetizationService.new(profile).grant_bp_xp(amount)

static func set_bp_level(profile: SaveData, level: int) -> void:
	profile.bp_season.level = clampi(level, 0, MonetizationData.MAX_LEVEL)
	profile.bp_season.xp = MonetizationData.total_xp_for_level(int(profile.bp_season.level))
	profile.save()

static func toggle_premium(profile: SaveData) -> void:
	profile.premium_pass_owned = not profile.premium_pass_owned
	profile.save()

static func toggle_subscription(profile: SaveData) -> void:
	profile.subscription_active = not profile.subscription_active
	profile.subscription_expiry_date = Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) + 30 * 86400) if profile.subscription_active else ""
	profile.save()

static func expire_subscription(profile: SaveData) -> void:
	profile.subscription_expiry_date = "2000-01-01"
	profile.save()

static func reset_starter(profile: SaveData) -> void:
	profile.starter_pack_purchased = false
	profile.purchase_entitlements.erase("starter_pack")
	profile.save()

static func reset_ad_limits(profile: SaveData) -> void:
	profile.ad_usage.clear()
	profile.dungeon_ad_usage.clear()
	profile.daily_bonus_ad_claim = ""
	for banner in profile.banners:
		profile.banners[banner]["ad_count"] = 0
		profile.banners[banner]["ad_day"] = ""
	profile.save()

static func force_offer_reset(profile: SaveData, period: String) -> void:
	if period == "daily": profile.offer_daily_reset = ""
	elif period == "weekly": profile.offer_weekly_reset = ""
	MonetizationService.new(profile).refresh_offers()

static func cosmetic(profile: SaveData, id: String, grant: bool) -> void:
	if not MonetizationData.COSMETICS.has(id): return
	if grant: profile.owned_cosmetics[id] = true
	else: profile.owned_cosmetics.erase(id)
	profile.save()

static func purchase_provider_failure() -> DevelopmentPurchaseProvider:
	var provider := DevelopmentPurchaseProvider.new()
	provider.fail_next = true
	return provider

static func ad_provider_failure() -> DevelopmentRewardedAdProvider:
	var provider := DevelopmentRewardedAdProvider.new()
	provider.fail_next = true
	return provider
