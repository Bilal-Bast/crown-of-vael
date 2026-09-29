extends RefCounted

# Test-only grants. This script is never loaded by the game scene.
static func grant_hero_pieces(profile: SaveData, id: String, amount: int) -> void:
	HeroProgress.new(profile).add_pieces(id, maxi(0, amount))

static func grant_generic_pieces(profile: SaveData, amount: int) -> void:
	profile.hero_pieces += maxi(0, amount)
	profile.save()

static func grant_evolution_resources(profile: SaveData, level: int = 100, gold: int = 1000000, crests: int = 500) -> void:
	profile.level = maxi(profile.level, level)
	profile.gold += maxi(0, gold)
	profile.evolution_crests += maxi(0, crests)
	profile.save()
