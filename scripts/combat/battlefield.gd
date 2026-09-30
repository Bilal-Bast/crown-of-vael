class_name Battlefield
extends Control

const SKY := Color("b9d5c5")
const GROUND := Color("738e65")
var vfx := CombatVfxService.new()

var battle: BattleController
var floaters: Array[Dictionary] = []
var impacts: Array[Dictionary] = []
var deaths: Array[Dictionary] = []
var flashes: Dictionary = {}
var lunges: Dictionary = {}
var enemy_attack_times: Dictionary = {}
var enemy_hit_times: Dictionary = {}
var companion_lunges: Dictionary = {}
var hero_projectiles: Array[Dictionary] = []
var hero_lunge := 0.0
var hero_bash := false
var hero_attack_art_time := 0.0
var hero_guard_art_time := 0.0
var pixel_skill_effect_time := 0.0
var pixel_skill_effect_pos := Vector2.ZERO
var pixel_background_layer: TextureRect
var pixel_hero_sprite: Sprite2D
var pixel_enemy_sprites: Array[Sprite2D] = []
## Compatibility aliases retained for the Phase 9/legacy smoke harness.
var squire_idle_texture: Texture2D
var squire_attack_texture: Texture2D
var squire_guard_texture: Texture2D
var shake_time := 0.0
var hero_visual_state := "idle"

func _init() -> void:
	floaters = vfx.labels
	impacts = vfx.effects

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	squire_idle_texture = HeroArtService.texture_for(0, "idle")
	squire_attack_texture = HeroArtService.texture_for(0, "attack")
	squire_guard_texture = HeroArtService.texture_for(0, "guard")
	floaters = vfx.labels
	impacts = vfx.effects
	deaths = []

func set_battle(value: BattleController) -> void:
	battle = value
	floaters = vfx.labels
	impacts = vfx.effects
	battle.changed.connect(_on_battle_changed)
	battle.damage_popup.connect(_on_damage_popup)
	battle.attack_started.connect(_on_attack_started)
	battle.enemy_defeated.connect(_on_enemy_defeated)
	battle.companion_attack.connect(_on_companion_attack)
	battle.artifact_proc.connect(_on_artifact_proc)
	battle.skill_cast.connect(_on_skill_cast)
	battle.skill_healed.connect(_on_skill_healed)
	battle.presentation_event.connect(_on_presentation_event)
	_update_texture_filter()
	queue_redraw()

func _on_battle_changed() -> void:
	_update_texture_filter()
	queue_redraw()

func _update_texture_filter() -> void:
	var pixel_active := PixelBattleArt.is_active(battle)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel_active else CanvasItem.TEXTURE_FILTER_LINEAR
	if pixel_background_layer != null:
		pixel_background_layer.visible = pixel_active
		pixel_background_layer.texture = PixelBattleArt.background_texture() if pixel_active else null
		pixel_background_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel_active else CanvasItem.TEXTURE_FILTER_LINEAR

func _process(delta: float) -> void:
	hero_lunge = maxf(0.0, hero_lunge - delta)
	hero_attack_art_time = maxf(0.0, hero_attack_art_time - delta)
	hero_guard_art_time = maxf(0.0, hero_guard_art_time - delta)
	pixel_skill_effect_time = maxf(0.0, pixel_skill_effect_time - delta)
	hero_visual_state = "guard" if hero_guard_art_time > 0.0 else ("attack" if hero_attack_art_time > 0.0 else "idle")
	shake_time = maxf(0.0, shake_time - delta)
	vfx.reduced = battle != null and battle.profile != null and battle.profile.reduced_effects
	vfx.tick(delta)
	for key in lunges.keys():
		lunges[key] = maxf(0.0, float(lunges[key]) - delta)
	for key in enemy_attack_times.keys():
		enemy_attack_times[key] = maxf(0.0, float(enemy_attack_times[key]) - delta)
	for key in enemy_hit_times.keys():
		enemy_hit_times[key] = maxf(0.0, float(enemy_hit_times[key]) - delta)
	for key in companion_lunges.keys():
		companion_lunges[key] = maxf(0.0, float(companion_lunges[key]) - delta)
		if float(companion_lunges[key]) <= 0.0:
			companion_lunges.erase(key)
	for key in flashes.keys():
		flashes[key] = maxf(0.0, float(flashes[key]) - delta)
	for group in [deaths]:
		for i in range(group.size() - 1, -1, -1):
			group[i]["age"] = float(group[i]["age"]) + delta
			if float(group[i]["age"]) >= float(group[i]["life"]):
				group.remove_at(i)
	if hero_lunge > 0.0 or hero_attack_art_time > 0.0 or hero_guard_art_time > 0.0 or pixel_skill_effect_time > 0.0 or shake_time > 0.0 or not floaters.is_empty() or not impacts.is_empty() or not deaths.is_empty() or not companion_lunges.is_empty() or not vfx.projectiles.is_empty() or battle != null and battle.active:
		queue_redraw()

func _on_companion_attack(slot: int, target: int, amount: int) -> void:
	companion_lunges[slot] = 0.24
	var companion_id := battle.profile.equipped_companion_slots[slot] if battle != null and battle.profile != null else ""
	var visual := str(CompanionData.COMPANIONS.get(companion_id, {}).get("visual", "beast"))
	var cue_color := Color("b5e5c2") if visual == "beast" else (Color("a9e9e3") if visual == "fairy" else (Color("dba3ef") if visual == "dragon" else Color("d5c39c")))
	var origin := Vector2(size.x * (0.09 + slot * 0.105), size.y * 0.70 - 25)
	if visual == "humanoid":
		vfx.pulse(_enemy_position(target) + Vector2(0, -70), cue_color, 0.55, 0.18, "slash")
	else:
		vfx.projectile(origin, _enemy_position(target) + Vector2(0, -72), cue_color, 0.18, 5)
	vfx.label(_enemy_position(target) + Vector2(0, -130), "ALLY %d" % amount, Color("a9e5c4"), 23, 0.8)
	queue_redraw()

func _play_audio(event: String) -> void:
	if not is_inside_tree():
		return
	var audio := get_node_or_null("/root/AudioService")
	if audio != null:
		audio.play_event(event)

func _on_artifact_proc(label: String, color: Color) -> void:
	vfx.label(_hero_position() + Vector2(0, -190), label, color, 28, 1.1)
	queue_redraw()

func _on_skill_cast(skill_id: String, _slot: int) -> void:
	var target := _hero_position()
	for index in battle.enemies.size():
		if float(battle.enemies[index]["current_hp"]) > 0.0:
			target = _enemy_position(index)
			break
	var hero_id := battle.profile.selected_hero_id if battle.profile != null else "knight"
	var element := HeroData.element(hero_id, battle.profile.heroes[hero_id]) if battle.profile != null else "Holy"
	var tint: Color = {"Fire": Color("ff9a57"), "Ice": Color("9fe5f1"), "Holy": Color("ffe39b"), "Dark": Color("b892ef")}.get(element, Color("dbe7e1"))
	if PixelBattleArt.is_active(battle) and skill_id == "shield_bash":
		pixel_skill_effect_pos = target + Vector2(0, -84)
		pixel_skill_effect_time = 0.28
	else:
		vfx.skill_effect(skill_id, _hero_position() + Vector2(0, -82), target + Vector2(0, -76), tint)
	_play_audio("shield_bash" if skill_id == "shield_bash" else "skill_activation")
	queue_redraw()

func _on_skill_healed(amount: int) -> void:
	if amount <= 0:
		return
	vfx.label(_hero_position() + Vector2(48, -160), "HEAL +%d" % amount, Color("9febaa"), 44, 0.95)
	queue_redraw()

