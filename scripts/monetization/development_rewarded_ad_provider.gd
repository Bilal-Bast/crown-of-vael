class_name DevelopmentRewardedAdProvider
extends RewardedAdProvider

var fail_next := false

func show_rewarded_ad(_placement: String = "") -> bool:
	if fail_next:
		fail_next = false
		return false
	return true
