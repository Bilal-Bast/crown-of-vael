extends SceneTree
const IDS := ["Ash Goblin","Fire Imp","Charred Skeleton","Raider","Magma Hound","Fire Archer","Flame Brute","Ash Knight","Infernal Ogre"]
const NORMALS := ["Ash Goblin","Fire Imp","Charred Skeleton","Raider","Magma Hound","Fire Archer"]
const NORMAL_COUNTS := [4,4,5,3]
var failures := 0
func _initialize(): call_deferred("_run")
func _run():
 var profile:=SaveData.new(); profile.region=3; profile.stage=1; profile.selected_hero_id="knight"
 var battle:=BattleController.new(); root.add_child(battle); battle.start(profile)
 _check(PixelBattleArt.is_active(battle),"Region 3 uses the shared pixel battle renderer")
 _check(battle.enemies.size()==7 and battle.spawned_enemy_count==1 and is_equal_approx(battle.enemy_entry_timer,0.9),"seven-enemy wave begins with the 0.9 second entry cadence")
 battle.hero_attack_time=100.0; battle._process(0.9)
 _check(battle.spawned_enemy_count==2 and float(battle.enemies[0].current_hp)>0 and float(battle.enemies[1].current_hp)>0,"living enemies coexist as later entries arrive")
 _check(battle.wave_transition_duration==1.5,"hero run transition remains 1.5 seconds")
 for enemy in battle.enemies: enemy.current_hp=0.0
 battle.spawned_enemy_count=2; _check(not battle._all_enemies_defeated(),"wave waits for all seven entries and defeats")
 battle.spawned_enemy_count=7; _check(battle._all_enemies_defeated(),"wave completes after all seven defeats")
 battle.active=false
 _check(CampaignData.REGIONS[2].enemies.size()+CampaignData.REGIONS[2].elites.size()+1==IDS.size(),"all nine Region 3 campaign IDs are covered")
 PixelBattleArt.set_battle_region(3)
 var bg:=PixelBattleArt.background_texture()
 _check(bg!=null and Vector2i(bg.get_size())==Vector2i(1280,720),"volcanic battlefield background loads at 1280x720")
 for id in IDS:
  _check(EnemyArtService.enemy_folder(id,3)!="" and PixelBattleArt.enemy_sheet(id)!=null,"%s resolves to pixel idle art"%id)
  var expected:=NORMAL_COUNTS.duplicate()
  if id in ["Flame Brute","Ash Knight"]: expected=[4,4,5,4]
  if id=="Infernal Ogre": expected=[4,4,6,4]
  var states=["idle","entry","attack","hit"]
  for i in states.size():
   var state:String=states[i]
   var count:=PixelBattleArt.enemy_entry_frame_count(id) if state=="entry" else PixelBattleArt.animation_frame_count(id,state)
   var frame:=PixelBattleArt.enemy_entry_frame(id,0) if state=="entry" else PixelBattleArt.animation_frame(id,state,0)
   _check(count==expected[i] and frame!=null,"%s %s count and frame load"%[id,state])
   var sheet:=PixelBattleArt.animation_sheet(id,state)
   if sheet!=null:
    var img:=sheet.get_image()
    _check(img.get_pixel(0,0).a==0.0 and img.get_pixel(255,0).a==0.0,"%s %s has clean transparent atlas corners"%[id,state])
  if id=="Infernal Ogre":
   _check(PixelBattleArt.animation_frame_count(id,"entrance")==4 and PixelBattleArt.animation_sheet(id,"entrance")!=null,"Infernal Ogre entrance strip loads")
   _check(PixelBattleArt.animation_frame_count(id,"death")==6 and PixelBattleArt.animation_frame(id,"death",5)!=null,"Infernal Ogre dedicated six-frame death loads")
 _check(PixelBattleArt.enemy_fallback_frame("Ash Goblin","death")!=null,"missing non-boss state falls back to Ash Goblin idle art")
 _check(PixelBattleArt.animation_frame("Unmapped Ash Enemy","idle",0)==null,"unknown enemy resolves to existing fallback")
 _check(PixelBattleArt.BODY_PLACEMENT["Magma Hound"].height<0.8 and EnemyArtService.metadata("Magma Hound").scale<0.7,"Magma Hound retains low quadruped body metadata")
 _check(PixelBattleArt.BODY_PLACEMENT["Fire Imp"].offset_y<0.5,"Fire Imp uses small floating placement metadata")
 _check(PixelBattleArt.BODY_PLACEMENT["Flame Brute"].height>1.0 and PixelBattleArt.BODY_PLACEMENT["Ash Knight"].height>1.0,"elite scale metadata is distinct from normals")
 var field:=Battlefield.new(); root.add_child(field); field.size=Vector2(360,192); field.set_battle(battle)
 var a:=CampaignData.enemy_stats("Ash Goblin",0,3,1,1); a.current_hp=a.hp; a.spawned=true
 var b:=CampaignData.enemy_stats("Magma Hound",0,3,1,1); b.current_hp=b.hp; b.spawned=true
 battle.enemies=[a,b]; field._update_pixel_enemy_sprite(0,field._enemy_position(0),a,"idle",0.32); field._update_pixel_enemy_sprite(1,field._enemy_position(1),b,"idle",0.32)
 _check(field.pixel_enemy_sprites.size()==2 and field.pixel_enemy_sprites[0]!=field.pixel_enemy_sprites[1],"living enemies retain independent sprite animation state")
 var archer:=CampaignData.enemy_stats("Fire Archer",0,3,1,1); archer.current_hp=archer.hp; archer.spawned=true; battle.enemies=[archer]
 field._on_attack_started(0,-1)
 _check(field.vfx.projectiles.size()==1 and field.vfx.projectiles[0].style=="pixel_arrow","Fire Archer reuses existing pixel arrow projectile")
 _check(field.vfx.projectiles[0].color==Color("e99a5b"),"Fire Archer uses a subtle ember arrow color")
 if not field.vfx.projectiles.is_empty(): _check(Vector2(field.vfx.projectiles[0].from).x>Vector2(field.vfx.projectiles[0].to).x,"Fire Archer projectile travels left")
 _check(field.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"nearest-neighbor filtering remains active")
 var warnings:Array[String]=PixelBattleArt.validation_report(); for warning in warnings: push_error(warning)
 _check(warnings.is_empty(),"all Region 3 strips and background pass validation")
 _check(GameData.ENEMY_ENTRY_INTERVAL==0.9,"global enemy entry interval remains 0.9 seconds")
 field.queue_free(); battle.queue_free()
 print("ASHEN HIGHLANDS PIXEL SMOKE: %s (%d failures)"%["PASS" if failures==0 else "FAIL",failures]); quit(1 if failures else 0)
func _check(ok:bool,description:String):
 if not ok: failures+=1; push_error("Ashen Highlands smoke: "+description)
