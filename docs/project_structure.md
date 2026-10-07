# Crown of Vael project map

## Production entry and screen ownership

- `scenes/main.tscn` is the only production scene root. Its attached `scripts/ui/main.gd` creates the battlefield, HUD, menus, dialogs, and navigation at runtime.
- Feature screen builders remain with their code: `scripts/characters/heroes/`, `scripts/skills/`, `scripts/equipment/`, `scripts/summons/`, and `scripts/ui/`.
- `scenes/screens/` and `scenes/ui/` contain editor-visible maps for the current runtime-built screen groups. They are not placeholder scenes.
- Reusable UI widgets live in `scripts/components/ui/`.

## Asset ownership

- `assets/characters/heroes/{standard,pixel}/` contains hero sprites.
- `assets/characters/enemies/{standard,pixel}/<region>/` contains region-specific enemies. Campaign bosses remain in these region libraries because gameplay resolves them through the region enemy catalog; AssetGallery presents their sprites in a separate Bosses category.
- `assets/characters/companions/pixel/` contains companion sprite atlases.
- `assets/environments/regions/<region>/{painted,pixel}/` keeps regional backgrounds together. `assets/environments/menus/` contains menu art.
- `assets/ui/icons/`, `assets/ui/panels/`, and `assets/ui/buttons/` hold UI artwork.
- `assets/effects/` is reserved for standalone VFX files. Current combat effects are drawn by `scripts/combat/combat_vfx_service.gd` and `scripts/combat/pixel_battle_impact.gd`.
- `assets/audio/{music,sfx,ambience}/` and `assets/fonts/` are organized for future content; no audio/font files are bundled yet.

## Code and data

- `scripts/systems/` contains shared runtime services and save handling.
- `scripts/data/` contains shared gameplay constants; feature-specific data stays with its owner.
- `resources/` holds designer-authored Godot Resources. Existing catalogs are code-backed, so the future resource folders include notes rather than empty `.tres` files.
- `tests/` contains smoke/layout checks and capture tools. Generated captures and temporary saves are written to the ignored `.godot/` folder.

## Development previews

- Open `dev/asset_gallery/asset_gallery.tscn` and press **F6** for the scrollable, category/region asset browser.
- Open `dev/screen_gallery/screen_gallery.tscn` and press **F6** for live production screen previews. It uses a dedicated `user://crown_of_vael_screen_gallery.save` file.
- The project main scene remains `scenes/main.tscn`; neither dev scene changes project startup or production save data.
