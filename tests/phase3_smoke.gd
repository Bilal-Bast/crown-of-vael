extends SceneTree

const TEST_SAVE := "res://.godot/phase3_smoke.save"
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var old := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	old.store_string(JSON.stringify({"stage": 3, "gold": 500, "level": 1, "exp": 29, "upgrades": {"atk": 2}}))
	old.close()
	var profile := SaveData.load_from(TEST_SAVE)
	_assert(profile.stage == 3 and profile.inventory.size() == 7 and profile.gems == 0 and profile.first_clears == [1, 2], "Phase 2 migration")
	var sword: Dictionary = {}
	for item in profile.inventory:
		if item["kind"] == "rusted_sword":
			sword = item
	_assert(not sword.is_empty(), "Starter sword")
	var base_atk := float(GameData.hero_stats(profile.level, profile.upgrades)["atk"])
	_assert(profile.equip(str(sword["id"])), "Equip")
	_assert(not profile.equip("missing-id"), "Invalid equip rejected")
	var equipped_atk := float(GameData.hero_stats(profile.level, profile.upgrades, profile.gear_stats())["atk"])
	_assert(equipped_atk > base_atk, "Equipped ATK")
	var battle := BattleController.new()
	root.add_child(battle)
	battle.start(profile)
	_assert(float(battle.hero["atk"]) == equipped_atk, "Live battle ATK")
	profile.enhancement_stones = 20
	_assert(profile.upgrade_item(str(sword["id"])), "Enhancement")
	battle.refresh_hero_stats()
	_assert(float(battle.hero["atk"]) > equipped_atk, "Live enhanced ATK")
	for item in profile.inventory:
		profile.equip(str(item["id"]))
	battle.refresh_hero_stats()
	var naked := GameData.hero_stats(profile.level, profile.upgrades)
	for stat in ["hp", "atk", "armor", "speed", "crit_chance", "crit_damage"]:
		_assert(float(battle.hero[stat]) > float(naked[stat]), "Live equipped %s" % stat)
	var speed_before := float(battle.hero["speed"])
	_assert(profile.unequip("Boots"), "Unequip")
	battle.refresh_hero_stats()
	_assert(float(battle.hero["speed"]) < speed_before, "Live unequip speed")
	var hp_before_level := float(battle.hero["hp"])
	_assert(profile.add_rewards(0, 1) and profile.level == 2, "Squire level-up")
	battle.refresh_hero_stats()
	_assert(float(battle.hero["hp"]) > hp_before_level, "Hero level increases live base HP")
	_assert(profile.add_rewards(0, 210) and profile.level == 5 and profile.gems == 2, "Increasing EXP and milestone Gems")
	_assert(profile.record_stage_clear(3) == 1 and profile.record_stage_clear(3) == 0, "First clear Gems")
	_assert(profile.record_stage_clear(10) == 5, "Boss Gems")
	for i in 5:
		profile.inventory.append(EquipmentData.create_item("rusted_sword", 0))
	_assert(profile.merge_count("rusted_sword", 0) >= 1, "Merge availability")
	var before := profile.inventory.size()
	var merged := profile.merge_items("rusted_sword", 0)
	_assert(int(merged.get("rarity", -1)) == 1 and profile.inventory.size() == before - 4, "Five-item merge")
	_assert(profile.merge_items("iron_ring", 0).is_empty(), "Invalid merge")
	var future_hero := SaveData.new()
	future_hero.level = 100
	future_hero.evolution_crests = 100
	_assert(not future_hero.can_evolve() and not future_hero.evolve() and future_hero.evolution == 0, "Future evolution remains locked")
	seed(12345)
	var boss_drops := 0
	var higher_stage_uncommon := 0
	for i in 100:
		if not EquipmentData.roll_drop(10, true).is_empty():
			boss_drops += 1
	for i in 1000:
		var drop := EquipmentData.roll_drop(9, false)
		if not drop.is_empty() and int(drop["rarity"]) >= 1:
			higher_stage_uncommon += 1
	_assert(boss_drops > 50 and higher_stage_uncommon > 3, "Boss and higher-stage drops")
	var restored := SaveData.load_from(TEST_SAVE)
	_assert(restored.level == 5 and restored.gems == 8 and restored.enhancement_stones > 0, "Saved progression")
	_assert(restored.get_item(str(merged["id"]))["rarity"] == 1, "Saved inventory")
	_assert(restored.equipped.get("Weapon", "") == sword["id"] and restored.get_item(str(sword["id"]))["level"] == 2, "Saved equipped ID and item level")
	if not failed:
		print("PASS: migration, live gear, Squire level, first-clear Gems, enhancement, merge, save/load")
	quit(1 if failed else 0)

func _assert(valid: bool, name: String) -> void:
	if not valid:
		failed = true
		push_error("FAIL: %s" % name)
