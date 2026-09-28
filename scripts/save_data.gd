class_name SaveData
extends RefCounted

const SAVE_PATH := "user://crown_of_vael.save"
const EVOLUTION_RELEASED := false

var stage := 1
var gold := 0
var gems := 0
var exp := 0
var level := 1
var upgrades := {"hp": 0, "atk": 0, "armor": 0}
var boss_retry_required := false
var campaign_complete := false
var enhancement_stones := 0
var evolution := 0
var evolution_crests := 0
var first_clears: Array[int] = []
var milestones: Array[String] = []
var inventory: Array[Dictionary] = []
var equipped := {}
var banners := {"equipment": SummonData.new_banner(), "skills": SummonData.new_banner()}
var skills := {"shield_bash": {"level": 1, "duplicates": 0, "rarity": 0}}
var equipped_skill_slots: Array[String] = ["shield_bash", "", "", ""]
var save_path := SAVE_PATH

static func load_profile() -> SaveData:
	return load_from(SAVE_PATH)

static func load_from(path: String) -> SaveData:
	var profile := SaveData.new()
	profile.save_path = path
	if not FileAccess.file_exists(path):
		profile._grant_starters()
		return profile
	var file := FileAccess.open(path, FileAccess.READ)
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
	profile.enhancement_stones = maxi(0, int(data.get("enhancement_stones", 0)))
	profile.evolution = clampi(int(data.get("evolution", 0)), 0, GameData.EVOLUTION_PATH.size() - 1)
	profile.evolution_crests = maxi(0, int(data.get("evolution_crests", 0)))
	for value_stage in data.get("first_clears", []):
		var cleared := int(value_stage)
		if cleared >= 1 and cleared <= GameData.MAX_STAGE and not profile.first_clears.has(cleared):
			profile.first_clears.append(cleared)
	if not data.has("first_clears"):
		var historical_limit := GameData.MAX_STAGE + 1 if profile.campaign_complete else profile.stage
		for cleared in range(1, historical_limit):
			profile.first_clears.append(cleared)
	for key in data.get("milestones", []):
		if not profile.milestones.has(str(key)):
			profile.milestones.append(str(key))
	var seen := {}
	for raw_item in data.get("inventory", []):
		if not raw_item is Dictionary or not EquipmentData.ITEMS.has(str(raw_item.get("kind", ""))):
			continue
		var id := str(raw_item.get("id", ""))
		if id.is_empty() or seen.has(id):
			continue
		seen[id] = true
		profile.inventory.append({"id": id, "kind": str(raw_item["kind"]), "rarity": clampi(int(raw_item.get("rarity", 0)), 0, 7), "level": clampi(int(raw_item.get("level", 1)), 1, 99)})
	var saved_equipped: Variant = data.get("equipped", {})
	if saved_equipped is Dictionary:
		for slot in EquipmentData.SLOTS:
			var id := str(saved_equipped.get(slot, ""))
			if profile.get_item(id).get("kind", "") != "" and EquipmentData.ITEMS[profile.get_item(id)["kind"]]["slot"] == slot:
				profile.equipped[slot] = id
	if not data.has("inventory"):
		profile._grant_starters()
	var saved_upgrades: Variant = data.get("upgrades", {})
	if saved_upgrades is Dictionary:
		for key in profile.upgrades:
			profile.upgrades[key] = clampi(int(saved_upgrades.get(key, 0)), 0, 999)
	var saved_banners: Variant = data.get("banners", {})
	if saved_banners is Dictionary:
		for banner in SummonData.BANNERS:
			var raw: Variant = saved_banners.get(banner, {})
			if raw is Dictionary:
				profile.banners[banner] = {
					"level": clampi(int(raw.get("level", 1)), 1, SummonData.MAX_LEVEL),
					"exp": maxi(0, int(raw.get("exp", 0))),
					"pity": clampi(int(raw.get("pity", 0)), 0, SummonData.PITY_LIMIT - 1),
					"free_day": str(raw.get("free_day", "")),
					"ad_day": str(raw.get("ad_day", "")),
					"ad_count": clampi(int(raw.get("ad_count", 0)), 0, SummonData.AD_DAILY_LIMIT)
				}
	var saved_skills: Variant = data.get("skills", {})
	if saved_skills is Dictionary:
		for id in saved_skills:
			var raw: Variant = saved_skills[id]
			if SkillData.SKILLS.has(str(id)) and raw is Dictionary:
				profile.skills[str(id)] = {"level": clampi(int(raw.get("level", 1)), 1, 99), "duplicates": maxi(0, int(raw.get("duplicates", 0))), "rarity": clampi(int(raw.get("rarity", SkillData.SKILLS[id]["rarity"])), 0, 7)}
	var saved_slots: Variant = data.get("equipped_skill_slots", [])
	if int(data.get("phase4_version", 0)) >= 1 and data.has("equipped_skill_slots") and saved_slots is Array:
		var clean: Array[String] = ["", "", "", ""]
		var used := {}
		for index in mini(4, saved_slots.size()):
			var id := str(saved_slots[index])
			if profile.skills.has(id) and not used.has(id):
				clean[index] = id
				used[id] = true
		profile.equipped_skill_slots = clean
	return profile

func save() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save profile: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify({
		"phase4_version": 1,
		"stage": stage,
		"gold": gold,
		"gems": gems,
		"exp": exp,
		"level": level,
		"upgrades": upgrades,
		"boss_retry_required": boss_retry_required,
		"campaign_complete": campaign_complete,
		"enhancement_stones": enhancement_stones, "evolution": evolution,
		"evolution_crests": evolution_crests, "first_clears": first_clears,
		"milestones": milestones, "inventory": inventory, "equipped": equipped,
		"banners": banners, "skills": skills, "equipped_skill_slots": equipped_skill_slots
	}))

