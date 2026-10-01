extends SceneTree

const KINDS := ["Goblin", "Skeleton", "Corrupted Wolf"]
var failures := 0
var field: Battlefield
var battle: BattleController

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var profile := SaveData.new()
 profile.save_path = "res://.godot/combat_animation_smoke.save"
 profile.region = 1
 profile.stage = 1
 profile.selected_hero_id = "knight"
 battle = BattleController.new()
 root.add_child(battle)
 battle.start(profile)
 field = Battlefield.new()
 root.add_child(field)
 field.size = Vector2(360, 190)
 field.set_battle(battle)
 await process_frame
 _check(PixelBattleArt.is_active(battle), "Greenvale Squire prototype is active")
 _check(PixelBattleArt.validation_report().is_empty(), "all animation and prototype sheets load with valid dimensions")
 var counts := {"Squire": {"idle":4,"attack":6,"guard":6,"hit":4}, "Goblin":{"idle":4,"attack":4,"hit":3}, "Skeleton":{"idle":4,"attack":4,"hit":3}, "Corrupted Wolf":{"idle":4,"attack":5,"hit":3}}
 var speeds := {"Squire": {"idle":7.0,"attack":12.0,"guard":12.0,"hit":12.0}, "Goblin":{"idle":8.0,"attack":11.0,"hit":11.0}, "Skeleton":{"idle":7.0,"attack":9.0,"hit":10.0}, "Corrupted Wolf":{"idle":8.0,"attack":12.0,"hit":11.0}}
 for character in counts:
  for state in counts[character]:
   _check(PixelBattleArt.animation_frame_count(character,state)==counts[character][state], "%s %s frame count" % [character,state])
   _check(is_equal_approx(PixelBattleArt.animation_fps(character,state),speeds[character][state]), "%s %s playback speed" % [character,state])
   _check(PixelBattleArt.animation_frame(character,state,0)!=null, "%s %s first frame loads" % [character,state])
   _check(PixelBattleArt.animation_frame(character,state,counts[character][state])==PixelBattleArt.animation_frame(character,state,0), "%s %s loops to first frame" % [character,state])
 _check(PixelBattleArt.animation_duration("Squire","attack",0.26)==0.5, "Squire attack presentation fits six frames at 12 FPS")
 _check(is_equal_approx(PixelBattleArt.animation_duration("Corrupted Wolf","attack",0.23),5.0/12.0), "wolf action duration is visual-only and follows its 12 FPS sheet")
 _check(PixelBattleArt.animation_duration("Squire","missing",0.3)==0.3, "missing sheet uses existing visual duration")
 _check(field._pixel_animation_frame("Squire","missing",0.0,false,0,"idle")!=null, "missing state falls back to legacy Squire sheet")

 field._on_attack_started(-1,0)
 field._process(0.0)
 _check(field.hero_visual_state=="attack", "Squire attack takes priority over idle")
 field._on_damage_popup(-1,5,false,false)
 field._process(0.0)
 _check(field.hero_visual_state=="hit", "Squire hit takes priority over attack")
 field.hero_hit_art_time=0.0
 field.hero_guard_art_time=0.0
 field.hero_attack_art_time=0.0
 field.hero_run_time=0.75
 field._process(0.0)
 _check(field.hero_visual_state=="idle", "run is selected below combat action priority")
 field._update_pixel_hero_sprite(field._hero_position(),0.32)
 _check(field.pixel_hero_sprite.texture==PixelBattleArt.hero_run_frame(1), "Squire keeps the run cycle during the run transition")
 field._on_skill_cast("shield_bash",0)
 field._process(0.0)
 _check(field.hero_visual_state=="guard" and field.pixel_skill_effect_time>0.0 and field.pixel_impact_overlay.visible, "Shield Bash selects guard animation and visible pixel impact")

 battle.enemies.clear()
 for kind in KINDS:
  var enemy := CampaignData.enemy_stats(kind,0,1,1,1)
  enemy["current_hp"]=enemy["hp"]
  enemy["spawned"]=true
  enemy["entry_time"]=0.0
  enemy["attack_time"]=3.0
  enemy["stun_time"]=0.0
  battle.enemies.append(enemy)
 battle.changed.emit()
 field.enemy_attack_times.clear()
 field.enemy_hit_times.clear()
 field.enemy_attack_art_durations.clear()
 field.enemy_hit_art_durations.clear()
 field._on_attack_started(0,-1)
 field._process(0.0)
 _check(field.enemy_visual_state(0)=="attack" and field.enemy_visual_state(1)=="idle", "enemy attack is isolated to its actor")
 var goblin_attack_start := field.pixel_enemy_sprites[0].texture
 field.enemy_attack_times[0]=float(field.enemy_attack_art_durations[0])-0.2
 field._update_pixel_enemy_sprite(0,field._enemy_position(0),battle.enemies[0],"attack",0.32)
 _check(goblin_attack_start!=field.pixel_enemy_sprites[0].texture, "Goblin attack frames advance independently")
 field._on_attack_started(1,-1)
 field._on_damage_popup(0,8,false,false)
 field._process(0.0)
 _check(field.enemy_visual_state(0)=="hit" and field.enemy_visual_state(1)=="attack" and field.enemy_visual_state(2)=="idle", "hit, attack, and idle states coexist on separate enemies")
 field.enemy_hit_times[0]=0.0
 field.enemy_attack_times[0]=0.0
 field.enemy_attack_times[1]=0.0
 field._process(0.0)
 _check(field.enemy_visual_state(0)=="idle" and field.enemy_visual_state(1)=="idle", "enemy action states return to looping idle")
 battle.enemies[2]["entry_time"]=0.3
 _check(field.enemy_visual_state(2)=="entry", "entry resumes beneath attack/hit and above idle")
 field._on_attack_started(2,-1)
 _check(field.enemy_visual_state(2)=="attack", "attack takes priority over enemy entry")
 for index in battle.enemies.size():
  field._update_pixel_enemy_sprite(index, field._enemy_position(index), battle.enemies[index], field.enemy_visual_state(index), 0.32)
 _check(field.pixel_enemy_sprites.size()>=3, "each active enemy owns an independent sprite node")
 battle.active=false
 field.queue_free()
 battle.queue_free()
 print("COMBAT ANIMATION SMOKE: %s (%d failures)" % ["FAIL" if failures else "PASS", failures])
 quit(1 if failures else 0)

func _check(condition: bool, description: String) -> void:
 if not condition:
  failures += 1
  push_error("Combat animation smoke: " + description)