func _on_presentation_event(event: String, data: Dictionary) -> void:
	if event == "boss_intro":
		vfx.boss_banner_name = str(data.get("name", "BOSS"))
		vfx.boss_banner_time = 1.8
		vfx.shake(0.30, 3.2)
		_play_audio("boss_entrance")
	elif event in ["boss_defeat", "stage_clear"]:
		vfx.clear_time = 0.72 if event == "boss_defeat" else 0.45
		vfx.pulse(Vector2(size.x * 0.5, size.y * 0.42), Color("ffe6a0"), 2.0 if event == "boss_defeat" else 1.2, 0.75)
		vfx.label(Vector2(size.x * 0.5, size.y * 0.42 - 55), "VICTORY!" if event == "boss_defeat" else "STAGE CLEAR", Color("fff0bc"), 44 if event == "boss_defeat" else 34, 0.72)
		if event == "boss_defeat":
			vfx.shake(0.22, 2.6)
			_play_audio("boss_defeat")
	elif event == "wave":
		vfx.boss_banner_name = "WAVE %d" % int(data.get("wave", 1))
		vfx.boss_banner_time = 0.72
	queue_redraw()

func _on_attack_started(attacker_index: int, target_index: int) -> void:
	if attacker_index < 0:
		if attacker_index == -1:
			_play_audio("projectile_launch" if battle.profile.selected_hero_id in ["mage", "ranger", "necromancer"] else "sword_swing")
		var selected_form := int(battle.profile.heroes.get(battle.profile.selected_hero_id, {}).get("evolution", 0)) if battle != null and battle.profile != null else 0
		if attacker_index == -1 or attacker_index == -2:
			hero_attack_art_time = float(HeroArtService.metadata(selected_form).get("attack_duration", 0.26)) * (1.25 if attacker_index == -2 else 1.0)
		var style := str(HeroData.HEROES[battle.profile.selected_hero_id]["style"])
		if attacker_index == -1 and style in ["magic", "arrow", "dark_bolt"]:
			var projectile_color := Color("8fe4f4") if style == "magic" else (Color("b08bda") if style == "dark_bolt" else Color("ead3a1"))
			vfx.projectile(_hero_position() + Vector2(35, -90), _enemy_position(target_index) + Vector2(0, -85), projectile_color, 0.22, 8, "arrow" if style == "arrow" else "orb")
		elif attacker_index == -1:
			if PixelBattleArt.is_active(battle):
				pixel_skill_effect_pos = _enemy_position(target_index) + Vector2(0, -65)
				pixel_skill_effect_time = 0.20
			else:
				vfx.pulse(_enemy_position(target_index) + Vector2(0, -65), Color("e8d5a0"), 0.8, 0.24, "slash")
			if battle.profile.selected_hero_id == "assassin":
				vfx.projectile(_hero_position() + Vector2(24, -76), _enemy_position(target_index) + Vector2(0, -64), Color("c8a0e5"), 0.12, 7)
		hero_lunge = 0.0 if style in ["magic", "arrow", "dark_bolt"] and attacker_index == -1 else (0.26 if attacker_index == -2 else 0.19)
		hero_bash = attacker_index == -2
		if attacker_index == -2:
			shake_time = maxf(shake_time, 0.18)
	else:
		var enemy: Dictionary = battle.enemies[attacker_index]
		var enemy_id := str(enemy.get("visual", enemy.get("kind", "")))
		enemy_attack_times[attacker_index] = float(EnemyArtService.metadata(enemy_id).get("attack_duration", 0.26))
		if str(enemy.get("archetype", "")) == "BOSS":
			vfx.shake(0.12, 2.0)
		if str(battle.enemies[attacker_index].get("archetype", "")) in ["RANGED", "MAGIC", "HEALER"]:
			var origin := _enemy_position(attacker_index) + Vector2(-18, -82)
			vfx.projectile(origin, _hero_position() + Vector2(0, -75), Color("d49aff") if str(battle.enemies[attacker_index].get("archetype", "")) == "MAGIC" else Color("dbe2c0"), 0.26, 6)
			vfx.pulse(_hero_position() + Vector2(0, -50), Color("f4f0d5"), 0.7, 0.3)
		else:
			lunges[attacker_index] = 0.18
	queue_redraw()

func _on_damage_popup(target_index: int, amount: int, critical: bool, bash: bool) -> void:
	if target_index < 0:
		var evolution := int(battle.profile.heroes.get("knight", {}).get("evolution", 0)) if battle != null and battle.profile != null and battle.profile.selected_hero_id == "knight" else 0
		hero_guard_art_time = float(HeroArtService.metadata(evolution).get("hit_duration", 0.30))
	elif battle != null and target_index < battle.enemies.size():
		var enemy: Dictionary = battle.enemies[target_index]
		var enemy_id := str(enemy.get("visual", enemy.get("kind", "")))
		enemy_hit_times[target_index] = float(EnemyArtService.metadata(enemy_id).get("hit_duration", 0.22))
	var pos := _hero_position() if target_index < 0 else _enemy_position(target_index)
	var text_value := NumberFormat.compact(amount)
	if critical:
		text_value = "CRIT %s!" % NumberFormat.compact(amount)
	elif bash:
		text_value = "BASH %s!" % NumberFormat.compact(amount)
	var label_color := Color("ffdf72") if critical else (Color("9de8f2") if bash else (Color("ffb4a0") if target_index < 0 else Color.WHITE))
	vfx.label(pos + Vector2(0, -100), text_value, label_color, 36 if critical else (34 if bash else 28), 0.72 if critical else 0.9, critical)
	if not (PixelBattleArt.is_active(battle) and bash):
		vfx.pulse(pos + Vector2(0, -56), Color("ffe59d") if critical or bash else Color("f4f0d5"), 1.7 if critical else (1.5 if bash else 0.8), 0.30)
	flashes[target_index] = 0.16
	if bash:
		shake_time = 0.28
		vfx.shake(0.20, 3.0)
	elif critical:
		vfx.shake(0.11, 1.2)
	else:
		vfx.shake(0.05, 0.45)
	_play_audio("shield_bash" if bash else ("critical_hit" if critical else "normal_hit"))
	queue_redraw()

func _on_enemy_defeated(target_index: int, gold: int, exp: int) -> void:
	var pos := _enemy_position(target_index)
	deaths.append({"pos": pos + Vector2(0, -50), "index": target_index, "age": 0.0, "life": 0.62})
	vfx.label(pos + Vector2(0, -140), "+%s GOLD  +%s EXP" % [NumberFormat.compact(gold), NumberFormat.compact(exp)], Color("ffe79c"), 22, 1.25)
	vfx.pulse(pos + Vector2(0, -50), Color("d9f1a5"), 1.4 if int(battle.enemies[target_index].get("archetype", "") == "BOSS") else 1.0, 0.52)
	_play_audio("enemy_death")
	_play_audio("gold_reward")
	queue_redraw()

func show_equipment_drop(item_name: String, rarity_color: Color) -> void:
	vfx.label(Vector2(size.x * 0.5, size.y * 0.45), "LOOT: %s" % item_name, rarity_color, 30, 2.2)
	queue_redraw()

func show_level_up(level: int, gem_bonus: int) -> void:
	var note := "SQUIRE LEVEL %d!" % level
	if gem_bonus > 0:
		note += "  +%d GEMS" % gem_bonus
	vfx.label(Vector2(size.x * 0.5, size.y * 0.28), note, Color("f7e9af"), 39, 2.0)
	queue_redraw()

