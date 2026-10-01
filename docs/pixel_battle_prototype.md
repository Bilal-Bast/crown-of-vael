# Greenvale Pixel Battle Prototype

This art-direction prototype changes battle presentation only for the base Squire in Greenvale campaign battles. It does not alter combat data, campaign content, saves, rewards, or progression.

The reversible switch is `PROTOTYPE_ENABLED` in `scripts/combat/pixel_battle_art.gd`. Set it to `false` to return to the existing illustrated Greenvale presentation. The existing UI and all content outside this narrow scope continue to use their current visuals.

## Prototype art

- `assets/prototype_pixel/heroes/squire/{idle,attack,guard,hit}.png`: looping four-frame idle at 7 FPS, six-frame attack and shield bash at 12 FPS, and a four-frame hit reaction at 12 FPS. These replace the former static state swaps while preserving the Squire identity.
- `assets/prototype_pixel/heroes/squire/run.png`: six right-facing run frames, looped at 10 FPS only during the 1.5-second between-wave transition. Missing or invalid run art falls back to the existing Squire idle sprite while movement continues.
- `assets/prototype_pixel/enemies/greenvale/{goblin,skeleton,corrupted_wolf}/{idle,attack,hit}.png`: four-frame looping idles; Goblin uses 4/4/3 frames at 8/11/11 FPS, Skeleton 4/4/3 at 7/9/10 FPS, and Wolf 4/5/3 at 8/12/11 FPS for idle/attack/hit.
- Matching `entry.png` sheets animate only the right-to-lane movement: Goblin (4 frames at 11 FPS), Skeleton (4 at 9 FPS), and Corrupted Wolf (4 at 11 FPS). Missing or invalid entry art falls back to the existing idle sprite while the current movement remains in effect.
- `assets/prototype_pixel/backgrounds/greenvale/battle.png`: dusk countryside, ruined tower and fence, distant hills, and broken road.
- Shield Bash and Squire melee attacks use a small stepped pixel impact effect drawn in the battle lane.

All combat animation sheets are horizontal strips of 256 by 256 frames and are downsampled with nearest-neighbor resampling from generated concept atlases. The run sheet remains six 256 by 256 frames. Hit overrides attack, Shield Bash and attack override movement, and movement overrides idle; actor timers are independent. Action presentation runs at each sheet's frame rate and does not change when combat damage or cooldowns are applied. Missing or invalid animation strips fall back to the former three-pose pixel sheets. The battlefield switches to nearest-neighbor texture filtering only while the prototype is active; it returns to linear filtering otherwise. Import settings retain alpha, use lossless compression, and disable mipmaps for these prototype textures.

## Captures and smoke test

Run the focused capture and smoke test with the project's Godot 4 console executable:

```powershell
& 'C:\path\to\Godot_v4.7.1-stable_win64_console.exe' --path . --script tests/prototype_pixel/prototype_pixel_smoke.gd
```

It writes captures under `.godot/prototype_pixel_captures/` at 360 by 640 and 1080 by 1920, including each character's idle, attack, and hit poses, the Squire's Shield Bash and inter-wave runs, a crowded seven-enemy wave, independent simultaneous enemy attacks, and a battle overview. The focused `tests/prototype_pixel/combat_animation_smoke.gd` checks frame counts, rates, action priority, fallback, and per-enemy state independence.
