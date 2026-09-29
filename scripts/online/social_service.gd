class_name SocialService
extends RefCounted

const FRIEND_LIMIT := 50
const MOCK_FRIENDS := [
	{"id": "MOCK-FRIEND-1", "name": "Aldric Moonfall", "hero": "knight", "evolution": 1, "level": 18, "power": 6200, "difficulty": "Easy", "region": 3, "stage": 12, "rank": "Silver", "guild": "The Ember Oath", "frame": "golden_frame"},
	{"id": "MOCK-FRIEND-2", "name": "Lyra Stormweaver", "hero": "mage", "level": 25, "power": 9300, "difficulty": "Normal", "region": 5, "stage": 6, "rank": "Gold", "guild": "Silver Stags", "frame": ""},
	{"id": "MOCK-FRIEND-3", "name": "Thorne Blackbriar", "hero": "ranger", "level": 31, "power": 14500, "difficulty": "Hard", "region": 2, "stage": 18, "rank": "Platinum", "guild": "", "frame": ""}
]
var profile: SaveData
var online_state := OnlineState.DEVELOPMENT_ONLINE
var fail_next := false

func _init(value: SaveData) -> void:
	profile = value
	for key in ["friends", "incoming", "outgoing"]:
		if not profile.friends_state.has(key): profile.friends_state[key] = []
	if profile.friends_state.friends.is_empty(): profile.friends_state.friends = MOCK_FRIENDS.duplicate(true)
	if profile.friends_state.incoming.is_empty(): profile.friends_state.incoming = [{"id": "MOCK-INCOMING-1", "name": "Ilyan Redbrook", "hero": "knight", "evolution": 1, "level": 12, "power": 2800, "difficulty": "Easy", "region": 1, "stage": 5, "rank": "Bronze", "guild": "", "frame": ""}]

func add_friend(player_id: String) -> bool:
	if fail_next:
		fail_next = false
		online_state = OnlineState.OFFLINE
		return false
	if player_id.strip_edges().is_empty() or profile.friends_state.friends.size() >= FRIEND_LIMIT or player_id == str(profile.account_meta.player_id): return false
	for friend in profile.friends_state.friends:
		if str(friend.id) == player_id: return false
	profile.friends_state.outgoing.append({"id": player_id.strip_edges(), "name": "Adventurer " + player_id.right(4), "hero": "knight", "level": 1, "power": 350, "rank": "Bronze", "guild": "", "frame": ""})
	profile.save()
	return true

func accept_request(player_id: String) -> bool:
	if profile.friends_state.friends.size() >= FRIEND_LIMIT: return false
	for index in profile.friends_state.incoming.size():
		var request: Dictionary = profile.friends_state.incoming[index]
		if str(request.id) == player_id:
			profile.friends_state.friends.append(request.duplicate(true))
			profile.friends_state.incoming.remove_at(index)
			profile.save()
			return true
	return false

func reject_request(player_id: String) -> bool:
	for index in profile.friends_state.incoming.size():
		if str(profile.friends_state.incoming[index].id) == player_id:
			profile.friends_state.incoming.remove_at(index); profile.save(); return true
	return false

func remove_friend(player_id: String) -> bool:
	for index in profile.friends_state.friends.size():
		if str(profile.friends_state.friends[index].id) == player_id:
			profile.friends_state.friends.remove_at(index); profile.save(); return true
	return false

func friend(player_id: String) -> Dictionary:
	for record in profile.friends_state.friends:
		if str(record.id) == player_id: return record.duplicate(true)
	return {}

func badge() -> bool:
	if not profile.friends_state.get("incoming", []).is_empty(): return true
	if int(profile.pvp_state.get("attempts", 0)) > 0 and profile.pvp_state.get("viewed_day", "") != CalendarService.day(): return true
	var boss: Dictionary = profile.guild_state.get("boss", {})
	return not profile.guild_state.get("guild", {}).is_empty() and int(boss.get("attempts", 0)) > 0 and profile.guild_state.get("boss_viewed_day", "") != CalendarService.day()
