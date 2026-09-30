# Asset inventory

Inventory reviewed 2026-09-30. The files are counted from `assets/`; origins and license records are not present in the project, so none are inferred here.

| Category | Contents | Status / source notes |
|---|---|---|
| Hero art | `assets/heroes/` — Knight forms and portraits (50 files including import sidecars) | Existing project art; source/generator and licensing are undocumented. Animation PNG imports have no size limit. Largest reviewed source is 1024x1536 animation / 1122x1402 portrait. |
| Enemy and boss art | `assets/enemies/` — region enemy sprites (180 files including import sidecars) | Existing project art; source/generator and licensing are undocumented. 81 enemy PNG imports cap at 512px; 9 boss PNG imports cap at 768px. Source PNGs reach 1536x1024. |
| Region backgrounds | `assets/backgrounds/regions/` — 10 battle backgrounds (20 files including import sidecars) | Existing project art; source/generator and licensing are undocumented. All 10 PNG imports cap at 1536px; source images are 941x1672 and around 2.6–2.8 MiB each. |
| VFX | Procedural draw effects in `scripts/combat/combat_vfx_service.gd`; no separate VFX texture library found | Code-generated lightweight effects; not a collection of production sprite assets. |
| Audio | No `.wav`, `.ogg`, `.mp3`, or `.flac` files found. Paths in `scripts/core/audio_service.gd` are intentionally empty. | Production music/SFX missing. Architecture fails silently when assets are absent. |
| App icon / splash | Root `icon.svg` (128x128); no dedicated Android adaptive icon or splash branding art | Project placeholder icon fallback only. Store-grade icon treatment remains needed. |

Totals: 250 files under `assets/`; 120 PNG sources, approximately 266 MiB on disk. Largest source PNG: Knight Divine Paladin attack, 1024x1536, approximately 3.2 MiB. Enemy and background imports already have mobile size limits; no source quality was destructively changed. Hero animation imports remain uncapped and should be measured on device. No byte-identical PNG duplicates were found. Decoded RGBA memory is much larger than file size; for example, one 1024x1536 texture is roughly 6 MiB before mipmaps/engine overhead. These observations are a review list, not a claim that every texture remains resident at once.
