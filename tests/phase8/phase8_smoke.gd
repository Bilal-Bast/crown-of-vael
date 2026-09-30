extends SceneTree

const PATH := "res://.godot/phase8_smoke.save"
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error("PHASE 8: " + label)

func _run() -> void:
	check(CampaignData.REGIONS.size() == 10 and CampaignData.DIFFICULTIES.size() == 6, "10 regions and 6 difficulties")
	check(CampaignData.STAGES_PER_REGION == 20 and CampaignData.REGIONS.size() * CampaignData.STAGES_PER_REGION == 200, "20 stages per region, 200 per difficulty")
	for region in range(1, 11):
		var info: Dictionary = CampaignData.REGIONS[region - 1]
		check(info["enemies"].size() == 6 and info["elites"].size() == 2, "region %d enemy pool" % region)
		check(CampaignData.wave_kinds(region, 20, 1) == [info["boss"]], "region %d boss" % region)
		for stage in [5, 10, 15]:
			var kinds := CampaignData.wave_kinds(region, stage, 3)
			check(kinds.size() == 7 and info["elites"].has(kinds[6]), "region %d stage %d elite" % [region, stage])
	for difficulty in range(1, 6):
		check(float(CampaignData.enemy_stats("Goblin", difficulty, 1, 1, 1)["hp"]) > float(CampaignData.enemy_stats("Goblin", difficulty - 1, 1, 1, 1)["hp"]), "HP difficulty scaling %d" % difficulty)
		check(float(CampaignData.enemy_stats("Goblin", difficulty, 1, 1, 1)["atk"]) > float(CampaignData.enemy_stats("Goblin", difficulty - 1, 1, 1, 1)["atk"]), "damage difficulty scaling %d" % difficulty)
	check(CampaignData.element_multiplier("Holy", "Dark") == 1.2 and CampaignData.element_multiplier("Fire", "Ice") == 1.2 and CampaignData.element_multiplier("Physical", "Dark") == 1.0, "element matchups")
	check(EquipmentData.campaign_rarity_weights(10, 5)[3] > EquipmentData.campaign_rarity_weights(1, 0)[3], "equipment rarity improves")
	var profile := SaveData.new()
	profile.save_path = PATH
	check(not profile.unlocked_region(0, 2) and profile.stage_state(0, 1, 2) == "locked", "initial map fog and stage lock")
	profile.record_stage_clear(1)
	check(profile.stage_state(0, 1, 1) == "cleared" and profile.stage_state(0, 1, 2) == "current", "stage states")
	var gems := profile.gems
	profile.record_stage_clear(1)
	check(profile.gems == gems, "no duplicate first clear")
	profile.region = 1
	profile.record_stage_clear(20)
	check(profile.unlocked_region(0, 2) and profile.region_rewards_claimed.has("0:1"), "region boss opens next region and claims reward")
	var highest := int(profile.highest_stages["0:1"])
	check(profile.select_campaign(0, 1, 1) and profile.selected_replay_stage == 1, "replay selection")
	profile.record_stage_clear(1)
	check(int(profile.highest_stages["0:1"]) == highest, "replay keeps highest progress")
	for difficulty in 6:
		profile.campaign_difficulty = difficulty
		profile.region = 10
		profile.stage = 20
		profile.record_stage_clear(20)
		check(profile.difficulty_completions.has(str(difficulty)), "difficulty completion %d" % difficulty)
		check(profile.highest_difficulty_unlocked == mini(5, difficulty + 1), "unlock order %d" % difficulty)
	profile.campaign_difficulty = 1
	profile.region = 1
	profile.stage = 1
	profile.save()
	var loaded := SaveData.load_from(PATH)
	check(loaded.campaign_difficulty == 1 and loaded.region == 1 and loaded.stage == 1 and loaded.highest_difficulty_unlocked == 5, "campaign save roundtrip")
	check(loaded.highest_stages.has("0:1") and loaded.campaign_first_clears.has("0:1:1") and loaded.region_rewards_claimed.has("0:1"), "records save roundtrip")
	var old := {"stage":10,"campaign_complete":true,"first_clears":[1,2,3,4,5,6,7,8,9,10],"gold":123,"gems":77,"level":9}
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	var migrated := SaveData.load_from(PATH)
	check(migrated.stage == 11 and migrated.region == 1 and migrated.campaign_difficulty == 0 and int(migrated.highest_stages["0:1"]) == 10, "Phase 7 1-10 migration continues at 1-11")
	check(migrated.gold == 123 and migrated.gems == 77 and migrated.level == 9 and not migrated.campaign_complete, "migration preserves resources without finishing region")
	file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"stage":4,"gold":23,"first_clears":[1,2,3]}))
	file.close()
	var old_four := SaveData.load_from(PATH)
	check(old_four.stage == 4 and int(old_four.highest_stages["0:1"]) == 3 and old_four.gold == 23, "Phase 7 1-4 stays at 1-4")
	var battle := BattleController.new()
	root.add_child(battle)
	battle.start(migrated)
	check(battle.enemies.size() == 7 and battle.boss_time == 30.0, "normal combat waves")
	battle.force_treasure = true
	battle._spawn_wave()
	check(str(battle.enemies[0]["archetype"]) == "TREASURE", "forced treasure spawn")
	battle.active = false
	migrated.stage = 20
	battle.start(migrated)
	check(battle.enemies.size() == 1 and battle.enemies[0]["kind"] == "Goblin Warlord", "region boss encounter")
	battle._process(30.1)
	check(not battle.active, "30 second boss timer")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	var ui_profile := main.get("profile") as SaveData
	ui_profile.save_path = PATH
	ui_profile.campaign_difficulty = 0
	ui_profile.highest_difficulty_unlocked = 0
	ui_profile.region = 1
	ui_profile.stage = 1
	ui_profile.world_map_region = 1
	ui_profile.highest_stages.clear()
	var ui_battle := main.get("battle") as BattleController
	ui_battle.active = false
	var adventure := main.get("adventure_screen") as AdventureScreen
	adventure.view = "map"
	adventure.refresh()
	var map_nodes := 0
	var fog_nodes := 0
	var hero_marker := false
	for child in adventure.get_children():
		if child is PanelContainer:
			map_nodes += 1
			var card_button := child.find_children("", "Button", true, false)
			if not card_button.is_empty() and card_button[0].disabled: fog_nodes += 1
			if "◆" in str(child.get_child(0).get_child(0).text): hero_marker = true
	check(map_nodes == 10 and fog_nodes == 9 and hero_marker, "world map nodes, fog, and hero marker")
	adventure.view = "stages"
	adventure.map_region = 1
	adventure.refresh()
	var stage_buttons := 0
	var boss_marker := false
	for child in adventure.find_children("", "Button", true, false):
		if "\n" in child.text:
			stage_buttons += 1
			if "20 BOSS" in child.text: boss_marker = true
	check(stage_buttons == 20 and boss_marker, "20 selectable stage nodes and boss marker")
	ui_profile.region = 1
	ui_profile.stage = 20
	ui_profile.campaign_difficulty = 0
	ui_battle.start(ui_profile)
	ui_battle.active = false
	main.call("_on_battle_lost", true)
	check(ui_profile.stage == 19 and ui_profile.boss_retry_required, "boss failure falls back one stage")
	main.call("_on_stage_cleared")
	check(ui_profile.stage == 20 and ui_profile.boss_retry_required and not ui_battle.active, "boss waits for manual retry after fallback clear")
	main.call("_on_action_pressed")
	check(ui_battle.active and ui_profile.stage == 20 and not ui_profile.boss_retry_required, "manual boss retry starts fight")
	ui_battle.active = false
	ui_profile.campaign_complete = false
	ui_profile.campaign_difficulty = 0
	ui_profile.region = 10
	ui_profile.stage = 20
	var retained_level := ui_profile.level
	var retained_inventory := ui_profile.inventory.size()
	main.call("_on_stage_cleared")
	check(ui_profile.campaign_difficulty == 1 and ui_profile.region == 1 and ui_profile.stage == 1, "Demon Lord clear starts Normal 1-1")
	check(ui_profile.level == retained_level and ui_profile.inventory.size() == retained_inventory, "difficulty restart retains hero and gear")
	print("PHASE 8 SMOKE: ", "FAIL (%d)" % failures if failures else "PASS")
	quit(1 if failures else 0)
