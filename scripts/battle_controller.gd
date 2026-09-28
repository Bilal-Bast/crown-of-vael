class_name BattleController
extends Node

signal changed
signal damage_popup(target_index: int, amount: int, critical: bool, bash: bool)
signal attack_started(attacker_index: int, target_index: int)
signal enemy_defeated(target_index: int, reward_gold: int, reward_exp: int)
signal equipment_dropped(item: Dictionary)
signal hero_leveled(level: int, gem_bonus: int)
signal skill_cast(id: String, slot: int)
signal companion_attack(slot: int, target: int, amount: int)
signal artifact_proc(label: String, color: Color)
signal message(text: String)
signal stage_cleared
signal battle_lost(boss_failure: bool)
signal mode_finished(result: Dictionary)

var profile: SaveData
var stage := 1
var wave := 1
var active := false
var hero: Dictionary = {}
var hero_hp := 0.0
var enemies: Array[Dictionary] = []
var boss_time := 30.0
var bash_time := 8.0
var hero_attack_time := 0.0
var skill_runtime := SkillRuntime.new()
var companion_runtime := CompanionRuntime.new()
var artifact_runtime := ArtifactRuntime.new()
var mode_config := {"mode": "campaign"}
var run_time := 0.0
var run_kills := 0
var run_damage := 0

func start(new_profile: SaveData) -> void:
	mode_config = {"mode": "campaign"}
	_start_shared(new_profile)
	message.emit("Goblin Warlord! Defeat him in 30 seconds." if stage == 10 else "%s | Wave 1/3" % GameData.stage_label(stage))
	changed.emit()

func start_mode(new_profile: SaveData, config: Dictionary) -> void:
	mode_config = config.duplicate(true)
	_start_shared(new_profile)
	message.emit("%s | %s" % [PveData.mode_label(config), mode_detail()])
	changed.emit()

func _start_shared(new_profile: SaveData) -> void:
	profile = new_profile
	stage = profile.stage
	wave = 1
	hero = profile.hero_stats()
	hero_hp = float(hero["hp"])
	boss_time = 30.0
	bash_time = 8.0
	hero_attack_time = 0.45
	run_time = 0.0
	run_kills = 0
	run_damage = 0
	active = true
	skill_runtime.start(profile)
	companion_runtime.start(profile)
	artifact_runtime.start()
	_spawn_wave()

func mode_detail() -> String:
	match str(mode_config.get("mode", "campaign")):
		"dungeon": return "Tier %d | Wave %d/3" % [int(mode_config["tier"]), wave]
		"tower": return "Floor %d" % int(mode_config["floor"])
		"boss_rush": return "Boss %d/5" % wave
		"endless": return "Wave %d" % wave
	return "Wave %d/3" % wave

func refresh_hero_stats() -> void:
	var old_max := float(hero.get("hp", 0.0))
	var old_hp := hero_hp
	hero = profile.hero_stats()
	skill_runtime.apply_buffs(hero)
	artifact_runtime.apply_buffs(hero)
	hero_hp = minf(float(hero["hp"]), old_hp + maxf(0.0, float(hero["hp"]) - old_max))
	changed.emit()

func _spawn_wave() -> void:
	enemies.clear()
	if str(mode_config.get("mode", "campaign")) != "campaign":
		for template in PveData.wave_enemies(mode_config, wave):
			var enemy := template.duplicate(true)
			enemy["current_hp"] = enemy["hp"]
			enemy["attack_time"] = 0.7 + randf_range(0.0, 0.5)
			enemy["stun_time"] = 0.0
			enemies.append(enemy)
		changed.emit()
		return

	var kinds: Array[String] = []

	if stage == 10:
		kinds = ["Goblin Warlord"]
	else:
		for kind in GameData.wave_kinds(stage, wave):
			kinds.append(str(kind))

	for kind in kinds:
		var enemy := GameData.enemy_stats(kind, stage)
		enemy["current_hp"] = enemy["hp"]
		enemy["attack_time"] = 0.7 + randf_range(0.0, 0.5)
		enemy["stun_time"] = 0.0
		enemies.append(enemy)

	changed.emit()

