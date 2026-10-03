extends SceneTree

const GREENVALE_IDS := ["Goblin", "Skeleton", "Corrupted Wolf", "Goblin Archer", "Goblin Spearman", "Bandit", "Goblin Captain", "Armored Skeleton", "Goblin Warlord"]
const COUNTS := {
	"Goblin Archer": {"idle": 4, "entry": 4, "attack": 5, "hit": 3},
	"Goblin Spearman": {"idle": 4, "entry": 4, "attack": 5, "hit": 3},
	"Bandit": {"idle": 4, "entry": 4, "attack": 5, "hit": 3},
	"Goblin Captain": {"idle": 4, "entry": 4, "attack": 5, "hit": 3},
	"Armored Skeleton": {"idle": 4, "entry": 4, "attack": 5, "hit": 3},
	"Goblin Warlord": {"idle": 4, "entry": 4, "attack": 6, "hit": 4, "death": 6},
}

var failures := 0
var battle: BattleController
var field: Battlefield

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var profile := SaveData.new()
	profile.save_path = "res://.godot/greenvale_pixel_smoke.save"
	profile.region = 1
	profile.stage = 1
	profile.selected_hero_id = "knight"
	battle = BattleController.new()
	root.add_child(battle)
	battle.start(profile)
	battle.active = false
	field = Battlefield.new()
	root.add_child(field)
	field.size = Vector2(360, 192)
	field.set_battle(battle)
	await process_frame
	_check(PixelBattleArt.is_active(battle), "Greenvale production pixel mode is active for base Squire")
	_check(CampaignData.REGIONS[0]["enemies"].size() + CampaignData.REGIONS[0]["elites"].size() + 1 == GREENVALE_IDS.size(), "all Greenvale enemy/elite/boss IDs are covered")
	_check(PixelBattleArt.background_texture() != null and Vector2i(PixelBattleArt.background_texture().get_size()) == Vector2i(1280, 720), "optimized Greenvale pixel background loads at 1280x720")
	for enemy_id in GREENVALE_IDS:
		_check(PixelBattleArt.enemy_sheet(enemy_id) != null, "%s resolves to pixel art" % enemy_id)
		_check(PixelBattleArt.enemy_entry_frame(enemy_id, 0) != null, "%s entry sheet loads" % enemy_id)
		if COUNTS.has(enemy_id):
			for state in COUNTS[enemy_id]:
				var expected := int(COUNTS[enemy_id][state])
				var count := PixelBattleArt.enemy_entry_frame_count(enemy_id) if state == "entry" else PixelBattleArt.animation_frame_count(enemy_id, state)
				_check(count == expected, "%s %s frame count is %d" % [enemy_id, state, expected])
				var frame := PixelBattleArt.enemy_entry_frame(enemy_id, 0) if state == "entry" else PixelBattleArt.animation_frame(enemy_id, state, 0)
				_check(frame != null, "%s %s first frame loads" % [enemy_id, state])
				if state != "entry":
					_check(PixelBattleArt.animation_fps(enemy_id, state) > 0.0, "%s %s has a positive playback rate" % [enemy_id, state])
	_check(PixelBattleArt.validation_report().is_empty(), "all Greenvale sheets pass texture dimension validation")
	_check(PixelBattleArt.animation_sheet("Goblin Warlord", "death") != null, "Warlord death sheet is available")
	_check(PixelBattleArt.animation_frame("Unknown Greenvale enemy", "idle", 0) == null, "missing art returns null safely")
	_check(PixelBattleArt.animation_duration("Unknown Greenvale enemy", "attack", 0.3) == 0.3, "missing sheets preserve fallback duration")

	battle.enemies.clear()
	var archer := CampaignData.enemy_stats("Goblin Archer", 0, 1, 1, 1)
	archer["current_hp"] = archer["hp"]
	archer["spawned"] = true
	archer["entry_time"] = 0.0
	archer["attack_time"] = 3.0
	battle.enemies.append(archer)
	battle.changed.emit()
	field._on_attack_started(0, -1)
	_check(field.vfx.projectiles.size() == 1 and field.vfx.projectiles[0]["style"] == "pixel_arrow", "Goblin Archer fires a pixel arrow through the existing projectile queue")
	if not field.vfx.projectiles.is_empty():
		var arrow: Dictionary = field.vfx.projectiles[0]
		_check(Vector2(arrow["from"]).x > Vector2(arrow["to"]).x, "Goblin Archer pixel arrow travels left toward the hero")
	field._update_pixel_enemy_sprite(0, field._enemy_position(0), archer, "attack", 0.34)
	_check(field.pixel_enemy_sprites.size() > 0, "pixel enemy sprite instance is created")
	_check(field.pixel_enemy_sprites[0].texture == PixelBattleArt.animation_frame("Goblin Archer", "attack", 0), "Archer attack uses its pixel animation sheet")

	var non_greenvale := BattleController.new()
	root.add_child(non_greenvale)
	profile.region = 2
	non_greenvale.start(profile)
	_check(PixelBattleArt.is_active(non_greenvale), "Whispering Forest shares the production pixel renderer")
	profile.region = 3
	var region_three := BattleController.new()
	root.add_child(region_three)
	region_three.start(profile)
	region_three.active = false
	_check(PixelBattleArt.is_active(region_three), "Ashen Highlands shares the production pixel renderer")
	root.remove_child(region_three)
	region_three.free()
	root.remove_child(non_greenvale)
	non_greenvale.free()
	field.queue_free()
	battle.queue_free()
	print("GREENVALE PIXEL SMOKE: %s (%d failures)" % ["FAIL" if failures else "PASS", failures])
	quit(1 if failures else 0)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("Greenvale pixel smoke: " + description)
