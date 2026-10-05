class_name SkillRuntime
extends RefCounted

var cooldowns := {}
var defense_time := 0.0
var defense_amount := 0.0
var attack_time := 0.0
var attack_amount := 0.0

func start(profile: SaveData) -> void:
	cooldowns.clear()
	defense_time = 0.0
	attack_time = 0.0
	for id in profile.equipped_skill_slots:
		if id != "" and SkillData.SKILLS.has(id):
			cooldowns[id] = float(SkillData.SKILLS[id]["cooldown"])

func sync(profile: SaveData) -> void:
	var active := {}
	for id in profile.equipped_skill_slots:
		if id != "" and SkillData.SKILLS.has(id):
			active[id] = true
			if not cooldowns.has(id):
				cooldowns[id] = float(SkillData.SKILLS[id]["cooldown"])
	for id in cooldowns.keys():
		if not active.has(id):
			cooldowns.erase(id)

func apply_buffs(hero: Dictionary) -> void:
	if defense_time > 0.0:
		hero["armor"] = float(hero["armor"]) + defense_amount
	if attack_time > 0.0:
		hero["atk"] = float(hero["atk"]) * (1.0 + attack_amount)

func process(delta: float, battle: BattleController) -> void:
	sync(battle.profile)
	var defense_expired := defense_time > 0.0 and defense_time <= delta
	var attack_expired := attack_time > 0.0 and attack_time <= delta
	defense_time = maxf(0.0, defense_time - delta)
	attack_time = maxf(0.0, attack_time - delta)
	if defense_expired or attack_expired:
		battle.refresh_hero_stats()
	for slot in 4:
		var id := battle.profile.equipped_skill_slots[slot]
		if id == "" or not cooldowns.has(id):
			continue
		cooldowns[id] = maxf(0.0, float(cooldowns[id]) - delta * battle.artifact_runtime.cooldown_rate(battle.profile))
		if float(cooldowns[id]) <= 0.0 and cast(id, battle):
			cooldowns[id] = float(SkillData.SKILLS[id]["cooldown"])
			battle.skill_cast.emit(id, slot)
			if not battle.active:
				return

func cast(id: String, battle: BattleController) -> bool:
	var data: Dictionary = SkillData.SKILLS[id]
	var level := int(battle.profile.skills[id]["level"])
	var strength := SkillData.strength(id, level)
	var effect := str(data["effect"])
	if effect in ["single", "area"]:
		var targets: Array[int] = []
		for index in battle.enemies.size():
			if battle.is_enemy_combat_ready(index):
				targets.append(index)
		if targets.is_empty():
			return false
		if effect == "single":
			targets.resize(1)
		for target in targets:
			if float(data.get("stun", 0.0)) > 0.0:
				battle.enemies[target]["stun_time"] = float(data["stun"])
			battle.attack_started.emit(-2, target)
			var damage := float(battle.hero["atk"]) * strength * (1.0 + float(battle.hero.get("skill_damage", 0.0)))
			if battle.stage == 20 and str(battle.mode_config.get("mode", "campaign")) == "campaign":
				damage *= 1.0 + float(battle.hero.get("boss_damage", 0.0))
			var attack_element := str(data.get("element", HeroData.element(battle.profile.selected_hero_id, battle.profile.heroes[battle.profile.selected_hero_id])))
			damage = battle.modified_element_damage(damage, target, attack_element)
			battle._hit_enemy(target, roundi(damage), false, id == "shield_bash")
			if not battle.active:
				break
	elif effect == "defense":
		defense_time = float(data["duration"])
		defense_amount = strength
		battle.refresh_hero_stats()
	elif effect == "attack":
		attack_time = float(data["duration"])
		attack_amount = strength
		battle.refresh_hero_stats()
	elif effect == "heal":
		var hp_before := battle.hero_hp
		battle.hero_hp = minf(float(battle.hero["hp"]), battle.hero_hp + float(battle.hero["hp"]) * strength * (1.0 + float(battle.hero.get("healing_bonus", 0.0))))
		battle.changed.emit()
		battle.skill_healed.emit(roundi(battle.hero_hp - hp_before))
	battle.message.emit("%s!" % data["name"])
	return true
