# Project Reorganization Move Manifest

This manifest records the source roots relocated during the project cleanup. A directory move includes every file below it, including nested folders and Godot `.import` sidecars, unless an extracted file is listed separately. Files were not renamed internally as part of the directory moves.

## Asset directories

| Previous location | New location |
| --- | --- |
| `assets/heroes/` | `assets/characters/heroes/standard/` |
| `assets/prototype_pixel/heroes/` | `assets/characters/heroes/pixel/` |
| `assets/enemies/` | `assets/characters/enemies/standard/` |
| `assets/prototype_pixel/enemies/` | `assets/characters/enemies/pixel/` |
| `assets/prototype_pixel/companions/` | `assets/characters/companions/pixel/` |
| `assets/backgrounds/menus/` | `assets/environments/menus/` |
| `assets/ui/navigation_icons/` | `assets/ui/icons/navigation/` |
| `assets/pixel_ui/` | `assets/ui/icons/pixel/` |
| `assets/backgrounds/regions/ashen_highlands/` | `assets/environments/regions/ashen_highlands/painted/` |
| `assets/backgrounds/regions/crimson_desert/` | `assets/environments/regions/crimson_desert/painted/` |
| `assets/backgrounds/regions/demon_realm/` | `assets/environments/regions/demon_realm/painted/` |
| `assets/backgrounds/regions/dragon_peaks/` | `assets/environments/regions/dragon_peaks/painted/` |
| `assets/backgrounds/regions/frostfang_mountains/` | `assets/environments/regions/frostfang_mountains/painted/` |
| `assets/backgrounds/regions/greenvale_outskirts/` | `assets/environments/regions/greenvale_outskirts/painted/` |
| `assets/backgrounds/regions/ruined_kingdom/` | `assets/environments/regions/ruined_kingdom/painted/` |
| `assets/backgrounds/regions/shadowlands/` | `assets/environments/regions/shadowlands/painted/` |
| `assets/backgrounds/regions/sunken_marshes/` | `assets/environments/regions/sunken_marshes/painted/` |
| `assets/backgrounds/regions/whispering_forest/` | `assets/environments/regions/whispering_forest/painted/` |
| `assets/prototype_pixel/backgrounds/ashen_highlands/` | `assets/environments/regions/ashen_highlands/pixel/` |
| `assets/prototype_pixel/backgrounds/crimson_desert/` | `assets/environments/regions/crimson_desert/pixel/` |
| `assets/prototype_pixel/backgrounds/demon_realm/` | `assets/environments/regions/demon_realm/pixel/` |
| `assets/prototype_pixel/backgrounds/dragon_peaks/` | `assets/environments/regions/dragon_peaks/pixel/` |
| `assets/prototype_pixel/backgrounds/frostfang_mountains/` | `assets/environments/regions/frostfang_mountains/pixel/` |
| `assets/prototype_pixel/backgrounds/greenvale/` | `assets/environments/regions/greenvale_outskirts/pixel/` |
| `assets/prototype_pixel/backgrounds/ruined_kingdom/` | `assets/environments/regions/ruined_kingdom/pixel/` |
| `assets/prototype_pixel/backgrounds/shadowlands/` | `assets/environments/regions/shadowlands/pixel/` |
| `assets/prototype_pixel/backgrounds/sunken_marshes/` | `assets/environments/regions/sunken_marshes/pixel/` |
| `assets/prototype_pixel/backgrounds/whispering_forest/` | `assets/environments/regions/whispering_forest/pixel/` |

## Script directories

| Previous location | New location |
| --- | --- |
| `scripts/core/` (except extracted `game_data.gd` and its UID file) | `scripts/systems/` |
| `scripts/heroes/` (except extracted `hero_portrait.gd` and its UID file) | `scripts/characters/heroes/` |
| `scripts/companions/` | `scripts/characters/companions/` |

## Extracted individual files

| Previous file | New file |
| --- | --- |
| `assets/ui/obsidian_menu_frame.png` | `assets/ui/panels/obsidian_menu_frame.png` |
| `assets/ui/obsidian_menu_frame.png.import` | `assets/ui/panels/obsidian_menu_frame.png.import` |
| `scripts/core/game_data.gd` | `scripts/data/game_data.gd` |
| `scripts/core/game_data.gd.uid` | `scripts/data/game_data.gd.uid` |
| `scripts/heroes/hero_portrait.gd` | `scripts/components/ui/hero_portrait.gd` |
| `scripts/heroes/hero_portrait.gd.uid` | `scripts/components/ui/hero_portrait.gd.uid` |
| `scripts/skills/skill_badge.gd` | `scripts/components/ui/skill_badge.gd` |
| `scripts/skills/skill_badge.gd.uid` | `scripts/components/ui/skill_badge.gd.uid` |

Path references, project autoloads, importer source paths, and authored test/tool references were updated for the new locations. The production entry scene remains `scenes/main.tscn`.

## Deliberately left in place

- `scripts/ui/main.gd` still constructs several feature screens at runtime. There were no authored production scenes to move for Battle, Heroes, Equipment, Skills, Summon, or Settings; their runtime construction is documented under `scenes/screens/`.
- Boss sprites remain inside their existing region-specific enemy asset directories because gameplay art lookup expects those paths. The AssetGallery labels the boss entries separately without relocating or duplicating art.
- `assets/prototype_pixel/` and `assets/backgrounds/` have no remaining tracked production content after the moves; any empty local directories are ignored by Git.
- The existing untracked `~/` workspace content was not touched.
