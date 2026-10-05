extends SceneTree

## Deterministic campaign-only progression and boss audit. Excludes random drops,
## summons, quests, dungeons and companions; equips the free starter gear set.
var snapshots: Dictionary = {}
var economy := {"level": 1, "exp": 0, "gold": 0, "upgrades": {"hp": 0, "atk": 0, "armor": 0}}
var upgrade_cycle := ["atk", "atk", "hp", "atk", "armor"]
var upgrade_cursor := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	seed(1401)
	_capture_point(0, 1, 1)
	for difficulty in range(6):
		for region in range(1, 11):
			for stage in range(1, 21):
				if stage in [1, 10, 20]:
					_capture_point(difficulty, region, stage)
				_simulate_campaign_stage(difficulty, region, stage)
			if region == 10 and difficulty < 5:
				_capture_point(difficulty + 1, 1, 1)
	print("PHASE 14A CAMPAIGN-ONLY PLAYER PROFILE (starter set equipped; attack-weighted upgrades; no drops/summons/PvE/quests)")
	var points := ["0:1:1", "0:1:10", "0:1:20", "0:3:1", "0:5:1", "0:7:1", "0:10:20", "1:1:1", "1:10:20", "2:1:1", "2:5:1", "2:10:20", "3:10:20", "4:10:20", "5:10:20"]
	for key in points:
		if not snapshots.has(key):
			continue
		var point: Dictionary = snapshots[key]
		var profile := _profile_from(point)
		var stats := profile.hero_stats()
		var parts: PackedStringArray = key.split(":")
		var difficulty := int(parts[0])
		var region := int(parts[1])
		var stage := int(parts[2])
		var boss: Dictionary = CampaignData.enemy_stats(str(CampaignData.REGIONS[region - 1]["boss"]), difficulty, region, 20, 1)
		var raw_hit_dps := float(stats["atk"]) * float(stats["speed"]) * (1.0 + 0.75 * float(stats["crit_chance"]))
		var effective_hit := maxf(1.0, raw_hit_dps / maxf(0.01, float(stats["speed"])) - float(boss["armor"])) * float(stats["speed"])
		var bash_dps := maxf(1.0, float(stats["atk"]) * 2.25 - float(boss["armor"])) / 8.0
		var estimated_dps := effective_hit + bash_dps
		var simulated := _simulate_boss(profile, region, stage, difficulty)
		print("%s L%d ATK%.1f ARM%.1f HP%.0f upg=%s bossHP=%.0f arm=%.1f reqDPS=%.1f baseDPS=%.1f modelTTK=%.1fs result=%s damageTaken=%.0f" % [key, profile.level, stats["atk"], stats["armor"], stats["hp"], str(profile.upgrades), boss["hp"], boss["armor"], float(boss["hp"]) / 30.0, estimated_dps, simulated["time"], "WIN" if simulated["won"] else "FAIL", simulated["damage_taken"]])
	_print_system_audit()
	quit()

func _capture_point(difficulty: int, region: int, stage: int) -> void:
	var key := "%d:%d:%d" % [difficulty, region, stage]
	if snapshots.has(key):
		return
	snapshots[key] = economy.duplicate(true)

func _simulate_campaign_stage(difficulty: int, region: int, stage: int) -> void:
	if stage == 20:
		var boss := CampaignData.enemy_stats(str(CampaignData.REGIONS[region - 1]["boss"]), difficulty, region, stage, 1)
		_add_rewards(int(boss["gold"]), int(boss["exp"]))
	else:
		for wave in range(1, GameData.WAVES_PER_STAGE + 1):
			for kind in CampaignData.wave_kinds(region, stage, wave):
				var enemy := CampaignData.enemy_stats(kind, difficulty, region, stage, wave)
				_add_rewards(int(enemy["gold"]), int(enemy["exp"]))
	if stage == 20:
		var region_reward := CampaignData.region_reward(difficulty, region)
		economy["gold"] = int(economy["gold"]) + int(region_reward["gold"])
	while true:
		var stat := str(upgrade_cycle[upgrade_cursor % upgrade_cycle.size()])
		var rank := int(economy["upgrades"][stat])
		var cost := GameData.upgrade_cost(rank)
		if int(economy["gold"]) < cost:
			break
		economy["gold"] = int(economy["gold"]) - cost
		economy["upgrades"][stat] = rank + 1
		upgrade_cursor += 1

