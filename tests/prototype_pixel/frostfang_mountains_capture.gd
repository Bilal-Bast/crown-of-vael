extends SceneTree
const CAPTURE_DIR:="res://.godot/prototype_pixel_captures"
const SMALL:=Vector2i(360,640); const LARGE:=Vector2i(1080,1920)
const MIX:=["Frost Wolf","Ice Goblin","Frozen Skeleton","Snow Bandit","Ice Archer","Frost Spirit","Ice Troll"]
var main:Control; var profile:SaveData; var battle:BattleController; var field:Battlefield; var failures:=0
func _initialize():
 OS.set_environment("VAEL_SAVE_PATH","res://.godot/frostfang_capture.save"); call_deferred("_run")
func _run():
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
 main=(load("res://scenes/main.tscn") as PackedScene).instantiate() as Control; root.add_child(main); await process_frame
 main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); main.position=Vector2.ZERO; main.scale=Vector2.ONE
 profile=main.get("profile") as SaveData; battle=main.get("battle") as BattleController; field=main.get("battlefield") as Battlefield
 profile.save_path="res://.godot/frostfang_capture.save"; profile.tutorial_state.completed=true; profile.tutorial_state.skipped=true; profile.region=4; profile.stage=1; profile.selected_hero_id="knight"; profile.heroes["knight"].evolution=0
 battle.region=4; battle.stage=1; battle.wave=1; battle.mode_config={"mode":"campaign"}; battle.start(profile); battle.active=false; main.call("_select_tab","Battle")
 for popup in ["tutorial_popup","offline_popup","login_popup"]:
  var node=main.get(popup); if node is Window or node is Control: node.hide()
 _set_enemies(["Snow Bandit"]); _attack(0); await _capture("frost_snow_bandit_attack_360x640",SMALL)
 _set_enemies(["Ice Archer"]); _attack(0)
 field.vfx.projectile(field._enemy_position(0)+Vector2(-24,-8),field._hero_position()+Vector2(0,-75),Color("91dff5"),0.26,6,"pixel_arrow")
 await _capture("frost_ice_archer_projectile_360x640",SMALL)
 _set_enemies(["Frost Wolf"]); _attack(0); await _capture("frost_wolf_attack_360x640",SMALL)
 for kind in ["Ice Troll","Frost Knight"]:
  _set_enemies([kind]); _attack(0); await _capture("frost_%s_attack_360x640"%_slug(kind),SMALL)
 _set_enemies(["Frostfang Giant"],true,true); battle.enemies[0].entry_time=0.0; await _capture("frost_giant_entrance_360x640",SMALL)
 _attack(0); await _capture("frost_giant_attack_360x640",SMALL)
 battle.enemies[0].current_hp=0.0; field._on_enemy_defeated(0,0,0); if not field.deaths.is_empty(): field.deaths[0].age=0.34; field.queue_redraw(); await _capture("frost_giant_death_360x640",SMALL)
 _set_enemies(MIX); await _capture("frost_mixed_seven_360x640",SMALL)
 _set_enemies(["Frostfang Giant"],false,true); await _capture("frost_boss_overview_1080x1920",LARGE)
 main.queue_free(); print("FROSTFANG MOUNTAINS CAPTURES: %s (%d failures)"%["PASS" if failures==0 else "FAIL",failures]); quit(1 if failures else 0)
func _set_enemies(kinds:Array,entering:=false,boss:=false):
 battle.enemies.clear(); battle.stage=20 if boss else 1
 for kind in kinds:
  var enemy=CampaignData.enemy_stats(str(kind),0,4,battle.stage,1); enemy.current_hp=enemy.hp; enemy.attack_time=3.0; enemy.stun_time=0.0; enemy.spawned=true; enemy.entry_time=0.10 if entering else 0.0; battle.enemies.append(enemy)
 field.enemy_attack_times.clear(); field.enemy_hit_times.clear(); field.enemy_attack_art_durations.clear(); field.enemy_hit_art_durations.clear(); field.deaths.clear(); battle.changed.emit()
func _attack(index:int):
 field.vfx.projectiles.clear(); field.vfx.labels.clear(); field.vfx.effects.clear(); field._on_attack_started(index,-1)
 var kind=str(battle.enemies[index].get("visual","")); var fps=PixelBattleArt.animation_fps(kind,"attack")
 field.enemy_attack_times[index]=field.enemy_attack_art_durations[index]-minf(2.0,PixelBattleArt.animation_frame_count(kind,"attack")-1.0)/fps
 field._process(0.0)
func _capture(name:String,resolution:Vector2i):
 DisplayServer.window_set_size(resolution)
 for _i in 3: await process_frame
 await RenderingServer.frame_post_draw
 var img=root.get_texture().get_image()
 if img.get_size()!=resolution: failures+=1; push_error("Unexpected capture dimensions: "+name)
 if img.save_png("%s/%s.png"%[CAPTURE_DIR,name])!=OK: failures+=1; push_error("Capture failed: "+name)
 print("Captured "+name)
func _slug(value:String)->String: return value.to_lower().replace(" ","_")
