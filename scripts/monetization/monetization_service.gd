class_name MonetizationService
extends RefCounted

var profile: SaveData
var purchases: PurchaseProvider
var ads: RewardedAdProvider

func _init(value: SaveData, purchase_provider: PurchaseProvider = null, ad_provider: RewardedAdProvider = null) -> void:
	profile = value
	purchases = purchase_provider if purchase_provider != null else DevelopmentPurchaseProvider.new()
	ads = ad_provider if ad_provider != null else DevelopmentRewardedAdProvider.new()

func season_open() -> bool:
	var today := CalendarService.day()
	return today >= str(profile.bp_season.start) and today < str(profile.bp_season.end)

func grant_bp_xp(amount: int) -> int:
	if amount <= 0 or not season_open(): return 0
	profile.bp_season.xp = int(profile.bp_season.xp) + amount
	var level := int(profile.bp_season.level)
	while level < MonetizationData.MAX_LEVEL and int(profile.bp_season.xp) >= MonetizationData.total_xp_for_level(level + 1): level += 1
	profile.bp_season.level = level
	profile.save()
	return level

func can_claim_bp(level: int, premium: bool) -> bool:
	if level < 1 or level > int(profile.bp_season.level) or not season_open(): return false
	if premium and not profile.premium_pass_owned: return false
	var claims: Dictionary = profile.bp_season.premium_claimed if premium else profile.bp_season.free_claimed
	return not claims.has(str(level))

func claim_bp(level: int, premium: bool) -> bool:
	if not can_claim_bp(level, premium): return false
	var claims: Dictionary = profile.bp_season.premium_claimed if premium else profile.bp_season.free_claimed
	claims[str(level)] = true
	grant_reward(MonetizationData.reward(level, premium))
	profile.save()
	return true

func claim_all_bp() -> int:
	var count := 0
	for level in range(1, int(profile.bp_season.level) + 1):
		if claim_bp(level, false): count += 1
		if claim_bp(level, true): count += 1
	return count

func bp_badge() -> bool:
	for level in range(1, int(profile.bp_season.level) + 1):
		if can_claim_bp(level, false) or can_claim_bp(level, true): return true
	return false

func grant_reward(reward: Dictionary) -> void:
	for key in reward:
		if key == "cosmetic": profile.owned_cosmetics[str(reward[key])] = true
		elif str(key).ends_with("_ticket"):
			var banner := str(key).trim_suffix("_ticket")
			profile.summon_tickets[banner] = int(profile.summon_tickets.get(banner, 0)) + int(reward[key])
		else: profile.set(key, int(profile.get(key)) + int(reward[key]))

func purchase(product_id: String) -> bool:
	if not MonetizationData.PRODUCTS.has(product_id): return false
	var item: Dictionary = MonetizationData.PRODUCTS[product_id]
	if not bool(item.repeatable) and profile.purchase_entitlements.has(product_id): return false
	if not purchases.purchase(product_id): return false
	grant_reward(item.reward)
	if str(item.type) == "subscription":
		profile.subscription_active = true
		var base := maxi(int(Time.get_unix_time_from_system()), Time.get_unix_time_from_datetime_string(profile.subscription_expiry_date + "T00:00:00") if profile.subscription_expiry_date != "" else 0)
		profile.subscription_expiry_date = Time.get_date_string_from_unix_time(base + MonetizationData.SUBSCRIPTION_DAYS * 86400)
	elif str(item.entitlement) != "": profile.set(str(item.entitlement), true)
	if str(item.type) != "consumable": profile.purchase_entitlements[product_id] = true
	profile.save()
	return true

func restore_purchases() -> int:
	var restored := purchases.restore(profile.purchase_entitlements)
	var count := 0
	for id in restored:
		if not MonetizationData.PRODUCTS.has(id): continue
		var entitlement := str(MonetizationData.PRODUCTS[id].entitlement)
		if entitlement == "" or entitlement == "subscription_active": continue
		profile.set(entitlement, true)
		count += 1
	profile.save()
	return count

func subscription_valid() -> bool:
	var valid := profile.subscription_active and profile.subscription_expiry_date > CalendarService.day()
	if profile.subscription_active and not valid:
		profile.subscription_active = false
		profile.save()
	return valid

func claim_subscription() -> bool:
	if not subscription_valid() or profile.subscription_last_claim == CalendarService.day(): return false
	profile.subscription_last_claim = CalendarService.day()
	grant_reward({"gems": 100, "enhancement_stones": 10, "companion_essence": 10})
	profile.save()
	return true

