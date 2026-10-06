class_name SocialScreen
extends VBoxContainer

const CrownUI = preload("res://scripts/ui/crown_ui.gd")

signal tutorial_feature_opened(feature_name: String)

var profile: SaveData
var friends: SocialService
var guild: GuildService
var pvp: PvPService
var tab := "Friends"
var notice := ""
var on_change: Callable
var opponents: Array = []
var message_edit: LineEdit

func configure(value: SaveData, callback: Callable) -> void:
	profile = value
	friends = SocialService.new(profile)
	guild = GuildService.new(profile)
	pvp = PvPService.new(profile)
	on_change = callback
	refresh()

func refresh() -> void:
	if profile == null: return
	for child in get_children(): child.queue_free()
	add_child(_label("SOCIAL HALL • %s" % friends.online_state.to_upper(), 38))
	var tabs := HBoxContainer.new()
	add_child(tabs)
	for name in ["Friends", "Guild", "PvP"]:
		var button := _button(name.to_upper())
		button.pressed.connect(_select.bind(name))
		tabs.add_child(button)
	match tab:
		"Guild": _guild_view()
		"PvP": _pvp_view()
		_: _friends_view()
	if notice != "": add_child(_label(notice, 25))

func _friends_view() -> void:
	var list: Array = profile.friends_state.get("friends", [])
	add_child(_label("FRIENDS %d/%d" % [list.size(), SocialService.FRIEND_LIMIT], 30))
	if list.is_empty(): add_child(_label("No friends yet. Add a friend with their Player ID.", 26))
	var add_row := HBoxContainer.new()
	add_child(add_row)
	var id := LineEdit.new()
	id.placeholder_text = "Player ID"
	id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_row.add_child(id)
	var add := _button("ADD")
	add.pressed.connect(_add_friend.bind(id))
	add_row.add_child(add)
	for friend in list:
		var card := _panel()
		add_child(card)
		var card_row := HBoxContainer.new()
		card.add_child(card_row)
		_add_portrait(card_row, str(friend.get("hero", "knight")), int(friend.get("evolution", 0)), "golden_frame" if str(friend.get("frame", "")) in ["Golden Profile Frame", "golden_frame"] else "", Vector2(110, 132))
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_row.add_child(box)
		var frame := " • " + str(friend.frame) if str(friend.get("frame", "")) != "" else ""
		box.add_child(_label("%s%s\n%s • Level %d • Power %d\nCampaign %s %d-%d • Guild %s • PvP %s" % [friend.name, frame, str(friend.hero).capitalize(), int(friend.level), int(friend.power), str(friend.get("difficulty", "Easy")), int(friend.get("region", 1)), int(friend.get("stage", 1)), str(friend.guild), str(friend.rank)], 23))
		var actions := HBoxContainer.new()
		box.add_child(actions)
		var duel := _button("PRACTICE BATTLE")
		duel.pressed.connect(_practice.bind(friend))
		actions.add_child(duel)
		var remove := _button("REMOVE")
		remove.pressed.connect(_remove.bind(str(friend.id)))
		actions.add_child(remove)
	var incoming: Array = profile.friends_state.get("incoming", [])
	add_child(_label("INCOMING REQUESTS • %d" % incoming.size(), 28))
	for request in incoming:
		var row := HBoxContainer.new()
		add_child(row)
		_add_portrait(row, str(request.get("hero", "knight")), int(request.get("evolution", 0)), str(request.get("frame", "")), Vector2(72, 88))
		var request_label := _label("%s • %s" % [request.name, request.id], 23)
		request_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(request_label)
		var accept := _button("ACCEPT")
		accept.pressed.connect(_accept.bind(str(request.id)))
		row.add_child(accept)
		var reject := _button("DECLINE")
		reject.pressed.connect(_reject.bind(str(request.id)))
		row.add_child(reject)
	add_child(_label("Outgoing requests: %d" % profile.friends_state.get("outgoing", []).size(), 22))

