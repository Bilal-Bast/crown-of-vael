class_name MonetizationData
extends RefCounted

const SEASON_ID := "season_1"
const SEASON_START := "2026-09-29"
const SEASON_END := "2026-10-29"
const MAX_LEVEL := 50
const DAILY_QUEST_XP := 40
const WEEKLY_QUEST_XP := 150
const SUBSCRIPTION_DAYS := 30
const AD_LIMITS := {"daily_bonus": 1, "gold_boost": 1}
const SUBSCRIBER_SKIP_AD := ["summon", "daily_bonus"]
const COSMETIC_CATEGORIES := ["Hero Skin", "Weapon Appearance", "Cape", "Profile Frame"]
const COSMETICS := {
	"royal_squire_cloak": {"name": "Royal Squire Cloak", "category": "Cape"},
	"golden_frame": {"name": "Golden Profile Frame", "category": "Profile Frame"},
	"crimson_sword": {"name": "Crimson Sword Appearance", "category": "Weapon Appearance"}
}
const PRODUCTS := {
	"starter_pack": {"type": "one_time", "name": "Starter Pack", "description": "A gentle beginning for your journey.", "price": "$1.99", "reward": {"gems": 500, "equipment_ticket": 10, "skills_ticket": 10, "companions_ticket": 10, "artifacts_ticket": 5, "gold": 20000, "enhancement_stones": 100}, "repeatable": false, "entitlement": "starter_pack_purchased"},
	"premium_pass": {"type": "one_time", "name": "Premium Battle Pass", "description": "Unlock the premium track for Season 1.", "price": "$4.99", "reward": {}, "repeatable": false, "entitlement": "premium_pass_owned"},
	"monthly_subscription": {"type": "subscription", "name": "Monthly Subscription", "description": "Daily value and convenient rewards for 30 days.", "price": "$4.99", "reward": {}, "repeatable": true, "entitlement": "subscription_active"},
	"gems_500": {"type": "consumable", "name": "500 Gems", "description": "500 Gems", "price": "$0.99", "reward": {"gems": 500}, "repeatable": true, "entitlement": ""},
	"gems_1200": {"type": "consumable", "name": "1,200 Gems", "description": "1,200 Gems", "price": "$1.99", "reward": {"gems": 1200}, "repeatable": true, "entitlement": ""},
	"gems_2500": {"type": "consumable", "name": "2,500 Gems", "description": "2,500 Gems", "price": "$3.99", "reward": {"gems": 2500}, "repeatable": true, "entitlement": ""},
	"gems_6500": {"type": "consumable", "name": "6,500 Gems", "description": "6,500 Gems", "price": "$9.99", "reward": {"gems": 6500}, "repeatable": true, "entitlement": ""}
}
const DAILY_OFFERS := [
	{"name": "Gold Satchel", "cost": 80, "reward": {"gold": 10000}},
	{"name": "Stone Cache", "cost": 100, "reward": {"enhancement_stones": 35}},
	{"name": "Essence Vial", "cost": 100, "reward": {"companion_essence": 30}},
	{"name": "Dust Pouch", "cost": 110, "reward": {"artifact_dust": 30}},
	{"name": "Equipment Tickets", "cost": 180, "reward": {"equipment_ticket": 3}}
]
const WEEKLY_OFFERS := [
	{"name": "Artifact Tickets", "cost": 900, "reward": {"artifacts_ticket": 10}},
	{"name": "Evolution Crest Cache", "cost": 700, "reward": {"evolution_crests": 5}},
	{"name": "Hero Piece Cache", "cost": 750, "reward": {"hero_pieces": 12}},
	{"name": "Companion Tickets", "cost": 800, "reward": {"companions_ticket": 10}},
	{"name": "Crafting Cache", "cost": 450, "reward": {"enhancement_stones": 100, "artifact_dust": 60}}
]

static func xp_for_level(level: int) -> int:
	return 80 + 10 * level

static func total_xp_for_level(level: int) -> int:
	var total := 0
	for index in range(1, clampi(level, 0, MAX_LEVEL) + 1): total += xp_for_level(index)
	return total

static func reward(level: int, premium: bool) -> Dictionary:
	if level == 50 and premium: return {"cosmetic": "royal_squire_cloak"}
	if premium:
		match level % 5:
			0: return {"gems": 100}
			1: return {"artifacts_ticket": 2}
			2: return {"hero_pieces": 3}
			3: return {"evolution_crests": 2}
			_: return {"enhancement_stones": 40, "companion_essence": 20}
	match level % 5:
		0: return {"gems": 40}
		1: return {"gold": 4000 + level * 200}
		2: return {"enhancement_stones": 20, "artifact_dust": 10}
		3: return {"equipment_ticket": 1}
		_: return {"hero_pieces": 1, "companion_essence": 10}