func add_skill_copy(id: String, rarity: int) -> void:
	if not SkillData.SKILLS.has(id):
		return
	if not skills.has(id):
		skills[id] = {"level": 1, "duplicates": 0, "rarity": clampi(rarity, 0, 7)}
		return
	var record: Dictionary = skills[id]
	record["rarity"] = maxi(int(record["rarity"]), rarity)
	record["duplicates"] = int(record["duplicates"]) + 1
	while int(record["level"]) < 99 and int(record["duplicates"]) >= SkillData.copies_to_level(int(record["level"])):
		record["duplicates"] = int(record["duplicates"]) - SkillData.copies_to_level(int(record["level"]))
		record["level"] = int(record["level"]) + 1

func equip_skill(id: String, slot: int) -> bool:
	if not skills.has(id) or slot < 0 or slot >= 4:
		return false
	for index in 4:
		if equipped_skill_slots[index] == id:
			equipped_skill_slots[index] = ""
	equipped_skill_slots[slot] = id
	save()
	return true

func unequip_skill(slot: int) -> bool:
	if slot < 0 or slot >= 4 or equipped_skill_slots[slot] == "":
		return false
	equipped_skill_slots[slot] = ""
	save()
	return true

func _grant_starters() -> void:
	for kind in EquipmentData.STARTER_KINDS:
		inventory.append(EquipmentData.create_item(kind))

func get_item(id: String) -> Dictionary:
	for item in inventory:
		if str(item["id"]) == id:
			return item
	return {}

func gear_stats() -> Dictionary:
	var result := {}
	for slot in EquipmentData.SLOTS:
		var item := get_item(str(equipped.get(slot, "")))
		var bonuses := EquipmentData.item_stats(item)
		for stat in bonuses:
			result[stat] = float(result.get(stat, 0.0)) + float(bonuses[stat])
	return result

func equip(id: String) -> bool:
	var item := get_item(id)
	if item.is_empty():
		return false
	equipped[EquipmentData.ITEMS[item["kind"]]["slot"]] = id
	save()
	return true

func unequip(slot: String) -> bool:
	if not equipped.has(slot):
		return false
	equipped.erase(slot)
	save()
	return true

func upgrade_item(id: String) -> bool:
	for item in inventory:
		if str(item["id"]) != id:
			continue
		var gold_cost := EquipmentData.upgrade_gold_cost(item)
		var stone_cost := EquipmentData.upgrade_stone_cost(item)
		if gold < gold_cost or enhancement_stones < stone_cost or int(item["level"]) >= 99:
			return false
		gold -= gold_cost
		enhancement_stones -= stone_cost
		item["level"] = int(item["level"]) + 1
		save()
		return true
	return false

func merge_count(kind: String, rarity: int, item_level: int = 1) -> int:
	var count := 0
	for item in inventory:
		if item["kind"] == kind and int(item["rarity"]) == rarity and int(item["level"]) == item_level:
			count += 1
	return count / 5 if rarity < 7 else 0

func merge_items(kind: String, rarity: int, item_level: int = 1) -> Dictionary:
	if merge_count(kind, rarity, item_level) < 1:
		return {}
	var consumed: Array[String] = []
	for item in inventory:
		if item["kind"] == kind and int(item["rarity"]) == rarity and int(item["level"]) == item_level:
			consumed.append(str(item["id"]))
			if consumed.size() == 5:
				break
	for id in consumed:
		for slot in equipped.keys():
			if equipped[slot] == id:
				equipped.erase(slot)
		for index in range(inventory.size() - 1, -1, -1):
			if inventory[index]["id"] == id:
				inventory.remove_at(index)
	var merged := EquipmentData.create_item(kind, rarity + 1)
	inventory.append(merged)
	save()
	return merged

func record_stage_clear(cleared_stage: int) -> int:
	if first_clears.has(cleared_stage):
		return 0
	first_clears.append(cleared_stage)
	var award := 5 if cleared_stage == 10 else 1
	gems += award
	enhancement_stones += 2 if cleared_stage == 10 else 1
	save()
	return award

func check_level_milestones() -> int:
	var award := 0
	for threshold in [5, 10, 20]:
		var key := "level_%d" % threshold
		if level >= threshold and not milestones.has(key):
			milestones.append(key)
			award += 2
	gems += award
	if award > 0:
		save()
	return award

func can_evolve() -> bool:
	# Phase 3 keeps the next forms visible while their acquisition is disabled.
	if not EVOLUTION_RELEASED or evolution >= GameData.EVOLUTION_PATH.size() - 1:
		return false
	var next_form: Dictionary = GameData.EVOLUTION_PATH[evolution + 1]
	return level >= int(next_form["level"]) and evolution_crests >= int(next_form["crests"])

func evolve() -> bool:
	if not can_evolve():
		return false
	var next_form: Dictionary = GameData.EVOLUTION_PATH[evolution + 1]
	evolution_crests -= int(next_form["crests"])
	evolution += 1
	save()
	return true

func add_rewards(reward_gold: int, reward_exp: int) -> bool:
	gold += reward_gold
	exp += reward_exp
	var leveled_up := false
	while exp >= GameData.exp_to_next(level):
		exp -= GameData.exp_to_next(level)
		level += 1
		leveled_up = true
	check_level_milestones()
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
