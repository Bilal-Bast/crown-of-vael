extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	seed(1405)
	_test_bundle(1,100)
	_test_bundle(10,900)
	_test_bundle(30,2640)
	_test_bundle(50,4250)
	for ticket_count in [0,5,15,29,30,35]:
		_test_ticket_quote(ticket_count)
	_test_insufficient_currency()
	_test_pity_exp_new_and_save()
	_test_result_pages()
	await _test_menu_navigation()
	print("SUMMON / MENU POLISH SMOKE: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)

func _profile() -> SaveData:
	var profile := SaveData.new()
	profile.save_path = "res://.godot/summon_polish_smoke.save"
	profile.gems = 100000
	return profile

func _test_bundle(count: int, price: int) -> void:
	var profile := _profile()
	var service := SummonService.new(profile)
	_check(SummonData.COSTS[count] == price, "%dx quoted price" % count)
	var results := service.summon("equipment", count)
	_check(results.size() == count, "%dx produces every reward" % count)
	_check(profile.gems == 100000-price, "%dx charges exact gem price" % count)
	var progress := int(profile.banners.equipment.exp)
	for level in range(1,int(profile.banners.equipment.level)):
		progress += SummonData.exp_to_next(level)
	_check(progress == mini(count,450), "%dx advances banner EXP/level" % count)

func _test_ticket_quote(ticket_count: int) -> void:
	var profile := _profile()
	profile.gems = 5000
	profile.summon_tickets.equipment = ticket_count
	var service := SummonService.new(profile)
	var used := mini(ticket_count,30)
	var expected_gems := ceili(2640.0 * float(30-used) / 30.0)
	var quote := service.quote("equipment",30)
	_check(int(quote.tickets) == used and int(quote.gems) == expected_gems, "30x quote with %d tickets" % ticket_count)
	_check(service.can_summon("equipment",30), "30x affordability with %d tickets" % ticket_count)
	var result := service.summon("equipment",30)
	_check(result.size() == 30, "30x purchase with %d tickets" % ticket_count)
	_check(int(profile.summon_tickets.equipment) == ticket_count-used and profile.gems == 5000-expected_gems, "ticket-first deduction with %d tickets" % ticket_count)
	_check(profile.gems >= 0 and int(profile.summon_tickets.equipment) >= 0, "nonnegative balances with %d tickets" % ticket_count)

func _test_insufficient_currency() -> void:
	var profile := _profile()
	profile.gems = 87
	profile.summon_tickets.equipment = 0
	var service := SummonService.new(profile)
	_check(not service.can_summon("equipment",1), "insufficient gems disable summon")
	_check(service.summon("equipment",1).is_empty(), "insufficient gems produce no rewards")
	_check(profile.gems == 87 and int(profile.summon_tickets.equipment) == 0, "insufficient purchase leaves balances unchanged")
	profile.summon_tickets.equipment = 1
	_check(service.can_summon("equipment",1), "one ticket covers summon without gems")
	_check(service.quote("equipment",1).gems == 0, "ticket-only summon quotes zero gems")

func _test_pity_exp_new_and_save() -> void:
	var profile := _profile()
	var state: Dictionary = profile.banners.equipment
	state["pity"] = 98
	var service := SummonService.new(profile)
	var rewards := service.summon("equipment",30)
	var guaranteed := false
	for reward in rewards:
		if int(reward.rarity) >= 4: guaranteed = true
	_check(guaranteed and int(state.pity) == 28, "30x pity crosses the guarantee and preserves remainder")
	_check(int(state.level) >= 2, "30x adds banner EXP")
	_check(bool(rewards[0].get("is_new",false)), "new equipment is marked NEW")
	var ticket_profile := _profile()
	ticket_profile.summon_tickets.artifacts = 15
	ticket_profile.banners.artifacts.pity = 63
	ticket_profile.banners.artifacts.exp = 7
	ticket_profile.save()
	var loaded := SaveData.load_from(ticket_profile.save_path)
	_check(int(loaded.summon_tickets.artifacts) == 15, "tickets survive save/load")
	_check(int(loaded.banners.artifacts.pity) == 63 and int(loaded.banners.artifacts.exp) == 7, "banner pity and EXP survive save/load")
	_check(SummonService.new(loaded).quote("artifacts",30).gems == 1320, "loaded tickets still quote correctly")

func _test_result_pages() -> void:
	var profile := _profile()
	var screen := SummonScreen.new()
	root.add_child(screen)
	screen.configure(profile,Callable())
	screen.results.clear()
	screen.result_banner = "equipment"
	for i in 30:
		screen.results.append({"kind":"sacred_sword","rarity":4,"is_new":i == 0})
	screen.refresh()
	_check(_grid_card_count(screen) == 6, "30x reveal renders six cards per page")
	_check(_new_marker_count(screen) == 1, "only first discovery has NEW marker")
	screen.page = 4
	screen.refresh()
	_check(_grid_card_count(screen) == 6, "last full 30x page renders six cards")
	screen.results.resize(10)
	screen.page = 1
	screen.refresh()
	_check(_grid_card_count(screen) == 4, "10x second page renders remaining four cards")
	_check(_all_reward_cards_have_icons(screen), "summon rewards include pixel icons")
	_check(_featured_reward_is_centered(screen), "multi-summon page has a large featured reward")
	for sample in [
		{"banner":"equipment", "kind":str(EquipmentData.ITEMS.keys()[0])},
		{"banner":"skills", "kind":str(SkillData.SKILLS.keys()[0])},
		{"banner":"artifacts", "kind":str(ArtifactData.ARTIFACTS.keys()[0])},
		{"banner":"companions", "kind":str(CompanionData.COMPANIONS.keys()[0])},
	]:
		screen.result_banner = sample.banner
		screen.results = [{"kind":sample.kind,"rarity":4,"is_new":true}]
		screen.page = 0
		screen.featured_index = 0
		screen.refresh()
		_check(_featured_reward_is_centered(screen), "%s reward has centered pixel art" % sample.banner)
	screen.queue_free()

func _test_menu_navigation() -> void:
	OS.set_environment("VAEL_SAVE_PATH", "res://.godot/summon_menu_polish_nav.save")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Control
	root.add_child(main)
	await process_frame
	main.call("_select_tab","Equipment")
	_check((main.get("equipment_area") as Control).visible and not (main.get("battle_area") as Control).visible, "equipment navigation opens its screen")
	_check(not (main.get("stage_panel") as Control).visible, "campaign HUD is hidden outside battle")
	var drawer := main.get("menu_drawer") as Control
	var toggle := main.get("menu_toggle") as Button
	toggle.pressed.emit()
	await process_frame
	_check(drawer.visible and toggle.text == "Menu -", "menu drawer opens")
	var nav_buttons: Dictionary = main.get("nav_buttons")
	for destination in ["Adventure","Skills","Quests","Login","Pass","Shop","Account","Social","Settings"]:
		_check(nav_buttons.has(destination), "drawer keeps %s navigation" % destination)
	toggle.pressed.emit()
	main.queue_free()

func _grid_card_count(node: Node) -> int:
	for child in node.get_children():
		if child is GridContainer and child.get_child_count() > 0 and child.get_child(0) is PanelContainer:
			return child.get_child_count()
	return 0

func _new_marker_count(node: Node) -> int:
	var total := 0
	for child in node.find_children("*", "Label", true, false):
		if str(child.text).begins_with("NEW! "): total += 1
	return total

func _all_reward_cards_have_icons(node: Node) -> bool:
	for child in node.get_children():
		if child is GridContainer:
			for card in child.get_children():
				if card.get_child_count() == 0 or card.get_child(0).get_child_count() == 0: return false
				var icon := card.get_child(0).get_child(0) as TextureRect
				if icon.texture == null: return false
			return child.get_child_count() > 0
	return false

func _featured_reward_is_centered(node: Node) -> bool:
	var icon := node.find_child("FeaturedRewardImage", true, false) as TextureRect
	var frame := node.find_child("FeaturedRewardFrame", true, false) as PanelContainer
	var title := node.find_child("FeaturedRewardName", true, false) as Label
	return icon != null and icon.texture != null and icon.custom_minimum_size.y >= 300 and frame != null and title != null

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("Summon polish: " + label)