func _add_rewards(gold: int, exp: int) -> void:
	economy["gold"] = int(economy["gold"]) + gold
	economy["exp"] = int(economy["exp"]) + exp
	while int(economy["exp"]) >= GameData.exp_to_next(int(economy["level"])):
		economy["exp"] = int(economy["exp"]) - GameData.exp_to_next(int(economy["level"]))
		economy["level"] = int(economy["level"]) + 1

func _profile_from(point: Dictionary) -> SaveData:
	var profile := SaveData.new()
	profile.save_path = "res://.godot/phase14a_boss_sim.save"
	profile.level = int(point["level"])
	profile.exp = int(point["exp"])
	profile.gold = int(point["gold"])
	profile.upgrades = (point["upgrades"] as Dictionary).duplicate(true)
	profile.campaign_difficulty = 0
	profile._grant_starters()
	for item in profile.inventory:
		profile.equipped[str(EquipmentData.ITEMS[str(item["kind"])]["slot"])] = str(item["id"])
	return profile

func _simulate_boss(profile: SaveData, region: int, _stage: int, difficulty: int) -> Dictionary:
	profile.region = region
	profile.stage = 20
	profile.campaign_difficulty = difficulty
	var battle := BattleController.new()
	battle.start(profile)
	var time := 0.0
	var max_time := 30.0
	while battle.active and time < max_time:
		var step := 1.0 / 60.0
		battle._process(step)
		time += step
	return {"time": time, "won": not battle.active and float(battle.enemies[0]["current_hp"]) <= 0.0, "damage_taken": float(profile.hero_stats()["hp"]) - battle.hero_hp}

func _print_system_audit() -> void:
	var campaign_first_clear_gems := 0
	for difficulty in range(6):
		for region in range(1, 11):
			campaign_first_clear_gems += 19 + 5 + difficulty
			campaign_first_clear_gems += int(CampaignData.region_reward(difficulty, region)["gems"])
	print("CAMPAIGN FIRST-CLEAR GEMS across all 6x10x20 clears: %d (does not include quests/login/achievements/events)." % campaign_first_clear_gems)
	print("Summon pity: 100 pulls; best paid batch cost 2 x 50-pulls = %d gems. Pity cadence is 100 days at 1 free pull/day/banner, or 25 days/banner with 1 daily + 3 ad pulls/day." % (SummonData.COSTS[50] * 2))
	print("Free daily/ad capacity: %d pulls/day across four banners (assuming 3 rewarded pulls per banner). Banner level 1->10 requires 450 pulls." % (SummonData.BANNERS.size() * (1 + SummonData.AD_DAILY_LIMIT)))
	for tier in [1, 3, 5]:
		var hero_trial := PveData.reward({"mode": "dungeon", "dungeon": "hero_trial", "tier": tier}, 3, true)
		var artifact := PveData.reward({"mode": "dungeon", "dungeon": "artifacts", "tier": tier}, 3, true)
		var companions := PveData.reward({"mode": "dungeon", "dungeon": "companions", "tier": tier}, 3, true)
		print("Dungeon tier %d x2/day: Hero Trial %d crests/%d generic pieces +%d XP; Artifact %d dust; Companion %d essence/%d crest plus %d%% copy chance per run." % [tier, int(hero_trial["evolution_crests"]) * 2, int(hero_trial["hero_pieces"]) * 2, int(hero_trial["exp"]) * 2, int(artifact["artifact_dust"]) * 2, int(companions["companion_essence"]) * 2, int(companions["companion_crests"]) * 2, tier * 10])
	var evolution_total := 0
	for cost in HeroData.KNIGHT_EVOLUTION:
		evolution_total += int(cost["crests"])
	print("Knight evolution total: level 230 cumulative gates; %d crests; %d gold." % [evolution_total, 630000])
	print("Companion boss-damage stage check currently compares stage 10 while boss stages are stage 20 (audit flag).")
