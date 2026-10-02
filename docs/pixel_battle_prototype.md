# Production Pixel Battle Presentation

This art-direction prototype changes battle presentation only for the base Squire in Greenvale and Whispering Forest campaign battles. It does not alter combat data, campaign content, saves, rewards, or progression. Other regions retain their current presentation.

The reversible switch is `PROTOTYPE_ENABLED` in `scripts/combat/pixel_battle_art.gd`. Set it to `false` to return to the existing illustrated presentation.

## Prototype art

- `assets/prototype_pixel/heroes/squire/{idle,attack,guard,hit}.png`: looping four-frame idle at 7 FPS, six-frame attack and shield bash at 12 FPS, and a four-frame hit reaction at 12 FPS. These replace the former static state swaps while preserving the Squire identity.
- `assets/prototype_pixel/heroes/squire/run.png`: six right-facing run frames, looped at 10 FPS only during the 1.5-second between-wave transition. Missing or invalid run art falls back to the existing Squire idle sprite while movement continues.
- `assets/prototype_pixel/enemies/greenvale/{goblin,skeleton,corrupted_wolf}/{idle,attack,hit}.png`: four-frame looping idles; Goblin uses 4/4/3 frames at 8/11/11 FPS, Skeleton 4/4/3 at 7/9/10 FPS, and Wolf 4/5/3 at 8/12/11 FPS for idle/attack/hit.
- Matching `entry.png` sheets animate only the right-to-lane movement: Goblin (4 frames at 11 FPS), Skeleton (4 at 9 FPS), and Corrupted Wolf (4 at 11 FPS). Missing or invalid entry art falls back to the existing idle sprite while the current movement remains in effect.
- `assets/prototype_pixel/backgrounds/greenvale/battle.png`: dusk countryside, ruined tower and fence, distant hills, and broken road.
- `assets/prototype_pixel/enemies/whispering_forest/`: production animation strips for Forest Goblin, Giant Spider, Corrupted Boar, Forest Bandit, Skeleton Archer, Poison Wolf, Spider Matriarch, Forest Brute, and Ancient Treant. Normal enemies use 4 idle, 4 entry, 5 attack, and 3 hit frames. Elites use 4/4/5/4. The Treant uses 4 idle, 4 entrance, 5 attack, 3 hit, and 6 death frames. Strips run at 8 FPS idle, 11 FPS entry/attack/hit, and 9 FPS for Treant entrance/death.
- `assets/prototype_pixel/backgrounds/whispering_forest/battle.png`: 1280 by 720 forest background, filtered nearest-neighbor and contained in the existing battlefield region.
- Skeleton Archer uses the existing pixel-arrow projectile style and timing.
- Shield Bash and Squire melee attacks use a small stepped pixel impact effect drawn in the battle lane.

All combat animation sheets are horizontal strips of 256 by 256 frames and are downsampled with nearest-neighbor resampling from generated concept atlases. The run sheet remains six 256 by 256 frames. Hit overrides attack, Shield Bash and attack override movement, and movement overrides idle; actor timers are independent. Action presentation runs at each sheet's frame rate and does not change when combat damage or cooldowns are applied. Missing or invalid animation strips fall back to the former three-pose pixel sheets. The battlefield switches to nearest-neighbor texture filtering only while the prototype is active; it returns to linear filtering otherwise. Import settings retain alpha, use lossless compression, and disable mipmaps for these prototype textures.

## Captures and smoke test

Run the focused capture and smoke tests with the project's Godot 4 console executable:

```powershell
& 'C:\path\to\Godot_v4.7.1-stable_win64_console.exe' --path . --script tests/prototype_pixel/prototype_pixel_smoke.gd
& 'C:\path\to\Godot_v4.7.1-stable_win64_console.exe' --path . --script tests/prototype_pixel/whispering_forest_pixel_smoke.gd
& 'C:\path\to\Godot_v4.7.1-stable_win64_console.exe' --path . --script tests/prototype_pixel/whispering_forest_capture.gd
```

The Greenvale runner writes its established production captures. The Whispering Forest runner writes each Region 2 enemy's idle, attack, and hit poses, the Skeleton Archer projectile, Treant entrance/attack/death, a seven-enemy wave, the between-wave run, and battle/boss overviews to `.godot/prototype_pixel_captures/`. The focused combat-animation and Region 2 smokes check frame counts, rates, action priority, fallback, independent sprites, and the existing battle flow.
