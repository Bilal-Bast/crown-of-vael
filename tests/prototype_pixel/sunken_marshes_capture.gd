extends SceneTree
const CAPTURE_DIR:="res://.godot/prototype_pixel_captures"
const SMALL:=Vector2i(360,640); const LARGE:=Vector2i(1080,1920)
const MIXED:=["Swamp Goblin","Plague Rat","Bog Skeleton","Poison Slime","Swamp Beast","Cultist","Bog Horror"]
var main:Control; var battle:BattleController; var field:Battlefield; var failures:=0
func _initialize():
	OS.set_environment("VAEL_SAVE_PATH","res://.godot/sunken_capture.save"); call_deferred("_run")
func _run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	main=(load("res://scenes/main.tscn") as PackedScene).instantiate() as Control; root.add_child(main); await process_frame
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); main.position=Vector2.ZERO; main.scale=Vector2.ONE
	var profile:=main.get("profile") as SaveData; battle=main.get("battle") as BattleController; field=main.get("battlefield") as Battlefield
	profile.save_path="res://.godot/sunken_capture.save"; profile.tutorial_state.completed=true; profile.tutorial_state.skipped=true; profile.region=5; profile.stage=1; profile.selected_hero_id="knight"; profile.heroes["knight"].evolution=0
	battle.region=5; battle.stage=1; battle.wave=1; battle.mode_config={"mode":"campaign"}; battle.start(profile); battle.active=false; main.call("_select_tab","Battle")
	for popup in ["tutorial_popup","offline_popup","login_popup"]:
		var node=main.get(popup); if node is Window or node is Control: node.hide()
	if OS.get_cmdline_user_args().has("--overview-only"):
		_set_enemies(MIXED); await _capture("sunken_mixed_overview_1080",LARGE)
		_set_enemies(["Marsh Hydra"],false,true); await _capture("sunken_hydra_overview_1080",LARGE)
		main.queue_free(); print("SUNKEN MARSHES OVERVIEW CAPTURES: %s (%d failures)"%["PASS" if failures==0 else "FAIL",failures]); quit(1 if failures else 0); return
	if OS.get_cmdline_user_args().has("--placement-only"):
		_set_enemies(["Plague Rat"]); await _capture("sunken_poison_rat_360",SMALL)
		_set_enemies(["Poison Slime"]); await _capture("sunken_poison_slime_360",SMALL)
		_set_enemies(["Swamp Beast"]); await _capture("sunken_swamp_beast_360",SMALL)
		_set_enemies(["Bog Horror"]); await _capture("sunken_bog_horror_360",SMALL)
		_set_enemies(MIXED); await _capture("sunken_mixed_overview_1080",LARGE)
		main.queue_free(); print("SUNKEN MARSHES PLACEMENT CAPTURES: %s (%d failures)"%["PASS" if failures==0 else "FAIL",failures]); quit(1 if failures else 0); return
	if OS.get_cmdline_user_args().has("--mixed-only"):
		_set_enemies(MIXED); await _capture("sunken_mixed_overview_1080",LARGE)
		main.queue_free(); print("SUNKEN MARSHES MIXED OVERVIEW: %s (%d failures)"%["PASS" if failures==0 else "FAIL",failures]); quit(1 if failures else 0); return
	_set_enemies(["Swamp Goblin"]); _attack(0); await _capture("sunken_goblin_attack_360",SMALL)
	_set_enemies(["Poison Slime"]); await _capture("sunken_poison_slime_360",SMALL)
	_set_enemies(["Swamp Beast"],true); await _capture("sunken_swamp_beast_entry_360",SMALL)
	_set_enemies(["Bog Horror"]); _attack(0); await _capture("sunken_bog_horror_attack_360",SMALL)
	_set_enemies(["Marsh Hydra"],false,true); _attack(0); await _capture("sunken_hydra_attack_360",SMALL)
	_set_enemies(MIXED); await _capture("sunken_mixed_overview_1080",LARGE)
	_set_enemies(["Marsh Hydra"],false,true); await _capture("sunken_hydra_overview_1080",LARGE)
	main.queue_free(); print("SUNKEN MARSHES CAPTURES: %s (%d failures)"%["PASS" if failures==0 else "FAIL",failures]); quit(1 if failures else 0)
func _set_enemies(kinds:Array,entering:=false,boss:=false):
	battle.enemies.clear(); battle.stage=20 if boss else 1
	for kind in kinds:
		var enemy=CampaignData.enemy_stats(str(kind),0,5,battle.stage,1); enemy.current_hp=enemy.hp; enemy.attack_time=3.0; enemy.stun_time=0.0; enemy.spawned=true; enemy.entry_time=0.10 if entering else 0.0; battle.enemies.append(enemy)
	field.enemy_attack_times.clear(); field.enemy_hit_times.clear(); field.enemy_attack_art_durations.clear(); field.enemy_hit_art_durations.clear(); field.deaths.clear(); battle.changed.emit()
func _attack(index:int):
	field.vfx.projectiles.clear(); field.vfx.labels.clear(); field.vfx.effects.clear(); field._on_attack_started(index,-1)
	var kind:=str(battle.enemies[index].get("visual","")); var fps:=PixelBattleArt.animation_fps(kind,"attack")
	field.enemy_attack_times[index]=field.enemy_attack_art_durations[index]-minf(2.0,PixelBattleArt.animation_frame_count(kind,"attack")-1.0)/fps; field._process(0.0)
func _capture(name:String,resolution:Vector2i):
	DisplayServer.window_set_size(resolution)
	for _i in 3: await process_frame
	await RenderingServer.frame_post_draw
	var img:=root.get_texture().get_image()
	if img.get_size()!=resolution: failures+=1; push_error("Unexpected capture dimensions: "+name)
	if img.save_png("%s/%s.png"%[CAPTURE_DIR,name])!=OK: failures+=1; push_error("Capture failed: "+name)
	print("Captured "+name)
