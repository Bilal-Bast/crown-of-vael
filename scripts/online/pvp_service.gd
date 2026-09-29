class_name PvPService
extends RefCounted

const DAILY_ATTEMPTS := 5
const MATCH_SECONDS := 60
const RANK_THRESHOLDS := {"Bronze": 0, "Silver": 1100, "Gold": 1300, "Platinum": 1600, "Diamond": 2000, "Master": 2400}
var profile: SaveData
var provider: DevelopmentPvPProvider

func _init(value: SaveData, pvp_provider: DevelopmentPvPProvider = null) -> void:
	profile = value
	provider = pvp_provider if pvp_provider != null else DevelopmentPvPProvider.new()
	refresh_day()

func refresh_day(day: String = "") -> void:
	day = CalendarService.day() if day == "" else day
	if profile.pvp_state.get("attempt_day", "") != day:
		profile.pvp_state["attempt_day"] = day
		profile.pvp_state["attempts"] = DAILY_ATTEMPTS
		profile.save()

func opponents() -> Dictionary:
	return provider.opponents(profile, 3)

func fight(opponent: Dictionary, practice: bool = false, result_override: String = "") -> Dictionary:
	refresh_day()
	if not practice and int(profile.pvp_state.attempts) <= 0: return {"ok": false, "error": "No ranked attempts remain today."}
	var snapshot: Dictionary = opponent.get("snapshot", {})
	if snapshot.is_empty(): return {"ok": false, "error": "Opponent snapshot unavailable."}
	var result := result_override
	var combat_summary := {"duration": MATCH_SECONDS, "player_hp_remaining": 0.0, "opponent_hp_remaining": 0.0}
	if result == "":
		combat_summary = simulate_auto_battle(snapshot)
		result = str(combat_summary.result)
	if result not in ["win", "loss", "timeout_win", "timeout_loss"]: return {"ok": false, "error": "Invalid match result."}
	var won := result in ["win", "timeout_win"]
	if practice: return {"ok": true, "result": result, "won": won, "reward": {}, "duration": combat_summary.duration, "player_hp_remaining": combat_summary.player_hp_remaining, "opponent_hp_remaining": combat_summary.opponent_hp_remaining, "practice": true}
	profile.pvp_state.attempts = int(profile.pvp_state.attempts) - 1
	var rating_delta := 25 if won else -18
	profile.pvp_state.rating = maxi(0, int(profile.pvp_state.rating) + rating_delta)
	if won:
		profile.pvp_state.wins = int(profile.pvp_state.wins) + 1
		profile.pvp_state.tokens = int(profile.pvp_state.tokens) + 5
		profile.gold += 500
		profile.gems += 2
	else:
		profile.pvp_state.losses = int(profile.pvp_state.losses) + 1
		profile.pvp_state.tokens = int(profile.pvp_state.tokens) + 1
		profile.gold += 150
	var rank := DevelopmentPvPProvider.rank_for_rating(int(profile.pvp_state.rating))
	profile.pvp_state.highest_rank = rank if _rank_value(rank) > _rank_value(str(profile.pvp_state.highest_rank)) else profile.pvp_state.highest_rank
	profile.account_meta.pvp_rank = rank
	profile.save()
	return {"ok": true, "result": result, "won": won, "rating_delta": rating_delta, "rating": profile.pvp_state.rating, "rank": rank, "reward": {"gold": 500 if won else 150, "gems": 2 if won else 0, "pvp_tokens": 5 if won else 1}, "duration": combat_summary.duration, "player_hp_remaining": combat_summary.player_hp_remaining, "opponent_hp_remaining": combat_summary.opponent_hp_remaining, "practice": false}

func simulate_auto_battle(snapshot: Dictionary) -> Dictionary:
	var player: Dictionary = profile.hero_stats()
	var enemy: Dictionary = snapshot.get("hero", {})
	if enemy.is_empty(): enemy = {"hp": 1, "atk": 1, "armor": 0, "speed": 1, "crit_chance": 0.0, "crit_damage": 1.5}
	var player_dps := maxf(1.0, (float(player.atk) * float(player.speed) * (1.0 + float(player.crit_chance) * (float(player.crit_damage) - 1.0))) - float(enemy.get("armor", 0)))
	var enemy_dps := maxf(1.0, (float(enemy.get("atk", 1)) * float(enemy.get("speed", 1)) * (1.0 + float(enemy.get("crit_chance", 0)) * (float(enemy.get("crit_damage", 1.5)) - 1.0))) - float(player.armor))
	var player_kill_time := float(enemy.get("hp", 1)) / player_dps
	var enemy_kill_time := float(player.hp) / enemy_dps
	var duration := minf(MATCH_SECONDS, minf(player_kill_time, enemy_kill_time))
	var player_remaining := clampf((float(player.hp) - enemy_dps * duration) / maxf(1.0, float(player.hp)), 0.0, 1.0)
	var opponent_remaining := clampf((float(enemy.get("hp", 1)) - player_dps * duration) / maxf(1.0, float(enemy.get("hp", 1))), 0.0, 1.0)
	var result := "win" if player_kill_time < enemy_kill_time and player_kill_time <= MATCH_SECONDS else "loss" if enemy_kill_time < player_kill_time and enemy_kill_time <= MATCH_SECONDS else "timeout_win" if player_remaining > opponent_remaining else "timeout_loss"
	return {"result": result, "duration": duration, "player_hp_remaining": player_remaining, "opponent_hp_remaining": opponent_remaining}

func practice(friend: Dictionary) -> Dictionary:
	var snapshot := friend.duplicate(true)
	if not snapshot.has("snapshot"):
		snapshot["snapshot"] = {"power": int(snapshot.get("power", 1)), "hero_id": str(snapshot.get("hero", "knight")), "hero": {}}
	return fight(snapshot, true)

func rank() -> String:
	return DevelopmentPvPProvider.rank_for_rating(int(profile.pvp_state.rating))

func _rank_value(rank_name: String) -> int:
	var order := ["Bronze", "Silver", "Gold", "Platinum", "Diamond", "Master"]
	return order.find(rank_name)
