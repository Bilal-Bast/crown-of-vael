class_name BattleController
extends Node

signal changed
signal damage_popup(target_index: int, amount: int, critical: bool, bash: bool)
signal attack_started(attacker_index: int, target_index: int)
signal enemy_defeated(target_index: int, reward_gold: int, reward_exp: int)
signal equipment_dropped(item: Dictionary)
signal hero_leveled(level: int, gem_bonus: int)
signal skill_cast(id: String, slot: int)
signal skill_healed(amount: int)
signal companion_attack(slot: int, target: int, amount: int)
signal artifact_proc(label: String, color: Color)
signal message(text: String)
signal stage_cleared
signal battle_lost(boss_failure: bool)
signal presentation_event(event: String, data: Dictionary)
signal mode_finished(result: Dictionary)

var profile: SaveData
var stage := 1
var region := 1
var difficulty := 0
var force_treasure := false
var force_elite := false
var force_boss := false
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
var pending_hero_hits: Array[Dictionary] = []
var enemy_entry_timer := 0.0
var spawned_enemy_count := 0
var wave_transition_time := 0.0
var wave_transition_duration := 1.5

func start(new_profile: SaveData) -> void:
	mode_config = {"mode": "campaign"}
	_start_shared(new_profile)
	if stage == 20:
		presentation_event.emit("boss_intro", {"name": str(CampaignData.REGIONS[region - 1]["boss"])})
	var audio := get_node_or_null("/root/AudioService") if is_inside_tree() else null
	if audio != null:
		audio.set_music("boss" if stage == 20 else "battle_region_%02d" % region)
	message.emit("%s! Defeat it in 30 seconds." % CampaignData.REGIONS[region - 1]["boss"] if stage == 20 else "%s | Wave 1/3" % CampaignData.label(difficulty, region, stage))
	changed.emit()

func start_mode(new_profile: SaveData, config: Dictionary) -> void:
	mode_config = config.duplicate(true)
	_start_shared(new_profile)
	message.emit("%s | %s" % [PveData.mode_label(config), mode_detail()])
	changed.emit()

func _start_shared(new_profile: SaveData) -> void:
	profile = new_profile
	stage = profile.stage
	region = profile.region
	difficulty = profile.campaign_difficulty
	wave = 1
	hero = profile.hero_stats()
	hero_hp = float(hero["hp"])
	boss_time = 30.0
	bash_time = 8.0
	hero_attack_time = 0.45
	run_time = 0.0
	run_kills = 0
	run_damage = 0
	enemy_entry_timer = 0.0
	spawned_enemy_count = 0
	wave_transition_time = 0.0
	pending_hero_hits.clear()
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
	enemy_entry_timer = 0.0
	spawned_enemy_count = 0
	if str(mode_config.get("mode", "campaign")) != "campaign":
		for template in PveData.wave_enemies(mode_config, wave):
			var enemy := template.duplicate(true)
			enemy["current_hp"] = enemy["hp"]
			enemy["combat_ready"] = true
			enemy["attack_time"] = 0.7 + randf_range(0.0, 0.5)
			enemy["stun_time"] = 0.0
			enemies.append(enemy)
		changed.emit()
		return

	var kinds := CampaignData.wave_kinds(region, 20 if force_boss else stage, wave, force_elite, force_treasure)
	force_treasure = false

	var paced_entries := stage != 20 and not force_boss
	for kind in kinds:
		var enemy := CampaignData.enemy_stats(kind, difficulty, region, stage, wave)
		var enters_now := not paced_entries or spawned_enemy_count == 0
		enemy["current_hp"] = enemy["hp"] if enters_now else 0.0
		enemy["spawned"] = enters_now
		enemy["attack_time"] = 0.7 + randf_range(0.0, 0.5)
		enemy["stun_time"] = 0.0
		enemy["entry_time"] = GameData.ENEMY_ENTRY_DURATION if paced_entries and enters_now else (GameData.BOSS_ENTRY_ANIMATION_DURATION if enters_now else 0.0)
		enemy["combat_ready"] = not paced_entries
		enemies.append(enemy)
		if enters_now:
			spawned_enemy_count += 1

	if paced_entries and spawned_enemy_count > 0:
		enemy_entry_timer = GameData.ENEMY_ENTRY_INTERVAL
	changed.emit()

