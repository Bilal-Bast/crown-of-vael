# Crown of Vael

Open `project.godot` in Godot 4.7.1 and run the project. The 1080 × 1920 portrait viewport scales to 360 × 640. Characters, the Squire portrait, item icons, and effects use procedural Godot drawing and text.

The Squire fights automatically and casts Shield Bash every eight seconds. Easy 1-1 through Easy 1-9 each have three waves of five enemies. Easy 1-10 is a 30-second Goblin Warlord fight. Stage progression, death rollback, boss retry, the HUD, and account-wide Gold upgrades continue from Phase 2.

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
- **Artifacts:** Every owned relic grants a small permanent bonus. Two equipped slots activate stronger combat effects, including critical healing, faster skill recovery, fire bursts, extra critical effects, periodic guarding, and a once-per-battle Phoenix revive. Dragon Relics grant a two-piece Crit Damage bonus; the three-piece fire bonus is implemented for a future third slot. Artifact copies, Gold, and Dust raise artifact levels.
- **Persistence:** Phase 4 saves migrate to the new banners, materials, collections, levels, pieces, evolution stages, and equipped slots without losing earlier progress.

The rewarded-ad provider is a development simulation, and daily claims use the device's local calendar. Debug grants live only in `tests/phase5_debug.gd`.

## Structure and checks

- `scripts/game_data.gd`: enemy, hero, evolution, and progression values.
- `scripts/equipment_data.gd`: starter pool, rarity visuals, item stats, costs, and drop rolls.
- `scripts/save_data.gd`: persistence, migration, rewards, equipment actions, and future evolution gate.
- `scripts/battle_controller.gd`: combat and live reward events.
- `scripts/battlefield.gd`, `scripts/hero_portrait.gd`: procedural battle art and Squire portrait.
- `scripts/main.gd`: portrait HUD, Heroes, Equipment, and navigation.
- `tests/progression_smoke.gd`, `tests/layout_smoke.gd`, `tests/phase3_smoke.gd`: progression, layout, and Phase 3 checks.
- `tests/phase3_visual_capture.gd`: 360 × 640 captures for visual review.