func _guild_view() -> void:
	var state: Dictionary = profile.guild_state
	var record: Dictionary = state.get("guild", {})
	if record.is_empty():
		add_child(_label("GUILDS", 30))
		add_child(_label("Join a Guild or create one to take part in group activities.", 26))
		var name := LineEdit.new(); name.placeholder_text = "Guild name (3–24)"; add_child(name)
		var tag := LineEdit.new(); tag.placeholder_text = "Tag (2–6)"; add_child(tag)
		var description := LineEdit.new(); description.placeholder_text = "Description"; add_child(description)
		var create := _button("CREATE GUILD • FREE DEVELOPMENT")
		create.pressed.connect(_create_guild.bind(name, tag, description))
		add_child(create)
		for guild_record in GuildService.CATALOG:
			var join := _button("JOIN %s [%s] • Lv.%d • %d MEMBERS • %d POWER" % [guild_record.name, guild_record.tag, guild_record.level, guild_record.members, guild_record.power])
			join.pressed.connect(_join_guild.bind(str(guild_record.id)))
			add_child(join)
		return
	add_child(_label("%s [%s] • Lv.%d\n%s\nRole: %s • Guild Power: %d\nContribution: %d • Guild Coins: %d" % [record.get("name", "Guild"), record.get("tag", ""), int(record.get("level", 1)), record.get("description", ""), state.role, int(record.get("power", profile.power())), int(state.contribution), int(state.coins)], 27))
	var checkin := _button("DAILY GUILD CHECK-IN +5 CONTRIBUTION")
	checkin.disabled = state.checkin_day == CalendarService.day()
	checkin.pressed.connect(_checkin)
	add_child(checkin)
	var boss: Dictionary = state.boss
	var boss_label := _label("GUILD BOSS • HP %d/%d\nToday %d/2 attempts • Personal damage %d" % [int(boss.hp), int(boss.max_hp), 2 - int(boss.attempts), int(boss.personal_damage)], 27)
	add_child(boss_label)
	var attack := _button("FIGHT GUILD BOSS • 30 SECOND AUTO RUN")
	attack.disabled = int(boss.attempts) <= 0
	attack.pressed.connect(_boss_attack)
	add_child(attack)
	for milestone in [10000, 50000, 200000]:
		var reward := _button("CLAIM DAMAGE REWARD • %d" % milestone)
		reward.disabled = int(boss.personal_damage) < milestone or boss.claimed.has(str(milestone))
		reward.pressed.connect(_claim_boss.bind(milestone))
		add_child(reward)
	var roster: Array = record.get("members", [])
	add_child(_label("ROSTER %d" % roster.size(), 30))
	for member in roster:
		var frame := " • Golden Profile Frame" if profile.owned_cosmetics.has("golden_frame") and profile.equipped_cosmetics.get("Profile Frame", "") == "golden_frame" and str(member.id) == str(profile.account_meta.player_id) else ""
		var member_row := HBoxContainer.new()
		member_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(member_row)
		var member_hero := str(member.get("hero", "knight"))
		var member_evolution := int(member.get("evolution", 0))
		if str(member.id) == str(profile.account_meta.player_id):
			member_evolution = int(profile.heroes.get(member_hero, {}).get("evolution", member_evolution))
		_add_portrait(member_row, member_hero, member_evolution, "golden_frame" if not frame.is_empty() else "", Vector2(92, 112))
		var member_details := _label("%s%s • %d Power • %s • %s contribution • Active %s" % [member.name, frame, int(member.power), str(member.hero).capitalize(), member.get("role", "Member"), str(member.get("last_active", "Unknown"))], 22)
		member_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		member_row.add_child(member_details)
	var leave := _button("LEAVE GUILD")
	leave.disabled = state.role == "Leader"
	leave.pressed.connect(_leave)
	add_child(leave)
	var chat_title := _label("GUILD CHAT • Local development • Max 180 characters", 27)
	add_child(chat_title)
	var chat_log := _panel()
	add_child(chat_log)
	var messages := VBoxContainer.new()
	chat_log.add_child(messages)
	for entry in state.chat:
		messages.add_child(_label("%s  %s\n%s" % [entry.sender, entry.timestamp, entry.text], 20))
	var send_row := HBoxContainer.new()
	add_child(send_row)
	message_edit = LineEdit.new()
	message_edit.placeholder_text = "Message the guild"
	message_edit.max_length = GuildService.MAX_MESSAGE
	message_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	send_row.add_child(message_edit)
	var send := _button("SEND")
	send.pressed.connect(_send_chat)
	send_row.add_child(send)
	var report := _button("REPORT MESSAGE • PLACEHOLDER")
	report.pressed.connect(_report_chat)
	add_child(report)
	var guild_shop := _button("GUILD SHOP • COMING LATER")
	guild_shop.disabled = true
	add_child(guild_shop)

