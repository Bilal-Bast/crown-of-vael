extends SceneTree
const IDS := ["Frost Wolf","Ice Goblin","Frozen Skeleton","Snow Bandit","Ice Archer","Frost Spirit","Ice Troll","Frost Knight","Frostfang Giant"]
const NORMALS := ["Frost Wolf","Ice Goblin","Frozen Skeleton","Snow Bandit","Ice Archer","Frost Spirit"]
const NORMAL_COUNTS := [4,4,5,3]
var failures := 0
func _initialize(): call_deferred("_run")
func _run():
 var profile:=SaveData.new(); profile.region=4; profile.stage=1; profile.selected_hero_id="knight"
 var battle:=BattleController.new(); root.add_child(battle); battle.start(profile)
 _check(PixelBattleArt.is_active(battle),"Region 4 uses the shared pixel battle renderer")
 _check(battle.enemies.size()==7 and battle.spawned_enemy_count==1 and is_equal_approx(battle.enemy_entry_timer,GameData.ENEMY_ENTRY_INTERVAL),"seven-enemy wave begins with the centralized entry cadence")
 battle.hero_attack_time=100.0; battle._process(GameData.ENEMY_ENTRY_INTERVAL)
 _check(battle.spawned_enemy_count==2 and float(battle.enemies[0].current_hp)>0 and float(battle.enemies[1].current_hp)>0,"living enemies coexist as later entries arrive")
 _check(battle.wave_transition_duration==1.5,"hero run transition remains 1.5 seconds")
 for enemy in battle.enemies: enemy.current_hp=0.0
 battle.spawned_enemy_count=2; _check(not battle._all_enemies_defeated(),"wave waits for all seven entries and defeats")
 battle.spawned_enemy_count=7; _check(battle._all_enemies_defeated(),"wave completes after all seven defeats")
 battle.active=false
 _check(CampaignData.REGIONS[3].enemies.size()+CampaignData.REGIONS[3].elites.size()+1==IDS.size(),"all nine Frostfang Mountains IDs are covered")
 PixelBattleArt.set_battle_region(4)
 var bg:=PixelBattleArt.background_texture()
 _check(bg!=null and Vector2i(bg.get_size())==Vector2i(1280,720),"frozen mountain battlefield background loads at 1280x720")
 for id in IDS:
  _check(EnemyArtService.enemy_folder(id,4)!="" and PixelBattleArt.enemy_sheet(id)!=null,"%s resolves to pixel idle art"%id)
  var expected:=NORMAL_COUNTS.duplicate()
  if id in ["Ice Troll","Frost Knight"]: expected=[4,4,5,4]
  if id=="Frostfang Giant": expected=[4,4,6,4]
  for i in expected.size():
   var state=["idle","entry","attack","hit"][i]
   var count:=PixelBattleArt.enemy_entry_frame_count(id) if state=="entry" else PixelBattleArt.animation_frame_count(id,state)
   var frame:=PixelBattleArt.enemy_entry_frame(id,0) if state=="entry" else PixelBattleArt.animation_frame(id,state,0)
   _check(count==expected[i] and frame!=null,"%s %s frame count and texture load"%[id,state])
   var sheet:=PixelBattleArt.animation_sheet(id,state)
   if sheet!=null:
    var img:=sheet.get_image()
    _check(img.get_pixel(0,0).a==0.0 and img.get_pixel(255,0).a==0.0,"%s %s has transparent frame corners"%[id,state])
  if id=="Frostfang Giant":
   _check(PixelBattleArt.animation_frame_count(id,"entrance")==4 and PixelBattleArt.animation_sheet(id,"entrance")!=null,"Frostfang Giant entrance alias loads")
   _check(PixelBattleArt.animation_frame_count(id,"death")==6 and PixelBattleArt.animation_frame(id,"death",5)!=null,"Frostfang Giant dedicated death strip loads")
 _check(PixelBattleArt.enemy_fallback_frame("Frost Wolf","death")!=null,"unsupported normal death state falls back to idle art")
 _check(PixelBattleArt.animation_frame("Unmapped Frost Enemy","idle",0)==null,"unknown enemy remains unmapped for existing fallback")
 _check(PixelBattleArt.BODY_PLACEMENT["Frost Wolf"].offset_y>0.5,"Frost Wolf keeps its low quadruped placement")
 _check(PixelBattleArt.BODY_PLACEMENT["Frost Spirit"].width<1.0 and PixelBattleArt.BODY_PLACEMENT["Frost Spirit"].height<1.0,"Frost Spirit uses compact floating metadata")
 _check(PixelBattleArt.BODY_PLACEMENT["Frostfang Giant"].width>1.0 and PixelBattleArt.BODY_PLACEMENT["Frostfang Giant"].height>1.0,"Frostfang Giant keeps a larger uniform boss scale")
 var field:=Battlefield.new(); root.add_child(field); field.size=Vector2(360,192); field.set_battle(battle)
 var a:=CampaignData.enemy_stats("Ice Goblin",0,4,1,1); a.current_hp=a.hp; a.spawned=true
 var b:=CampaignData.enemy_stats("Frost Wolf",0,4,1,1); b.current_hp=b.hp; b.spawned=true
 battle.enemies=[a,b]; field._update_pixel_enemy_sprite(0,field._enemy_position(0),a,"idle",0.32); field._update_pixel_enemy_sprite(1,field._enemy_position(1),b,"idle",0.32)
 _check(field.pixel_enemy_sprites.size()==2 and field.pixel_enemy_sprites[0]!=field.pixel_enemy_sprites[1],"living enemies retain independent sprite animation state")
 var archer:=CampaignData.enemy_stats("Ice Archer",0,4,1,1); archer.current_hp=archer.hp; archer.spawned=true; battle.enemies=[archer]
 field._on_attack_started(0,-1)
 _check(field.vfx.projectiles.size()==1 and field.vfx.projectiles[0].style=="pixel_arrow","Ice Archer reuses existing pixel arrow projectile")
 _check(field.vfx.projectiles[0].color==Color("91dff5"),"Ice Archer projectile uses a subtle frost color")
 if not field.vfx.projectiles.is_empty(): _check(Vector2(field.vfx.projectiles[0].from).x>Vector2(field.vfx.projectiles[0].to).x,"Ice Archer projectile travels left")
 _check(field.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST,"nearest-neighbor filtering remains active")
 var warnings:Array[String]=PixelBattleArt.validation_report(); for warning in warnings: push_error(warning)
 _check(warnings.is_empty(),"all Region 4 sheets and background pass validation")
 _check(is_equal_approx(GameData.ENEMY_ENTRY_INTERVAL,0.60),"normal campaign entry interval is 0.60 seconds")
 field.queue_free(); battle.queue_free()
 print("FROSTFANG MOUNTAINS PIXEL SMOKE: %s (%d failures)"%["PASS" if failures==0 else "FAIL",failures]); quit(1 if failures else 0)
func _check(ok:bool,description:String):
 if not ok: failures+=1; push_error("Frostfang Mountains smoke: "+description)
