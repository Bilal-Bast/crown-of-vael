extends RefCounted

static func reset_onboarding_only(profile: SaveData) -> void:
	profile.tutorial_state = TutorialService.fresh_state()
	profile.save()

static func simulate_offline(profile: SaveData, hours: int, now: int) -> Dictionary:
	profile.offline_pending_rewards = {}
	profile.offline_last_claim = maxi(0, now - maxi(0, hours) * 3600)
	return IdleRewardService.new(profile).prepare(now)

static func show_feature(main: Node, feature_name: String) -> void:
	main.call("_show_feature_for_tab", feature_name)

static func inspect_idle(profile: SaveData, seconds: int) -> Dictionary:
	var service := IdleRewardService.new(profile)
	var result := service.calculate(seconds)
	result["cap_hours"] = service.offline_cap_hours()
	return result
