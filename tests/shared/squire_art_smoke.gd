extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error("SQUIRE ART: " + label)

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	var profile := main.get("profile") as SaveData
	profile.save_path = "res://.godot/squire_art_smoke.save"
	profile.last_login_reward_date = CalendarService.day()
	(main.get("battle") as BattleController).active = false
	var field := main.get("battlefield") as Battlefield
	_check(field.squire_idle_texture != null and field.squire_attack_texture != null and field.squire_guard_texture != null, "battle textures loaded")
	_check(SquireArt.load_texture(SquireArt.PORTRAIT_PATH) != null, "portrait texture loaded")
	_check(SquireArt.load_texture("res://assets/characters/heroes/standard/knight/squire/missing.png") == null, "missing asset returns null")
	field._on_attack_started(-1, 0)
	_check(field.hero_attack_art_time > 0.0, "normal attack starts temporary art state")
	field._process(0.30)
	_check(field.hero_attack_art_time == 0.0, "attack returns to idle")
	field._on_damage_popup(-1, 1, false, false)
	_check(field.hero_guard_art_time > 0.0, "hero hit starts guard art state")
	field._process(0.31)
	_check(field.hero_guard_art_time == 0.0, "guard returns to idle")
	field.squire_idle_texture = null
	_check(not field._draw_squire_art(), "procedural fallback when image is missing")
	print("SQUIRE ART SMOKE: ", "FAIL (%d)" % failures if failures else "PASS")
	quit(1 if failures else 0)
