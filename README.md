# Crown of Vael — playable prototype

Open `project.godot` in Godot 4.3 or newer and run the project. The game uses a 1080 × 1920 portrait viewport that scales to smaller portrait screens. Characters and effects are drawn with Godot shapes, so no external art is required.

The Squire attacks automatically, casts Shield Bash every eight seconds, and earns Gold and Hero EXP from defeated enemies. Easy 1-1 through Easy 1-9 each have three waves of five enemies. Easy 1-10 is a 30-second Goblin Warlord fight. Death returns to the previous stage. A failed boss attempt returns to Easy 1-9; after clearing it, the player must tap **Retry Boss** to begin the next attempt.

Gold buys persistent HP, ATK, or Armor upgrades. The HUD shows Gold, Gems (currently display only), and a derived Player Power score. Stage, Gold, Gems, EXP, level, upgrades, and boss retry state are stored in `user://crown_of_vael.save`.

The Battle tab contains the live fight, Shield Bash cooldown, Squire stats, and upgrades. Heroes, Equipment, Skills, and Summon open future-feature placeholders while combat continues.

## Structure

- `scripts/game_data.gd`: enemy definitions, wave composition, stat scaling, and progression values.
- `scripts/save_data.gd`: local profile persistence and purchases.
- `scripts/battle_controller.gd`: automatic combat, rewards, stage events, and boss timer.
- `scripts/battlefield.gd`: placeholder battlefield rendering and floating damage numbers.
- `scripts/skill_badge.gd`: Shield Bash icon and cooldown ring.
- `scripts/main.gd`: portrait HUD, bottom navigation, and progression flow.
- `tests/progression_smoke.gd`: checks the first three stages, rewards, and saved stage data.
- `tests/layout_smoke.gd`: checks portrait panel boundaries and tab switching.
- `tests/visual_capture.gd`: captures the Easy 1-1 screen to `.godot/phase2_capture.png` for visual checks.

Future equipment, companions, artifacts, heroes, dungeons, and summons can add data and systems around the profile and battle controller without changing the battlefield renderer.
