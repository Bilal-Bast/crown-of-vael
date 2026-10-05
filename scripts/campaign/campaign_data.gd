class_name CampaignData
extends RefCounted

const STAGES_PER_REGION := 20
const DIFFICULTIES := ["Easy", "Normal", "Hard", "Nightmare", "Hell", "Infernal"]
const HP_MULTIPLIERS := [1.0, 2.0, 5.0, 12.0, 30.0, 75.0]
const DAMAGE_MULTIPLIERS := [1.0, 1.8, 4.2, 9.0, 21.0, 48.0]
const DEMON_LORD_INFERNAL_HP_SCALE := 0.90
const TREASURE_CHANCE := 0.015
const ADVANTAGE := 1.20
const DISADVANTAGE := 0.90
const REGIONS := [
	{"name":"Greenvale Outskirts","theme":"Ruined countryside","icon":"♜","sky":"a9cabc","ground":"65845c","accent":"d6bc77","element":"Physical","enemies":["Goblin","Skeleton","Corrupted Wolf","Goblin Archer","Goblin Spearman","Bandit"],"elites":["Goblin Captain","Armored Skeleton"],"boss":"Goblin Warlord"},
	{"name":"Whispering Forest","theme":"Magical dark forest","icon":"♣","sky":"536a72","ground":"344f46","accent":"8fd9bd","element":"Poison","enemies":["Forest Goblin","Giant Spider","Corrupted Boar","Forest Bandit","Skeleton Archer","Poison Wolf"],"elites":["Spider Matriarch","Forest Brute"],"boss":"Ancient Treant"},
	{"name":"Ashen Highlands","theme":"Volcanic highlands","icon":"▲","sky":"8f6765","ground":"534544","accent":"f0a45e","element":"Fire","enemies":["Ash Goblin","Fire Imp","Charred Skeleton","Raider","Magma Hound","Fire Archer"],"elites":["Flame Brute","Ash Knight"],"boss":"Infernal Ogre"},
	{"name":"Frostfang Mountains","theme":"Snow and ice cliffs","icon":"❄","sky":"9ab8cf","ground":"68869b","accent":"d5edf6","element":"Ice","enemies":["Frost Wolf","Ice Goblin","Frozen Skeleton","Snow Bandit","Ice Archer","Frost Spirit"],"elites":["Ice Troll","Frost Knight"],"boss":"Frostfang Giant"},
	{"name":"Sunken Marshes","theme":"Poisoned swamp ruins","icon":"≈","sky":"788c74","ground":"465b45","accent":"b8d273","element":"Poison","enemies":["Swamp Goblin","Plague Rat","Bog Skeleton","Poison Slime","Swamp Beast","Cultist"],"elites":["Bog Horror","Plague Knight"],"boss":"Marsh Hydra"},
	{"name":"Crimson Desert","theme":"Red dunes and buried temples","icon":"◈","sky":"ce8c70","ground":"9c5948","accent":"f5cc88","element":"Fire","enemies":["Desert Raider","Sand Scorpion","Desert Skeleton","Fire Cultist","Sand Wolf","Tomb Archer"],"elites":["Sand Golem","Crimson Champion"],"boss":"Ancient Sand Wyrm"},
	{"name":"Ruined Kingdom","theme":"Destroyed capital","icon":"♛","sky":"957471","ground":"514a4c","accent":"d6ad87","element":"Dark","enemies":["Fallen Knight","Corrupted Soldier","Undead Guard","Dark Archer","Armored Ghoul","War Beast"],"elites":["Royal Executioner","Fallen Champion"],"boss":"Corrupted King"},
	{"name":"Shadowlands","theme":"Purple fog and floating ruins","icon":"◆","sky":"54466f","ground":"302d4c","accent":"bd8be0","element":"Dark","enemies":["Shadow Hound","Shade","Dark Mage","Phantom Archer","Shadow Knight","Void Spawn"],"elites":["Void Reaper","Shadow Champion"],"boss":"Lord of Shadows"},
	{"name":"Dragon Peaks","theme":"Dragon ruins, fire and lightning","icon":"♠","sky":"9a7a75","ground":"554d58","accent":"f0bd73","element":"Lightning","enemies":["Drake","Dragon Cultist","Flame Drake","Storm Drake","Dragon Knight","Wyvern"],"elites":["Elder Wyvern","Dragon Champion"],"boss":"Ancient Dragon"},
	{"name":"Demon Realm","theme":"Infernal castles and portals","icon":"✦","sky":"8b4147","ground":"402e3c","accent":"f36e65","element":"Dark","enemies":["Lesser Demon","Demon Archer","Hellhound","Demon Knight","Infernal Mage","Corrupted Giant"],"elites":["Demon Champion","Infernal Reaper"],"boss":"Demon Lord"}
]
const TREASURES := ["Treasure Goblin", "Golden Mimic", "Crystal Sprite"]
const FAMILY_WORDS := {"Goblin":"goblin","Skeleton":"skeleton","Wolf":"wolf","Hound":"wolf","Archer":"archer","Knight":"knight","Spider":"beast","Boar":"beast","Drake":"dragon","Wyvern":"dragon","Demon":"demon"}
const ARCHETYPE_MODIFIERS := {
	"MELEE":{"hp":1.0,"atk":1.0,"speed":1.0,"armor":0.0},
	"FAST":{"hp":0.75,"atk":0.75,"speed":1.5,"armor":0.0},
	"TANK":{"hp":2.0,"atk":0.85,"speed":0.8,"armor":3.0},
	"RANGED":{"hp":0.7,"atk":1.1,"speed":0.78,"armor":0.0},
	"MAGIC":{"hp":0.8,"atk":1.2,"speed":0.82,"armor":0.0},
	"HEALER":{"hp":0.9,"atk":0.6,"speed":0.75,"armor":0.0},
	"ELITE":{"hp":3.0,"atk":1.5,"speed":0.9,"armor":4.0},
	"BOSS":{"hp":20.0,"atk":3.0,"speed":0.85,"armor":6.0},
	"TREASURE":{"hp":1.8,"atk":0.2,"speed":0.55,"armor":0.0}
}

