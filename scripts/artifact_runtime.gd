class_name ArtifactRuntime
extends RefCounted

var hero_attacks := 0
var guard_timer := 18.0
var guard_time := 0.0
var guard_amount := 0.0
var revive_used := false

func start() -> void:
	hero_attacks = 0
	guard_timer = 18.0
	guard_time = 0.0
	guard_amount = 0.0
	revive_used = false

func equipped_effects(profile: SaveData) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for id in profile.equipped_artifact_slots:
		if id == "" or not profile.artifacts.has(id):
			continue
		effects.append({"id": id, "kind": str(ArtifactData.ARTIFACTS[id]["effect"]), "value": ArtifactData.effect_value(id, profile.artifacts[id])})
	return effects

func cooldown_rate(profile: SaveData) -> float:
	var rate := 1.0
	for effect in equipped_effects(profile):
		if effect["kind"] == "cooldown_rate":
			rate += float(effect["value"])
	return rate

func apply_buffs(hero: Dictionary) -> void:
	if guard_time > 0.0:
		hero["armor"] = float(hero["armor"]) + guard_amount

func process(delta: float, battle: BattleController) -> void:
	if guard_time > 0.0:
		guard_time = maxf(0.0, guard_time - delta)
		if guard_time <= 0.0:
			battle.refresh_hero_stats()
	var has_guard := false
	for effect in equipped_effects(battle.profile):
		if effect["kind"] == "periodic_guard":
			has_guard = true
			guard_timer -= delta
			if guard_timer <= 0.0:
				guard_timer += 18.0
				guard_time = 5.0
				guard_amount = float(effect["value"])
				battle.refresh_hero_stats()
				battle.artifact_proc.emit("GUARD", Color("9dd7df"))
			break
	if not has_guard and guard_time > 0.0:
		guard_time = 0.0
		battle.refresh_hero_stats()

func on_hero_attack(battle: BattleController, target: int, amount: int, critical: bool) -> void:
	hero_attacks += 1
	for effect in equipped_effects(battle.profile):
		match str(effect["kind"]):
			"crit_heal":
				if critical:
					battle.hero_hp = minf(float(battle.hero["hp"]), battle.hero_hp + amount * float(effect["value"]) * (1.0 + float(battle.hero.get("healing_bonus", 0.0))))
					battle.artifact_proc.emit("BLOOD HEAL", Color("f09b9b"))
			"crit_extra":
				if critical and randf() < float(effect["value"]) and target < battle.enemies.size() and float(battle.enemies[target]["current_hp"]) > 0.0:
					battle._hit_enemy(target, roundi(amount * 0.7), false, false)
					battle.artifact_proc.emit("EYE STRIKE", Color("efc36b"))
			"attack_burst":
				if hero_attacks % 20 == 0:
					var burst := roundi(float(battle.hero["atk"]) * float(effect["value"]) * (1.0 + float(battle.hero.get("fire_burst_bonus", 0.0))))
					for index in battle.enemies.size():
						if battle.active and float(battle.enemies[index]["current_hp"]) > 0.0:
							battle._hit_enemy(index, burst, false, false)
					battle.artifact_proc.emit("FIRE BURST • SET" if float(battle.hero.get("fire_burst_bonus", 0.0)) > 0.0 else "FIRE BURST", Color("ffce6e") if float(battle.hero.get("fire_burst_bonus", 0.0)) > 0.0 else Color("ff9f68"))

func prevent_death(battle: BattleController) -> bool:
	if revive_used:
		return false
	for effect in equipped_effects(battle.profile):
		if effect["kind"] == "revive":
			revive_used = true
			battle.hero_hp = float(battle.hero["hp"]) * float(effect["value"])
			battle.artifact_proc.emit("PHOENIX REVIVE", Color("ffb876"))
			return true
	return false
