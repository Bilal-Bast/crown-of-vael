class_name TutorialService
extends RefCounted

const STEPS := [
	{"id": "battle", "title": "BATTLE", "body": "Your hero attacks automatically. Enemies are defeated automatically, and the campaign advances through stages on its own."},
	{"id": "upgrade", "title": "UPGRADE", "body": "Spend Gold on ATK to help your hero clear enemies faster. Make your first ATK upgrade whenever it is affordable."},
	{"id": "waves", "title": "WAVES & STAGES", "body": "Each stage has three waves. Clearing them moves the campaign forward and brings new rewards."}
]
const FEATURES := {
	"Equipment": ["EQUIPMENT", "Gear adds hero stats. Check new drops in your Armory and equip useful pieces."],
	"Skills": ["SKILLS", "Skills add automatic combat effects. Level or equip a skill to shape your hero's build."],
	"Summon": ["SUMMON", "Summons can find heroes, gear, skills, companions, and artifacts. Use tickets before Gems."],
	"Heroes": ["HEROES", "Heroes bring different roles and stats. Unlock or select a hero to change your battle style."],
	"Companions": ["COMPANIONS", "Companions attack and add passive bonuses. Equip an unlocked companion to support your hero."],
	"Artifacts": ["ARTIFACTS", "Artifacts add lasting bonuses. Discover pieces in adventure modes and equip them in your collection."],
	"Adventure": ["ADVENTURE", "Adventure holds optional modes and campaign stages. Choose a run to earn focused rewards."],
	"Dungeons": ["DUNGEONS", "Dungeons provide focused materials. Choose an open dungeon and spend an attempt for its reward."],
	"Tower": ["TOWER", "The Tower rewards steady floor progress with milestone prizes. Start at your highest available floor."],
	"Boss Rush": ["BOSS RUSH", "Boss Rush chains boss fights for focused rewards. Use an attempt when you are ready."],
	"Endless Survival": ["ENDLESS SURVIVAL", "Endless tests how far your build can go and records your best wave. Enter when you want a challenge."],
	"Quests": ["QUESTS", "Quests track regular play and offer claimable rewards. Check here when a reward badge appears."],
	"Battle Pass": ["BATTLE PASS", "Battle Pass rewards come from normal play. Review the free track and claim any unlocked rewards."],
	"Friends": ["FRIENDS", "Friends let you connect with other players. Open Social to manage your friend list."],
	"Guild": ["GUILD", "Guilds provide a shared home and group activities. Open Social to join or create one."],
	"PvP": ["PVP", "PvP compares your team with other players for seasonal rewards. Open Social when you want to compete."]
}

var profile: SaveData

func _init(value: SaveData) -> void:
	profile = value

static func fresh_state() -> Dictionary:
	return {"completed": false, "skipped": false, "steps": {}, "features": {}, "migration": 1}

static func migrated_state(data: Dictionary) -> Dictionary:
	var raw: Variant = data.get("tutorial_state", null)
	if raw is Dictionary:
		var state := fresh_state()
		state.merge(raw, true)
		if not state.steps is Dictionary: state.steps = {}
		if not state.features is Dictionary: state.features = {}
		return state
	var meaningful := int(data.get("stage", 1)) > 1 or int(data.get("level", 1)) > 1 or int(data.get("gold", 0)) > 0 or int(data.get("phase8_version", 0)) > 0 or int(data.get("phase10_version", 0)) > 0
	for key in ["campaign_first_clears", "first_clears", "purchase_entitlements"]:
		var field: Variant = data.get(key, {})
		if field is Dictionary and not field.is_empty(): meaningful = true
	var saved_inventory: Variant = data.get("inventory", [])
	if saved_inventory is Array and saved_inventory.size() > EquipmentData.STARTER_KINDS.size(): meaningful = true
	var state := fresh_state()
	if meaningful:
		state.completed = true
		state.skipped = true
	return state

func onboarding_active() -> bool:
	return not bool(profile.tutorial_state.get("completed", false)) and not bool(profile.tutorial_state.get("skipped", false))

func mark_step(id: String) -> void:
	profile.tutorial_state.steps[id] = true
	if id == "waves": profile.tutorial_state.completed = true
	profile.save()

func skip() -> void:
	profile.tutorial_state.skipped = true
	profile.tutorial_state.completed = true
	profile.save()

func feature_seen(id: String) -> bool:
	return bool(profile.tutorial_state.features.get(id, false))

func acknowledge_feature(id: String) -> void:
	profile.tutorial_state.features[id] = true
	if id in ["Equipment", "Skills", "Summon"]: profile.tutorial_state.steps[id.to_lower()] = true
	profile.save()

func feature_copy(id: String) -> Array:
	return FEATURES.get(id, [])
