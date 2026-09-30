class_name IdleRewardService
extends RefCounted

const Balance = preload("res://scripts/progression/progression_balance.gd")
var profile: SaveData

func _init(value: SaveData) -> void:
	profile = value

func offline_cap_hours() -> int:
	return Balance.OFFLINE_SUBSCRIBER_CAP_HOURS if MonetizationService.new(profile).subscription_valid() else Balance.OFFLINE_BASE_CAP_HOURS

func rates() -> Dictionary:
	var region_progress := maxi(0, profile.region - 1)
	var stage_progress := maxi(0, profile.stage - 1)
	return {"gold_per_hour": Balance.OFFLINE_BASE_GOLD_PER_HOUR + region_progress * Balance.OFFLINE_GOLD_PER_REGION + stage_progress * Balance.OFFLINE_GOLD_PER_STAGE + maxi(0, profile.level - 1) * Balance.OFFLINE_GOLD_PER_LEVEL,
		"exp_per_hour": Balance.OFFLINE_BASE_EXP_PER_HOUR + region_progress * Balance.OFFLINE_EXP_PER_REGION + stage_progress * Balance.OFFLINE_EXP_PER_STAGE + maxi(0, profile.level - 1) * Balance.OFFLINE_EXP_PER_LEVEL}

func calculate(seconds: int) -> Dictionary:
	var safe_seconds := clampi(seconds, 0, offline_cap_hours() * 3600)
	var values := rates()
	return {"seconds": safe_seconds, "gold": maxi(0, floori(float(safe_seconds) / 3600.0 * float(values.gold_per_hour))), "exp": maxi(0, floori(float(safe_seconds) / 3600.0 * float(values.exp_per_hour))), "gold_per_hour": values.gold_per_hour, "exp_per_hour": values.exp_per_hour}

func prepare(now: int) -> Dictionary:
	if profile.offline_pending_rewards is Dictionary and not profile.offline_pending_rewards.is_empty(): return profile.offline_pending_rewards.duplicate(true)
	if profile.offline_last_claim <= 0:
		profile.offline_last_claim = maxi(0, now)
		profile.save()
		return {}
	if now < profile.offline_last_claim: return {}
	var reward := calculate(now - profile.offline_last_claim)
	if int(reward.seconds) >= Balance.OFFLINE_MIN_POPUP_SECONDS:
		profile.offline_pending_rewards = reward.duplicate(true)
		profile.offline_pending_rewards["created_at"] = now
	else:
		profile.offline_last_claim = now
	profile.save()
	return profile.offline_pending_rewards.duplicate(true)

func claim(double_reward: bool, now: int, ads: RewardedAdProvider = null) -> Dictionary:
	if profile.offline_pending_rewards.is_empty(): return {}
	if double_reward:
		var provider := ads if ads != null else DevelopmentRewardedAdProvider.new()
		if not provider.show_rewarded_ad("offline_double"): return {}
	var reward := profile.offline_pending_rewards.duplicate(true)
	var multiplier := 2 if double_reward else 1
	var result := {"gold": maxi(0, int(reward.get("gold", 0))) * multiplier, "exp": maxi(0, int(reward.get("exp", 0))) * multiplier, "seconds": maxi(0, int(reward.get("seconds", 0)))}
	profile.offline_pending_rewards = {}
	profile.offline_last_claim = maxi(profile.offline_last_claim, now)
	profile.add_rewards(result.gold, result.exp, false)
	return result
