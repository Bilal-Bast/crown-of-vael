# Asset inventory

Inventory reviewed 2026-09-30. The files are counted from `assets/`; origins and license records are not present in the project, so none are inferred here.

| Category | Contents | Status / source notes |
|---|---|---|
| Hero art | `assets/characters/heroes/standard/` and `assets/characters/heroes/pixel/` | Existing art sets are kept intact; sprite imports and source/generator notes remain alongside the files. |
| Enemy and boss art | `assets/characters/enemies/standard/` and `assets/characters/enemies/pixel/` | Enemy/boss sprites remain grouped by region. The AssetGallery labels the ten campaign bosses separately. |
| Region backgrounds | `assets/environments/regions/<region>/{painted,pixel}/` — existing regional sets | Each region's painted and pixel backgrounds now share one region folder. |
| VFX | Procedural draw effects in `scripts/combat/combat_vfx_service.gd`; no separate VFX texture library found | Code-generated lightweight effects; not a collection of production sprite assets. |
| Audio | `assets/audio/{music,sfx,ambience}/` | No audio files are included yet; campaign music paths now point to the music folder reserved for them. |
| App icon / splash | Root `icon.svg` (128x128); no dedicated Android adaptive icon or splash branding art | Project placeholder icon fallback only. Store-grade icon treatment remains needed. |

Totals: 250 files under `assets/`; 120 PNG sources, approximately 266 MiB on disk. Largest source PNG: Knight Divine Paladin attack, 1024x1536, approximately 3.2 MiB. Enemy and background imports already have mobile size limits; no source quality was destructively changed. Hero animation imports remain uncapped and should be measured on device. No byte-identical PNG duplicates were found. Decoded RGBA memory is much larger than file size; for example, one 1024x1536 texture is roughly 6 MiB before mipmaps/engine overhead. These observations are a review list, not a claim that every texture remains resident at once.
