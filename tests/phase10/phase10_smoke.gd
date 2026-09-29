extends SceneTree

const PATH := "res://.godot/phase10_smoke.save"
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, label: String) -> void:
	if condition: return
	failures += 1
	push_error("PHASE 10: " + label)

func _run() -> void:
	var profile := SaveData.new()
	profile.save_path = PATH
	var purchase_provider := DevelopmentPurchaseProvider.new()
	var ad_provider := DevelopmentRewardedAdProvider.new()
	var service := MonetizationService.new(profile, purchase_provider, ad_provider)
	var quests := ProgressionService.new(profile)
	quests.refresh()
	quests.report("enemy_defeated", 100)
	var quest_id := ""
	for entry in ProgressionData.DAILY:
		if str(entry[4]) == "enemy_defeated": quest_id = str(entry[0]); break
	if quest_id != "":
		check(quests.claim_quest("daily", quest_id) and int(profile.bp_season.xp) == MonetizationData.DAILY_QUEST_XP, "daily quest BP XP")
		profile.bp_season.xp = 0
		profile.bp_season.level = 0
	check(MonetizationData.total_xp_for_level(50) > MonetizationData.total_xp_for_level(1), "XP curve")
	check(str(profile.bp_season.end) == "2026-10-29", "30-day season")
	service.grant_bp_xp(MonetizationData.total_xp_for_level(3))
	check(int(profile.bp_season.level) == 3, "BP levels")
	check(service.bp_badge() and service.claim_bp(1, false), "free claim")
	check(not service.claim_bp(1, false) and not service.claim_bp(1, true), "duplicate and premium lock")
	check(service.purchase("premium_pass") and service.claim_bp(1, true), "late premium back claim")
	check(service.claim_all_bp() == 4 and not service.bp_badge(), "claim all and badge clear")
	check(service.purchase("starter_pack") and not service.purchase("starter_pack"), "starter one-time")
	var gems_before := profile.gems
	check(service.purchase("gems_500") and profile.gems == gems_before + 500, "consumable pack")
	purchase_provider.fail_next = true
	check(not service.purchase("gems_500"), "purchase failure")
	check(service.restore_purchases() >= 2, "restore entitlements")
	service.refresh_offers()
	check(profile.daily_offers.size() == 3 and profile.weekly_offers.size() == 3, "offers")
	var offer_name := str(profile.daily_offers[0].name)
	service.refresh_offers()
	check(str(profile.daily_offers[0].name) == offer_name, "offer persistence")
	check(service.shop_badge() and service.claim_free_offer(), "free offer badge")
	check(not service.claim_free_offer(), "free offer once")
	profile.offer_daily_viewed = profile.offer_daily_reset
	profile.offer_weekly_viewed = profile.offer_weekly_reset
	check(not service.shop_badge(), "shop badge clears after action and view")
	var offer: Dictionary = profile.daily_offers[0]
	profile.gems = 0
	check(not service.buy_offer("daily", 0), "insufficient Gems")
	profile.gems = int(offer.cost)
	check(service.buy_offer("daily", 0) and not service.buy_offer("daily", 0), "offer once")
	MonetizationDebug.force_offer_reset(profile, "daily")
	check(not bool(profile.daily_offers[0].bought), "daily offer reset")
	MonetizationDebug.force_offer_reset(profile, "weekly")
	check(profile.weekly_offers.size() == 3, "weekly offer reset")
	check(service.purchase("monthly_subscription") and service.offline_cap_hours() == 16, "subscription cap")
	check(service.claim_subscription() and not service.claim_subscription(), "subscription daily")
	ad_provider.fail_next = true
	check(SummonService.new(profile, ad_provider).summon("equipment", 1, "ad").size() == 1, "subscriber summon convenience")
	check(ad_provider.fail_next, "subscriber did not watch simulated ad")
	ad_provider.fail_next = false
	check(service.claim_daily_bonus() and not service.claim_daily_bonus(), "daily bonus limit")
	check(service.grant_dungeon_attempt("gold") and not service.grant_dungeon_attempt("gold"), "dungeon ad limit")
	check(service.activate_gold_boost() and not service.activate_gold_boost(), "gold boost limit")
	profile.offline_last_claim = 100000
	var offline := service.offline_reward(100000 + 20 * 3600)
	check(int(offline.seconds) == 16 * 3600, "offline cap")
	check(service.claim_offline(true, 100000 + 20 * 3600) == int(offline.gold) * 2, "offline double")
	var claimed_at := profile.offline_last_claim
	check(service.claim_offline(false, claimed_at) == 0 and profile.offline_last_claim == claimed_at, "offline duplicate")
	MonetizationDebug.expire_subscription(profile)
	check(not service.subscription_valid() and service.offline_cap_hours() == 12, "expiry cap")
	ad_provider.fail_next = true
	check(SummonService.new(profile, ad_provider).summon("skills", 1, "ad").is_empty(), "failed summon ad")
	profile.daily_bonus_ad_claim = ""
	ad_provider.fail_next = true
	var before := profile.gold
	check(not service.claim_daily_bonus() and profile.gold == before, "failed ad gives no reward")
	profile.offline_last_claim = 100000
	ad_provider.fail_next = true
	check(service.claim_offline(true, 103600) == 0 and profile.offline_last_claim == 100000, "failed offline ad preserves claim")
	MonetizationDebug.cosmetic(profile, "royal_squire_cloak", true)
	var power := profile.power()
	check(service.equip_cosmetic("royal_squire_cloak") and profile.power() == power, "cosmetic no power")
	profile.save()
	var loaded := SaveData.load_from(PATH)
	check(loaded.premium_pass_owned and loaded.starter_pack_purchased and loaded.owned_cosmetics.has("royal_squire_cloak"), "entitlements save")
	check(loaded.daily_offers.size() == 3 and loaded.bp_season.free_claimed.has("1"), "offers and BP save")
	check(loaded.gold_boost_expiry > 0 and loaded.dungeon_ad_usage.has("gold"), "ad state save")
	var legacy := {"phase9_version": 1, "gold": 700, "gems": 45, "stage": 7}
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var migrated := SaveData.load_from(PATH)
	check(migrated.gold == 700 and migrated.gems == 45 and migrated.bp_season.id == "season_1", "Phase 9 migration")
	DirAccess.remove_absolute(PATH)
	print("PHASE 10: %s" % ("PASS" if failures == 0 else "%d FAILURES" % failures))
	quit(0 if failures == 0 else 1)
