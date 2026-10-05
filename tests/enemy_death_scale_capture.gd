extends SceneTree

const CAPTURE_DIR := "res://.godot/enemy_death_scale_captures"
const SMALL := Vector2i(360, 640)
const LARGE := Vector2i(1080, 1920)
const NORMALS := [
	{"region": 1, "kind": "Goblin", "label": "humanoid"},
	{"region": 1, "kind": "Corrupted Wolf", "label": "quadruped"},
	{"region": 8, "kind": "Shade", "label": "flying"},
	{"region": 2, "kind": "Forest Brute", "label": "wide_low"},
	{"region": 1, "kind": "Goblin Archer", "label": "ranged"},
	{"region": 1, "kind": "Goblin Captain", "label": "elite"}
]
const BOSSES := [
	{"region": 1, "kind": "Goblin Warlord"},
	{"region": 2, "kind": "Ancient Treant"},
	{"region": 9, "kind": "Ancient Dragon"},
	{"region": 10, "kind": "Demon Lord"}
]

var main: Control
var profile: SaveData
var battle: BattleController
var field: Battlefield
var failures := 0

func _initialize() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/enemy_death_scale_capture.save")
	call_deferred("_run")

func _run() -> void:
	if root.get_texture() == null:
		push_error("Enemy death captures require a graphical viewport; do not use --headless.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	profile = main.get("profile") as SaveData
	profile.save_path = "res://.godot/enemy_death_scale_capture.save"
	profile.tutorial_state.completed = true
	profile.tutorial_state.skipped = true
	battle = main.get("battle") as BattleController
	field = main.get("battlefield") as Battlefield
	main.call("_select_tab", "Battle")
	for popup in ["tutorial_popup", "offline_popup", "login_popup"]:
		var node = main.get(popup)
		if node is Window or node is Control:
			node.hide()
	for sample in NORMALS:
		for phase in ["before", "first", "middle", "final"]:
			_set_normal(sample, phase)
			await _capture("%s_%s_360x640" % [sample.label, phase], SMALL)
	for sample in BOSSES:
		for phase in ["before", "first", "middle", "final"]:
			_set_boss(sample, phase)
			await _capture("%s_%s_360x640" % [str(sample.kind).to_snake_case(), phase], SMALL)
	for sample in [{"region": 1, "kind": "Goblin Captain", "label": "elite"}, {"region": 10, "kind": "Demon Lord", "label": "boss"}]:
		_set_single(sample.region, sample.kind, "middle")
		await _capture("%s_death_middle_1080x1920" % sample.label, LARGE)
	main.queue_free()
	print("ENEMY DEATH SCALE CAPTURES: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _set_normal(sample: Dictionary, phase: String) -> void:
	var region := int(sample.region)
	var kind := str(sample.kind)
	profile.region = region
	profile.stage = 1
	battle.region = region
	battle.stage = 1
	battle.wave = 1
	battle.mode_config = {"mode": "campaign"}
	battle.start(profile)
	battle.active = false
	battle.enemies.clear()
	var enemy := CampaignData.enemy_stats(kind, 0, region, 1, 1)
	enemy.current_hp = 0 if phase != "before" else enemy.hp
	enemy.spawned = true
	enemy.combat_ready = true
	enemy.entry_time = 0.0
	enemy.attack_time = 10.0
	battle.enemies.append(enemy)
	for filler_kind in CampaignData.wave_kinds(region, 1, 1):
		if battle.enemies.size() >= 7:
			break
		if str(filler_kind) == kind:
			continue
		var filler := CampaignData.enemy_stats(str(filler_kind), 0, region, 1, 1)
		filler.current_hp = filler.hp
		filler.spawned = true
		filler.combat_ready = true
		filler.entry_time = 0.0
		filler.attack_time = 10.0
		battle.enemies.append(filler)
	_finish_setup(phase)

func _set_boss(sample: Dictionary, phase: String) -> void:
	_set_single(int(sample.region), str(sample.kind), phase)

func _set_single(region: int, kind: String, phase: String) -> void:
	profile.region = region
	profile.stage = 20
	battle.region = region
	battle.stage = 20
	battle.wave = 1
	battle.mode_config = {"mode": "campaign"}
	battle.start(profile)
	battle.active = false
	battle.enemies.clear()
	var enemy := CampaignData.enemy_stats(kind, 0, region, 20, 1)
	enemy.current_hp = 0 if phase != "before" else enemy.hp
	enemy.spawned = true
	enemy.combat_ready = true
	enemy.entry_time = 0.0
	enemy.attack_time = 10.0
	battle.enemies.append(enemy)
	_finish_setup(phase)

func _finish_setup(phase: String) -> void:
	field.deaths.clear()
	field.set_process(false)
	field.enemy_attack_times.clear()
	field.enemy_hit_times.clear()
	battle.changed.emit()
	if phase != "before":
		var life := 0.62
		if battle.stage == 20 and str(battle.enemies[0].get("archetype", "")) == "BOSS":
			life = float(EnemyArtService.metadata(str(battle.enemies[0].get("kind", ""))).get("death_duration", 1.0))
		var ratio := 0.02 if phase == "first" else (0.5 if phase == "middle" else 0.94)
		var pos: Vector2 = field._enemy_position(0)
		field.deaths.append({"pos": pos + Vector2(0, -50), "index": 0, "age": life * ratio, "life": life})
	field.queue_redraw()

func _capture(name: String, resolution: Vector2i) -> void:
	DisplayServer.window_set_size(resolution)
	for _i in 4:
		await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != resolution:
		failures += 1
		push_error("Invalid enemy death capture: " + name)
		return
	if image.save_png("%s/%s.png" % [CAPTURE_DIR, name]) != OK:
		failures += 1
		push_error("Could not save enemy death capture: " + name)
		return
	print("Captured " + name)
