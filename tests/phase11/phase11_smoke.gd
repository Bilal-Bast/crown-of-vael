extends SceneTree

const PATH := "res://.godot/phase11_smoke.save"
const RESTORE_PATH := "res://.godot/phase11_restore.save"
const LEGACY_PATH := "res://.godot/phase11_legacy.save"
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if value: return
	failures += 1
	push_error("PHASE 11: " + label)

func _run() -> void:
	var profile := SaveData.new()
	profile.save_path = PATH
	profile.gold = 5000
	profile.level = 10
	profile.stage = 8
	profile.save()
	var player_id := str(profile.account_meta.player_id)
	var loaded := SaveData.load_from(PATH)
	check(str(loaded.account_meta.player_id) == player_id, "stable Guest Player ID")
	var auth := DevelopmentAuthProvider.new()
	var cloud := DevelopmentCloudSaveProvider.new()
	var account := AccountService.new(profile, auth, cloud)
	check(not account.set_display_name("  ") and not account.set_display_name("a") and not account.set_display_name("Invalid/Name"), "display-name validation")
	check(account.set_display_name("  Dawn Keeper  ") and profile.account_meta.display_name == "Dawn Keeper", "trimmed display name")
	check(account.link("Google").ok and profile.account_meta.account_type == "Linked" and profile.gold == 5000, "Google link preserves local progress")
	check(account.sync_now().ok, "manual cloud sync")
	check(not account.inspect_cloud().conflict, "clean sync has no false conflict")
	profile.level = 15
	profile.stage = 14
	profile.save()
	var conflict := account.inspect_cloud()
	check(conflict.ok and conflict.conflict and conflict.local.level == 15 and conflict.cloud.level == 10, "cloud conflict comparison")
	check(account.resolve_cloud("Keep Local").ok and cloud.load_cloud(player_id).cloud.summary.level == 15, "Keep Local resolution")
	profile.level = 20
	profile.save()
	check(account.sync_now().ok, "sync newer snapshot")
	var fresh := SaveData.new()
	fresh.save_path = RESTORE_PATH
	fresh.account_meta.player_id = player_id
	var fresh_account := AccountService.new(fresh, DevelopmentAuthProvider.new(), cloud)
	check(fresh_account.restore_cloud().ok and fresh.level == 20 and fresh.stage == 14 and fresh.gold == 5000, "restore cloud to clean profile")
	var restore_file := FileAccess.open(RESTORE_PATH, FileAccess.READ)
	var restore_json: Dictionary = JSON.parse_string(restore_file.get_as_text())
	check(int(restore_json.get("phase11_version", 0)) == 1, "cloud payload schema version")
	var before_failure := profile.gold
	cloud.fail_next = true
	check(not account.sync_now().ok and profile.gold == before_failure, "cloud failure preserves local save")
	cloud.fail_next = true
	check(not account.restore_cloud().ok and profile.gold == before_failure, "restore failure preserves local save")
	check(account.sign_out() and profile.account_meta.account_type == "Guest" and profile.gold == before_failure, "sign out preserves local progress")
	var cloud_file := FileAccess.open(cloud._path(player_id), FileAccess.READ)
	var cloud_record: Dictionary = JSON.parse_string(cloud_file.get_as_text())
	cloud_file.close()
	cloud_record["schema_version"] = 99
	cloud_file = FileAccess.open(cloud._path(player_id), FileAccess.WRITE)
	cloud_file.store_string(JSON.stringify(cloud_record)); cloud_file.close()
	check(not cloud.load_cloud(player_id).ok and profile.gold == before_failure, "incompatible cloud schema rejected safely")
	var conflict_cloud := DevelopmentCloudSaveProvider.new()
	var linked := AccountService.new(profile, DevelopmentAuthProvider.new(), conflict_cloud)
	check(linked.link("Apple", "Keep Local").ok and profile.account_meta.account_type == "Linked", "Apple link with cloud conflict choice")
	check(linked.sign_out(), "Apple sign out")
	var social := SocialService.new(profile)
	check(social.add_friend("MOCK-NEW-01") and profile.friends_state.outgoing.size() == 1, "outgoing friend request")
	check(social.accept_request("MOCK-INCOMING-1") and profile.friends_state.incoming.is_empty(), "accept incoming request")
	check(not social.accept_request("missing"), "invalid request rejected")
	profile.friends_state.incoming.append({"id": "MOCK-DECLINE", "name": "Decline"})
	check(social.reject_request("MOCK-DECLINE"), "reject friend request")
	check(social.friend("MOCK-FRIEND-1").has("name"), "friend profile available")
	check(social.remove_friend("MOCK-FRIEND-1"), "remove friend")
	for i in 55: profile.friends_state.friends.append({"id": "F%d" % i})
	check(not social.add_friend("OVER-LIMIT"), "friend limit")
	profile.friends_state.friends.clear()
	var guild := GuildService.new(profile)
	check(guild.create("Crown Wardens", "CROWN", "A local development guild"), "create guild")
	check(profile.guild_state.role == "Leader" and not guild.leave(), "guild leader permissions")
	profile.guild_state.guild.members.append({"id": "MOCK-MEMBER", "name": "Mock", "role": "Member", "power": 100, "hero": "knight", "contribution": 0})
	check(guild.set_role("MOCK-MEMBER", "Officer") and guild.can_manage(), "guild roles")
	check(guild.remove_member("MOCK-MEMBER") and guild.check_in() and not guild.check_in() and profile.guild_state.coins > 0, "roster removal, check-in and Guild Coin")
	var boss := guild.fight_boss(50000)
	check(boss.ok and boss.damage == 50000 and profile.guild_state.coins > 0, "Guild Boss damage and coins")
	check(guild.claim_damage_reward(10000) and not guild.claim_damage_reward(10000), "Guild Boss milestone claim")
	var defeat := guild.fight_boss(2000000)
	check(defeat.ok and defeat.defeated and int(defeat.defeat_reward.gems) == 20 and int(profile.guild_state.coins) >= 120, "Guild Boss defeat reward")
	guild.now_override = 1000
	check(guild.send_message("Hello guild") and not guild.send_message("Spam"), "chat send and cooldown")
	guild.now_override = 1003
	check(guild.send_message("[blocked] text") and "•••" in str(profile.guild_state.chat[1].text) and not guild.send_message("x".repeat(181)), "chat filter, length and history")
	profile.guild_state.guild.members.append({"id": "NEXT-LEADER", "name": "Next", "role": "Officer", "power": 100, "hero": "mage", "contribution": 0})
	check(guild.transfer_leadership("NEXT-LEADER") and profile.guild_state.role == "Member", "leadership transfer")
	var joiner := SaveData.new(); joiner.save_path = "res://.godot/phase11_joiner.save"
	var join_service := GuildService.new(joiner)
	check(join_service.join("guild_ember") and joiner.guild_state.role == "Member" and join_service.leave(), "mock guild join and leave")
	var pvp := PvPService.new(profile)
	var matchups := pvp.opponents()
	check(matchups.ok and matchups.opponents.size() == 3 and matchups.opponents[0].snapshot.has("skills") and matchups.opponents[0].snapshot.has("companions") and matchups.opponents[0].snapshot.has("artifacts"), "three build opponent snapshots")
	var before_rating := int(profile.pvp_state.rating)
	var ranked := pvp.fight(matchups.opponents[0], false, "timeout_win")
	check(ranked.ok and ranked.won and ranked.rating > before_rating and profile.pvp_state.wins == 1, "ranked timeout win and rating")
	var loss := pvp.fight(matchups.opponents[1], false, "loss")
	check(loss.ok and not loss.won and profile.pvp_state.losses == 1 and loss.rating_delta < 0, "ranked loss and rating")
	var attempts_before := int(profile.pvp_state.attempts)
	var practice := pvp.practice(profile.friends_state.friends[0] if not profile.friends_state.friends.is_empty() else {"power": profile.power(), "hero": "knight"})
	check(practice.ok and practice.practice and practice.reward.is_empty() and int(profile.pvp_state.attempts) == attempts_before, "practice duel gives no rewards")
	profile.pvp_state.attempts = 0
	check(not pvp.fight(matchups.opponents[0]).ok, "ranked daily attempt limit")
	check(DevelopmentPvPProvider.rank_for_rating(2500) == "Master" and DevelopmentPvPProvider.rank_for_rating(2100) == "Diamond", "rank thresholds")
	var simulation := pvp.simulate_auto_battle({"hero": {"hp": 1000000000.0, "atk": 1.0, "armor": 999999.0, "speed": 0.1, "crit_chance": 0.0, "crit_damage": 1.5}})
	check(int(simulation.duration) == PvPService.MATCH_SECONDS and str(simulation.result) == "timeout_loss", "60 second timeout HP tiebreak")
	var old_attempt_day := str(profile.pvp_state.attempt_day)
	pvp.refresh_day("2099-01-02")
	check(str(profile.pvp_state.attempt_day) == "2099-01-02" and profile.pvp_state.attempts == 5 and old_attempt_day != "2099-01-02", "daily ranked attempts reset")
	var offline_start := BattleController.new()
	offline_start.start(profile)
	check(offline_start.active, "campaign starts without online providers")
	var failed_social := SocialService.new(profile); failed_social.fail_next = true
	check(not failed_social.add_friend("MOCK-OFFLINE") and failed_social.online_state == "Offline", "social provider failure is contained")
	var failed_pvp := DevelopmentPvPProvider.new(); failed_pvp.fail_next = true
	check(not PvPService.new(profile, failed_pvp).opponents().ok, "matchmaking failure is contained")
	profile.save()
	var restored := SaveData.load_from(PATH)
	check(restored.gold == profile.gold and restored.account_meta.player_id == player_id, "Phase 10 progression and account migration")
	check(restored.guild_state.chat.size() == 2 and restored.pvp_state.wins == 1 and restored.friends_state.outgoing.size() == 1, "social state save/load")
	check(restored.pvp_state.rating == profile.pvp_state.rating and restored.guild_state.coins == profile.guild_state.coins, "PvP and Guild currency persistence")
	var legacy_file := FileAccess.open(LEGACY_PATH, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({"phase10_version": 1, "gold": 12345, "gems": 77, "level": 8, "stage": 9, "bp_season": {"id": "season_1", "xp": 400, "level": 2}}))
	legacy_file.close()
	var migrated := SaveData.load_from(LEGACY_PATH)
	check(migrated.gold == 12345 and migrated.gems == 77 and migrated.level == 8 and migrated.bp_season.level == 2 and str(migrated.account_meta.account_type) == "Guest", "Phase 10 save migration")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RESTORE_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(joiner.save_path))
	print("PHASE 11: %s" % ("PASS" if failures == 0 else "%d FAILURES" % failures))
	quit(0 if failures == 0 else 1)