static func stage_key(difficulty: int, region: int, stage: int) -> String:
	return "%d:%d:%d" % [difficulty, region, stage]

static func region_key(difficulty: int, region: int) -> String:
	return "%d:%d" % [difficulty, region]

static func label(difficulty: int, region: int, stage: int) -> String:
	return "%s %d-%d" % [DIFFICULTIES[clampi(difficulty, 0, 5)], region, stage]

static func is_elite(stage: int) -> bool:
	return stage in [5, 10, 15]

static func archetype(kind: String, elite: bool = false, boss: bool = false) -> String:
	if boss: return "BOSS"
	if elite: return "ELITE"
	if TREASURES.has(kind): return "TREASURE"
	if "Healer" in kind or kind == "Cultist": return "HEALER"
	if "Archer" in kind or "Bandit" in kind: return "RANGED"
	if "Mage" in kind or "Spirit" in kind or "Imp" in kind or "Shade" in kind: return "MAGIC"
	if "Knight" in kind or "Golem" in kind or "Guard" in kind or "Giant" in kind or "Brute" in kind: return "TANK"
	if "Wolf" in kind or "Hound" in kind or "Rat" in kind or "Spider" in kind or "Scorpion" in kind: return "FAST"
	return "MELEE"

static func family(kind: String) -> String:
	if "Demon" in kind or "Hell" in kind or "Infernal" in kind: return "demon"
	if "Dragon" in kind or "Drake" in kind or "Wyvern" in kind: return "dragon"
	for word in FAMILY_WORDS:
		if word in kind: return FAMILY_WORDS[word]
	return "humanoid"

