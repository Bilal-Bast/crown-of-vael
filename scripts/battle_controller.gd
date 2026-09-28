class_name BattleController
extends Node

signal changed
signal damage_popup(target_index: int, amount: int, critical: bool, bash: bool)
signal attack_started(attacker_index: int, target_index: int)
signal enemy_defeated(target_index: int, reward_gold: int, reward_exp: int)
signal equipment_dropped(item: Dictionary)
signal hero_leveled(level: int, gem_bonus: int)
signal skill_cast(id: String, slot: int)
signal message(text: String)
signal stage_cleared
signal battle_lost(boss_failure: bool)

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

func start(new_profile: SaveData) -> void:
	profile = new_profile
	stage = profile.stage
	wave = 1
	hero = GameData.hero_stats(profile.level, profile.upgrades, profile.gear_stats())
	hero_hp = float(hero["hp"])
	boss_time = 30.0
	bash_time = 8.0
	hero_attack_time = 0.45
	active = true
	skill_runtime.start(profile)
	_spawn_wave()
	message.emit("Goblin Warlord! Defeat him in 30 seconds." if stage == 10 else "%s | Wave 1/3" % GameData.stage_label(stage))
	changed.emit()

func refresh_hero_stats() -> void:
	var old_max := float(hero.get("hp", 0.0))
	var old_hp := hero_hp
	hero = GameData.hero_stats(profile.level, profile.upgrades, profile.gear_stats())
	skill_runtime.apply_buffs(hero)
	hero_hp = minf(float(hero["hp"]), old_hp + maxf(0.0, float(hero["hp"]) - old_max))
	changed.emit()

func _spawn_wave() -> void:
	enemies.clear()

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
	if stage == 10:
		boss_time = maxf(0.0, boss_time - delta)
		if boss_time <= 0.0:
			_lose(true)
			return
	skill_runtime.process(delta, self)
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
			if hero_hp <= 0.0:
				_lose(stage == 10)
				return
	changed.emit()

func _hero_attack() -> void:
	for i in enemies.size():
		if float(enemies[i]["current_hp"]) > 0.0:
			attack_started.emit(-1, i)
			var critical := randf() < float(hero["crit_chance"])
			var amount := float(hero["atk"]) * (float(hero["crit_damage"]) if critical else 1.0)
			_hit_enemy(i, roundi(amount), critical, false)
			return

func _hit_enemy(index: int, amount: int, critical: bool, bash: bool) -> void:
	var enemy := enemies[index]
	enemy["current_hp"] = maxf(0.0, float(enemy["current_hp"]) - amount)
	damage_popup.emit(index, amount, critical, bash)
	if float(enemy["current_hp"]) <= 0.0:
		enemy_defeated.emit(index, int(enemy["gold"]), int(enemy["exp"]))
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

func _all_enemies_defeated() -> bool:
	for enemy in enemies:
		if float(enemy["current_hp"]) > 0.0:
			return false
	return true

func _lose(boss_failure: bool) -> void:
	active = false
	battle_lost.emit(boss_failure)
	changed.emit()
