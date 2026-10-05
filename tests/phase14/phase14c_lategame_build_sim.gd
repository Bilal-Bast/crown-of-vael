extends SceneTree

## Build-aware validation uses the actual SaveData stat assembly and BattleController.
var incoming := 0.0
var outgoing := 0.0
var companion_damage := 0.0

const BUILDS := [
	{"name":"MODEST", "level":110, "evolution":3, "stars":2, "upgrades":{"hp":35,"atk":105,"armor":35}, "gear_family":"knight", "rarity":2, "enhance":2, "skill_level":1, "companions":[["archer_companion",5,1,1,0],["wolf",5,1,1,0]], "artifacts":[["blood_crown",1],["phoenix_feather",1]], "owned_heroes":[], "owned_artifacts":[]},
	{"name":"SOLID", "level":130, "evolution":3, "stars":3, "upgrades":{"hp":48,"atk":145,"armor":48}, "gear_family":"royal", "rarity":3, "enhance":6, "skill_level":2, "companions":[["archer_companion",10,2,2,0],["fairy",10,2,2,0],["wolf",10,2,2,1],["cleric_companion",8,1,1,0]], "artifacts":[["dragon_fang",1],["dragon_eye",1]], "owned_heroes":["mage"], "owned_artifacts":["hourglass_arkon","guardian_sigil"]},
	{"name":"STRONG", "level":155, "evolution":4, "stars":4, "upgrades":{"hp":60,"atk":185,"armor":60}, "gear_family":"mixed", "gear":[["sacred",4,10],["royal",3,8],["sacred",4,9],["sacred",4,9],["sacred",4,10],["sacred",4,9],["royal",3,8]], "skill_level":3, "companions":[["archer_companion",15,3,3,0],["wolf",20,3,4,3],["young_dragon",15,3,3,0],["cleric_companion",12,2,2,0]], "artifacts":[["dragon_fang",2],["dragon_eye",2]], "owned_heroes":["mage","ranger","assassin","necromancer"], "owned_artifacts":["blood_crown","dragon_heart","guardian_sigil","phoenix_feather","hourglass_arkon"]},
	{"name":"STRONG-SUSTAIN", "level":155, "evolution":4, "stars":4, "upgrades":{"hp":60,"atk":185,"armor":60}, "gear_family":"mixed", "gear":[["sacred",4,10],["royal",3,8],["sacred",4,9],["sacred",4,9],["sacred",4,10],["sacred",4,9],["royal",3,8]], "skill_level":3, "companions":[["archer_companion",15,3,3,0],["wolf",20,3,4,3],["young_dragon",15,3,3,0],["cleric_companion",12,2,2,0]], "artifacts":[["dragon_fang",2],["phoenix_feather",2]], "owned_heroes":["mage","ranger","assassin","necromancer"], "owned_artifacts":["blood_crown","dragon_heart","guardian_sigil","hourglass_arkon"]}
]
const GEAR_SLOTS := ["Weapon","Helmet","Armor","Gloves","Boots","Necklace","Ring"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	seed(1403)
	print("Phase 14C actual BattleController validation. Boss: Demon Lord, R10 S20. Build tiers are scenarios, not claims of measured player behavior.")
	for build in BUILDS:
		var profile := _make_profile(build)
		var stats := profile.hero_stats()
		var gear_summary := str(build["gear"]) if build.has("gear") else "%s rarity%d +%d" % [build["gear_family"], build["rarity"], build["enhance"]]
		print("BUILD %s: L%d %s %d-star; ATK %.0f HP %.0f ARM %.0f speed %.2f/s crit %.0f%% x%.2f boss+%.0f%%; gear=%s; skills lvl%d; companions=%s artifacts=%s" % [build["name"], profile.level, HeroData.title("knight", profile.heroes["knight"]), build["stars"], stats["atk"], stats["hp"], stats["armor"], stats["speed"], stats["crit_chance"] * 100.0, stats["crit_damage"], stats["boss_damage"] * 100.0, gear_summary, build["skill_level"], str(build["companions"].map(func(row): return row[0])), str(profile.equipped_artifact_slots.slice(0, 2))])
		for difficulty in [3,4,5]:
			var result := _simulate(profile, difficulty)
			var boss := CampaignData.enemy_stats(str(CampaignData.REGIONS[9]["boss"]), difficulty, 10, 20, 1)
			if difficulty == 5:
				var d4_boss := CampaignData.enemy_stats(str(CampaignData.REGIONS[9]["boss"]), 4, 10, 20, 1)
				assert(is_equal_approx(float(boss["hp"]), float(d4_boss["hp"]) * 2.5 * CampaignData.DEMON_LORD_INFERNAL_HP_SCALE), "Demon Lord index-5 HP adjustment is scoped to the intended boss")
			var required := float(boss["hp"]) / 30.0
			var dealt_dps := float(result["dealt"]) / maxf(0.01, float(result["time"]))
			var pressure := maxf(1.0, float(boss["atk"]) - float(stats["armor"])) * float(boss["speed"])
			print("  D%d bossHP %.0f armor %.1f requiredDPS %.0f actualDPS %.0f clearTime %.2fs outcome=%s bossHPleft=%.0f heroHP=%.0f/%.0f incoming=%.0f (%.0f/s) nominalPressure=%.0f/s companionDirect=%d timerLeft=%.1f" % [difficulty, boss["hp"], boss["armor"], required, dealt_dps, result["time"], "CLEAR" if result["won"] else ("SURVIVAL_LOSS" if result["died"] else "TIMER_LOSS"), result["boss_left"], result["hero_hp"], result["max_hp"], result["incoming"], float(result["incoming"]) / maxf(0.01, float(result["time"])), pressure, result["companion_damage"], result["timer_left"]])
			if build["name"] == "STRONG-SUSTAIN" and difficulty == 5:
				assert(result["won"], "strong sustain build should clear Demon Lord at difficulty index 5")
	quit()

func _make_profile(build: Dictionary) -> SaveData:
	var profile := SaveData.new()
	profile.save_path = "res://.godot/phase14c_build_validation.save"
	profile.level = int(build["level"])
	profile.upgrades = (build["upgrades"] as Dictionary).duplicate(true)
	profile.region = 10
	profile.stage = 20
	profile.campaign_difficulty = 3
	profile.evolution = int(build["evolution"])
	profile.heroes["knight"]["evolution"] = int(build["evolution"])
	profile.heroes["knight"]["stars"] = int(build["stars"])
	profile.heroes["knight"]["unlocked"] = true
	for owned_id in build["owned_heroes"]:
		profile.heroes[str(owned_id)]["unlocked"] = true
	profile.inventory.clear()
	var family := str(build["gear_family"])
	for index in GEAR_SLOTS.size():
		var slot: String = GEAR_SLOTS[index]
		var item_family := family
		var rarity := int(build.get("rarity", 0))
		var enhance := int(build.get("enhance", 1))
		if build.has("gear"):
			var gear_row: Array = build["gear"][index]
			item_family = str(gear_row[0])
			rarity = int(gear_row[1])
			enhance = int(gear_row[2])
		var kind := _gear_kind(item_family, slot)
		var item := EquipmentData.create_item(kind, rarity, "%s_%s" % [build["name"], slot])
		item["level"] = enhance
		profile.inventory.append(item)
		profile.equipped[slot] = str(item["id"])
	profile.equipped_skill_slots = ["shield_bash", "battle_cry", "iron_guard", "healing_light"]
	for skill_id in profile.equipped_skill_slots:
		profile.skills[skill_id] = {"level": int(build["skill_level"]), "duplicates": 0, "rarity": SkillData.SKILLS[skill_id]["rarity"]}
	profile.companion_essence = 999999
	profile.companion_crests = 999
	profile.equipped_companion_slots = ["", "", "", ""]
	for index in build["companions"].size():
		var row: Array = build["companions"][index]
		var id := str(row[0])
		profile.companions[id] = {"level":int(row[1]),"rarity":int(row[2]),"stars":int(row[3]),"evolution":int(row[4]),"pieces":0}
		profile.equipped_companion_slots[index] = id
	profile.artifacts.clear()
	profile.equipped_artifact_slots = ["", "", "", "", "", ""]
	for index in build["artifacts"].size():
		var row: Array = build["artifacts"][index]
		var id := str(row[0])
		profile.artifacts[id] = {"level":int(row[1]),"duplicates":0,"rarity":2}
		profile.equipped_artifact_slots[index] = id
	for id in build["owned_artifacts"]:
		var artifact_id := str(id)
		if ArtifactData.ARTIFACTS.has(artifact_id) and not profile.artifacts.has(artifact_id):
			profile.artifacts[artifact_id] = {"level":1,"duplicates":0,"rarity":2}
	return profile

func _gear_kind(family: String, slot: String) -> String:
	var suffix: String = {"Weapon":"sword","Helmet":"helm","Armor":"plate","Gloves":"gauntlets","Boots":"boots","Necklace":"amulet","Ring":"ring"}[slot]
	return "%s_%s" % [family, suffix]

func _simulate(profile: SaveData, difficulty: int) -> Dictionary:
	profile.campaign_difficulty = difficulty
	var battle := BattleController.new()
	incoming = 0.0
	outgoing = 0.0
	companion_damage = 0.0
	battle.damage_popup.connect(func(target: int, amount: int, _critical: bool, _bash: bool):
		if target < 0:
			incoming += amount
		else:
			outgoing += amount
	)
	battle.companion_attack.connect(func(_slot: int, _target: int, amount: int): companion_damage += amount)
	battle.start(profile)
	var start_hp := float(battle.hero["hp"])
	var max_hp := start_hp
	var max_time := 30.0
	while battle.active and battle.run_time < max_time:
		battle._process(1.0 / 60.0)
	var time := minf(max_time, battle.run_time)
	var boss_left := float(battle.enemies[0]["current_hp"]) if not battle.enemies.is_empty() else 0.0
	var won := not battle.active and boss_left <= 0.0
	var died := float(battle.hero_hp) <= 0.0
	var remaining := float(battle.hero_hp)
	var final_enemy_hp := boss_left
	var timer_left := maxf(0.0, 30.0 - time)
	battle.free()
	return {"time":time,"won":won,"died":died,"hero_hp":remaining,"max_hp":max_hp,"boss_left":final_enemy_hp,"incoming":incoming,"dealt":outgoing,"companion_damage":companion_damage,"timer_left":timer_left,"start_hp":start_hp}
