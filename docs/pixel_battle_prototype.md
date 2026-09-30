# Greenvale Pixel Battle Prototype

This art-direction prototype changes battle presentation only for the base Squire in Greenvale campaign battles. It does not alter combat data, campaign content, saves, rewards, or progression.

The reversible switch is `PROTOTYPE_ENABLED` in `scripts/combat/pixel_battle_art.gd`. Set it to `false` to return to the existing illustrated Greenvale presentation. The existing UI and all content outside this narrow scope continue to use their current visuals.

## Prototype art

- `assets/prototype_pixel/heroes/squire/sheet.png`: idle, sword attack, and shield guard/hit frames.
- `assets/prototype_pixel/enemies/greenvale/{goblin,skeleton,corrupted_wolf}/sheet.png`: idle, attack, and hit frames.
- `assets/prototype_pixel/backgrounds/greenvale/battle.png`: dusk countryside, ruined tower and fence, distant hills, and broken road.
- Shield Bash and Squire melee attacks use a small stepped pixel impact effect drawn in the battle lane.

Sprite sheets are three 256 by 256 frames in a horizontal strip. They were downsampled with nearest-neighbor resampling from the generated concept sheets. The battle field switches to nearest-neighbor texture filtering only while the prototype is active; it returns to linear filtering otherwise. Import settings retain alpha, use lossless compression, and disable mipmaps for these prototype textures.

## Captures and smoke test

Run the focused capture and smoke test with the project's Godot 4 console executable:

```powershell
& 'C:\path\to\Godot_v4.7.1-stable_win64_console.exe' --path . --script tests/prototype_pixel/prototype_pixel_smoke.gd
```

It writes 11 comparison captures under `.godot/prototype_pixel_captures/` at 360 by 640 and 1080 by 1920. The harness checks texture loading, prototype scope, campaign battle startup, attack and hit states, and the pixel Shield Bash effect.
