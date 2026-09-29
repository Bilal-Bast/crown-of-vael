class_name ProgressionData
extends RefCounted

const DAILY := [
	["kills", "⚔", "Defeat Enemies", "Defeat 100 enemies", "enemy_defeated", 100, {"gold": 3000}],
	["stages", "◆", "Campaign March", "Clear 10 campaign stages", "campaign_stage_cleared", 10, {"enhancement_stones": 5}],
	["dungeons", "◈", "Dungeon Delver", "Complete 2 Dungeons", "dungeon_completed", 2, {"companion_essence": 5}],
	["summons", "✦", "Summoner", "Summon 10 times", "summon_performed", 10, {"gems": 5}],
	["equipment", "⚒", "Forge Work", "Enhance equipment 3 times", "equipment_enhanced", 3, {"enhancement_stones": 5}],
	["skills", "✧", "Skill Study", "Level a skill once", "skill_upgraded", 1, {"gold": 4000}],
	["companions", "♞", "Companion Care", "Upgrade a companion once", "companion_upgraded", 1, {"companion_essence": 8}],
	["artifacts", "◉", "Relic Care", "Upgrade an artifact once", "artifact_upgraded", 1, {"artifact_dust": 8}],
	["tower", "♜", "Tower Climb", "Complete 1 Tower floor", "tower_floor_cleared", 1, {"evolution_crests": 2}],
	["gold", "●", "Gold Seeker", "Collect 50,000 Gold", "gold_earned", 50000, {"gold": 5000}]
]

const WEEKLY := [
	["kills", "⚔", "Monster Hunt", "Defeat 1,000 enemies", "enemy_defeated", 1000, {"gold": 20000}],
	["stages", "◆", "Long Campaign", "Clear 100 campaign stages", "campaign_stage_cleared", 100, {"gems": 20}],
	["dungeons", "◈", "Dungeon Veteran", "Complete 10 Dungeons", "dungeon_completed", 10, {"enhancement_stones": 25}],
	["summons", "✦", "Arcane Patron", "Summon 100 times", "summon_performed", 100, {"gems": 25}],
	["tower", "♜", "Tower Conqueror", "Clear 20 Tower floors", "tower_floor_cleared", 20, {"evolution_crests": 10}],
	["boss_rush", "♛", "Boss Hunter", "Play Boss Rush 3 times", "boss_rush_run", 3, {"hero_pieces": 5}],
	["endless", "∞", "Survivor", "Complete 5 rewarded Endless runs", "endless_rewarded_run", 5, {"artifact_dust": 20}],
	["equipment", "⚒", "Master Smith", "Enhance equipment 20 times", "equipment_enhanced", 20, {"enhancement_stones": 25}],
	["skills", "✧", "Skill Scholar", "Level skills 10 times", "skill_upgraded", 10, {"skill_ticket": 2}],
	["companions", "♞", "Beast Keeper", "Upgrade companions 10 times", "companion_upgraded", 10, {"companion_essence": 25}],
	["artifacts", "◉", "Relic Keeper", "Upgrade artifacts 5 times", "artifact_upgraded", 5, {"artifact_dust": 25}],
	["gold", "●", "Fortune Hunter", "Earn 1,000,000 Gold", "gold_earned", 1000000, {"gold": 30000}]
]

const DAILY_MILESTONES := {20: {"gold": 3000}, 40: {"enhancement_stones": 8}, 60: {"gems": 8}, 80: {"companion_essence": 12, "artifact_dust": 12}, 100: {"gems": 30, "hero_pieces": 8, "evolution_crests": 5}}
const WEEKLY_MILESTONES := {50: {"gold": 15000}, 100: {"gems": 15, "enhancement_stones": 15}, 150: {"companion_ticket": 2, "artifact_ticket": 2}, 200: {"gems": 25, "evolution_crests": 15}, 250: {"gems": 75, "equipment_ticket": 3, "skill_ticket": 3, "evolution_crests": 30, "hero_pieces": 20}}