func show_hero_switch(title: String) -> void:
	vfx.label(Vector2(size.x * 0.5, size.y * 0.28), "%s SELECTED" % title.to_upper(), Color("f7e9af"), 34, 1.0)
	flashes[-1] = 0.35
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var unit := minf(w / 1000.0, h / (560.0 if PixelBattleArt.is_active(battle) else 650.0))
	_draw_landscape(w, h)
	var shake := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * unit * vfx.shake_strength * (vfx.shake_time / 0.20) if vfx.shake_time > 0.0 else Vector2.ZERO
	var hero_pos := _hero_position() + shake
	if hero_lunge > 0.0:
		hero_pos.x += sin((1.0 - hero_lunge / (0.26 if hero_bash else 0.19)) * PI) * (75.0 if hero_bash else 49.0) * unit
	_draw_companions(unit)
	_draw_hero(hero_pos, unit, float(flashes.get(-1, 0.0)) > 0.0 and not vfx.reduced)
	_update_pixel_hero_sprite(hero_pos, unit)
	if battle != null:
		for i in battle.enemies.size():
			var enemy: Dictionary = battle.enemies[i]
			if float(enemy["current_hp"]) <= 0.0:
				var death_found := false
				for death in deaths:
					if int(death.get("index", -1)) == i:
						death_found = true
						var death_ratio := float(death["age"]) / float(death["life"])
						if PixelBattleArt.enemy_sheet(str(enemy.get("visual", enemy.get("kind", "")))) != null and PixelBattleArt.is_active(battle):
							_update_pixel_enemy_sprite(i, _enemy_position(i) + shake, enemy, "idle", unit, 1.0 - death_ratio, 1.0 - death_ratio * 0.45)
						else:
							_draw_defeated_enemy(_enemy_position(i) + shake, enemy, unit, death_ratio)
						break
				if not death_found:
					_sync_pixel_enemy_visibility(i, false)
				continue
			var pos := _enemy_position(i) + shake
			var lunge := float(lunges.get(i, 0.0))
			if lunge > 0.0:
				pos.x -= sin((1.0 - lunge / 0.18) * PI) * 24.0 * unit
			var hit_time := float(enemy_hit_times.get(i, 0.0))
			if hit_time > 0.0:
				var hit_duration := float(EnemyArtService.metadata(str(enemy.get("visual", enemy["kind"]))).get("hit_duration", 0.22))
				pos.x += sin((1.0 - hit_time / hit_duration) * PI) * 16.0 * unit
			_draw_enemy(pos, enemy, unit, float(flashes.get(i, 0.0)) > 0.0, i)
			_update_pixel_enemy_sprite(i, pos, enemy, enemy_visual_state(i), unit)
		for i in range(battle.enemies.size(), pixel_enemy_sprites.size()):
			_sync_pixel_enemy_visibility(i, false)
	else:
		_update_pixel_hero_sprite(Vector2.ZERO, 0.0, false)
		for i in pixel_enemy_sprites.size():
			_sync_pixel_enemy_visibility(i, false)
	_draw_effects(unit)
	_draw_artifact_indicators(unit)
	_draw_pixel_impact(unit)

func _draw_pixel_impact(unit: float) -> void:
	if not PixelBattleArt.is_active(battle) or pixel_skill_effect_time <= 0.0:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var fade := clampf(pixel_skill_effect_time / 0.28, 0.0, 1.0)
	var block := maxf(3.0, 12.0 * unit)
	for point in [Vector2(-2, -1), Vector2(-1, -2), Vector2(1, -2), Vector2(2, -1), Vector2(2, 1), Vector2(1, 2), Vector2(-1, 2), Vector2(-2, 1)]:
		draw_rect(Rect2(pixel_skill_effect_pos + (point * block).round(), Vector2(block, block)), Color("ffd56a", fade))
	draw_rect(Rect2(pixel_skill_effect_pos + Vector2(-block * 0.5, -block * 0.5).round(), Vector2(block, block)), Color("fff1b5", fade))