func refresh_offers() -> void:
	CalendarService.reset_periods(profile)
	var changed := false
	if profile.offer_daily_reset != profile.daily_reset_date:
		profile.offer_daily_reset = profile.daily_reset_date
		profile.daily_offers = _pick_offers(MonetizationData.DAILY_OFFERS, profile.offer_daily_reset)
		changed = true
	if profile.offer_weekly_reset != profile.weekly_reset_week:
		profile.offer_weekly_reset = profile.weekly_reset_week
		profile.weekly_offers = _pick_offers(MonetizationData.WEEKLY_OFFERS, profile.offer_weekly_reset)
		changed = true
	if changed: profile.save()

func _pick_offers(pool: Array, seed_text: String) -> Array:
	var indices := range(pool.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_text)
	for i in range(indices.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp: int = indices[i]
		indices[i] = indices[j]
		indices[j] = temp
	var result := []
	for i in 3:
		var offer: Dictionary = pool[indices[i]].duplicate(true)
		offer["bought"] = false
		result.append(offer)
	return result

func buy_offer(period: String, index: int) -> bool:
	refresh_offers()
	var offers: Array = profile.daily_offers if period == "daily" else profile.weekly_offers if period == "weekly" else []
	if index < 0 or index >= offers.size(): return false
	var offer: Dictionary = offers[index]
	if bool(offer.bought) or profile.gems < int(offer.cost): return false
	profile.gems -= int(offer.cost)
	offer.bought = true
	grant_reward(offer.reward)
	profile.save()
	return true

func claim_free_offer() -> bool:
	if profile.ad_usage.get("free_offer", "") == CalendarService.day(): return false
	profile.ad_usage["free_offer"] = CalendarService.day()
	grant_reward({"gold": 1000, "enhancement_stones": 3})
	profile.save()
	return true

func equip_cosmetic(id: String) -> bool:
	if not profile.owned_cosmetics.has(id) or not MonetizationData.COSMETICS.has(id): return false
	profile.equipped_cosmetics[str(MonetizationData.COSMETICS[id].category)] = id
	profile.save()
	return true

func _ad(placement: String) -> bool:
	return (subscription_valid() and MonetizationData.SUBSCRIBER_SKIP_AD.has(placement)) or ads.show_rewarded_ad(placement)

func claim_daily_bonus() -> bool:
	if profile.daily_bonus_ad_claim == CalendarService.day() or not _ad("daily_bonus"): return false
	profile.daily_bonus_ad_claim = CalendarService.day()
	grant_reward({"gold": 1500, "enhancement_stones": 5})
	profile.save()
	return true

func grant_dungeon_attempt(id: String) -> bool:
	if not PveData.DUNGEONS.has(id): return false
	PveService.new(profile).refresh_day()
	if profile.dungeon_ad_usage.get(id, "") == CalendarService.day() or not _ad("dungeon_attempt"): return false
	profile.dungeon_ad_usage[id] = CalendarService.day()
	profile.dungeon_attempts[id]["remaining"] += 1
	profile.save()
	return true

func activate_gold_boost() -> bool:
	var now := int(Time.get_unix_time_from_system())
	if profile.gold_boost_expiry > now or profile.ad_usage.get("gold_boost", "") == CalendarService.day() or not _ad("gold_boost"): return false
	profile.ad_usage["gold_boost"] = CalendarService.day()
	profile.gold_boost_expiry = now + 1800
	profile.save()
	return true

func offline_cap_hours() -> int:
	return IdleRewardService.new(profile).offline_cap_hours()

func offline_reward(now: int = 0) -> Dictionary:
	now = int(Time.get_unix_time_from_system()) if now == 0 else now
	if profile.offline_last_claim == 0: return {"gold": 0, "seconds": 0}
	return IdleRewardService.new(profile).calculate(now - profile.offline_last_claim)

func claim_offline(double_with_ad: bool = false, now: int = 0) -> int:
	now = int(Time.get_unix_time_from_system()) if now == 0 else now
	var idle := IdleRewardService.new(profile)
	if profile.offline_pending_rewards.is_empty(): idle.prepare(now)
	var reward := idle.claim(double_with_ad, now, ads)
	return int(reward.get("gold", 0))

func shop_badge() -> bool:
	refresh_offers()
	return bp_badge() or profile.ad_usage.get("free_offer", "") != CalendarService.day() or subscription_valid() and profile.subscription_last_claim != CalendarService.day() or profile.offer_daily_viewed != profile.offer_daily_reset or profile.offer_weekly_viewed != profile.offer_weekly_reset