func _pvp_view() -> void:
	var state: Dictionary = profile.pvp_state
	add_child(_label("ASYNC ARENA • Season %s\n%s • %d Rating • %d Wins / %d Losses\nRanked attempts %d/5 • Tokens %d" % [state.season_id, pvp.rank(), state.rating, state.wins, state.losses, state.attempts, state.tokens], 28))
	var find := _button("FIND 3 OPPONENTS")
	find.pressed.connect(_find_opponents)
	add_child(find)
	for opponent in opponents:
		var frame := " • Golden Profile Frame" if str(opponent.get("frame", "")) == "golden_frame" else ""
		var card := _panel()
		add_child(card)
		var card_row := HBoxContainer.new(); card.add_child(card_row)
		var snapshot: Dictionary = opponent.get("snapshot", {})
		_add_portrait(card_row, str(snapshot.get("hero_id", opponent.get("hero", "knight"))), int(snapshot.get("evolution", 0)), "golden_frame" if str(opponent.get("frame", "")) == "golden_frame" else "", Vector2(110, 132))
		var box := VBoxContainer.new(); box.size_flags_horizontal = Control.SIZE_EXPAND_FILL; card_row.add_child(box)
		box.add_child(_label("%s%s • %s\nPower %d • Rating %d • %s\nReward preview: 500 Gold + 2 Gems + 5 PvP Tokens" % [opponent.name, frame, str(opponent.hero).capitalize(), int(opponent.power), int(opponent.rating), opponent.rank], 23))
		var fight := _button("RANKED AUTO BATTLE • 60 SEC")
		fight.disabled = int(profile.pvp_state.attempts) <= 0
		fight.pressed.connect(_ranked_fight.bind(opponent))
		box.add_child(fight)
	if not opponents.is_empty() and not profile.friends_state.friends.is_empty():
		var practice := _button("PRACTICE DUEL • " + str(profile.friends_state.friends[0].name))
		practice.pressed.connect(_practice.bind(profile.friends_state.friends[0]))
		add_child(practice)
	add_child(_label("Timeout is resolved by remaining HP percentage. Practice has no rewards.", 23))

func _select(value: String) -> void:
	tab = value
	if tab == "PvP":
		profile.pvp_state["viewed_day"] = CalendarService.day()
		profile.save()
	if tab == "Guild":
		profile.guild_state["boss_viewed_day"] = CalendarService.day()
		profile.save()
	if tab == "PvP" and opponents.is_empty(): _find_opponents()
	else: refresh()
	tutorial_feature_opened.emit(tab)

func _add_friend(id: LineEdit) -> void:
	notice = "Friend request sent." if friends.add_friend(id.text) else "Friend could not be added. Check the ID or friend limit."
	refresh()
	_sync()

func _accept(id: String) -> void:
	notice = "Friend request accepted." if friends.accept_request(id) else "Could not accept request."
	refresh(); _sync()

