class_name CompanionRuntime
extends RefCounted

var timers := {}

func start(profile: SaveData) -> void:
	timers.clear()
	for id in profile.equipped_companion_slots:
		if id != "" and profile.companions.has(id):
			timers[id] = 0.65

func sync(profile: SaveData) -> void:
	var active := {}
	for id in profile.equipped_companion_slots:
		if id != "" and profile.companions.has(id):
			active[id] = true
			if not timers.has(id):
				timers[id] = 0.65
	for id in timers.keys():
		if not active.has(id):
			timers.erase(id)

func process(delta: float, battle: BattleController) -> void:
	sync(battle.profile)
	for slot in 4:
		var id := battle.profile.equipped_companion_slots[slot]
		if id == "" or not timers.has(id):
			continue
		timers[id] = float(timers[id]) - delta
		if float(timers[id]) > 0.0:
			continue
		timers[id] += 1.0 / CompanionData.attack_speed(id, battle.profile.companions[id])
		for target in battle.enemies.size():
			if float(battle.enemies[target]["current_hp"]) <= 0.0:
				continue
			var amount := CompanionData.attack(id, battle.profile.companions[id])
			if battle.stage == 10:
				amount *= 1.0 + float(battle.hero.get("boss_damage", 0.0))
			battle.companion_attack.emit(slot, target, roundi(amount))
			battle._hit_enemy(target, roundi(amount), false, false)
			break
		if not battle.active:
			return
