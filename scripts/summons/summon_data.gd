class_name SummonData
extends RefCounted

const BANNERS := ["equipment", "skills", "companions", "artifacts"]
const COSTS := {1: 100, 10: 900, 30: 2640, 50: 4250}
const PITY_LIMIT := 100
const AD_DAILY_LIMIT := 3
const MAX_LEVEL := 10
const EXP_PER_SUMMON := 1
# Common through Divine. Each row sums to 10000; both banners use the same
# progression table so equipment and skills follow the same rarity ladder.
const RARITY_WEIGHTS := [
	[7400, 2000, 500, 90, 10, 0, 0, 0],
	[7000, 2250, 620, 115, 14, 1, 0, 0],
	[6600, 2450, 740, 180, 28, 2, 0, 0],
	[6200, 2650, 850, 245, 50, 5, 0, 0],
	[5800, 2800, 990, 330, 70, 10, 0, 0],
	[5400, 2950, 1100, 430, 100, 18, 2, 0],
	[5000, 3050, 1250, 540, 130, 26, 4, 0],
	[4600, 3150, 1390, 650, 165, 38, 7, 0],
	[4200, 3250, 1510, 780, 205, 45, 9, 1],
	[3800, 3300, 1650, 900, 270, 65, 13, 2]
]
const ARTIFACT_WEIGHTS := [
	[0, 0, 9500, 499, 1, 0, 0, 0],
	[0, 0, 9350, 648, 2, 0, 0, 0],
	[0, 0, 9200, 795, 5, 0, 0, 0],
	[0, 0, 9000, 990, 10, 0, 0, 0],
	[0, 0, 8800, 1180, 19, 1, 0, 0],
	[0, 0, 8550, 1415, 32, 3, 0, 0],
	[0, 0, 8300, 1650, 45, 5, 0, 0],
	[0, 0, 8050, 1875, 66, 8, 1, 0],
	[0, 0, 7800, 2080, 105, 14, 1, 0],
	[0, 0, 7600, 2200, 180, 18, 2, 0]
]

static func new_banner() -> Dictionary:
	return {"level": 1, "exp": 0, "pity": 0, "free_day": "", "ad_day": "", "ad_count": 0}

static func exp_to_next(level: int) -> int:
	return 10 * level

static func rarity_weights(level: int, banner: String = "equipment") -> Array:
	var table := ARTIFACT_WEIGHTS if banner == "artifacts" else RARITY_WEIGHTS
	return table[clampi(level, 1, MAX_LEVEL) - 1]

static func roll_rarity(level: int, banner: String = "equipment") -> int:
	var roll := randi_range(0, 9999)
	var total := 0
	var weights := rarity_weights(level, banner)
	for rarity in weights.size():
		total += int(weights[rarity])
		if roll < total:
			return rarity
	return 0