const ACHIEVEMENT_CATEGORIES := ["CAMPAIGN", "HEROES", "COMBAT", "SUMMONING", "EQUIPMENT", "SKILLS", "COMPANIONS", "ARTIFACTS", "ADVENTURE", "COLLECTION", "PROGRESSION"]

static func achievements() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var specs := [
		["COMBAT", "enemy_defeated", "Monster Hunter", [1000, 10000, 100000]],
		["COMBAT", "critical_hit", "Critical Master", [1000]],
		["COMBAT", "damage_dealt", "Destroyer", [1000000, 100000000]],
		["COMBAT", "boss_defeated", "Boss Slayer", [100]],
		["COMBAT", "elite_defeated", "Elite Slayer", [1000]],
		["COMBAT", "treasure_found", "Treasure Hunter", [10, 100]],
		["SUMMONING", "summon_performed", "Summoner", [10, 100, 1000]],
		["EQUIPMENT", "equipment_enhanced", "Master Smith", [10, 100]],
		["EQUIPMENT", "equipment_merged", "Fusion Master", [10]],
		["SKILLS", "skill_cast", "Spell Master", [10000]],
		["COMPANIONS", "companion_damage", "Trusted Allies", [100000, 1000000]],
		["ADVENTURE", "dungeon_completed", "Dungeon Explorer", [10, 100]],
		["ADVENTURE", "boss_rush_run", "Boss Rush Veteran", [10]],
		["CAMPAIGN", "campaign_stage_cleared", "Campaign Veteran", [100, 500, 1000]]
	]
	for spec in specs:
		for index in spec[3].size():
			var target: int = spec[3][index]
			entries.append({"id": "%s_%d" % [spec[1], target], "category": spec[0], "title": "%s %s" % [spec[2], ["I", "II", "III"][index]], "description": "Reach %s %s" % [str(target), str(spec[1]).replace("_", " ")], "key": spec[1], "target": target, "reward": {"gems": mini(50, 10 + index * 15), "gold": 1000 * (index + 1)}})
	var static_entries := [
		["CAMPAIGN", "campaign:0:1:20", "Clear Greenvale Outskirts", 1],
		["CAMPAIGN", "easy_regions", "Clear All Easy Regions", 10],
		["CAMPAIGN", "difficulty_unlocked", "Unlock Normal", 1],
		["CAMPAIGN", "difficulty_unlocked", "Unlock Hard", 2],
		["CAMPAIGN", "difficulty_unlocked", "Unlock Nightmare", 3],
		["CAMPAIGN", "difficulty_unlocked", "Unlock Hell", 4],
		["CAMPAIGN", "difficulty_unlocked", "Unlock Infernal", 5],
		["CAMPAIGN", "campaign:5:10:20", "Clear Infernal 10-20", 1],
		["HEROES", "heroes_unlocked", "Unlock 2 Heroes", 2],
		["HEROES", "heroes_unlocked", "Unlock All 5 Heroes", 5],
		["HEROES", "hero_max_stars", "Reach 3 Stars", 3],
		["HEROES", "hero_max_stars", "Reach 5 Stars", 5],
		["HEROES", "knight_evolution", "Evolve into Knight", 1],
		["HEROES", "knight_evolution", "Evolve into Royal Knight", 2],
		["HEROES", "knight_evolution", "Evolve into Paladin", 3],
		["HEROES", "knight_evolution", "Evolve into Divine Paladin", 4],
		["EQUIPMENT", "equipment_slots", "Equip All 7 Slots", 7],
		["SKILLS", "skills_owned", "Unlock 4 Skills", 4],
		["SKILLS", "skill_slots", "Fill All Skill Slots", 4],
		["SKILLS", "skill_max_level", "Level 5 Skill", 5],
		["SKILLS", "skill_max_level", "Level 10 Skill", 10],
		["COMPANIONS", "companions_owned", "Unlock 4 Companions", 4],
		["COMPANIONS", "companion_slots", "Fill All Companion Slots", 4],
		["COMPANIONS", "companion_max_stars", "Reach 5-Star Companion", 5],
		["COMPANIONS", "wolf_evolution", "Evolve Dire Wolf", 1],
		["COMPANIONS", "wolf_evolution", "Evolve Shadow Wolf", 2],
		["COMPANIONS", "wolf_evolution", "Evolve Fenrir", 3],
		["ARTIFACTS", "artifacts_owned", "Obtain First Artifact", 1],
		["ARTIFACTS", "artifact_slots", "Equip 2 Artifacts", 2],
		["ARTIFACTS", "artifact_slot_limit", "Unlock Artifact Slot 3", 3],
		["ARTIFACTS", "artifact_max_level", "Level 10 Artifact", 10],
		["ARTIFACTS", "dragon_set", "Activate Dragon Relics 2-Piece", 2],
		["ARTIFACTS", "dragon_set", "Activate Dragon Relics 3-Piece", 3],
		["ADVENTURE", "dungeon_tier_5", "Clear Tier 5 Dungeon", 1],
		["ADVENTURE", "tower_highest", "Reach Tower Floor 10", 10],
		["ADVENTURE", "tower_highest", "Reach Tower Floor 20", 20],
		["ADVENTURE", "tower_highest", "Reach Tower Floor 50", 50],
		["ADVENTURE", "tower_highest", "Reach Tower Floor 100", 100],
		["ADVENTURE", "boss_rush_best", "Defeat Boss 5", 5],
		["ADVENTURE", "highest_endless_wave", "Reach Endless Wave 25", 25],
		["ADVENTURE", "highest_endless_wave", "Reach Endless Wave 50", 50],
		["ADVENTURE", "highest_endless_wave", "Reach Endless Wave 100", 100],
		["COLLECTION", "equipment_owned", "Own 10 Equipment", 10],
		["COLLECTION", "collection_total", "Gather 20 Collectibles", 20],
		["PROGRESSION", "hero_level", "Reach Hero Level 100", 100]
	]
	for item in static_entries:
		entries.append({"id": str(item[1]) + "_" + str(item[3]), "category": item[0], "title": item[2], "description": item[2], "key": item[1], "target": item[3], "reward": {"gold": 3000, "hero_pieces": 2}})
	for banner in ["equipment", "skills", "companions", "artifacts"]:
		for rarity in range(4, 8):
			var category: String = {"equipment": "EQUIPMENT", "skills": "SKILLS", "companions": "COMPANIONS", "artifacts": "ARTIFACTS"}[banner]
			entries.append({"id": "%s_rarity_%d" % [banner, rarity], "category": category, "title": "Obtain %s %s" % [EquipmentData.RARITIES[rarity], banner.capitalize()], "description": "Own one of this rarity", "key": "rarity:%s:%d" % [banner, rarity], "target": 1, "reward": {"gems": 10, "gold": 3000}})
	for rarity in range(4, 8):
		entries.append({"id": "summon_first_rarity_%d" % rarity, "category": "SUMMONING", "title": "First %s Summon" % EquipmentData.RARITIES[rarity], "description": "Summon from any banner", "key": "summon_rarity_%d" % rarity, "target": 1, "reward": {"gems": 15}})
	return entries

static func login_reward(index: int, monthly: bool = false) -> Dictionary:
	var day := index % (28 if monthly else 7) + 1
	if monthly:
		if day == 28: return {"gems": 100, "hero_pieces": 25, "evolution_crests": 15}
		if day % 7 == 0: return {"gems": 25, "hero_pieces": 5}
		match day % 6:
			0: return {"companion_crests": 2}
			1: return {"gold": 5000}
			2: return {"enhancement_stones": 5}
			3: return {"gems": 5}
			4: return {"companion_essence": 8}
			_: return {"artifact_dust": 8}
	match day:
		1: return {"gold": 3000}
		2: return {"enhancement_stones": 6}
		3: return {"gems": 8}
		4: return {"companion_essence": 8}
		5: return {"artifact_dust": 8}
		6: return {"evolution_crests": 5}
		_: return {"gems": 30, "hero_pieces": 8}
