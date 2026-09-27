class_name SaveData
extends RefCounted

const SAVE_PATH := "user://crown_of_vael.save"

var stage := 1
var gold := 0
var gems := 0
var exp := 0
var level := 1
var upgrades := {"hp": 0, "atk": 0, "armor": 0}
var boss_retry_required := false
var campaign_complete := false
var save_path := SAVE_PATH

static func load_profile() -> SaveData:
	var profile := SaveData.new()
	if not FileAccess.file_exists(SAVE_PATH):
		return profile
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return profile
	var value: Variant = JSON.parse_string(file.get_as_text())
	if not value is Dictionary:
		return profile
	var data: Dictionary = value
	profile.stage = clampi(int(data.get("stage", 1)), 1, GameData.MAX_STAGE)
	profile.gold = maxi(0, int(data.get("gold", 0)))
	profile.gems = maxi(0, int(data.get("gems", 0)))
	profile.exp = maxi(0, int(data.get("exp", 0)))
	profile.level = maxi(1, int(data.get("level", 1)))
	profile.boss_retry_required = bool(data.get("boss_retry_required", false))
	profile.campaign_complete = bool(data.get("campaign_complete", false))
	var saved_upgrades: Variant = data.get("upgrades", {})
	if saved_upgrades is Dictionary:
		for key in profile.upgrades:
			profile.upgrades[key] = clampi(int(saved_upgrades.get(key, 0)), 0, 999)
	return profile

func save() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save profile: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify({
		"stage": stage,
		"gold": gold,
		"gems": gems,
		"exp": exp,
		"level": level,
		"upgrades": upgrades,
		"boss_retry_required": boss_retry_required,
		"campaign_complete": campaign_complete
	}))

func add_rewards(reward_gold: int, reward_exp: int) -> bool:
	gold += reward_gold
	exp += reward_exp
	var leveled_up := false
	while exp >= GameData.exp_to_next(level):
		exp -= GameData.exp_to_next(level)
		level += 1
		leveled_up = true
	save()
	return leveled_up

func buy_upgrade(stat: String) -> bool:
	if not upgrades.has(stat):
		return false
	var cost := GameData.upgrade_cost(int(upgrades[stat]))
	if gold < cost:
		return false
	gold -= cost
	upgrades[stat] = int(upgrades[stat]) + 1
	save()
	return true