func _draw_companions(unit: float) -> void:
	if battle == null or battle.profile == null:
		return
	for slot in 4:
		var id := battle.profile.equipped_companion_slots[slot]
		if id == "" or not battle.profile.companions.has(id):
			continue
		var record: Dictionary = battle.profile.companions[id]
		var data: Dictionary = CompanionData.COMPANIONS[id]
		var pos := Vector2(size.x * (0.09 + slot * 0.105), size.y * (0.66 if slot % 2 == 0 else 0.76))
		var lunge := float(companion_lunges.get(slot, 0.0))
		if lunge > 0.0:
			pos.x += sin((1.0 - lunge / 0.24) * PI) * 42.0 * unit
		var color: Color = EquipmentData.COLORS[int(record["rarity"])]
		if id == "wolf":
			match int(record["evolution"]):
				1: color = Color("8195ae")
				2: color = Color("725189")
				3: color = Color("9ce9e8")
		draw_set_transform(pos, 0.0, Vector2.ONE * unit * 1.20)
		match str(data["visual"]):
			"fairy":
				draw_circle(Vector2(-19, -38), 27, Color(color, 0.55))
				draw_circle(Vector2(19, -38), 27, Color(color, 0.55))
				draw_circle(Vector2(0, -44), 20, color)
			"humanoid":
				draw_rect(Rect2(-18, -60, 36, 54), color.darkened(0.35))
				draw_circle(Vector2(0, -73), 20, Color("d9b999"))
			"dragon":
				draw_colored_polygon(PackedVector2Array([Vector2(-47, -35), Vector2(-10, -88), Vector2(0, -40), Vector2(36, -84), Vector2(48, -25)]), color.darkened(0.25))
				draw_circle(Vector2(0, -48), 24, color)
			_:
				draw_ellipse_placeholder(Vector2(0, -30), Vector2(38, 25), color)
				draw_circle(Vector2(-24, -58), 21, color)
				draw_colored_polygon(PackedVector2Array([Vector2(-37, -67), Vector2(-36, -94), Vector2(-18, -71)]), color)
		if id == "wolf" and int(record["evolution"]) > 0:
			draw_arc(Vector2(-12, -52), 30 + int(record["evolution"]) * 7, PI, TAU, 12, Color("b9a6eb"), 5)
		draw_string(ThemeDB.fallback_font, Vector2(-20, 2), str(data["icon"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
		draw_set_transform(Vector2.ZERO)

func _draw_artifact_indicators(unit: float) -> void:
	if battle == null or battle.profile == null:
		return
	for slot in battle.profile.artifact_slot_limit():
		var id := battle.profile.equipped_artifact_slots[slot]
		if id == "" or not battle.profile.artifacts.has(id):
			continue
		var pos := Vector2(16 + slot * 68, 18)
		draw_rect(Rect2(pos, Vector2(56, 50)), Color("253739"), true)
		draw_rect(Rect2(pos, Vector2(56, 50)), EquipmentData.COLORS[int(battle.profile.artifacts[id]["rarity"])], false, 3.0)
		draw_string(ThemeDB.fallback_font, pos + Vector2(13, 35), str(ArtifactData.ARTIFACTS[id]["icon"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("efcf8e"))

func _draw_landscape(w: float, h: float) -> void:
	if battle != null and battle.profile != null and str(battle.mode_config.get("mode", "campaign")) == "campaign":
		_draw_region_landscape(w, h)
		return
	draw_rect(Rect2(Vector2.ZERO, size), SKY)
	draw_circle(Vector2(w * 0.8, h * 0.15), 62, Color("e8e6b5"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, h * 0.6), Vector2(w * 0.15, h * 0.32), Vector2(w * 0.32, h * 0.59), Vector2(w * 0.53, h * 0.36), Vector2(w * 0.76, h * 0.58), Vector2(w, h * 0.4), Vector2(w, h * 0.78), Vector2(0, h * 0.78)]), Color("91b69d"))
	for i in 6:
		var x := w * (0.06 + i * 0.18)
		var y := h * (0.47 + (i % 2) * 0.04)
		draw_rect(Rect2(x - 7, y, 14, h * 0.24), Color("6c7656"))
		draw_circle(Vector2(x, y), 35, Color("668f72"))
		draw_circle(Vector2(x - 18, y + 8), 27, Color("729b78"))
	draw_rect(Rect2(0, h * 0.72, w, h * 0.28), GROUND)
	draw_line(Vector2(0, h * 0.72), Vector2(w, h * 0.72), Color("527655"), 5)
	for i in 9:
		var x := w * (0.04 + i * 0.12)
		draw_line(Vector2(x, h * 0.88), Vector2(x + 7, h * 0.86), Color("a6bb79"), 3)
	draw_rect(Rect2(Vector2.ZERO, size), Color("19332e", 0.08), false, 5)

func _draw_region_landscape(w: float, h: float) -> void:
	if PixelBattleArt.is_active(battle):
		return
	if battle.region >= 1 and battle.region <= 10:
		var background := EnemyArtService.background_texture(battle.region, battle.stage == 20)
		if background != null:
			var scale_to_cover := maxf(w / float(background.get_width()), h / float(background.get_height()))
			var bg_size := Vector2(background.get_size()) * scale_to_cover
			draw_texture_rect(background, Rect2((size - bg_size) * 0.5, bg_size), false)
			# Lower contrast just enough for sprites, bars, and floating combat text.
			draw_rect(Rect2(Vector2.ZERO, size), Color("10211f", 0.12))
			draw_rect(Rect2(0, h * 0.76, w, h * 0.24), Color("3c513f", 0.17))
			return
	var info: Dictionary = CampaignData.REGIONS[battle.region - 1]
	var sky := Color(str(info["sky"]))
	var ground := Color(str(info["ground"]))
	var accent := Color(str(info["accent"]))
	draw_rect(Rect2(Vector2.ZERO, size), sky)
	draw_circle(Vector2(w * 0.78, h * 0.17), 55, Color(accent, 0.65))
	for layer in 3:
		var points := PackedVector2Array()
		points.append(Vector2(0, h))
		for i in 7:
			var x := w * float(i) / 6.0
			var y := h * (0.51 + layer * 0.085) - (sin(float(i * 2 + battle.region * 3)) * 35.0 + (i % 2) * 24.0)
			points.append(Vector2(x, y))
		points.append(Vector2(w, h))
		draw_colored_polygon(points, ground.lightened(0.17 - layer * 0.06))
	for i in 7:
		var x := w * (0.05 + i * 0.15)
		var y := h * (0.50 + (i % 3) * 0.045)
		match battle.region:
			2, 5, 8:
				draw_line(Vector2(x, y), Vector2(x + 5, y - 75), ground.darkened(0.35), 13)
				draw_circle(Vector2(x + 5, y - 78), 34, Color(accent, 0.35))
			3, 6, 10:
				draw_colored_polygon(PackedVector2Array([Vector2(x - 22, y), Vector2(x + 3, y - 64), Vector2(x + 27, y)]), ground.darkened(0.38))
			4, 9:
				draw_colored_polygon(PackedVector2Array([Vector2(x - 42, y), Vector2(x + 2, y - 100), Vector2(x + 38, y)]), accent.lightened(0.2))
			_:
				draw_rect(Rect2(x - 16, y - 54, 33, 54), ground.darkened(0.4))
				draw_colored_polygon(PackedVector2Array([Vector2(x - 23, y - 54), Vector2(x, y - 77), Vector2(x + 24, y - 54)]), ground.darkened(0.55))
	draw_rect(Rect2(0, h * 0.77, w, h * 0.23), ground)
	for i in 13:
		var pos := Vector2(w * float((i * 47 + battle.region * 13) % 100) / 100.0, h * float((i * 19 + battle.region * 7) % 50) / 100.0)
		draw_circle(pos, 3.0 + i % 3, Color(accent, 0.5))
	if battle.difficulty >= 3:
		draw_rect(Rect2(Vector2.ZERO, size), Color("371c3c", 0.12 + (battle.difficulty - 3) * 0.06))

func _hero_position() -> Vector2:
	return Vector2(size.x * 0.24, size.y * 0.72)

func _enemy_position(index: int) -> Vector2:
	if PixelBattleArt.is_active(battle) and battle.enemies.size() <= 3:
		var x_positions := [0.70] if battle.enemies.size() == 1 else ([0.62, 0.84] if battle.enemies.size() == 2 else [0.52, 0.73, 0.92])
		return Vector2(size.x * float(x_positions[index]), size.y * 0.73)
	if battle != null and (str(battle.mode_config.get("mode", "campaign")) == "boss_rush" or str(battle.mode_config.get("mode", "campaign")) == "campaign" and battle.stage == 20):
		return Vector2(size.x * 0.75, size.y * 0.71)
	return Vector2(size.x * (0.59 + (index % 3) * 0.14), size.y * (0.54 + int(index / 3) * 0.20))

func _draw_hero(pos: Vector2, unit: float, flash: bool) -> void:
	var hero_id := battle.profile.selected_hero_id if battle != null and battle.profile != null else "knight"
	var hero_record: Dictionary = battle.profile.heroes[hero_id] if battle != null and battle.profile != null else {"evolution": 0}
	var form := clampi(int(hero_record.get("evolution", 0)), 0, 4) if hero_id == "knight" else 0
	var metadata := HeroArtService.metadata(form)
	if hero_visual_state == "idle":
		pos.y += sin(float(Time.get_ticks_msec()) * 0.002) * 1.5 * unit
	draw_set_transform(pos + metadata.get("offset", Vector2.ZERO) * unit, 0.0, Vector2.ONE * unit * float(metadata.get("scale", 1.0)))
	if hero_id != "knight":
		_draw_other_hero(hero_id, flash)
		draw_set_transform(Vector2.ZERO)
		return
	if float(metadata.get("aura", 0.0)) > 0.0:
		var aura_color := Color("fff0aa", float(metadata["aura"]))
		var aura_texture := HeroArtService.texture_for(form, "aura")
		if aura_texture != null:
			var aura_height := 320.0
			var aura_width := aura_height * float(aura_texture.get_width()) / float(aura_texture.get_height())
			draw_texture_rect(aura_texture, Rect2(-aura_width * 0.5, -260, aura_width, aura_height), false)
		else:
			draw_circle(Vector2(0, -102), 84 if form == 3 else 98, Color(aura_color, 0.10))
			draw_arc(Vector2(0, -100), 64 if form == 3 else 78, PI, TAU, 32, aura_color, 4 if form == 3 else 6)
	if _draw_knight_art(form):
		if flash and not PixelBattleArt.is_active(battle):
			draw_circle(Vector2(0, -100), 49 if hero_bash else 45, Color(1, 1, 1, 0.4 if hero_bash else 0.32))
		var art_ratio := battle.hero_hp / float(battle.hero["hp"]) if battle != null and not battle.hero.is_empty() else 1.0
		var pixel_squire := PixelBattleArt.is_active(battle)
		_draw_hp_bar(Vector2(-57, -380 if pixel_squire else -258), 114, art_ratio, Color("65d78c"))
		draw_string(ThemeDB.fallback_font, Vector2(-57, -392 if pixel_squire else -270), HeroData.title("knight", hero_record).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("e4eee0") if pixel_squire else Color("1d3030"))
		draw_set_transform(Vector2.ZERO)
		return
	if form >= 3:
		draw_arc(Vector2(0, -85), 80 if form == 4 else 68, 0, TAU, 36, Color("fff2a3", 0.65), 6)
	if form >= 2:
		draw_colored_polygon(PackedVector2Array([Vector2(-29, -101), Vector2(-70, -38), Vector2(-53, 38), Vector2(27, -88)]), Color("772f4c") if form == 2 else Color("f5edd4"))
	draw_ellipse_placeholder(Vector2(0, 21), Vector2(47, 12), Color("334e3a", 0.35))
	# Boots and plain trousers.
	draw_rect(Rect2(-27, -25, 20, 64), Color("514a3d"))
	draw_rect(Rect2(7, -25, 20, 64), Color("514a3d"))
	draw_rect(Rect2(-31, 28, 25, 13), Color("342d2a"))
	draw_rect(Rect2(5, 28, 27, 13), Color("342d2a"))
	# Linen tunic, leather vest and belt; no plate armor.
	draw_colored_polygon(PackedVector2Array([Vector2(-36, -100), Vector2(32, -100), Vector2(27, -24), Vector2(-33, -24)]), Color("d8cfaa"))
	draw_colored_polygon(PackedVector2Array([Vector2(-25, -96), Vector2(23, -96), Vector2(19, -28), Vector2(-22, -28)]), [Color("6d7861"), Color("84929a"), Color("526c9a"), Color("e9e4ce"), Color("fff9dd")][form])
	if form > 0:
		draw_rect(Rect2(-22, -87, 44, 42), Color("a8adb1") if form == 1 else (Color("edc873") if form >= 3 else Color("9fb7d0")), false, 6)
	draw_rect(Rect2(-27, -50, 52, 10), Color("745332"))
	draw_circle(Vector2(1, -45), 5, Color("d7b578"))
	# Exposed arms and young face.
	draw_line(Vector2(-30, -88), Vector2(-43, -52), Color("ddb792"), 15)
	draw_line(Vector2(26, -88), Vector2(41, -58), Color("ddb792"), 15)
	draw_circle(Vector2(0, -126), 25, Color("e4bf9a"))
	draw_colored_polygon(PackedVector2Array([Vector2(-26, -132), Vector2(-21, -153), Vector2(-5, -160), Vector2(21, -151), Vector2(27, -131), Vector2(14, -142), Vector2(-7, -138)]), Color("1c2223"))
	draw_circle(Vector2(-8, -126), 2, Color("26302a"))
	draw_circle(Vector2(8, -126), 2, Color("26302a"))
	# Simple iron sword and small wooden shield.
	draw_line(Vector2(40, -59), Vector2(89 if form >= 2 else 81, -155 if form >= 2 else -141), Color("fff5b5") if form >= 3 else Color("b9c5c7"), 14 if form == 4 else 10)
	draw_line(Vector2(38, -66), Vector2(55, -58), Color("7c5938"), 7)
	draw_colored_polygon(PackedVector2Array([Vector2(-64, -84), Vector2(-34, -92), Vector2(-27, -69), Vector2(-34, -42), Vector2(-52, -31), Vector2(-68, -52)]), Color("785337") if form == 0 else (Color("d9b761") if form >= 3 else Color("8797a2")))
	draw_line(Vector2(-56, -78), Vector2(-48, -40), Color("b99059"), 4)
	draw_circle(Vector2(-48, -65), 6, Color("c8b88b"))
	if flash:
		draw_circle(Vector2(0, -91), 45, Color(1, 1, 1, 0.5))
	var ratio := battle.hero_hp / float(battle.hero["hp"]) if battle != null and not battle.hero.is_empty() else 1.0
	_draw_hp_bar(Vector2(-57, -190), 114, ratio, Color("65d78c"))
	draw_string(ThemeDB.fallback_font, Vector2(-57, -202), HeroData.title("knight", hero_record).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16 if form >= 2 else 20, Color("1d3030"))
	draw_set_transform(Vector2.ZERO)

func _update_pixel_hero_sprite(pos: Vector2, unit: float, allow_visible: bool = true) -> void:
	var active := allow_visible and unit > 0.0 and PixelBattleArt.is_active(battle)
	if not active:
		if pixel_hero_sprite != null:
			pixel_hero_sprite.visible = false
		return
	if pixel_hero_sprite == null:
		pixel_hero_sprite = Sprite2D.new()
		pixel_hero_sprite.name = "PixelSquireSprite"
		pixel_hero_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pixel_hero_sprite.z_index = 1
		add_child(pixel_hero_sprite)
	var state := "guard" if hero_guard_art_time > 0.0 else "attack" if hero_attack_art_time > 0.0 else "idle"
	pixel_hero_sprite.texture = PixelBattleArt.frame_texture(PixelBattleArt.hero_sheet(), state, "squire")
	pixel_hero_sprite.position = pos + Vector2(0.0, -158.0 * unit)
	var form_scale := float(HeroArtService.metadata(0).get("scale", 1.0))
	pixel_hero_sprite.scale = Vector2(370.0 / 256.0, 392.0 / 256.0) * unit * form_scale
	pixel_hero_sprite.modulate = Color.WHITE
	pixel_hero_sprite.visible = true

func _update_pixel_enemy_sprite(index: int, pos: Vector2, enemy: Dictionary, state: String, unit: float, opacity: float = 1.0, shrink: float = 1.0) -> void:
	var kind := str(enemy.get("visual", enemy.get("kind", "")))
	var sheet: Texture2D = PixelBattleArt.enemy_sheet(kind) if PixelBattleArt.is_active(battle) else null
	if sheet == null:
		_sync_pixel_enemy_visibility(index, false)
		return
	while pixel_enemy_sprites.size() <= index:
		var sprite := Sprite2D.new()
		sprite.name = "PixelEnemySprite%d" % pixel_enemy_sprites.size()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = 1
		add_child(sprite)
		pixel_enemy_sprites.append(sprite)
	var sprite := pixel_enemy_sprites[index]
	var boss_scale := 1.65 if str(enemy.get("archetype", "")) == "BOSS" else 1.0
	var elite_scale := 1.2 if str(enemy.get("archetype", "")) == "ELITE" else 1.0
	var actor_scale := unit * boss_scale * elite_scale * shrink
	sprite.texture = PixelBattleArt.frame_texture(sheet, state, "enemy:%s" % kind)
	sprite.position = pos + Vector2(0.0, -151.0 * actor_scale)
	sprite.scale = Vector2.ONE * (350.0 / 256.0) * actor_scale
	sprite.modulate = Color(1.0, 1.0, 1.0, opacity)
	sprite.visible = true

func _sync_pixel_enemy_visibility(index: int, visible: bool) -> void:
	if index >= 0 and index < pixel_enemy_sprites.size():
		pixel_enemy_sprites[index].visible = visible

func _draw_knight_art(form: int) -> bool:
	var state := "guard" if hero_guard_art_time > 0.0 else "attack" if hero_attack_art_time > 0.0 else "idle"
	if form == 0 and PixelBattleArt.is_active(battle):
		return PixelBattleArt.hero_sheet() != null
	var texture: Texture2D = null
	if form == 0:
		texture = squire_guard_texture if state == "guard" else squire_attack_texture if state == "attack" else squire_idle_texture
	else:
		texture = HeroArtService.texture_for(form, state)
	if texture == null:
		return false
	var art_height := 285.0 * float(HeroArtService.metadata(form).get("portrait_scale", 1.0))
	var art_width := art_height * float(texture.get_width()) / float(texture.get_height())
	draw_texture_rect(texture, Rect2(-art_width * 0.5, 38.0 - art_height, art_width, art_height), false)
	return true

func _draw_squire_art() -> bool:
	return _draw_knight_art(0)

func _draw_other_hero(id: String, flash: bool) -> void:
	var robe := Color("5363a3") if id == "mage" else (Color("576b46") if id == "ranger" else (Color("393947") if id == "assassin" else Color("423551")))
	var accent := Color("85d9ec") if id == "mage" else (Color("c5a568") if id == "ranger" else (Color("a27bb2") if id == "assassin" else Color("8cc977")))
	draw_ellipse_placeholder(Vector2(0, 21), Vector2(47, 12), Color("334e3a", 0.35))
	draw_line(Vector2(-16, -25), Vector2(-21, 36), robe.darkened(0.4), 20)
	draw_line(Vector2(16, -25), Vector2(21, 36), robe.darkened(0.4), 20)
	draw_colored_polygon(PackedVector2Array([Vector2(-34, -97), Vector2(34, -97), Vector2(43, 16), Vector2(-43, 16)]), robe)
	draw_line(Vector2(-31, -81), Vector2(-47, -43), robe.lightened(0.18), 15)
	draw_line(Vector2(31, -81), Vector2(48, -43), robe.lightened(0.18), 15)
	draw_circle(Vector2(0, -126), 25, Color("dbb38f"))
	draw_colored_polygon(PackedVector2Array([Vector2(-29, -134), Vector2(-18, -156), Vector2(16, -156), Vector2(31, -132), Vector2(11, -144), Vector2(-14, -143)]), robe.darkened(0.42))
	if id == "ranger":
		draw_arc(Vector2(56, -91), 46, -PI * 0.48, PI * 0.48, 18, accent, 5)
		draw_line(Vector2(59, -137), Vector2(59, -45), Color("d6dfd0"), 2)
	elif id == "assassin":
		draw_line(Vector2(-48, -47), Vector2(-73, -106), accent, 8)
		draw_line(Vector2(48, -47), Vector2(74, -106), accent, 8)
	else:
		draw_line(Vector2(48, -42), Vector2(59, -158), accent, 7)
		draw_circle(Vector2(59, -163), 12, accent)
	if flash:
		draw_circle(Vector2(0, -85), 46, Color(1, 1, 1, 0.4))
	var ratio := battle.hero_hp / float(battle.hero["hp"]) if battle != null and not battle.hero.is_empty() else 1.0
	_draw_hp_bar(Vector2(-57, -190), 114, ratio, Color("65d78c"))
	draw_string(ThemeDB.fallback_font, Vector2(-56, -202), HeroData.title(id, battle.profile.heroes[id]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("1d3030"))

func _draw_hero_projectiles(unit: float) -> void:
	for projectile in hero_projectiles:
		var target := int(projectile["target"])
		var progress := clampf(float(projectile["age"]) / 0.22, 0.0, 1.0)
		var origin := _hero_position() + Vector2(35, -90) * unit
		var destination := _enemy_position(target) + Vector2(0, -85) * unit
		var pos := origin.lerp(destination, progress)
		var style := str(projectile["style"])
		if style == "arrow":
			draw_line(pos - Vector2(22, 2) * unit, pos + Vector2(15, -2) * unit, Color("e8d4a2"), 5 * unit)
			draw_colored_polygon(PackedVector2Array([pos + Vector2(20, -2) * unit, pos + Vector2(10, -9) * unit, pos + Vector2(10, 5) * unit]), Color("edf2e7"))
		else:
			var color := Color("91ebf5") if style == "magic" else Color("a375d2")
			draw_line(origin.lerp(destination, maxf(0.0, progress - 0.12)), pos, color.darkened(0.2), 7 * unit)
			draw_circle(pos, 12 * unit, color)

func enemy_visual_state(index: int) -> String:
	if float(enemy_hit_times.get(index, 0.0)) > 0.0:
		return "hit"
	if float(enemy_attack_times.get(index, 0.0)) > 0.0:
		return "attack"
	return "idle"

func _draw_enemy(pos: Vector2, enemy: Dictionary, unit: float, flash: bool, enemy_index: int = -1) -> void:
	var kind := str(enemy.get("visual", enemy["kind"]))
	var boss := str(enemy.get("archetype", "")) == "BOSS" or kind == "Goblin Warlord"
	var enemy_state := enemy_visual_state(enemy_index)
	var art_meta := EnemyArtService.metadata(kind)
	var elite_scale := 1.2 if str(enemy.get("archetype", "")) == "ELITE" else 1.0
	var boss_scale := 1.65 if boss else 1.0
	var actor_scale := unit * elite_scale * boss_scale
	draw_set_transform(pos, 0.0, Vector2.ONE * actor_scale)
	if int(enemy.get("difficulty", 0)) >= 3:
		draw_arc(Vector2(0, -70), 65, 0, TAU, 24, Color("e3548b", 0.28 + 0.12 * (int(enemy["difficulty"]) - 3)), 7)
	draw_ellipse_placeholder(Vector2(0, 15), Vector2(39, 10), Color("314d37", 0.33))
	var art_region := int(enemy.get("region", battle.region if battle != null and str(battle.mode_config.get("mode", "campaign")) == "campaign" else 0))
	var pixel_sheet: Texture2D = PixelBattleArt.enemy_sheet(kind) if PixelBattleArt.is_active(battle) else null
	var enemy_texture := EnemyArtService.presentation_texture_for(kind, enemy_state, art_region) if pixel_sheet == null else null
	var art_size := Vector2.ZERO
	if pixel_sheet != null:
		art_size = Vector2(350.0, 350.0)
	elif enemy_texture != null:
		var art_height := 240.0 * float(art_meta.get("scale", 0.82))
		art_size = Vector2(art_height * float(enemy_texture.get_width()) / float(enemy_texture.get_height()), art_height)
		var width_cap := 500.0 if boss else (320.0 if elite_scale > 1.0 else 280.0)
		if art_size.x > width_cap:
			art_size *= width_cap / art_size.x
		if bool(art_meta.get("flip_h", false)):
			draw_set_transform(pos, 0.0, Vector2(-actor_scale, actor_scale))
		draw_texture_rect(enemy_texture, Rect2(Vector2(-art_size.x * 0.5, 24.0 - art_size.y) + Vector2(art_meta.get("offset", Vector2.ZERO)), art_size), false)
		if bool(art_meta.get("flip_h", false)):
			draw_set_transform(pos, 0.0, Vector2.ONE * actor_scale)
	elif boss and enemy.has("region") and kind != "Goblin Warlord":
		_draw_region_boss(enemy)
	else:
		match str(enemy.get("family", kind)):
			"skeleton": _draw_skeleton(Color(enemy.get("color", Color("ebe4ce"))) if enemy.has("region") else Color("ebe4ce"))
			"wolf": _draw_wolf(Color(enemy.get("color", Color("715675"))) if enemy.has("region") else Color("715675"))
			"archer": _draw_archer(Color(enemy.get("color", Color("87ba67"))) if enemy.has("region") else Color("87ba67"))
			"goblin":
				if kind == "Goblin Warlord": _draw_warlord()
				else: _draw_goblin(Color(enemy.get("color", Color("78b05e"))) if enemy.has("region") else Color("78b05e"))
			"dragon", "demon", "beast", "knight", "humanoid": _draw_campaign_creature(enemy)
			_:
				match kind:
					"Goblin Warlord": _draw_warlord()
					_: _draw_campaign_creature(enemy)
	if enemy.has("region"):
		draw_circle(Vector2(0, -82), 43, Color(enemy["color"], 0.14))
		if int(enemy.get("difficulty", 0)) == 1:
			draw_arc(Vector2(0, -76), 49, PI * 0.15, PI * 0.85, 12, Color(enemy["color"], 0.55), 4)
		if int(enemy.get("difficulty", 0)) >= 2:
			draw_rect(Rect2(-23, -70, 46, 14), Color("252733", 0.48))
			draw_circle(Vector2(-10, -99), 4, Color("ff547c"))
			draw_circle(Vector2(10, -99), 4, Color("ff547c"))
		if int(enemy.get("difficulty", 0)) >= 4:
			draw_arc(Vector2(0, -75), 56, PI * 0.1, PI * 0.9, 15, Color("ff704f", 0.7), 5)
		if str(enemy.get("archetype", "")) == "TREASURE":
			draw_arc(Vector2(0, -91), 50, 0, TAU, 20, Color("ffdf80"), 6)
	if (flash or enemy_state == "hit") and pixel_sheet == null:
		draw_circle(Vector2(0, -62), 47, Color(1, 1, 1, 0.20 if vfx.reduced else 0.4))
	var bar_width := 125.0 if boss else 85.0
	var pixel_enemy := pixel_sheet != null
	_draw_hp_bar(Vector2(-bar_width * 0.5, -374 if pixel_enemy else (-250 if boss else -116)), bar_width, float(enemy["current_hp"]) / float(enemy["hp"]), Color("eb6f67"))
	if boss:
		draw_string(ThemeDB.fallback_font, Vector2(-90, -265), kind.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("f8dfbc"))
	draw_set_transform(Vector2.ZERO)

func _draw_defeated_enemy(pos: Vector2, enemy: Dictionary, unit: float, ratio: float) -> void:
	var kind := str(enemy.get("visual", enemy.get("kind", "")))
	var pixel_sheet: Texture2D = PixelBattleArt.enemy_sheet(kind) if PixelBattleArt.is_active(battle) else null
	if pixel_sheet != null:
		var pixel_height := 300.0 * (1.0 - ratio * 0.45)
		draw_set_transform(pos, 0.0, Vector2.ONE * unit * (1.0 - ratio * 0.45))
		draw_texture_rect_region(pixel_sheet, Rect2(Vector2(-pixel_height * 0.5, 24.0 - pixel_height), Vector2(pixel_height, pixel_height)), PixelBattleArt.frame_region(pixel_sheet, "idle"), Color(1, 1, 1, 1.0 - ratio))
		draw_set_transform(Vector2.ZERO)
		return
	var texture := EnemyArtService.presentation_texture_for(kind, "idle", int(enemy.get("region", battle.region)))
	if texture == null:
		return
	var meta := EnemyArtService.metadata(kind)
	var actor_scale := unit * float(meta.get("scale", 0.82)) * (1.65 if str(enemy.get("archetype", "")) == "BOSS" else 1.0) * (1.0 - ratio * 0.45)
	var height := 240.0 * float(meta.get("scale", 0.82)) * (1.0 - ratio * 0.45)
	var width := height * float(texture.get_width()) / float(texture.get_height())
	var flip_scale := -actor_scale if bool(meta.get("flip_h", false)) else actor_scale
	draw_set_transform(pos, 0.0, Vector2(flip_scale, actor_scale))
	draw_texture_rect(texture, Rect2(Vector2(-width * 0.5, 24.0 - height), Vector2(width, height)), false, Color(1, 1, 1, 1.0 - ratio))
	draw_set_transform(Vector2.ZERO)

func _draw_campaign_creature(enemy: Dictionary) -> void:
	var color: Color = enemy.get("color", Color("8d9b85"))
	var family := str(enemy.get("family", "humanoid"))
	var role := str(enemy.get("archetype", "MELEE"))
	match family:
		"dragon":
			draw_colored_polygon(PackedVector2Array([Vector2(-45,-74),Vector2(-92,-128),Vector2(-74,-31),Vector2(-10,-51)]), color.darkened(0.3))
			draw_colored_polygon(PackedVector2Array([Vector2(35,-74),Vector2(92,-128),Vector2(72,-31),Vector2(10,-51)]), color.darkened(0.3))
			draw_rect(Rect2(-31,-75,62,66), color)
			draw_circle(Vector2(0,-93), 29, color.lightened(0.13))
			for x in [-20,0,20]:
				draw_colored_polygon(PackedVector2Array([Vector2(x-8,-111),Vector2(x,-146),Vector2(x+8,-111)]), color.lightened(0.35))
		"beast":
			draw_ellipse_placeholder(Vector2(0,-45), Vector2(45,29), color)
			for x in [-25,25]:
				draw_line(Vector2(x,-34),Vector2(x*1.7,16),color.darkened(0.25),9)
			draw_circle(Vector2(-24,-72), 22, color.lightened(0.1))
		"demon":
			draw_rect(Rect2(-27,-80,54,65), color.darkened(0.25))
			draw_circle(Vector2(0,-102), 26, color)
			draw_colored_polygon(PackedVector2Array([Vector2(-24,-112),Vector2(-32,-153),Vector2(-5,-126)]), color.darkened(0.35))
			draw_colored_polygon(PackedVector2Array([Vector2(24,-112),Vector2(32,-153),Vector2(5,-126)]), color.darkened(0.35))
			draw_circle(Vector2(-10,-105), 5, Color("ffdf85"))
			draw_circle(Vector2(10,-105), 5, Color("ffdf85"))
		_:
			draw_rect(Rect2(-26,-76,52,64), color.darkened(0.23))
			draw_circle(Vector2(0,-97), 24, color.lightened(0.2))
			if family == "knight" or role == "TANK":
				draw_rect(Rect2(-29,-110,58,24), color.darkened(0.5))
				draw_rect(Rect2(-26,-70,52,50), color.lightened(0.1), false, 6)
			elif role == "MAGIC" or role == "HEALER":
				draw_colored_polygon(PackedVector2Array([Vector2(-33,-107),Vector2(0,-154),Vector2(35,-107)]), color.darkened(0.4))
	for x in [-15,15]:
		draw_line(Vector2(x,-15),Vector2(x+3,20),color.darkened(0.37),12)
	if family != "demon":
		draw_circle(Vector2(-9,-99), 3, Color("f8d58e"))
		draw_circle(Vector2(9,-99), 3, Color("f8d58e"))
	if role in ["RANGED", "MAGIC", "HEALER"]:
		draw_line(Vector2(30,-67),Vector2(48,-121),color.lightened(0.35),6)
		draw_circle(Vector2(48,-125), 9, Color("c4d9ec"))
	else:
		draw_line(Vector2(26,-66),Vector2(53,-33),color.darkened(0.3),9)
		draw_line(Vector2(53,-33),Vector2(75,-65),Color("d8d9d1"),5)

func _draw_region_boss(enemy: Dictionary) -> void:
	var color: Color = enemy["color"]
	var region_id := int(enemy["region"])
	match region_id:
		2:
			draw_rect(Rect2(-35,-115,70,130), color.darkened(0.55))
			for side in [-1,1]:
				draw_line(Vector2(side*25,-90),Vector2(side*78,-153),color.darkened(0.5),15)
				draw_circle(Vector2(side*78,-154),28,color.darkened(0.15))
			draw_circle(Vector2(0,-151),42,color.darkened(0.1))
		3, 4:
			_draw_campaign_creature(enemy)
			draw_colored_polygon(PackedVector2Array([Vector2(-20,-118),Vector2(-36,-166),Vector2(-2,-125)]),color.lightened(0.3))
			draw_colored_polygon(PackedVector2Array([Vector2(20,-118),Vector2(36,-166),Vector2(2,-125)]),color.lightened(0.3))
		5:
			draw_ellipse_placeholder(Vector2(0,-25),Vector2(52,38),color.darkened(0.3))
			for side in [-1,0,1]:
				draw_line(Vector2(side*24,-50),Vector2(side*37,-115-abs(side)*15),color,18)
				draw_circle(Vector2(side*37,-126-abs(side)*15),20,color.lightened(0.1))
		6:
			draw_arc(Vector2(0,-45),70,PI*0.1,PI*1.75,25,color,25)
			draw_circle(Vector2(64,-30),28,color.lightened(0.1))
			draw_colored_polygon(PackedVector2Array([Vector2(50,-50),Vector2(71,-87),Vector2(76,-42)]),color.darkened(0.2))
		7:
			_draw_campaign_creature(enemy)
			draw_colored_polygon(PackedVector2Array([Vector2(-28,-121),Vector2(-22,-159),Vector2(0,-139),Vector2(21,-159),Vector2(29,-121)]),Color("e7b96a"))
		8:
			draw_colored_polygon(PackedVector2Array([Vector2(-15,-140),Vector2(15,-140),Vector2(68,13),Vector2(-68,13)]),color.darkened(0.55))
			draw_circle(Vector2(0,-122),26,color.darkened(0.2))
			draw_arc(Vector2(0,-92),65,0,TAU,24,color.lightened(0.35),5)
		9:
			_draw_campaign_creature(enemy)
			draw_arc(Vector2(0,-75),83,PI*0.1,PI*0.9,18,Color("f8cf78"),7)
		10:
			_draw_campaign_creature(enemy)
			draw_colored_polygon(PackedVector2Array([Vector2(-54,-73),Vector2(-102,-147),Vector2(-86,-25)]),color.darkened(0.4))
			draw_colored_polygon(PackedVector2Array([Vector2(54,-73),Vector2(102,-147),Vector2(86,-25)]),color.darkened(0.4))
		_:
			_draw_campaign_creature(enemy)
	if region_id != 8:
		draw_circle(Vector2(-11,-103),5,Color("fff2ba"))
		draw_circle(Vector2(11,-103),5,Color("fff2ba"))

func _draw_goblin(skin: Color = Color("78b05e")) -> void:
	draw_line(Vector2(-12, -28), Vector2(-16, 24), Color("5e6940"), 13)
	draw_line(Vector2(12, -28), Vector2(17, 24), Color("5e6940"), 13)
	draw_rect(Rect2(-26, -80, 51, 56), Color("805c3d"))
	draw_circle(Vector2(0, -97), 28, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-22, -102), Vector2(-56, -119), Vector2(-34, -84)]), skin)
	draw_colored_polygon(PackedVector2Array([Vector2(22, -102), Vector2(55, -119), Vector2(34, -84)]), skin)
	draw_circle(Vector2(-10, -98), 4, Color("3a332b"))
	draw_circle(Vector2(10, -98), 4, Color("3a332b"))
	draw_line(Vector2(25, -71), Vector2(49, -37), Color("735c42"), 10)
	draw_line(Vector2(49, -37), Vector2(69, -68), Color("b9b6a7"), 6)

func _draw_skeleton(bone: Color = Color("ebe4ce")) -> void:
	draw_line(Vector2(-11, -30), Vector2(-18, 25), bone, 11)
	draw_line(Vector2(11, -30), Vector2(18, 25), bone, 11)
	draw_line(Vector2(0, -80), Vector2(0, -30), bone, 9)
	for i in 3:
		var y := -75 + i * 14
		draw_line(Vector2(-23, y), Vector2(23, y), bone, 6)
	draw_line(Vector2(-18, -76), Vector2(-37, -41), bone, 9)
	draw_line(Vector2(18, -76), Vector2(42, -37), bone, 9)
	draw_circle(Vector2(0, -103), 27, bone)
	draw_rect(Rect2(-15, -91, 30, 12), bone)
	draw_circle(Vector2(-10, -106), 6, Color("34413f"))
	draw_circle(Vector2(10, -106), 6, Color("34413f"))
	draw_line(Vector2(0, -99), Vector2(0, -92), Color("34413f"), 4)

func _draw_wolf(fur: Color = Color("715675")) -> void:
	draw_line(Vector2(25, -57), Vector2(66, -91), fur.darkened(0.2), 16)
	draw_colored_polygon(PackedVector2Array([Vector2(-38, -81), Vector2(23, -86), Vector2(47, -61), Vector2(16, -42), Vector2(-42, -43)]), fur)
	for x in [-24, -2, 23, 39]:
		draw_line(Vector2(x, -45), Vector2(x + 5, 16), fur.darkened(0.27), 10)
	draw_circle(Vector2(-42, -93), 24, fur)
	draw_colored_polygon(PackedVector2Array([Vector2(-63, -104), Vector2(-59, -136), Vector2(-40, -111)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(-41, -110), Vector2(-22, -138), Vector2(-23, -100)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(-58, -87), Vector2(-85, -78), Vector2(-60, -68)]), fur.darkened(0.17))
	draw_circle(Vector2(-49, -98), 4, Color("f67b84"))
	draw_line(Vector2(-45, -72), Vector2(-18, -73), Color("bd6b87"), 4)

func _draw_archer(skin: Color = Color("87ba67")) -> void:
	draw_line(Vector2(-12, -28), Vector2(-15, 22), Color("4e6540"), 12)
	draw_line(Vector2(12, -28), Vector2(16, 22), Color("4e6540"), 12)
	draw_rect(Rect2(-24, -82, 48, 58), Color("536b45"))
	draw_circle(Vector2(0, -98), 26, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(-32, -95), Vector2(-21, -134), Vector2(2, -145), Vector2(28, -122), Vector2(32, -94)]), Color("355b3d"))
	draw_colored_polygon(PackedVector2Array([Vector2(-24, -102), Vector2(-49, -115), Vector2(-30, -84)]), skin)
	draw_circle(Vector2(-8, -98), 3, Color("26382f"))
	draw_circle(Vector2(9, -98), 3, Color("26382f"))
	draw_arc(Vector2(49, -72), 45, -PI * 0.49, PI * 0.49, 22, Color("9a6a3d"), 6)
	draw_line(Vector2(53, -117), Vector2(53, -27), Color("d9d3b8"), 2)
	draw_line(Vector2(19, -72), Vector2(82, -72), Color("c5b892"), 4)
	draw_colored_polygon(PackedVector2Array([Vector2(85, -72), Vector2(70, -81), Vector2(70, -63)]), Color("c9d4d0"))