func _process(delta: float) -> void:
	if not active:
		return
	run_time += delta
	if str(mode_config.get("mode", "campaign")) == "campaign" and stage == 20:
		boss_time = maxf(0.0, boss_time - delta)
		if boss_time <= 0.0:
			_lose(true)
			return
	if wave_transition_time > 0.0:
		wave_transition_time = maxf(0.0, wave_transition_time - delta)
		if wave_transition_time <= 0.0:
			_advance_campaign_wave()
		changed.emit()
		return
	_advance_enemy_entry_states(delta)
	_process_enemy_entries(delta)
	artifact_runtime.process(delta, self)
	skill_runtime.process(delta, self)
	companion_runtime.process(delta, self)
	_process_hero_projectiles(delta)
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
		if not is_enemy_combat_ready(i):
			continue
		enemy["stun_time"] = maxf(0.0, float(enemy["stun_time"]) - delta)
		if float(enemy["stun_time"]) > 0.0:
			continue
		enemy["attack_time"] = float(enemy["attack_time"]) - delta
		if float(enemy["attack_time"]) <= 0.0:
			enemy["attack_time"] = 1.0 / float(enemy["speed"])
			if str(enemy.get("archetype", "")) == "HEALER":
				var target := -1
				var lowest := 1.0
				for ally in enemies.size():
					var ratio := float(enemies[ally]["current_hp"]) / float(enemies[ally]["hp"])
					if is_enemy_combat_ready(ally) and ratio > 0.0 and ratio < lowest:
						lowest = ratio
						target = ally
				if target >= 0:
					enemies[target]["current_hp"] = minf(float(enemies[target]["hp"]), float(enemies[target]["current_hp"]) + float(enemy["atk"]) * 2.0)
					continue
			attack_started.emit(i, -1)
			var damage := maxi(1, roundi(float(enemy["atk"]) * (1.1 if str(enemy.get("archetype", "")) == "MAGIC" else 1.0) - float(hero["armor"]) * (0.5 if str(enemy.get("archetype", "")) == "MAGIC" else 1.0)))
			hero_hp = maxf(0.0, hero_hp - damage)
			damage_popup.emit(-1, damage, false, false)
			if hero_hp <= 0.0 and not artifact_runtime.prevent_death(self):
				_lose(stage == 20 and str(mode_config.get("mode", "campaign")) == "campaign")
				return
	changed.emit()

func _process_enemy_entries(delta: float) -> void:
	if str(mode_config.get("mode", "campaign")) != "campaign" or stage == 20 or spawned_enemy_count >= enemies.size():
		return
	enemy_entry_timer -= delta
	if enemy_entry_timer > 0.0:
		return
	for index in enemies.size():
		if bool(enemies[index].get("spawned", false)):
			continue
		enemies[index]["current_hp"] = enemies[index]["hp"]
		enemies[index]["spawned"] = true
		enemies[index]["entry_time"] = GameData.ENEMY_ENTRY_DURATION
		enemies[index]["combat_ready"] = false
		enemies[index]["attack_time"] = 0.7 + randf_range(0.0, 0.5)
		spawned_enemy_count += 1
		enemy_entry_timer = GameData.ENEMY_ENTRY_INTERVAL
		presentation_event.emit("enemy_enter", {"index": index})
		changed.emit()
		return

func _advance_enemy_entry_states(delta: float) -> void:
	for index in enemies.size():
		var enemy := enemies[index]
		if not bool(enemy.get("spawned", true)) or float(enemy.get("entry_time", 0.0)) <= 0.0:
			continue
		enemy["entry_time"] = maxf(0.0, float(enemy.get("entry_time", 0.0)) - delta)
		if float(enemy["entry_time"]) <= 0.0 and not bool(enemy.get("combat_ready", true)):
			enemy["combat_ready"] = true

func is_enemy_combat_ready(index: int) -> bool:
	if index < 0 or index >= enemies.size():
		return false
	var enemy := enemies[index]
	if float(enemy.get("current_hp", 0.0)) <= 0.0 or not bool(enemy.get("spawned", true)):
		return false
	return bool(enemy.get("combat_ready", float(enemy.get("entry_time", 0.0)) <= 0.0))

func _hero_attack() -> void:
	for i in enemies.size():
		if is_enemy_combat_ready(i):
			attack_started.emit(-1, i)
			var critical := randf() < float(hero["crit_chance"])
			var amount := float(hero["atk"]) * (float(hero["crit_damage"]) if critical else 1.0)
			if stage == 20 and str(mode_config.get("mode", "campaign")) == "campaign":
				amount *= 1.0 + float(hero.get("boss_damage", 0.0))
			amount = modified_element_damage(amount, i, HeroData.element(profile.selected_hero_id, profile.heroes[profile.selected_hero_id]))
			if HeroData.HEROES[profile.selected_hero_id]["style"] in ["magic", "arrow", "dark_bolt"]:
				pending_hero_hits.append({"time": 0.22, "wave": wave, "target": i, "amount": roundi(amount), "critical": critical})
			else:
				_resolve_hero_hit(i, roundi(amount), critical)
			return

