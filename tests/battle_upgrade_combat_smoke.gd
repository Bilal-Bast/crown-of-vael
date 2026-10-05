extends SceneTree

var failures := 0
var observed_hits: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := SaveData.new()
	profile.save_path = "res://.godot/battle_upgrade_combat_smoke.save"
	profile.upgrades["speed"] = 10
	profile.upgrades["crit_chance"] = 0
	profile.upgrades["crit_damage"] = 0
	var battle := BattleController.new()
	root.add_child(battle)
	battle.start(profile)
	_check(is_equal_approx(float(battle.hero["speed"]), 1.5), "Gold Attack Speed rank enters the live battle stat block")
	battle.hero_attack_time = 0.001
	battle._process(0.001)
	_check(is_equal_approx(battle.hero_attack_time, 1.0 / float(battle.hero["speed"])), "actual hero attack timer uses upgraded attacks-per-second")
	var target := CampaignData.enemy_stats("Goblin", 0, 1, 1, 1)
	target["hp"] = 1000000000.0
	target["current_hp"] = 1000000000.0
	target["armor"] = 0.0
	target["spawned"] = true
	target["combat_ready"] = true
	target["entry_time"] = 0.0
	battle.enemies = [target]
	battle.damage_popup.connect(_record_hit)
	profile.upgrades["crit_chance"] = 0
	profile.upgrades["crit_damage"] = 0
	battle.refresh_hero_stats()
	var base_chance := float(battle.hero["crit_chance"])
	var base_count := _crit_count_for_seed(battle, 240, 123456)
	profile.upgrades["crit_chance"] = GameData.PREMIUM_UPGRADE_MAX_RANK
	profile.upgrades["crit_damage"] = GameData.PREMIUM_UPGRADE_MAX_RANK
	battle.refresh_hero_stats()
	var upgraded_chance := float(battle.hero["crit_chance"])
	_check(upgraded_chance > base_chance and upgraded_chance <= 1.0, "Gold Crit Chance raises real battle probability and respects the 100% cap")
	var upgraded_count := _crit_count_for_seed(battle, 240, 123456)
	_check(upgraded_count > base_count, "upgraded Crit Chance produces more critical attacks with the same random sequence")
	var expected_crit_amount := roundi(float(battle.hero["atk"]) * float(battle.hero["crit_damage"]))
	var confirmed_crit_damage := false
	for hit in observed_hits:
		if bool(hit["critical"]):
			_check(int(hit["amount"]) == expected_crit_amount, "critical damage uses the upgraded final Crit Damage value")
			confirmed_crit_damage = true
			break
	_check(confirmed_crit_damage, "seeded combat sample includes an upgraded critical hit")
	_check(is_equal_approx(float(battle.hero["crit_damage"]), 2.75), "Crit Damage rank 100 contributes +100 percentage points in combat")
	battle.queue_free()
	print("BATTLE UPGRADE COMBAT SMOKE: %s (%d failures)" % ["FAIL" if failures else "PASS", failures])
	quit(1 if failures else 0)

func _crit_count_for_seed(battle: BattleController, count: int, seed_value: int) -> int:
	observed_hits.clear()
	seed(seed_value)
	for _i in count:
		battle._hero_attack()
	var critical_count := 0
	for hit in observed_hits:
		if bool(hit["critical"]):
			critical_count += 1
	return critical_count

func _record_hit(_target: int, amount: int, critical: bool, _bash: bool) -> void:
	observed_hits.append({"amount": amount, "critical": critical})

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("Battle upgrade combat smoke: " + description)