func _reject(id: String) -> void:
	friends.reject_request(id); notice = "Request declined."; refresh(); _sync()

func _remove(id: String) -> void:
	friends.remove_friend(id); notice = "Friend removed."; refresh(); _sync()

func _practice(friend: Dictionary) -> void:
	var result := pvp.practice(friend)
	notice = "Practice result: %s • %ds • no rewards" % [str(result.get("result", "Unavailable")), int(result.get("duration", 0))]
	refresh()

func _create_guild(name: LineEdit, tag: LineEdit, description: LineEdit) -> void:
	notice = "Guild created." if guild.create(name.text, tag.text, description.text) else "Guild name or tag is invalid."
	refresh(); _sync()

func _join_guild(id: String) -> void:
	notice = "Joined the guild." if guild.join(id) else "Could not join that guild."
	refresh(); _sync()

func _leave() -> void:
	notice = "Left the guild." if guild.leave() else "Guild leaders must transfer leadership before leaving."
	refresh(); _sync()

func _checkin() -> void:
	guild.check_in(); notice = "Guild check-in recorded."; refresh(); _sync()

func _boss_attack() -> void:
	var damage := maxi(1000, profile.power() * 30)
	var result := guild.fight_boss(damage)
	notice = "Guild Boss: %d damage in a simulated 30 second run." % int(result.get("damage", 0)) if bool(result.get("ok", false)) else str(result.get("error", "Unavailable"))
	refresh(); _sync()

func _claim_boss(milestone: int) -> void:
	notice = "Guild Boss milestone claimed." if guild.claim_damage_reward(milestone) else "Milestone not ready."
	refresh(); _sync()

func _send_chat() -> void:
	notice = "Message sent." if guild.send_message(message_edit.text) else "Message too long, empty, or on cooldown."
	refresh(); _sync()

func _report_chat() -> void:
	notice = "Reports will be sent to the server moderation service in a production build."
	refresh()

func _find_opponents() -> void:
	var result := pvp.opponents()
	if bool(result.get("ok", false)):
		opponents = result.opponents
		notice = "Three development opponents found."
	else:
		notice = str(result.get("error", "Matchmaking unavailable."))
	refresh()

func _ranked_fight(opponent: Dictionary) -> void:
	var result := pvp.fight(opponent)
	if bool(result.get("ok", false)): notice = "%s • %s %d Rating • %ds • HP %.0f%% / %.0f%% • +%d Gold" % ["Victory" if result.won else "Defeat", result.rank, result.rating, int(result.duration), float(result.player_hp_remaining) * 100.0, float(result.opponent_hp_remaining) * 100.0, result.reward.gold]
	else: notice = str(result.get("error", "Match unavailable."))
	refresh(); _sync()

func _sync() -> void:
	if on_change.is_valid(): on_change.call()

func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	CrownUI.style_panel(panel)
	return panel

func _add_portrait(parent: Control, hero_id: String, evolution: int, frame: String, minimum: Vector2) -> void:
	var portrait := HeroPortrait.new()
	var normalized_hero := hero_id.to_lower().replace(" ", "_")
	portrait.hero_id = normalized_hero if HeroData.HEROES.has(normalized_hero) else "knight"
	portrait.evolution = clampi(evolution, 0, 4)
	portrait.profile_frame = frame
	portrait.custom_minimum_size = minimum
	parent.add_child(portrait)

func _label(value: String, size: int) -> Label:
	var label := Label.new(); label.text = value; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.add_theme_font_size_override("font_size", size); label.add_theme_color_override("font_color", Color("e9c87d")); return label

func _button(value: String) -> Button:
	var button := Button.new(); button.text = value; button.custom_minimum_size.y = 68; button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; button.add_theme_font_size_override("font_size", 21); button.clip_text = true; CrownUI.set_button_role(button, &"QuietButton"); return button
