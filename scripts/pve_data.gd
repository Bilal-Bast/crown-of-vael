class_name PveData
extends RefCounted

const DUNGEONS := {
	"gold": {"name": "Gold Dungeon", "theme": "Treasure Goblins and a Golden Goblin", "reward": "Gold"},
	"exp": {"name": "EXP Dungeon", "theme": "Undead spirits and a Spectral Knight", "reward": "Hero EXP"},
	"equipment": {"name": "Equipment Dungeon", "theme": "Armored raiders and a Forge Guardian", "reward": "Gear + Enhancement Stones"},
	"companions": {"name": "Companion Dungeon", "theme": "Corrupted beasts and a Beastmaster", "reward": "Companion Essence + Crests"},
	"artifacts": {"name": "Artifact Dungeon", "theme": "Ancient constructs and a Sentinel", "reward": "Artifact Dust + rare progress"},
	"hero_trial": {"name": "Hero Trial", "theme": "Oathbound shades and a Trial Champion", "reward": "Evolution Crests + Hero Pieces"}
}
const TIER_STAGES := [1, 3, 5, 7, 10]
const BOSS_RUSH := ["Goblin Warlord", "Corrupted Ogre", "Skeleton Champion", "Beast Tyrant", "Ancient Guardian"]
const BOSS_HEAL := 0.10
const DAILY_ATTEMPTS := 2

static func unlocked_tier(profile: SaveData) -> int:
	var cleared := 10 if profile.campaign_complete else profile.stage - 1
	var result := 1
	for index in TIER_STAGES.size():
		if cleared >= int(TIER_STAGES[index]):
			result = index + 1
	return result

static func mode_label(config: Dictionary) -> String:
	match str(config.get("mode", "campaign")):
		"dungeon": return str(DUNGEONS[config["dungeon"]]["name"]).to_upper()
		"tower": return "TOWER"
		"boss_rush": return "BOSS RUSH"
		"endless": return "ENDLESS"
	return "CAMPAIGN"

static func scale(config: Dictionary, wave: int = 1) -> Dictionary:
	match str(config["mode"]):
		"dungeon":
			var tier := int(config["tier"])
			return {"hp": 0.50 + (tier - 1) * 0.45, "atk": 0.48 + (tier - 1) * 0.40}
		"tower":
			var floor := int(config["floor"])
			return {"hp": 0.70 + (floor - 1) * 0.16, "atk": 0.55 + (floor - 1) * 0.12}
		"boss_rush":
			return {"hp": 0.80 + (wave - 1) * 0.48, "atk": 0.72 + (wave - 1) * 0.40}
		"endless":
			return {"hp": 0.55 + (wave - 1) * 0.16, "atk": 0.50 + (wave - 1) * 0.13}
	return {"hp": 1.0, "atk": 1.0}

static func wave_enemies(config: Dictionary, wave: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var mode := str(config["mode"])
	var names: Array = []
	var elite := false
	var visual := "Goblin"
	match mode:
		"dungeon":
			var id := str(config["dungeon"])
			elite = wave == 3
			match id:
				"gold": names = ["Golden Goblin"] if elite else ["Treasure Goblin", "Treasure Goblin", "Treasure Goblin", "Treasure Goblin", "Treasure Goblin"]; visual = "Goblin"
				"exp": names = ["Spectral Knight"] if elite else ["Wandering Spirit", "Skeleton", "Wandering Spirit", "Skeleton"]; visual = "Skeleton"
				"equipment": names = ["Forge Guardian"] if elite else ["Armored Raider", "Armored Raider", "Forge Sentry"]; visual = "Skeleton"
				"companions": names = ["Beastmaster"] if elite else ["Corrupted Wolf", "Wild Beast", "Corrupted Wolf", "Wild Beast"]; visual = "Corrupted Wolf"
				"artifacts": names = ["Ancient Sentinel"] if elite else ["Cursed Construct", "Ruin Guardian", "Cursed Construct"]; visual = "Skeleton"
				_: names = ["Trial Champion"] if elite else ["Oathbound Shade", "Oathbound Shade", "Skeleton"]; visual = "Skeleton"
		"tower":
			var floor := int(config["floor"])
			elite = floor % 5 == 0
			visual = "Goblin Warlord" if floor % 10 == 0 else ("Skeleton" if elite else "Goblin")
			names = ["Tower Warden"] if floor % 10 == 0 else (["Tower Elite"] if elite else ["Tower Guard", "Tower Guard", "Tower Guard"])
		"boss_rush":
			elite = true
			visual = ["Goblin Warlord", "Goblin", "Skeleton", "Corrupted Wolf", "Skeleton"][clampi(wave - 1, 0, 4)]
			names = [BOSS_RUSH[clampi(wave - 1, 0, 4)]]
		"endless":
			elite = wave % 5 == 0
			names = ["Survival Elite"] if elite else ["Goblin", "Skeleton", "Corrupted Wolf", "Goblin"]
			visual = "Goblin Warlord" if elite else "Goblin"
	var multipliers := scale(config, wave)
	for name in names:
		var hp := (115.0 if elite else 29.0) * float(multipliers["hp"])
		var atk := (10.0 if elite else 4.0) * float(multipliers["atk"])
		if mode == "dungeon" and config["dungeon"] == "equipment":
			hp *= 1.3
		if mode == "boss_rush":
			hp *= 2.5
		result.append({"kind": name, "visual": visual, "hp": hp, "atk": atk, "speed": 1.0 if elite else 1.15, "gold": 0, "exp": 0, "color": Color("d09548") if elite else Color("83b761")})
	return result

static func reward(config: Dictionary, progress: int, first_clear: bool = true) -> Dictionary:
	var result := {"gold": 0, "exp": 0, "gems": 0, "enhancement_stones": 0, "companion_essence": 0, "companion_crests": 0, "artifact_dust": 0, "evolution_crests": 0, "hero_pieces": 0}
	match str(config["mode"]):
		"dungeon":
			var tier := int(config["tier"])
			match str(config["dungeon"]):
				"gold": result["gold"] = 120 * tier * tier
				"exp": result["exp"] = 50 * tier * tier; result["gold"] = 10 * tier
				"equipment": result["enhancement_stones"] = 2 * tier; result["gold"] = 20 * tier
				"companions": result["companion_essence"] = 8 * tier; result["companion_crests"] = 1 if tier >= 3 else 0
				"artifacts": result["artifact_dust"] = 5 * tier
				"hero_trial": result["evolution_crests"] = 1 + tier / 2; result["exp"] = 25 * tier; result["hero_pieces"] = tier
		"tower":
			if first_clear:
				var floor := int(config["floor"])
				result["gold"] = 30 + floor * 12
				result["gems"] = 1 + floor / 5
				result["enhancement_stones"] = 1 + floor / 10
				result["companion_essence"] = floor / 5
				result["artifact_dust"] = floor / 10
				if floor % 10 == 0:
					result["gold"] += 250 + floor * 10
					result["gems"] += 10
					result["evolution_crests"] = 1
		"boss_rush":
			result["gold"] = 35 * progress
			result["gems"] = progress
			result["enhancement_stones"] = progress / 2
			result["companion_essence"] = 2 * progress
			result["artifact_dust"] = progress
			if progress == 5:
				result["gems"] += 10
				result["artifact_dust"] += 8
		"endless":
			result["gold"] = 8 * progress
			result["exp"] = 3 * progress
			result["enhancement_stones"] = progress / 8
			result["companion_essence"] = progress / 10
			result["artifact_dust"] = progress / 15
	return result