func _process(delta: float) -> void:
	if not active:
		return
	run_time += delta
	if str(mode_config.get("mode", "campaign")) == "campaign" and stage == 10:
		boss_time = maxf(0.0, boss_time - delta)
		if boss_time <= 0.0:
			_lose(true)
			return
	artifact_runtime.process(delta, self)
	skill_runtime.process(delta, self)
	companion_runtime.process(delta, self)
	bash_time = float(skill_runtime.cooldowns.get("shield_bash", 0.0))
	if not active:
		return
	hero_attack_time -= delta
	if hero_attack_time <= 0.0:
		hero_attack_time += 1.0 / float(hero["speed"])
		_hero_attack()
		if not active:
			return
	for i in enemies.size():
		var enemy := enemies[i]
		if float(enemy["current_hp"]) <= 0.0:
			continue
		enemy["stun_time"] = maxf(0.0, float(enemy["stun_time"]) - delta)
		if float(enemy["stun_time"]) > 0.0:
			continue
		enemy["attack_time"] = float(enemy["attack_time"]) - delta
		if float(enemy["attack_time"]) <= 0.0:
			enemy["attack_time"] = 1.0 / float(enemy["speed"])
			attack_started.emit(i, -1)
			var damage := maxi(1, roundi(float(enemy["atk"]) - float(hero["armor"])))
			hero_hp = maxf(0.0, hero_hp - damage)
			damage_popup.emit(-1, damage, false, false)
			if hero_hp <= 0.0 and not artifact_runtime.prevent_death(self):
				_lose(stage == 10 and str(mode_config.get("mode", "campaign")) == "campaign")
				return
	changed.emit()

func _hero_attack() -> void:
	for i in enemies.size():
		if float(enemies[i]["current_hp"]) > 0.0:
			attack_started.emit(-1, i)
			var critical := randf() < float(hero["crit_chance"])
			var amount := float(hero["atk"]) * (float(hero["crit_damage"]) if critical else 1.0)
			if stage == 10 and str(mode_config.get("mode", "campaign")) == "campaign":
				amount *= 1.0 + float(hero.get("boss_damage", 0.0))
			var dealt := mini(roundi(amount), ceili(float(enemies[i]["current_hp"])))
			_hit_enemy(i, roundi(amount), critical, false)
			artifact_runtime.on_hero_attack(self, i, dealt, critical)
			return

func _hit_enemy(index: int, amount: int, critical: bool, bash: bool) -> void:
	var enemy := enemies[index]
	if str(mode_config.get("mode", "campaign")) != "campaign":
		run_damage += mini(amount, ceili(float(enemy["current_hp"])))
	enemy["current_hp"] = maxf(0.0, float(enemy["current_hp"]) - amount)
	damage_popup.emit(index, amount, critical, bash)
	if float(enemy["current_hp"]) <= 0.0:
		enemy_defeated.emit(index, int(enemy["gold"]), int(enemy["exp"]))
		if str(mode_config.get("mode", "campaign")) != "campaign":
			run_kills += 1
			if _all_enemies_defeated():
				_advance_mode()
			changed.emit()
			return
		var gems_before := profile.gems
		var leveled_up := profile.add_rewards(int(enemy["gold"]), int(enemy["exp"]))
		var drop := EquipmentData.roll_drop(stage, stage == 10)
		if not drop.is_empty():
			profile.inventory.append(drop)
			profile.save()
			equipment_dropped.emit(drop)
		if leveled_up:
			refresh_hero_stats()
			hero_leveled.emit(profile.level, profile.gems - gems_before)
			message.emit("Level up! Squire is now level %d." % profile.level)
		if _all_enemies_defeated():
			if stage == 10 or wave >= GameData.WAVES_PER_STAGE:
				active = false
				stage_cleared.emit()
			else:
				wave += 1
				_spawn_wave()
				message.emit("Wave %d/%d" % [wave, GameData.WAVES_PER_STAGE])
	changed.emit()

func _advance_mode() -> void:
	var mode := str(mode_config["mode"])
	if mode == "tower" or mode == "dungeon" and wave >= 3 or mode == "boss_rush" and wave >= PveData.BOSS_RUSH.size():
		_finish_mode(true)
		return
	if mode == "boss_rush":
		hero_hp = minf(float(hero["hp"]), hero_hp + float(hero["hp"]) * PveData.BOSS_HEAL)
	wave += 1
	_spawn_wave()
	message.emit("%s | %s" % [PveData.mode_label(mode_config), mode_detail()])

func _finish_mode(won: bool) -> void:
	active = false
	var mode := str(mode_config["mode"])
	var progress := 0
	if mode == "dungeon" or mode == "tower":
		progress = wave if won else wave - 1
	elif mode == "boss_rush":
		progress = wave if won else wave - 1
	else:
		progress = wave
	mode_finished.emit({"won": won, "progress": progress, "time": run_time, "kills": run_kills, "damage": run_damage})
	changed.emit()

func _all_enemies_defeated() -> bool:
	for enemy in enemies:
		if float(enemy["current_hp"]) > 0.0:
			return false
	return true

func _lose(boss_failure: bool) -> void:
	if str(mode_config.get("mode", "campaign")) != "campaign":
		_finish_mode(false)
		return
	active = false
	battle_lost.emit(boss_failure)
	changed.emit()
