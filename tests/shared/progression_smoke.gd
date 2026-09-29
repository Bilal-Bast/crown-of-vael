extends SceneTree

const TEST_SAVE := "res://.godot/phase2_progression_smoke.save"

var profile: SaveData
var battle: BattleController
var cleared_stages: Array[int] = []
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	profile = SaveData.new()
	profile.save_path = TEST_SAVE
	battle = BattleController.new()
	root.add_child(battle)
	battle.stage_cleared.connect(_on_stage_cleared)
	battle.battle_lost.connect(_on_battle_lost)
	battle.start(profile)
	for step in 12000:
		if profile.stage >= 4 or failed:
			break
		battle._process(0.05)
	if failed or cleared_stages != [1, 2, 3] or profile.stage != 4:
		push_error("Progression smoke test failed: cleared=%s, stage=%d, failed=%s" % [str(cleared_stages), profile.stage, failed])
		quit(1)
		return
	var file := FileAccess.open(TEST_SAVE, FileAccess.READ)
	if file == null:
		push_error("Progression smoke test could not read its save.")
		quit(1)
		return
	var saved: Dictionary = JSON.parse_string(file.get_as_text())
	if int(saved.get("stage", 0)) != 4 or int(saved.get("gold", 0)) <= 0:
		push_error("Progression smoke test saved invalid data: %s" % str(saved))
		quit(1)
		return
	print("PASS: Easy 1-1, 1-2, and 1-3 cleared; Easy 1-4 saved. Level %d, Gold %d." % [profile.level, profile.gold])
	quit()

func _on_stage_cleared() -> void:
	cleared_stages.append(profile.stage)
	profile.stage += 1
	profile.save()
	if profile.stage <= 3:
		battle.start(profile)

func _on_battle_lost(_boss_failure: bool) -> void:
	failed = true
