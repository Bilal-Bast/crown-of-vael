class_name Phase8Debug
extends RefCounted

static func unlock_region(profile: SaveData, difficulty: int, region: int) -> void:
	if OS.has_feature("release"): return
	profile.highest_difficulty_unlocked = maxi(profile.highest_difficulty_unlocked, difficulty)
	for number in range(1, region):
		profile.highest_stages[CampaignData.region_key(difficulty, number)] = 20
	profile.save()

static func set_campaign(profile: SaveData, difficulty: int, region: int, stage: int) -> void:
	if OS.has_feature("release"): return
	unlock_region(profile, difficulty, region)
	profile.campaign_difficulty = difficulty
	profile.region = region
	profile.stage = stage
	profile.save()

static func unlock_difficulty(profile: SaveData, difficulty: int) -> void:
	if OS.has_feature("release"): return
	profile.highest_difficulty_unlocked = maxi(profile.highest_difficulty_unlocked, difficulty)
	profile.save()

static func spawn_treasure(battle: BattleController) -> void:
	if OS.has_feature("release"): return
	battle.force_treasure = true
	battle._spawn_wave()

static func force_elite(battle: BattleController) -> void:
	if OS.has_feature("release"): return
	battle.force_elite = true
	battle.wave = 3
	battle._spawn_wave()

static func force_boss(battle: BattleController) -> void:
	if OS.has_feature("release"): return
	battle.force_boss = true
	battle._spawn_wave()
	battle.force_boss = false

static func test_element_matchup(attacker: String, defender: String) -> float:
	return CampaignData.element_multiplier(attacker, defender)

static func mark_difficulty_complete(profile: SaveData, difficulty: int) -> void:
	if OS.has_feature("release"): return
	profile.difficulty_completions[str(difficulty)] = true
	profile.highest_difficulty_unlocked = mini(5, maxi(profile.highest_difficulty_unlocked, difficulty + 1))
	profile.save()