static func element(kind: String, region: int) -> String:
	if "Fire" in kind or "Flame" in kind or "Magma" in kind or "Infernal" in kind: return "Fire"
	if "Ice" in kind or "Frost" in kind or "Frozen" in kind: return "Ice"
	if "Storm" in kind: return "Lightning"
	if "Poison" in kind or "Plague" in kind or "Bog" in kind: return "Poison"
	if "Dark" in kind or "Shadow" in kind or "Void" in kind or "Demon" in kind: return "Dark"
	return str(REGIONS[region - 1]["element"])

static func element_multiplier(attacker: String, defender: String) -> float:
	if attacker == "Holy" and defender == "Dark": return ADVANTAGE
	if attacker == "Dark" and defender == "Holy": return DISADVANTAGE
	if attacker == "Fire" and defender == "Ice": return ADVANTAGE
	if attacker == "Ice" and defender == "Fire": return DISADVANTAGE
	if attacker == "Lightning" and defender in ["Dragon", "Water"]: return ADVANTAGE
	return 1.0

static func music_path(region: int, boss: bool, difficulty: int = 0) -> String:
	var suffix := "boss" if boss else "battle"
	var variant := "_hard" if difficulty >= 3 else ""
	return "res://audio/region_%02d_%s%s.ogg" % [region, suffix, variant]

static func wave_kinds(region: int, stage: int, wave: int, force_elite: bool = false, force_treasure: bool = false) -> Array[String]:
	var result: Array[String] = []
	var info: Dictionary = REGIONS[region - 1]
	if stage == 20:
		result.append(str(info["boss"]))
		return result
	var pool: Array = info["enemies"]
	for i in GameData.ENEMIES_PER_WAVE:
		result.append(str(pool[(stage + wave + i) % pool.size()]))
	if wave == 3 and (is_elite(stage) or force_elite):
		result[result.size() - 1] = str(info["elites"][(stage / 5) % 2])
	if force_treasure or randf() < TREASURE_CHANCE / 3.0:
		result[0] = TREASURES[randi_range(0, TREASURES.size() - 1)]
	return result

static func enemy_stats(kind: String, difficulty: int, region: int, stage: int, wave: int) -> Dictionary:
	var info: Dictionary = REGIONS[region - 1]
	var elite := (info["elites"] as Array).has(kind)
	var boss := str(info["boss"]) == kind
	var role := archetype(kind, elite, boss)
	var modifier: Dictionary = ARCHETYPE_MODIFIERS[role]
	var rank := 1.0 + (region - 1) * 0.72 + (stage - 1) * 0.045 + (wave - 1) * 0.04
	var base_hp: float = 28.0 * rank * float(modifier["hp"]) * float(HP_MULTIPLIERS[difficulty])
	var base_atk: float = 3.0 * rank * float(modifier["atk"]) * float(DAMAGE_MULTIPLIERS[difficulty])
	if boss and region == 10 and stage == 20 and difficulty == 5:
		base_hp *= DEMON_LORD_INFERNAL_HP_SCALE
	if boss and region == 1 and difficulty == 0:
		base_hp = 1250.0
		base_atk = 24.0
	var reward_scale := 1.0 + (region - 1) * 0.28 + (stage - 1) * 0.025 + difficulty * 0.5
	var reward_bonus := 3.0 if role == "TREASURE" else (4.0 if boss else (1.7 if elite else 1.0))
	return {"kind":kind,"visual":kind,"family":family(kind),"archetype":role,"element":element(kind, region),"hp":base_hp,"atk":base_atk,"armor":float(modifier["armor"]) * rank,"speed":float(modifier["speed"]),"gold":maxi(1,roundi(4.0 * reward_scale * reward_bonus)),"exp":maxi(1,roundi(3.0 * reward_scale * reward_bonus)),"color":Color(str(info["accent"])),"difficulty":difficulty,"region":region}

static func region_reward(difficulty: int, region: int) -> Dictionary:
	return {"gems":3 + difficulty * 2 + region / 3,"gold":100 * region * (difficulty + 1),"crests":1 + difficulty / 2,"stones":2 + difficulty,"essence":1 + difficulty,"dust":1 + difficulty}
