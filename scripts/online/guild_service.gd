class_name GuildService
extends RefCounted

const CHAT_LIMIT := 100
const MAX_MESSAGE := 180
const CHAT_COOLDOWN := 2
const CATALOG := [
	{"id": "guild_ember", "name": "The Ember Oath", "tag": "EMBER", "description": "Keepers of the first flame.", "level": 3, "members": 8, "power": 52000},
	{"id": "guild_silver", "name": "Silver Stags", "tag": "STAG", "description": "A quiet company of scouts.", "level": 2, "members": 5, "power": 34000},
	{"id": "guild_veil", "name": "Veilwatch", "tag": "VEIL", "description": "Guardians of the northern veil.", "level": 1, "members": 2, "power": 16000}
]
var profile: SaveData
var now_override := 0

func _init(value: SaveData) -> void:
	profile = value
	if profile.guild_state.is_empty():
		profile.guild_state = {"guild": {}, "role": "", "contribution": 0, "coins": 0, "boss": {"day": "", "attempts": 2, "hp": 1000000, "max_hp": 1000000, "personal_damage": 0, "claimed": {}}, "chat": [], "last_chat": 0, "checkin_day": ""}
	_ensure_keys()

func _ensure_keys() -> void:
	var defaults := {"guild": {}, "role": "", "contribution": 0, "coins": 0, "boss": {"day": "", "attempts": 2, "hp": 1000000, "max_hp": 1000000, "personal_damage": 0, "claimed": {}}, "chat": [], "last_chat": 0, "checkin_day": ""}
	for key in defaults:
		if not profile.guild_state.has(key): profile.guild_state[key] = defaults[key].duplicate(true) if defaults[key] is Dictionary or defaults[key] is Array else defaults[key]

func create(name: String, tag: String, description: String) -> bool:
	if not profile.guild_state.guild.is_empty(): return false
	var clean := name.strip_edges()
	var clean_tag := tag.strip_edges().to_upper()
	if clean.length() < 3 or clean.length() > 24 or clean_tag.length() < 2 or clean_tag.length() > 6: return false
	var id := "G-%08X" % randi()
	profile.guild_state.guild = {"id": id, "name": clean, "tag": clean_tag, "description": description.strip_edges().substr(0, 120), "icon": "♜", "level": 1, "leader_id": profile.account_meta.player_id, "members": [{"id": profile.account_meta.player_id, "name": profile.account_meta.display_name, "power": profile.power(), "hero": profile.selected_hero_id, "role": "Leader", "contribution": int(profile.guild_state.contribution), "last_active": "Now"}], "boss": profile.guild_state.boss}
	profile.guild_state.role = "Leader"
	profile.account_meta.guild_id = id
	profile.save()
	return true

func join(guild_id: String) -> bool:
	if not profile.guild_state.guild.is_empty(): return false
	for record in CATALOG:
		if str(record.id) != guild_id: continue
		profile.guild_state.guild = record.duplicate(true)
		profile.guild_state.guild["leader_id"] = "MOCK-LEADER"
		profile.guild_state.guild["members"] = [{"id": "MOCK-LEADER", "name": "Guildmaster Rowan", "power": record.power, "hero": "knight", "role": "Leader", "contribution": 120, "last_active": "Today"}, {"id": str(profile.account_meta.player_id), "name": str(profile.account_meta.display_name), "power": profile.power(), "hero": profile.selected_hero_id, "role": "Member", "contribution": int(profile.guild_state.contribution), "last_active": "Now"}]
		profile.guild_state.role = "Member"
		profile.account_meta.guild_id = guild_id
		profile.save()
		return true
	return false

func leave() -> bool:
	if profile.guild_state.guild.is_empty() or profile.guild_state.role == "Leader": return false
	profile.guild_state.guild = {}
	profile.guild_state.role = ""
	profile.account_meta.guild_id = ""
	profile.save()
	return true

func can_manage() -> bool:
	return profile.guild_state.role in ["Leader", "Officer"]

func set_role(player_id: String, role: String) -> bool:
	if profile.guild_state.role != "Leader" or role not in ["Officer", "Member"]: return false
	for member in profile.guild_state.guild.get("members", []):
		if str(member.id) == player_id and str(member.id) != str(profile.account_meta.player_id):
			member.role = role
			profile.save()
			return true
	return false

func transfer_leadership(player_id: String) -> bool:
	if profile.guild_state.role != "Leader": return false
	var members: Array = profile.guild_state.guild.get("members", [])
	var target: Dictionary = {}
	var old_leader: Dictionary = {}
	for member in members:
		if str(member.id) == player_id: target = member
		if str(member.id) == str(profile.account_meta.player_id): old_leader = member
	if target.is_empty() or old_leader.is_empty(): return false
	target.role = "Leader"
	old_leader.role = "Member"
	profile.guild_state.guild.leader_id = player_id
	profile.guild_state.role = "Member"
	profile.save()
	return true

