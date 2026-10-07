# Crown of Vael

Open `project.godot` in Godot 4.7.1 and run the project. The 1080 × 1920 portrait viewport scales to 360 × 640. Character sprites, region backgrounds, UI icons, and procedural combat effects are organized under `assets/`.

The selected hero fights automatically with equipped skills, companions, and artifacts. Campaign stages have three waves of five enemies; each region's Stage 20 is a 30-second boss fight. Stage progression, death rollback, boss retry, the HUD, and account-wide Gold upgrades continue from earlier phases.

## Phase 8 campaign world

The campaign spans ten regions with 20 stages each: Greenvale Outskirts, Whispering Forest, Ashen Highlands, Frostfang Mountains, Sunken Marshes, Crimson Desert, Ruined Kingdom, Shadowlands, Dragon Peaks, and Demon Realm. Each of the six difficulties (Easy, Normal, Hard, Nightmare, Hell, Infernal) has 200 stages, for 1,200 difficulty-stage combinations. Every region's Stages 5, 10, and 15 include an elite in the final wave; Stage 20 is a named region boss. A rare treasure enemy can replace a normal enemy and award extra resources.

Adventure → Campaign opens the overview, world map, and 20-stage selection for each unlocked region. Defeating a region boss opens the next region. Defeating the Demon Lord opens the next difficulty at 1-1 while keeping all account progress. Previous stages and regions remain replayable. Stage and region first-clear rewards, completion, unlocks, selected replay stage, and map position are saved per difficulty. Phase 7 Easy 1-10 saves continue at Easy 1-11 without treating the new Stage 20 as cleared.

`scripts/campaign/campaign_data.gd` centralizes regions, enemy pools, archetypes, element matchups, difficulty multipliers, rewards, treasure probability, and placeholder music paths. `tests/phase8/phase8_smoke.gd` checks structure, scaling, migration, map and stage states, boss retry, and save persistence. `tests/phase8/phase8_visual_capture.gd` creates portrait captures for the overview, map, stage selection, ten region battles, elite, treasure, boss, and Infernal variant. Debug-only helpers are in `tests/phase8/phase8_debug.gd`. Music assets and complex boss mechanics are not included.

## Phase 3 progression

- **Heroes:** Squire is the only playable hero. Combat EXP raises Hero Level and base stats. The fixed Squire → Knight → Royal Knight → Paladin → Divine Paladin path shows future level and Evolution Crest costs, while Mage, Ranger, Assassin, and Necromancer appear as locked roster cards. Evolution remains unavailable.
- **Gems:** A stage's first clear grants 1 Gem and 1 Enhancement Stone. The first Goblin Warlord clear grants 5 Gems and 2 Stones. Reaching Hero Levels 5, 10, and 20 grants 2 Gems each, once.
- **Equipment:** Seven slots and a seven-item starter pool are available. Enemies can drop more equipment; bosses have a higher chance. Gear contributes ATK, HP, Armor, Attack Speed, Crit Chance, or Crit Damage to live combat and Power. Items can be equipped, removed, upgraded with Gold and Stones, and compared. Five copies with the same item, rarity, and level merge into one copy of the next rarity. All eight rarity frames are supported.
- **Save:** `user://crown_of_vael.save` stores currencies, hero progression, first clears, milestone claims, equipment IDs and levels, equipped slots, and evolution progress. Existing Phase 2 saves receive safe defaults and the starter item pool.

No purchases or online systems are included.

## Phase 4 and 5 build systems

- **Summoning:** Equipment, Skills, Companions, and Artifacts have separate banner levels, rarity tables, daily free claims, simulated rewarded-ad claims, and 100-pull Legendary pity. Paid 1x, 10x, and 50x pulls cost Gems. The Summon screen opens the Companion Hall and Artifact Vault. Hero summons remain locked.
- **Skills:** Four active slots auto-cast in battle. Shield Bash is the Squire's starting skill. Summoned copies unlock and level the eight initial skills.
- **Companions:** Four active allies appear and attack automatically. Copies grant pieces for star ranks; Gold and Companion Essence raise levels. Wolf can evolve through Dire Wolf, Shadow Wolf, and Fenrir using levels, stars, Essence, and Companion Crests. Other evolution paths remain locked.
- **Artifacts:** Every owned relic grants a small permanent bonus. Two equipped slots activate stronger combat effects, including critical healing, faster skill recovery, fire bursts, extra critical effects, periodic guarding, and a once-per-battle Phoenix revive. Tower Floor 20 unlocks a third slot, enabling the Dragon Relics three-piece fire bonus. Artifact copies, Gold, and Dust raise artifact levels.
- **Persistence:** Phase 4 saves migrate to the new banners, materials, collections, levels, pieces, evolution stages, and equipped slots without losing earlier progress.

The rewarded-ad provider is a development simulation, and daily claims use the device's local calendar. Debug grants live only in `tests/phase5/phase5_debug.gd`.

## Phase 6 Adventure

The Adventure tab opens Campaign, six Dungeons, Permanent Tower, Boss Rush, and Endless Survival. Every mode uses the existing hero, skills, companions, artifacts, and battle scene.

| Dungeon | Main reward |
| --- | --- |
| Gold Dungeon | Gold |
| EXP Dungeon | Hero EXP, small Gold |
| Equipment Dungeon | Enhancement Stones and an equipment item |
| Companion Dungeon | Companion Essence, higher-tier Crests, occasional pieces |
| Artifact Dungeon | Artifact Dust, rare duplicate progress |
| Hero Trial | Evolution Crests, Hero EXP, generic Hero Pieces |

