class_name PveService
extends RefCounted

var profile: SaveData

func _init(value: SaveData) -> void:
	profile = value
	for id in PveData.DUNGEONS:
		if not profile.dungeon_attempts.has(id):
			profile.dungeon_attempts[id] = {"day": "", "remaining": 2}

static func local_day() -> String:
	var date := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]

func refresh_day(day: String = "") -> void:
	if day == "":
		day = local_day()
	var dirty := false
	for id in PveData.DUNGEONS:
		var state: Dictionary = profile.dungeon_attempts[id]
		if state.get("day", "") != day:
			state["day"] = day
			state["remaining"] = PveData.DAILY_ATTEMPTS
			dirty = true
	if profile.boss_rush_state.get("day", "") != day:
		profile.boss_rush_state["day"] = day
		profile.boss_rush_state["remaining"] = PveData.DAILY_ATTEMPTS
		dirty = true
	if profile.endless_state.get("day", "") != day:
		profile.endless_state["day"] = day
		profile.endless_state["reward_remaining"] = PveData.DAILY_ATTEMPTS
		dirty = true
	var tier := maxi(profile.unlocked_dungeon_tier, PveData.unlocked_tier(profile))
	if tier != profile.unlocked_dungeon_tier:
		profile.unlocked_dungeon_tier = tier
		dirty = true
	if dirty:
		profile.save()

func can_start(config: Dictionary) -> bool:
	refresh_day()
	match str(config.get("mode", "")):
		"dungeon":
			var id := str(config.get("dungeon", ""))
			return PveData.DUNGEONS.has(id) and int(config.get("tier", 0)) >= 1 and int(config.get("tier", 0)) <= profile.unlocked_dungeon_tier and int(profile.dungeon_attempts[id]["remaining"]) > 0
		"tower": return int(config.get("floor", 0)) >= 1 and int(config.get("floor", 0)) <= profile.tower_highest + 1
		"boss_rush": return int(profile.boss_rush_state["remaining"]) > 0
		"endless": return true
	return false

func begin(config: Dictionary) -> Dictionary:
	if not can_start(config):
		return {}
	var run := config.duplicate(true)
	match str(run["mode"]):
		"dungeon": profile.dungeon_attempts[str(run["dungeon"])]["remaining"] -= 1
		"boss_rush": profile.boss_rush_state["remaining"] -= 1
		"endless":
			run["rewarded"] = int(profile.endless_state["reward_remaining"]) > 0
			if run["rewarded"]:
				profile.endless_state["reward_remaining"] -= 1
	profile.save()
	return run

func complete(run: Dictionary, result: Dictionary) -> Dictionary:
	var mode := str(run["mode"])
	var progress := int(result.get("progress", 0))
	var won := bool(result.get("won", false))
	var first := false
	if mode == "tower" and won:
		var floor := int(run["floor"])
		first = not profile.tower_first_clears.has(floor)
		if first:
			profile.tower_first_clears.append(floor)
		profile.tower_highest = maxi(profile.tower_highest, floor)
		if profile.tower_highest >= 20:
			profile.artifact_slot3_unlocked = true
	if mode == "boss_rush":
		profile.boss_rush_state["best_boss"] = maxi(int(profile.boss_rush_state["best_boss"]), progress)
		if progress >= PveData.BOSS_RUSH.size():
			profile.boss_rush_state["full_clear"] = true
	if mode == "endless":
		profile.endless_state["best_wave"] = maxi(int(profile.endless_state["best_wave"]), progress)
	var tracker := ProgressionService.new(profile)
	if mode == "dungeon" and won:
		tracker.report("dungeon_completed")
		if int(run.get("tier", 0)) >= 5: tracker.report("dungeon_tier_5")
	if mode == "tower" and won: tracker.report("tower_floor_cleared")
	if mode == "boss_rush": tracker.report("boss_rush_run")
	if mode == "endless":
		tracker.report("endless_wave_reached", progress)
		if bool(run.get("rewarded", false)): tracker.report("endless_rewarded_run")
	var reward := PveData.reward(run, progress, first)
	if mode == "dungeon" and not won or mode == "endless" and not bool(run.get("rewarded", false)):
		for key in reward:
			reward[key] = 0
	profile.add_rewards(int(reward["gold"]), int(reward["exp"]), false)
	for key in ["gems", "enhancement_stones", "companion_essence", "companion_crests", "artifact_dust", "evolution_crests", "hero_pieces"]:
		profile.set(key, int(profile.get(key)) + int(reward[key]))
	var drops: Array[Dictionary] = []
	if mode == "dungeon" and won:
		var tier := int(run["tier"])
		match str(run["dungeon"]):
			"equipment":
				var item := EquipmentData.summon_item(mini(7, tier - 1))
				profile.inventory.append(item)
				drops.append(item)
			"companions":
				if randi_range(1, 10) <= tier:
					var id: String = CompanionData.COMPANIONS.keys().pick_random()
					profile.add_companion_copy(id, mini(7, tier - 1))
					reward["companion_piece"] = id
			"artifacts":
				if randi_range(1, 50) <= tier:
					var id: String = ArtifactData.ARTIFACTS.keys().pick_random()
					profile.add_artifact_copy(id, 2)
					reward["artifact_progress"] = id
			"hero_trial":
				if tier >= 2:
					var id: String = ["mage", "ranger", "assassin", "necromancer"].pick_random()
					HeroProgress.new(profile).add_pieces(id, 1)
					reward["hero_piece"] = id
	profile.save()
	return {"reward": reward, "equipment": drops, "first_clear": first, "won": won, "progress": progress, "time": float(result.get("time", 0.0)), "kills": int(result.get("kills", 0)), "damage": int(result.get("damage", 0))}
