extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error("PHASE 12D: " + label)

func _run() -> void:
	var fresh := SaveData.new()
	fresh.save_path = "res://.godot/phase12d_fresh.save"
	var tutorials := TutorialService.new(fresh)
	check(tutorials.onboarding_active(), "fresh save starts onboarding")
	tutorials.skip()
	check(not tutorials.onboarding_active() and bool(fresh.tutorial_state.skipped), "skip ends onboarding")
	fresh.tutorial_state = TutorialService.fresh_state()
	tutorials = TutorialService.new(fresh)
	tutorials.mark_step("battle")
	tutorials.acknowledge_feature("Equipment")
	var tutorial_copy := SaveData.load_from(fresh.save_path)
	check(bool(tutorial_copy.tutorial_state.steps.get("battle", false)) and bool(tutorial_copy.tutorial_state.features.get("Equipment", false)), "step and feature acknowledgements persist")

	var old_path := "res://.godot/phase12d_legacy.save"
	var legacy := FileAccess.open(old_path, FileAccess.WRITE)
	legacy.store_string(JSON.stringify({"stage": 9, "level": 7, "gold": 430, "gems": 91, "exp": 12, "skills": {"shield_bash": {"level": 4, "duplicates": 0, "rarity": 0}}, "purchase_entitlements": {"starter_pack": true}, "campaign_first_clears": {"easy:1:1": true}}))
	legacy.close()
	var migrated := SaveData.load_from(old_path)
	check(migrated.stage == 9 and migrated.level == 7 and migrated.gold == 430 and migrated.gems == 91, "meaningful legacy progress preserved")
	check(bool(migrated.tutorial_state.completed) and bool(migrated.tutorial_state.skipped), "meaningful legacy save skips forced onboarding")
	check(int(migrated.skills.get("shield_bash", {}).get("level", 0)) == 4 and bool(migrated.purchase_entitlements.get("starter_pack", false)), "legacy skill and purchase state preserved")

	var idle := IdleRewardService.new(SaveData.new())
	check(int(idle.calculate(0).gold) == 0 and int(idle.calculate(-60).exp) == 0, "zero and negative offline duration safe")
	var one_hour: Dictionary = idle.calculate(3600)
	check(int(one_hour.gold) == 120 and int(one_hour.exp) == 18, "one hour base calculation")
	var capped: Dictionary = idle.calculate(20 * 3600)
	check(int(capped.seconds) == 12 * 3600 and int(capped.gold) == 1440, "base twelve hour cap")
	var clock_profile := SaveData.new()
	clock_profile.offline_last_claim = 20000
	check(IdleRewardService.new(clock_profile).prepare(10000).is_empty() and clock_profile.offline_last_claim == 20000, "backwards local clock yields no reward or timestamp rollback")
	var subscriber_profile := SaveData.new()
	subscriber_profile.subscription_active = true
	subscriber_profile.subscription_expiry_date = "9999-12-31"
	var subscriber_idle := IdleRewardService.new(subscriber_profile)
	check(subscriber_idle.offline_cap_hours() == 16 and int(subscriber_idle.calculate(20 * 3600).seconds) == 16 * 3600, "subscriber sixteen hour cap")

	var reward_profile := SaveData.new()
	reward_profile.save_path = "res://.godot/phase12d_rewards.save"
	reward_profile.offline_last_claim = 10000
	var rewards := IdleRewardService.new(reward_profile)
	var pending: Dictionary = rewards.prepare(13600)
	check(int(pending.gold) == 120 and int(pending.exp) == 18 and int(pending.created_at) == 13600 and int(reward_profile.offline_last_claim) == 10000, "prepared offline reward stores source time without consuming claim")
	var failed_ads := DevelopmentRewardedAdProvider.new()
	failed_ads.fail_next = true
	check(rewards.claim(true, 13600, failed_ads).is_empty() and not reward_profile.offline_pending_rewards.is_empty(), "failed 2x ad does not consume claim")
	var doubled: Dictionary = rewards.claim(true, 13600)
	check(int(doubled.gold) == 240 and int(doubled.exp) == 36 and reward_profile.gold == 240, "simulated 2x claim grants gold and hero EXP")
	check(rewards.claim(false, 13600).is_empty(), "duplicate claim prevention")
	reward_profile.offline_pending_rewards = {"seconds": 3600, "gold": 120, "exp": 18, "gold_per_hour": 120, "exp_per_hour": 18}
	reward_profile.save()
	check(not SaveData.load_from(reward_profile.save_path).offline_pending_rewards.is_empty(), "pending reward save/load persistence")

	var progression := SaveData.load_from("res://.godot/phase12d_fresh_profile_missing.save")
	progression.save_path = "res://.godot/phase12d_progress.save"
	check(progression.inventory.size() >= 1 and progression.skills.has("shield_bash"), "starter gear and skill available")
	check(SummonService.new(progression).can_summon("equipment", 1, "daily"), "introductory daily summon opportunity available")
	check(PveService.new(progression).can_start({"mode": "dungeon", "dungeon": "gold", "tier": 1}), "first dungeon access remains available")
	progression.add_rewards(30, 0, false)
	check(progression.gold >= GameData.upgrade_cost(0) and progression.buy_upgrade("atk"), "first ATK upgrade affordable from ordinary early rewards")
	var campaign_profile := SaveData.load_from("res://.godot/phase12d_campaign_missing.save")
	campaign_profile.save_path = "res://.godot/phase12d_early_campaign.save"
	var campaign_battle := BattleController.new()
	root.add_child(campaign_battle)
	var campaign_state := {"cleared": 0, "lost": false}
	campaign_battle.stage_cleared.connect(_advance_early_campaign.bind(campaign_profile, campaign_battle, campaign_state))
	campaign_battle.battle_lost.connect(_mark_early_loss.bind(campaign_state))
	campaign_battle.start(campaign_profile)
	for frame in 30000:
		if campaign_state.lost or campaign_profile.region >= 3: break
		campaign_battle._process(0.05)
	check(not bool(campaign_state.lost) and campaign_state.cleared == 40 and campaign_profile.region == 3 and campaign_profile.stage == 1, "fresh campaign simulation clears Easy 1-1 through 2-20")
	check(NumberFormat.compact(950) == "950" and NumberFormat.compact(1200) == "1.2K" and NumberFormat.compact(15800) == "15.8K" and NumberFormat.compact(2400000) == "2.4M" and NumberFormat.compact(1100000000) == "1.1B", "compact number formatting")
	check(NumberFormat.compact(999950) == "1.0M" and NumberFormat.compact(999950000) == "1.0B", "compact number unit boundaries")
	check(TutorialService.FEATURES.size() >= 15 and not TutorialService.FEATURES["Guild"].is_empty() and not TutorialService.FEATURES["PvP"].is_empty(), "contextual feature copy coverage")

	print("PHASE 12D SMOKE: %s" % ("FAIL (%d)" % failures if failures else "PASS"))
	quit(1 if failures else 0)

func _advance_early_campaign(profile: SaveData, battle: BattleController, state: Dictionary) -> void:
	state.cleared = int(state.cleared) + 1
	var cleared_stage := profile.stage
	profile.record_stage_clear(cleared_stage)
	if cleared_stage == 20:
		profile.region += 1
		profile.stage = 1
	else:
		profile.stage += 1
	profile.save()
	if profile.region < 3: battle.start(profile)

func _mark_early_loss(_boss_failure: bool, state: Dictionary) -> void:
	state.lost = true