Each Dungeon has two daily attempts and five tiers unlocked by campaign progress. Daily resets use the device's local date. Tower floors scale procedurally beyond Floor 100; first clears grant Gold, Gems, and materials, with milestone chests every ten floors. Boss Rush has five consecutive bosses, keeps HP between fights, heals 10% between bosses, and allows two daily entries. Endless Survival has two rewarded runs per day and unlimited unrewarded practice. Rewards, records, and attempts are saved. Tower Floor 20 unlocks Artifact Slot 3 and the Dragon Relics three-piece effect.

`scripts/adventure/pve_data.gd` holds mode scaling and rewards, `scripts/adventure/pve_service.gd` owns attempts and records, and `scripts/adventure/adventure_screen.gd` presents the modes. `tests/phase6/phase6_smoke.gd`, `tests/phase6/phase6_layout_smoke.gd`, and `tests/phase6/phase6_visual_capture.gd` cover the new systems. Debug-only helpers live in `tests/phase6/phase6_debug.gd`.

## Phase 7 heroes

Hero Level, EXP, Gold upgrades, equipment, skills, companions, and artifacts remain account-wide. The Heroes screen manages five launch archetypes with separate unlock pieces, stars, permanent evolution state, active passives, and owned account bonuses:

| Hero | Base rarity | Unlock | Active identity | Owned bonus |
| --- | --- | --- | --- | --- |
| Knight | Rare | Starts as Squire | HP and Armor | Armor |
| Mage | Epic | 50 Mage Pieces | Skill Damage | Skill Damage |
| Ranger | Epic | 50 Ranger Pieces | Attack Speed | Attack Speed |
| Assassin | Legendary | 75 Assassin Pieces | Crit Chance and Crit Damage | Crit Damage |
| Necromancer | Legendary | 100 Necromancer Pieces | Companion Damage | Companion Damage |

Hero stars cost 20, 40, 80, and 160 specific pieces. Five Generic Hero Pieces convert into one selected hero piece after confirmation. Hero Trial also awards specific hero pieces at Tier 2 and above. Hero switching is free at camp and blocked during active combat; a retreat action is available when the Heroes screen is opened during a fight.

The permanent Knight path is Squire → Knight → Royal Knight → Paladin → Divine Paladin. Its four steps require Level 20/40/70/100, 10/25/60/150 Evolution Crests, and 5,000/25,000/100,000/500,000 Gold. Each step updates stats, passive strength, title, element identity, portrait, battle appearance, and Power. Mage, Ranger, Assassin, and Necromancer each expose a five-stage future evolution path in data and UI.

Mage, Ranger, and Necromancer use lightweight traveling projectiles; Assassin uses a fast melee dash; Knight retains sword-and-shield combat. Existing skills remain unrestricted, with optional hero tags available for future restrictions. `tests/phase7/phase7_smoke.gd`, `tests/phase7/phase7_layout_smoke.gd`, and `tests/phase7/phase7_visual_capture.gd` cover progression, combat, migration, layout, and visual states. Phase 7 debug grants live only in `tests/phase7/phase7_debug.gd`.

## Structure and checks

- `scripts/data/game_data.gd`: enemy, hero, evolution, and progression values.
- `scripts/equipment/equipment_data.gd`: starter pool, rarity visuals, item stats, costs, and drop rolls.
- `scripts/systems/save_data.gd`: persistence, migration, rewards, equipment actions, and future evolution gate.
- `scripts/combat/battle_controller.gd`: combat and live reward events.
- `scripts/combat/battlefield.gd`, `scripts/components/ui/hero_portrait.gd`: battle presentation and reusable Squire portrait.
- `scripts/ui/main.gd`: portrait HUD, Heroes, Equipment, and navigation.
- `tests/shared/progression_smoke.gd`, `tests/shared/layout_smoke.gd`, `tests/phase3/phase3_smoke.gd`: progression, layout, and Phase 3 checks.
- `tests/phase3/phase3_visual_capture.gd`: 360 × 640 captures for visual review.

## Project map and editor previews

- `scenes/main.tscn` is the production root. It builds the current screens and HUD in `scripts/ui/main.gd`; screen-specific logic stays in its feature folders.
- `scripts/systems/`, `scripts/data/`, `scripts/characters/`, `scripts/combat/`, `scripts/ui/`, and `scripts/components/ui/` hold shared systems, data, character code, combat, screen code, and reusable UI widgets.
- `assets/characters/` separates standard and pixel sprites. `assets/environments/regions/` keeps each region's painted and pixel battle backgrounds together.
- `resources/` is reserved for designer-authored `.tres` catalogs. Current gameplay data remains in the existing typed scripts.
- `tests/` holds checks and capture helpers; generated captures and local test saves go under the ignored `.godot/` directory.

For a visual asset browser, open `dev/asset_gallery/asset_gallery.tscn` and run **Current Scene (F6)**. Use the category and region selectors to browse hero/enemy/boss sprites, region and menu backgrounds, UI icons, and live previews of the procedural combat effects.

For screen browsing, open `dev/screen_gallery/screen_gallery.tscn` and run **Current Scene (F6)**. Its buttons switch the embedded production UI between Battle, Heroes, Equipment, Skills, Summon, and Settings. The preview uses `user://crown_of_vael_screen_gallery.save`, separate from the production save.
