extends RefCounted

# Test-only helpers. Never loaded by the game scene.
static func reset_dungeon(profile: SaveData, id: String) -> void:
	profile.dungeon_attempts[id] = {"day": PveService.local_day(), "remaining": 2}
	profile.save()

static func set_tower_floor(profile: SaveData, floor: int) -> void:
	profile.tower_highest = maxi(0, floor)
	profile.artifact_slot3_unlocked = profile.tower_highest >= 20
	profile.save()

static func reset_boss_rush(profile: SaveData) -> void:
	profile.boss_rush_state["day"] = PveService.local_day()
	profile.boss_rush_state["remaining"] = 2
	profile.save()

static func reset_endless(profile: SaveData) -> void:
	profile.endless_state["day"] = PveService.local_day()
	profile.endless_state["reward_remaining"] = 2
	profile.save()

static func grant_materials(profile: SaveData, crests: int, pieces: int) -> void:
	profile.evolution_crests += maxi(0, crests)
	profile.hero_pieces += maxi(0, pieces)
	profile.save()
