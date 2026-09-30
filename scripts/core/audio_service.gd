extends Node

## Central audio routing. Empty paths are intentional until production assets arrive.
const EVENT_PATHS := {
	"sword_swing": "", "normal_hit": "", "critical_hit": "", "shield_bash": "",
	"skill_activation": "", "projectile_launch": "", "projectile_impact": "",
	"enemy_death": "", "boss_entrance": "", "boss_defeat": "",
	"gold_reward": "", "gem_reward": "", "level_up": "", "evolution": "",
	"button_click": "", "claim_reward": "", "summon": "", "equip": "", "upgrade": "", "error": "",
}
const MUSIC_PATHS := {"home": "", "battle": "", "boss": "", "battle_region_01": "", "battle_region_02": "", "battle_region_03": "", "battle_region_04": "", "battle_region_05": "", "battle_region_06": "", "battle_region_07": "", "battle_region_08": "", "battle_region_09": "", "battle_region_10": ""}
const BUS_NAMES := ["Master", "Music", "SFX", "UI"]

var players: Array[AudioStreamPlayer] = []
var music_players: Array[AudioStreamPlayer] = []
var active_music := -1
var music_tween: Tween

func _ready() -> void:
	_ensure_buses()
	for i in 10:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX" if i < 8 else "UI"
		add_child(player)
		players.append(player)
	for i in 2:
		var music_player := AudioStreamPlayer.new()
		music_player.bus = "Music"
		music_player.volume_db = -40.0
		add_child(music_player)
		music_players.append(music_player)
	_apply_settings({})

func _ensure_buses() -> void:
	for bus in BUS_NAMES:
		if AudioServer.get_bus_index(bus) >= 0:
			continue
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
		if bus != "Master":
			AudioServer.set_bus_send(AudioServer.get_bus_index(bus), "Master")

func apply_settings(settings: Dictionary) -> void:
	_apply_settings(settings)

func _apply_settings(settings: Dictionary) -> void:
	var muted := bool(settings.get("muted", false))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)
	for pair in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"], ["UI", "ui"]]:
		var index := AudioServer.get_bus_index(str(pair[0]))
		if index < 0:
			continue
		var volume := clampf(float(settings.get(str(pair[1]), 1.0)), 0.0, 1.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.001)))

func play_event(event: String, category := "SFX") -> bool:
	var path := str(EVENT_PATHS.get(event, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return false
	var stream := load(path) as AudioStream
	if stream == null or players.is_empty():
		return false
	var first := 0 if category != "UI" else 8
	var last := 7 if category != "UI" else 9
	for index in range(first, last + 1):
		if not players[index].playing:
			players[index].stream = stream
			players[index].play()
			return true
	return false

func set_music(track: String) -> void:
	var path := str(MUSIC_PATHS.get(track, ""))
	if track.begins_with("battle_region_"):
		path = str(MUSIC_PATHS.get(track, MUSIC_PATHS.get("battle", "")))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null or music_players.is_empty():
		return
	var next := 0 if active_music != 0 else 1
	var outgoing := active_music
	if music_tween != null and music_tween.is_running():
		music_tween.kill()
	music_players[next].stream = stream
	music_players[next].volume_db = -40.0
	music_players[next].play()
	music_tween = create_tween()
	music_tween.tween_property(music_players[next], "volume_db", 0.0, 0.55)
	if outgoing >= 0:
		music_tween.parallel().tween_property(music_players[outgoing], "volume_db", -40.0, 0.55)
		music_tween.tween_callback(music_players[outgoing].stop)
	active_music = next
