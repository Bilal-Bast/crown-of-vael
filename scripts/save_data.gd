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
var enhancement_stones := 0
var evolution := 0
var selected_hero_id := "knight"
var heroes := {}
var hero_milestones: Array[String] = []
var evolution_crests := 0
var hero_pieces := 0
var dungeon_attempts := {}
var unlocked_dungeon_tier := 1
var tower_highest := 0
var tower_first_clears: Array[int] = []
var boss_rush_state := {"day": "", "remaining": 2, "best_boss": 0, "full_clear": false}
var endless_state := {"day": "", "reward_remaining": 2, "best_wave": 0}
var artifact_slot3_unlocked := false
var first_clears: Array[int] = []
var milestones: Array[String] = []
var inventory: Array[Dictionary] = []
var equipped := {}
var banners := {"equipment": SummonData.new_banner(), "skills": SummonData.new_banner(), "companions": SummonData.new_banner(), "artifacts": SummonData.new_banner()}
var skills := {"shield_bash": {"level": 1, "duplicates": 0, "rarity": 0}}
var equipped_skill_slots: Array[String] = ["shield_bash", "", "", ""]
var companion_essence := 0
var companion_crests := 0
var companions := {}
var equipped_companion_slots: Array[String] = ["", "", "", ""]
var artifact_dust := 0
var artifacts := {}
var equipped_artifact_slots: Array[String] = ["", "", "", "", "", ""]
var save_path := SAVE_PATH

func _init() -> void:
	for id in HeroData.HEROES:
		heroes[id] = HeroData.starter_record(id)

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
	profile.heroes["knight"]["evolution"] = profile.evolution
	var saved_heroes: Variant = data.get("heroes", {})
	if saved_heroes is Dictionary:
		for id in HeroData.HEROES:
			var raw: Variant = saved_heroes.get(id, {})
			if raw is Dictionary:
				profile.heroes[id] = {"unlocked": true if id == "knight" else bool(raw.get("unlocked", false)), "pieces": maxi(0, int(raw.get("pieces", 0))), "stars": clampi(int(raw.get("stars", 1)), 1, HeroData.MAX_STARS), "evolution": clampi(int(raw.get("evolution", profile.evolution if id == "knight" else 0)), 0, 4)}
	profile.evolution = int(profile.heroes["knight"]["evolution"])
	var requested_hero := str(data.get("selected_hero_id", "knight"))
	if profile.heroes.has(requested_hero) and bool(profile.heroes[requested_hero]["unlocked"]):
		profile.selected_hero_id = requested_hero
	for key in data.get("hero_milestones", []):
		if HeroData.MILESTONES.has(str(key)) and not profile.hero_milestones.has(str(key)):
			profile.hero_milestones.append(str(key))
	profile.evolution_crests = maxi(0, int(data.get("evolution_crests", 0)))
	profile.hero_pieces = maxi(0, int(data.get("hero_pieces", 0)))
	profile.unlocked_dungeon_tier = clampi(int(data.get("unlocked_dungeon_tier", 1)), 1, 5)
	profile.tower_highest = maxi(0, int(data.get("tower_highest", 0)))
	profile.artifact_slot3_unlocked = profile.tower_highest >= 20 or bool(data.get("artifact_slot3_unlocked", false))
	for raw_floor in data.get("tower_first_clears", []):
		var floor := int(raw_floor)
		if floor > 0 and not profile.tower_first_clears.has(floor):
			profile.tower_first_clears.append(floor)
	if not data.has("tower_first_clears"):
		for floor in range(1, profile.tower_highest + 1):
			profile.tower_first_clears.append(floor)
	var raw_dungeons: Variant = data.get("dungeon_attempts", {})
	for id in PveData.DUNGEONS:
		var raw: Dictionary = raw_dungeons.get(id, {}) if raw_dungeons is Dictionary else {}
		profile.dungeon_attempts[id] = {"day": str(raw.get("day", "")), "remaining": clampi(int(raw.get("remaining", 2)), 0, 2)}
	var raw_boss: Variant = data.get("boss_rush_state", {})
	if raw_boss is Dictionary:
		profile.boss_rush_state = {"day": str(raw_boss.get("day", "")), "remaining": clampi(int(raw_boss.get("remaining", 2)), 0, 2), "best_boss": clampi(int(raw_boss.get("best_boss", 0)), 0, 5), "full_clear": bool(raw_boss.get("full_clear", false))}
	var raw_endless: Variant = data.get("endless_state", {})
	if raw_endless is Dictionary:
		profile.endless_state = {"day": str(raw_endless.get("day", "")), "reward_remaining": clampi(int(raw_endless.get("reward_remaining", 2)), 0, 2), "best_wave": maxi(0, int(raw_endless.get("best_wave", 0)))}
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
	profile.companion_essence = maxi(0, int(data.get("companion_essence", 0)))
	profile.companion_crests = maxi(0, int(data.get("companion_crests", 0)))
	var saved_companions: Variant = data.get("companions", {})
	if saved_companions is Dictionary:
		for id in saved_companions:
			var raw: Variant = saved_companions[id]
			if CompanionData.COMPANIONS.has(str(id)) and raw is Dictionary:
				profile.companions[str(id)] = {"rarity": clampi(int(raw.get("rarity", 0)), 0, 7), "level": clampi(int(raw.get("level", 1)), 1, 99), "stars": clampi(int(raw.get("stars", 1)), 1, CompanionData.MAX_STARS), "pieces": maxi(0, int(raw.get("pieces", 0))), "evolution": clampi(int(raw.get("evolution", 0)), 0, 3 if str(id) == "wolf" else 0)}
	var raw_companion_slots: Variant = data.get("equipped_companion_slots", [])
	if raw_companion_slots is Array:
		var clean_companions: Array[String] = ["", "", "", ""]
		var used_companions := {}
		for index in mini(4, raw_companion_slots.size()):
			var id := str(raw_companion_slots[index])
			if profile.companions.has(id) and not used_companions.has(id):
				clean_companions[index] = id
				used_companions[id] = true
		profile.equipped_companion_slots = clean_companions
	profile.artifact_dust = maxi(0, int(data.get("artifact_dust", 0)))
	var saved_artifacts: Variant = data.get("artifacts", {})
	if saved_artifacts is Dictionary:
		for id in saved_artifacts:
			var raw: Variant = saved_artifacts[id]
			if ArtifactData.ARTIFACTS.has(str(id)) and raw is Dictionary:
				profile.artifacts[str(id)] = {"rarity": clampi(int(raw.get("rarity", 2)), 2, 7), "level": clampi(int(raw.get("level", 1)), 1, 99), "duplicates": maxi(0, int(raw.get("duplicates", 0)))}
	var raw_artifact_slots: Variant = data.get("equipped_artifact_slots", [])
	if raw_artifact_slots is Array:
		var clean_artifacts: Array[String] = ["", "", "", "", "", ""]
		var used_artifacts := {}
		for index in mini(profile.artifact_slot_limit(), raw_artifact_slots.size()):
			var id := str(raw_artifact_slots[index])
			if profile.artifacts.has(id) and not used_artifacts.has(id):
				clean_artifacts[index] = id
				used_artifacts[id] = true
		profile.equipped_artifact_slots = clean_artifacts
	return profile