func remove_member(player_id: String) -> bool:
	if profile.guild_state.role not in ["Leader", "Officer"] or player_id == str(profile.account_meta.player_id): return false
	var members: Array = profile.guild_state.guild.get("members", [])
	for index in members.size():
		if str(members[index].id) == player_id:
			members.remove_at(index)
			profile.save()
			return true
	return false

func check_in() -> bool:
	var today := CalendarService.day()
	if profile.guild_state.checkin_day == today or profile.guild_state.guild.is_empty(): return false
	profile.guild_state.checkin_day = today
	_add_contribution(5)
	profile.guild_state.coins = int(profile.guild_state.coins) + 1
	profile.save()
	return true

func reset_boss_day(day: String = "") -> void:
	day = CalendarService.day() if day == "" else day
	var boss: Dictionary = profile.guild_state.boss
	if str(boss.day) != day:
		boss.day = day
		boss.attempts = 2
		boss.personal_damage = 0
		boss.claimed = {}
		boss.defeat_reward_claimed = false

func fight_boss(damage: int) -> Dictionary:
	if profile.guild_state.guild.is_empty(): return {"ok": false, "error": "Join a guild to challenge its boss."}
	reset_boss_day()
	var boss: Dictionary = profile.guild_state.boss
	if int(boss.attempts) <= 0 or damage <= 0: return {"ok": false, "error": "No Guild Boss attempts remain today."}
	var dealt := mini(damage, int(boss.hp))
	var was_alive := int(boss.hp) > 0
	boss.hp = maxi(0, int(boss.hp) - dealt)
	boss.attempts = int(boss.attempts) - 1
	boss.personal_damage = int(boss.personal_damage) + dealt
	profile.guild_state.guild["boss"] = boss
	_add_contribution(maxi(1, dealt / 1000))
	profile.guild_state.coins = int(profile.guild_state.coins) + maxi(1, dealt / 10000)
	var defeat_reward := {}
	if was_alive and int(boss.hp) == 0 and not bool(boss.get("defeat_reward_claimed", false)):
		boss.defeat_reward_claimed = true
		profile.gold += 5000
		profile.gems += 20
		profile.enhancement_stones += 50
		profile.companion_essence += 50
		profile.artifact_dust += 30
		profile.guild_state.coins = int(profile.guild_state.coins) + 100
		defeat_reward = {"gold": 5000, "gems": 20, "enhancement_stones": 50, "companion_essence": 50, "artifact_dust": 30, "guild_coins": 100}
	profile.save()
	return {"ok": true, "damage": dealt, "hp": boss.hp, "defeated": int(boss.hp) == 0, "coins": maxi(1, dealt / 10000), "defeat_reward": defeat_reward}

func claim_damage_reward(milestone: int) -> bool:
	var boss: Dictionary = profile.guild_state.boss
	if int(boss.personal_damage) < milestone or boss.claimed.has(str(milestone)): return false
	boss.claimed[str(milestone)] = true
	profile.gold += 1000 + milestone / 100
	profile.enhancement_stones += 10
	profile.gems += 5 if milestone >= 50000 else 0
	profile.guild_state.coins = int(profile.guild_state.coins) + 20
	profile.save()
	return true

func send_message(text: String, sender: String = "") -> bool:
	var clean := text.strip_edges()
	if clean.is_empty() or clean.length() > MAX_MESSAGE or profile.guild_state.guild.is_empty(): return false
	var now := int(Time.get_unix_time_from_system()) if now_override == 0 else now_override
	if now - int(profile.guild_state.last_chat) < CHAT_COOLDOWN: return false
	profile.guild_state.last_chat = now
	var filtered := clean
	# Placeholder filter only. Production moderation needs server-side enforcement.
	for blocked in ["<script>", "[blocked]"]: filtered = filtered.replace(blocked, "•••")
	profile.guild_state.chat.append({"sender": profile.account_meta.display_name if sender == "" else sender, "text": filtered, "timestamp": Time.get_datetime_string_from_system()})
	while profile.guild_state.chat.size() > CHAT_LIMIT: profile.guild_state.chat.pop_front()
	profile.save()
	return true

func _add_contribution(amount: int) -> void:
	profile.guild_state.contribution = int(profile.guild_state.contribution) + amount
	if not profile.guild_state.guild.is_empty():
		for member in profile.guild_state.guild.get("members", []):
			if str(member.id) == str(profile.account_meta.player_id): member.contribution = int(member.get("contribution", 0)) + amount
	profile.save()
