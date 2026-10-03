extends SceneTree
const IDS := ["Swamp Goblin","Plague Rat","Bog Skeleton","Poison Slime","Swamp Beast","Cultist","Bog Horror","Plague Knight","Marsh Hydra"]
const NORMALS := ["Swamp Goblin","Plague Rat","Bog Skeleton","Poison Slime","Swamp Beast","Cultist"]
var failures := 0
func _initialize(): call_deferred("_run")
func _run():
	var profile:=SaveData.new(); profile.region=5; profile.stage=1; profile.selected_hero_id="knight"
	var battle:=BattleController.new(); root.add_child(battle); battle.start(profile)
	_check(PixelBattleArt.is_active(battle),"Region 5 uses shared pixel battlefield")
	_check(CampaignData.REGIONS[4].name=="Sunken Marshes" and CampaignData.REGIONS[4].theme=="Poisoned swamp ruins","campaign Region 5 identity is unchanged")
	_check(CampaignData.REGIONS[4].enemies.size()+CampaignData.REGIONS[4].elites.size()+1==IDS.size(),"all nine Region 5 roster IDs covered")
	_check(CampaignData.archetype("Cultist")=="HEALER","Cultist retains existing healer role")
	PixelBattleArt.set_battle_region(5)
	var bg:=PixelBattleArt.background_texture()
	_check(bg!=null and Vector2i(bg.get_size())==Vector2i(1280,720),"Sunken Marshes 1280x720 background loads")
	for id in IDS:
		_check(EnemyArtService.enemy_folder(id,5)!="" and PixelBattleArt.enemy_sheet(id)!=null,"%s maps to new idle sprite"%id)
		var placement:Dictionary=PixelBattleArt.BODY_PLACEMENT.get(id,{"width":1.0,"height":1.0})
		_check(is_equal_approx(float(placement.width),float(placement.height)),"%s uses uniform sprite scaling"%id)
		var elite:bool=id in ["Bog Horror","Plague Knight"]; var boss:bool=id=="Marsh Hydra"
		var expected:=[4,4,5,4 if elite or boss else 3]
		if boss: expected[2]=6
		for i in expected.size():
			var state=["idle","entry","attack","hit"][i]
			var count:=PixelBattleArt.enemy_entry_frame_count(id) if state=="entry" else PixelBattleArt.animation_frame_count(id,state)
			var frame:=PixelBattleArt.enemy_entry_frame(id,0) if state=="entry" else PixelBattleArt.animation_frame(id,state,0)
			_check(count==expected[i] and frame!=null,"%s %s uses %d frames and loads"%[id,state,expected[i]])
			_check(is_equal_approx(PixelBattleArt.animation_fps(id,state),7.0 if state=="idle" else 11.0),"%s %s keeps established FPS"%[id,state])
			var sheet:=PixelBattleArt.animation_sheet(id,state)
			if sheet!=null:
				var image:=sheet.get_image()
				_check(image.get_width()==expected[i]*256 and image.get_height()==256,"%s %s frame strip dimensions parse"%[id,state])
				_check(image.get_pixel(0,0).a==0.0 and image.get_pixel(255,0).a==0.0,"%s %s sheet corner alpha is transparent"%[id,state])
		if boss:
			_check(PixelBattleArt.animation_frame_count(id,"entrance")==4 and PixelBattleArt.animation_sheet(id,"entrance")!=null,"Marsh Hydra entrance alias loads")
			_check(PixelBattleArt.animation_frame_count(id,"death")==6 and PixelBattleArt.animation_frame(id,"death",5)!=null,"Marsh Hydra death strip loads")
			_check(is_equal_approx(PixelBattleArt.animation_fps(id,"death"),8.0),"Marsh Hydra death keeps established FPS")
	_check(PixelBattleArt.enemy_fallback_frame("Swamp Goblin","death")!=null,"normal death fallback resolves to idle art")
	_check(PixelBattleArt.BODY_PLACEMENT["Plague Rat"].height<1.0 and PixelBattleArt.BODY_PLACEMENT["Poison Slime"].height<1.0,"low-body enemies retain compact metadata")
	_check(PixelBattleArt.BODY_PLACEMENT["Swamp Beast"].offset_y>0.5,"Swamp Beast retains natural low-body placement")
	_check(PixelBattleArt.BODY_PLACEMENT["Bog Horror"].offset_y>0.5,"Bog Horror clears the battlefield's lower edge")
	var boss_body:Dictionary=PixelBattleArt.BODY_PLACEMENT["Marsh Hydra"]
	_check(boss_body.width==boss_body.height and boss_body.width>1.0 and boss_body.offset_y>=0.5,"Marsh Hydra uses larger uniform metadata scale with lower-lane clearance")
	var warnings:Array[String]=PixelBattleArt.validation_report()
	for warning in warnings: push_error(warning)
	_check(warnings.is_empty(),"Region 5 sheets and background pass load validation")
	_check(PixelBattleArt.animation_frame("Unknown Marsh Enemy","idle",0)==null,"unmapped enemies retain existing procedural fallback route")
	battle.queue_free()
	print("SUNKEN MARSHES PIXEL SMOKE: %s (%d failures)"%["PASS" if failures==0 else "FAIL",failures]); quit(1 if failures else 0)
func _check(ok:bool,description:String):
	if not ok: failures+=1; push_error("Sunken Marshes smoke: "+description)
