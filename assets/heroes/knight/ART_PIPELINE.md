# Knight evolution art slots

Each form folder accepts `idle.png`, `attack.png`, `guard.png`, and `portrait.png` (the established Squire filenames remain unchanged). Optional `skill.png`, `death.png`, `evolution_fx.png`, and `aura.png` slots are recognized for later use.

Export transparent PNGs with a consistent ground/feet baseline. Keep source dimensions appropriate for mobile display; runtime preserves aspect ratio and caches imported textures. The existing Squire imports use lossless compression, alpha border fixing, and no mipmaps; use the same settings for replacements. Use linear CanvasItem filtering and avoid premultiplying alpha. Real art is optional: missing files use the established procedural character rendering.

Visual direction by evolution: Squire (linen, sword, wooden shield), Knight (steel and metal shield), Royal Knight (ornate plate and blue cape), Paladin (white/gold armor and soft holy glow), Divine Paladin (bright armor, glowing sword, majestic cape and stronger halo). This metadata is presentation only and does not change stats.