func save() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save profile: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify({
		"phase4_version": 1, "phase5_version": 1, "phase6_version": 1, "phase7_version": 1,
		"stage": stage,
		"gold": gold,
		"gems": gems,
		"exp": exp,
		"level": level,
		"upgrades": upgrades,
		"boss_retry_required": boss_retry_required,
		"campaign_complete": campaign_complete,
		"enhancement_stones": enhancement_stones, "evolution": evolution,
		"selected_hero_id": selected_hero_id, "heroes": heroes, "hero_milestones": hero_milestones,
		"evolution_crests": evolution_crests, "hero_pieces": hero_pieces,
		"dungeon_attempts": dungeon_attempts, "unlocked_dungeon_tier": unlocked_dungeon_tier,
		"tower_highest": tower_highest, "tower_first_clears": tower_first_clears,
		"boss_rush_state": boss_rush_state, "endless_state": endless_state,
		"artifact_slot3_unlocked": artifact_slot3_unlocked, "first_clears": first_clears,
		"milestones": milestones, "inventory": inventory, "equipped": equipped,
		"banners": banners, "skills": skills, "equipped_skill_slots": equipped_skill_slots,
		"companion_essence": companion_essence, "companion_crests": companion_crests,
		"companions": companions, "equipped_companion_slots": equipped_companion_slots,
		"artifact_dust": artifact_dust, "artifacts": artifacts, "equipped_artifact_slots": equipped_artifact_slots
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

func add_companion_copy(id: String, rarity: int) -> void:
	if not CompanionData.COMPANIONS.has(id):
		return
	if not companions.has(id):
		companions[id] = {"rarity": clampi(rarity, 0, 7), "level": 1, "stars": 1, "pieces": 0, "evolution": 0}
		return
	var record: Dictionary = companions[id]
	record["rarity"] = maxi(int(record["rarity"]), rarity)
	record["pieces"] = int(record["pieces"]) + 1

func equip_companion(id: String, slot: int) -> bool:
	if not companions.has(id) or slot < 0 or slot >= 4:
		return false
	for index in 4:
		if equipped_companion_slots[index] == id:
			equipped_companion_slots[index] = ""
	equipped_companion_slots[slot] = id
	save()
	return true

func unequip_companion(slot: int) -> bool:
	if slot < 0 or slot >= 4 or equipped_companion_slots[slot] == "":
		return false
	equipped_companion_slots[slot] = ""
	save()
	return true

func level_companion(id: String) -> bool:
	if not companions.has(id):
		return false
	var record: Dictionary = companions[id]
	if int(record["level"]) >= 99:
		return false
	var cost := CompanionData.level_cost(int(record["level"]))
	if gold < int(cost["gold"]) or companion_essence < int(cost["essence"]):
		return false
	gold -= int(cost["gold"])
	companion_essence -= int(cost["essence"])
	record["level"] = int(record["level"]) + 1
	save()
	return true

func star_companion(id: String) -> bool:
	if not companions.has(id):
		return false
	var record: Dictionary = companions[id]
	if int(record["stars"]) >= CompanionData.MAX_STARS:
		return false
	var cost := CompanionData.star_cost(int(record["stars"]))
	if int(record["pieces"]) < cost:
		return false
	record["pieces"] = int(record["pieces"]) - cost
	record["stars"] = int(record["stars"]) + 1
	save()
	return true

func evolve_companion(id: String) -> bool:
	if id != "wolf" or not companions.has(id):
		return false
	var record: Dictionary = companions[id]
	var stage := int(record["evolution"])
	if stage >= CompanionData.WOLF_EVOLUTION.size():
		return false
	var cost: Dictionary = CompanionData.WOLF_EVOLUTION[stage]
	if int(record["level"]) < int(cost["level"]) or int(record["stars"]) < int(cost["stars"]) or companion_essence < int(cost["essence"]) or companion_crests < int(cost["crests"]):
		return false
	companion_essence -= int(cost["essence"])
	companion_crests -= int(cost["crests"])
	record["evolution"] = stage + 1
	save()
	return true

func add_artifact_copy(id: String, rarity: int) -> void:
	if not ArtifactData.ARTIFACTS.has(id):
		return
	if not artifacts.has(id):
		artifacts[id] = {"rarity": clampi(rarity, 2, 7), "level": 1, "duplicates": 0}
		return
	var record: Dictionary = artifacts[id]
	record["rarity"] = maxi(int(record["rarity"]), rarity)
	record["duplicates"] = int(record["duplicates"]) + 1

func equip_artifact(id: String, slot: int) -> bool:
	if not artifacts.has(id) or slot < 0 or slot >= artifact_slot_limit():
		return false
	for index in artifact_slot_limit():
		if equipped_artifact_slots[index] == id:
			equipped_artifact_slots[index] = ""
	equipped_artifact_slots[slot] = id
	save()
	return true

func unequip_artifact(slot: int) -> bool:
	if slot < 0 or slot >= artifact_slot_limit() or equipped_artifact_slots[slot] == "":
		return false
	equipped_artifact_slots[slot] = ""
	save()
	return true

func artifact_slot_limit() -> int:
	return 3 if artifact_slot3_unlocked or tower_highest >= 20 else 2

func level_artifact(id: String) -> bool:
	if not artifacts.has(id):
		return false
	var record: Dictionary = artifacts[id]
	if int(record["level"]) >= 99:
		return false
	var cost := ArtifactData.level_cost(int(record["level"]))
	if gold < int(cost["gold"]) or artifact_dust < int(cost["dust"]) or int(record["duplicates"]) < int(cost["copies"]):
		return false
	gold -= int(cost["gold"])
	artifact_dust -= int(cost["dust"])
	record["duplicates"] = int(record["duplicates"]) - int(cost["copies"])
	record["level"] = int(record["level"]) + 1
	save()
	return true

func combat_bonuses() -> Dictionary:
	var total := gear_stats()
	for id in equipped_companion_slots:
		if id == "" or not companions.has(id):
			continue
		var stat := str(CompanionData.COMPANIONS[id]["passive"])
		total[stat] = float(total.get(stat, 0.0)) + CompanionData.passive_value(id, companions[id])
	for source in [ArtifactData.owned_stats(artifacts), ArtifactData.equipped_stats(artifacts, equipped_artifact_slots)]:
		for stat in source:
			total[stat] = float(total.get(stat, 0.0)) + float(source[stat])
	return total

func hero_stats() -> Dictionary:
	return HeroData.apply_stats(GameData.hero_stats(level, upgrades, combat_bonuses()), self)

func power() -> int:
	var live_stats := hero_stats()
	var result := GameData.hero_power(live_stats)
	for id in equipped_companion_slots:
		if id != "" and companions.has(id):
			result += roundi(CompanionData.attack(id, companions[id]) * CompanionData.attack_speed(id, companions[id]) * 3.0 * (1.0 + float(live_stats.get("companion_damage", 0.0))))
	for id in equipped_artifact_slots:
		if id != "" and artifacts.has(id):
			result += maxi(1, roundi(ArtifactData.effect_value(id, artifacts[id]) * 20.0))
	return result

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
	return HeroProgress.new(self).can_evolve("knight")

func evolve() -> bool:
	return not HeroProgress.new(self).evolve("knight").is_empty()

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
