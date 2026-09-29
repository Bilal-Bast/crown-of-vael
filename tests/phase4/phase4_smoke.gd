extends SceneTree

const TEST_SAVE := "res://.godot/phase4_smoke.save"
var failed := false
var casts: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var old := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	old.store_string(JSON.stringify({"stage": 4, "gold": 250, "gems": 11, "level": 5, "exp": 9, "enhancement_stones": 3, "first_clears": [1, 2, 3]}))
	old.close()
	var profile := SaveData.load_from(TEST_SAVE)
	_assert(profile.stage == 4 and profile.level == 5 and profile.exp == 9 and profile.gems == 11 and profile.inventory.size() == 7, "Phase 3 migration preserves progression")
	_assert(profile.skills.has("shield_bash") and profile.equipped_skill_slots[0] == "shield_bash" and profile.banners["equipment"]["level"] == 1, "Shield Bash and banners migrate")
	var service := SummonService.new(profile)
	_assert(not service.can_summon("equipment", 1) and service.summon("equipment", 1).is_empty(), "Insufficient Gems rejected")
	# Debug-only test funding; no grant control is present in gameplay.
	profile.gems = 20000
	seed(4821)
	var before := profile.inventory.size()
	_assert(service.summon("equipment", 1).size() == 1 and profile.gems == 19900, "1x cost")
	_assert(service.summon("equipment", 10).size() == 10 and profile.gems == 19000, "10x cost")
	_assert(service.summon("equipment", 50).size() == 50 and profile.gems == 14750, "50x cost")
	_assert(profile.inventory.size() == before + 61 and int(profile.banners["equipment"]["level"]) > 1, "Summons enter inventory and raise banner level")
	var slots := {}
	var families := {}
	for item in profile.inventory.slice(before):
		slots[EquipmentData.ITEMS[item["kind"]]["slot"]] = true
		families[str(item["kind"]).split("_")[0]] = true
	_assert(slots.size() == 7 and families.size() >= 3, "Expanded equipment pool covers seven slots and families")
	var day := "2026-09-28"
	_assert(service.summon("equipment", 1, "daily", day).size() == 1 and service.summon("equipment", 1, "daily", day).is_empty(), "Equipment daily free limit")
	_assert(service.summon("skills", 1, "daily", day).size() == 1 and service.summon("skills", 1, "daily", day).is_empty(), "Skill free summon independent")
	_assert(service.summon("equipment", 1, "daily", "2026-09-29").size() == 1, "Daily reset by local day")
	for i in SummonData.AD_DAILY_LIMIT:
		_assert(service.summon("equipment", 1, "ad", day).size() == 1, "Simulated rewarded ad %d" % i)
	_assert(service.summon("equipment", 1, "ad", day).is_empty() and service.summon("skills", 1, "ad", day).size() == 1, "Ad cap independent per banner")
	profile.banners["equipment"]["pity"] = 99
	var pity_reward := service.summon("equipment", 1, "daily", "2026-09-30")
	_assert(pity_reward.size() == 1 and int(pity_reward[0]["rarity"]) >= 4 and int(profile.banners["equipment"]["pity"]) == 0, "100th pull guarantees Legendary and resets pity")
	_assert(int(profile.banners["skills"]["pity"]) > 0, "Skill pity independent")
	profile.banners["skills"]["pity"] = 99
	var skill_pity := service.summon("skills", 1, "daily", "2026-09-29")
	_assert(skill_pity.size() == 1 and int(skill_pity[0]["rarity"]) >= 4 and int(profile.banners["skills"]["pity"]) == 0, "Skill banner has independent Legendary pity")
	var skill_count := profile.skills.size()
	_assert(service.summon("skills", 10).size() == 10 and profile.skills.size() > skill_count, "Skill summons unlock skills")
	profile.add_skill_copy("power_strike", 1)
	profile.skills["power_strike"] = {"level": 1, "duplicates": 0, "rarity": 1}
	profile.add_skill_copy("power_strike", 1)
	profile.add_skill_copy("power_strike", 1)
	_assert(int(profile.skills["power_strike"]["level"]) == 2 and int(profile.skills["power_strike"]["duplicates"]) == 0, "Two duplicates raise skill to level 2")
	for i in 4:
		profile.add_skill_copy("power_strike", 1)
	_assert(int(profile.skills["power_strike"]["level"]) == 3 and SkillData.strength("power_strike", 3) > SkillData.strength("power_strike", 1), "Four more duplicates raise strength")
	for id in ["whirlwind_slash", "iron_guard", "healing_light", "battle_cry"]:
		profile.add_skill_copy(id, 2)
	_assert(profile.equip_skill("power_strike", 1) and profile.equip_skill("iron_guard", 2) and profile.equip_skill("healing_light", 3), "Four active slots equip")
	_assert(profile.equipped_skill_slots == ["shield_bash", "power_strike", "iron_guard", "healing_light"], "Four distinct equipped skills")
	_assert(profile.unequip_skill(1) and profile.equip_skill("whirlwind_slash", 1), "Skill unequip and area skill equip")
	var battle := BattleController.new()
	root.add_child(battle)
	profile.stage = 1
	profile.level = 10
	battle.skill_cast.connect(_on_skill_cast)
	battle.start(profile)
	_assert(absf(float(battle.skill_runtime.cooldowns["shield_bash"]) - 8.0) < 0.01, "Shield Bash uses skill data cooldown")
	for enemy in battle.enemies:
		enemy["current_hp"] = 100000.0
		enemy["atk"] = 0.0
	battle.hero_attack_time = 1000.0
	battle.hero_hp = float(battle.hero["hp"]) * 0.5
	for step in 290:
		battle._process(0.05)
	_assert(casts.has("shield_bash") and casts.has("iron_guard") and casts.has("healing_light") and casts.has("whirlwind_slash"), "Equipped effects auto-cast independently")
	_assert(battle.hero_hp > float(battle.hero["hp"]) * 0.5, "Healing effect works")
	for enemy in battle.enemies:
		enemy["current_hp"] = 100000.0
	_assert(battle.skill_runtime.cast("whirlwind_slash", battle), "Whirlwind cast")
	var all_hit := true
	for enemy in battle.enemies:
		all_hit = all_hit and float(enemy["current_hp"]) < 100000.0
	_assert(all_hit, "Whirlwind damages every living enemy")
	battle.skill_runtime.defense_time = 0.0
	battle.refresh_hero_stats()
	var armor_before_guard := float(battle.hero["armor"])
	_assert(battle.skill_runtime.cast("iron_guard", battle) and float(battle.hero["armor"]) > armor_before_guard, "Iron Guard raises Armor")
	var atk_before_cry := float(battle.hero["atk"])
	_assert(battle.skill_runtime.cast("battle_cry", battle) and float(battle.hero["atk"]) > atk_before_cry, "Temporary attack buff works")
	profile.save()
	var restored := SaveData.load_from(TEST_SAVE)
	_assert(restored.gems == profile.gems and restored.inventory.size() == profile.inventory.size() and restored.skills.size() == profile.skills.size(), "Summon inventory and skill save/load")
	_assert(restored.banners == profile.banners and restored.equipped_skill_slots == profile.equipped_skill_slots, "Banner, daily, ad, pity, and skill slots persist")
	if not failed:
		print("PASS: Phase 3 migration, summon costs/types, daily/ad, banner levels, pity, equipment, skills, auto-cast, save/load")
	quit(1 if failed else 0)

func _on_skill_cast(id: String, _slot: int) -> void:
	casts.append(id)

func _assert(valid: bool, name: String) -> void:
	if not valid:
		failed = true
		push_error("FAIL: %s" % name)
