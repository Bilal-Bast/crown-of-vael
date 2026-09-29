extends RefCounted

# Test-only grants. This script is never referenced by gameplay UI or services.
static func grant_currency(profile: SaveData, gems: int, essence: int, crests: int, dust: int, gold: int) -> void:
	profile.gems += gems
	profile.companion_essence += essence
	profile.companion_crests += crests
	profile.artifact_dust += dust
	profile.gold += gold

static func grant_companion_copies(profile: SaveData, id: String, count: int, rarity: int = 0) -> void:
	for i in count:
		profile.add_companion_copy(id, rarity)

static func grant_artifact_copies(profile: SaveData, id: String, count: int, rarity: int = 2) -> void:
	for i in count:
		profile.add_artifact_copy(id, rarity)
