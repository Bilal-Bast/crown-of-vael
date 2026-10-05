# Knight evolution art pipeline

Each form has four-frame horizontal 256×256 sheets for `idle`, `run`, `attack`, `guard`, and `hit` (1024×256), plus a 256×256 transparent `portrait.png`. Squire retains its legacy filenames (`squire_idle.png`, `squire_run.png`, `squire_attack.png`, `squire_guard.png`, `squire_hit.png`, and `squire_portrait.png`). The runtime crops and caches individual animation frames.

The five source atlases in `source_atlases/` are 4×6 grids of 256px cells. `tests/hero_art/crop_hero_atlases.gd` extracts the state strips and aligns their opaque lower edge to the shared 240px contact line. PNG imports use lossless compression, alpha border fixing, no mipmaps, and no premultiplied alpha. Battle sprites and hero portraits use nearest-neighbor filtering.

Visual progression: Squire (linen, short sword, wooden shield), Knight (steel plate), Royal Knight (regal plate and blue cape), Paladin (ivory/gold holy armor), Divine Paladin (exalted gold regalia and radiant sword). Art and scale metadata are presentation only and do not change hero systems.