func _draw_warlord() -> void:
	_draw_goblin()
	draw_rect(Rect2(-31, -83, 62, 18), Color("9b7243"))
	draw_colored_polygon(PackedVector2Array([Vector2(-25, -119), Vector2(-24, -148), Vector2(-8, -133), Vector2(0, -154), Vector2(9, -133), Vector2(25, -148), Vector2(26, -119)]), Color("c79b4e"))
	draw_circle(Vector2(0, -132), 6, Color("d86b5d"))
	draw_line(Vector2(52, -55), Vector2(81, -116), Color("665341"), 10)
	draw_colored_polygon(PackedVector2Array([Vector2(70, -124), Vector2(95, -143), Vector2(109, -116), Vector2(91, -96)]), Color("adb1a4"))

func _draw_effects(unit: float) -> void:
	vfx.draw(self, unit, battle)
	for death in deaths:
		var ratio := float(death["age"]) / float(death["life"])
		var color := Color("b7e6a8", 0.7 * (1.0 - ratio))
		draw_arc(death["pos"], (20 + ratio * 85) * unit, 0, TAU, 24, color, 7 * unit)
		for i in 3:
			var coin_color := Color("f5cf72", 1.0 - ratio)
			var coin_pos: Vector2 = death["pos"] + Vector2((i - 1) * (26 + ratio * 32) * unit, (-18 - ratio * (45 + i * 9)) * unit)
			draw_circle(coin_pos, 8 * unit, coin_color)
			draw_circle(coin_pos, 4 * unit, Color("fff0ac", 1.0 - ratio))
	for floater in floaters:
		var ratio := float(floater["age"]) / float(floater["life"])
		var pos: Vector2 = floater["pos"] + Vector2(0, -ratio * 74 * unit)
		var color: Color = floater["color"]
		color.a = 1.0 - ratio
		var font_size := roundi(float(floater["size"]) * unit)
		var x_offset := -ThemeDB.fallback_font.get_string_size(str(floater["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * 0.5 if bool(floater.get("centered", false)) else -70.0 * unit
		draw_string(ThemeDB.fallback_font, pos + Vector2(x_offset, 0), str(floater["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_hp_bar(pos: Vector2, width: float, ratio: float, color: Color) -> void:
	draw_rect(Rect2(pos, Vector2(width, 10)), Color("233934"))
	draw_rect(Rect2(pos + Vector2(2, 2), Vector2((width - 4) * clampf(ratio, 0.0, 1.0), 6)), color)

func draw_ellipse_placeholder(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var angle := TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