func _process_hero_projectiles(delta: float) -> void:
	for index in range(pending_hero_hits.size() - 1, -1, -1):
		var hit: Dictionary = pending_hero_hits[index]
		hit["time"] = float(hit["time"]) - delta
		if float(hit["time"]) > 0.0:
			continue
		pending_hero_hits.remove_at(index)
		var target := int(hit["target"])
		if int(hit["wave"]) == wave and is_enemy_combat_ready(target):
			_resolve_hero_hit(target, int(hit["amount"]), bool(hit["critical"]))

func _resolve_hero_hit(target: int, amount: int, critical: bool) -> void:
	if not is_enemy_combat_ready(target):
		return
	var dealt := mini(amount, ceili(float(enemies[target]["current_hp"])))
	_hit_enemy(target, amount, critical, false)
	artifact_runtime.on_hero_attack(self, target, dealt, critical)

func _hit_enemy(index: int, amount: int, critical: bool, bash: bool) -> void:
	if not is_enemy_combat_ready(index):
		return
	var enemy := enemies[index]
	amount = maxi(1, roundi(amount - float(enemy.get("armor", 0.0))))
	var tracker := ProgressionService.new(profile)
	tracker.report("damage_dealt", mini(amount, ceili(float(enemy["current_hp"]))))
	if critical: tracker.report("critical_hit")
	if str(mode_config.get("mode", "campaign")) != "campaign":
		run_damage += mini(amount, ceili(float(enemy["current_hp"])))
	enemy["current_hp"] = maxf(0.0, float(enemy["current_hp"]) - amount)
	damage_popup.emit(index, amount, critical, bash)
	if float(enemy["current_hp"]) <= 0.0:
		tracker.report("enemy_defeated")
		if bool(enemy.get("boss", false)) or str(enemy.get("archetype", "")) == "BOSS": tracker.report("boss_defeated")
		if str(enemy.get("archetype", "")) == "ELITE": tracker.report("elite_defeated")
		if str(enemy.get("archetype", "")) == "TREASURE": tracker.report("treasure_found")
		enemy_defeated.emit(index, int(enemy["gold"]), int(enemy["exp"]))
		if str(mode_config.get("mode", "campaign")) != "campaign":
			run_kills += 1
			if _all_enemies_defeated():
				_advance_mode()
			changed.emit()
			return
		var gems_before := profile.gems
		var leveled_up := profile.add_rewards(int(enemy["gold"]), int(enemy["exp"]))
		var treasure := str(enemy.get("archetype", "")) == "TREASURE"
		if treasure:
			_grant_treasure_reward()
		var drop := EquipmentData.roll_campaign_drop(region, stage, difficulty, stage == 20, treasure)
		if not drop.is_empty():
			profile.inventory.append(drop)
			profile.save()
			equipment_dropped.emit(drop)
		if leveled_up:
			refresh_hero_stats()
			hero_leveled.emit(profile.level, profile.gems - gems_before)
			message.emit("Level up! Squire is now level %d." % profile.level)
		if _all_enemies_defeated():
			if stage == 20 or wave >= GameData.WAVES_PER_STAGE:
				active = false
				presentation_event.emit("boss_defeat" if stage == 20 else "stage_clear", {"boss": stage == 20})
				stage_cleared.emit()
			else:
				wave_transition_time = wave_transition_duration
				presentation_event.emit("wave_run", {"duration": wave_transition_duration})
		changed.emit()

func _advance_campaign_wave() -> void:
	if not active:
		return
	wave += 1
	presentation_event.emit("wave", {"wave": wave})
	_spawn_wave()
	message.emit("Wave %d/%d" % [wave, GameData.WAVES_PER_STAGE])

func _advance_mode() -> void:
	var mode := str(mode_config["mode"])
	if mode == "tower" or mode == "dungeon" and wave >= 3 or mode == "boss_rush" and wave >= PveData.BOSS_RUSH.size():
		_finish_mode(true)
		return
	if mode == "boss_rush":
		hero_hp = minf(float(hero["hp"]), hero_hp + float(hero["hp"]) * PveData.BOSS_HEAL)
	wave += 1
	presentation_event.emit("wave", {"wave": wave})
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
	if str(mode_config.get("mode", "campaign")) == "campaign" and spawned_enemy_count < enemies.size():
		return false
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

func modified_element_damage(amount: float, target: int, attack_element: String) -> float:
	if str(mode_config.get("mode", "campaign")) != "campaign": return amount
	return amount * CampaignData.element_multiplier(attack_element, str(enemies[target].get("element", "Physical")))

func _grant_treasure_reward() -> void:
	var roll := randf()
	if roll < 0.03:
		profile.gems += 1
	elif roll < 0.26:
		profile.enhancement_stones += 2 + difficulty
	elif roll < 0.49:
		profile.companion_essence += 2 + difficulty
	elif roll < 0.72:
		profile.artifact_dust += 2 + difficulty
	else:
		profile.gold += 25 * region * (difficulty + 1)
	profile.save()
