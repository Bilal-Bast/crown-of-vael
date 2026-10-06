extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	var profile := main.get("profile") as SaveData
	for id in CompanionData.COMPANIONS:
		profile.companions[id] = {"level": 4, "rarity": 3, "stars": 2, "evolution": 0, "pieces": 1}
	for id in SkillData.SKILLS:
		profile.skills[id] = {"level": 2, "duplicates": 1, "rarity": int(SkillData.SKILLS[id]["rarity"])}
	for id in ArtifactData.ARTIFACTS:
		profile.artifacts[id] = {"level": 3, "duplicates": 1, "rarity": 4}
	profile.inventory.clear()
	for kind in EquipmentData.STARTER_KINDS:
		profile.inventory.append(EquipmentData.create_item(kind, 3))
	main.call("_build_equipment_screen")
	var companions := main.get("companions_screen") as CompanionsScreen
	var skills := main.get("skills_screen") as SkillsScreen
	var artifacts := main.get("artifacts_screen") as ArtifactsScreen
	companions.refresh()
	skills.refresh()
	artifacts.refresh()
	var companion_grid := companions.get_node_or_null("CompanionCollection") as GridContainer
	var skill_grid := skills.get_node_or_null("SkillCollection") as GridContainer
	var artifact_grid := artifacts.get_node_or_null("ArtifactCollection") as GridContainer
	_check(companion_grid != null and companion_grid.columns == 2 and companion_grid.get_child_count() == CompanionData.COMPANIONS.size(), "companion collection is a separate two-column icon grid")
	_check(skill_grid != null and skill_grid.columns == 3 and skill_grid.get_child_count() == SkillData.SKILLS.size(), "skill collection is a separate three-column icon grid")
	_check(artifact_grid != null and artifact_grid.columns == 3 and artifact_grid.get_child_count() == ArtifactData.ARTIFACTS.size(), "artifact collection is a separate three-column icon grid")
	companions.call("_select", "wolf")
	skills.call("_select", "shield_bash")
	artifacts.call("_select", "dragon_heart")
	_check(companions.selected_id == "wolf" and skills.selected_id == "shield_bash" and artifacts.selected_id == "dragon_heart", "selecting collection tiles opens the matching details")
	main.free()
	print("UI COLLECTION SMOKE: ", "FAIL (%d)" % failures if failures else "PASS")
	quit(1 if failures else 0)

func _check(value: bool, label: String) -> void:
	if value:
		return
	failures += 1
	push_error("UI COLLECTION: " + label)
