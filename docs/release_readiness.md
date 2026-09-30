# Release readiness audit

Audit date: 2026-09-30. Scope: project-side Android preparation and local implementation boundaries. No external production service was configured or tested.

## Locally implemented and testable

- Campaign combat, screens, local progression and save/migration behavior.
- Local offline reward calculation/claiming, tutorial state and local audio settings.
- Phase 12C VFX are bounded; audio uses shared players and silently ignores empty asset paths.
- Settings, reduced effects, and save hooks are implemented locally. These are not cloud durability guarantees.

## Development or mock providers

- Rewarded ads: development/simulated provider. No ad network SDK, inventory, or server callback.
- Purchases/billing: local purchase provider and entitlement test behavior. No Google Play Billing or App Store transaction verification.
- Cloud save and account linking: local development providers/state. No authenticated production identity or cloud persistence service.
- Friends, Guild/chat, and PvP: local/mock data and opponent behavior. No production social/matchmaking backend.
- Push notifications: no production provider/integration found.
- Audio: architecture and event hooks exist; no production music or SFX files found. Runtime is intentionally silent for unmapped/missing paths.

These services require their production providers, security review, and device/store testing before public launch. The local save and idle reward model cannot provide server-grade anti-cheat or backup guarantees.

## Android and device status

- Godot 4.7.1, portrait orientation, 1080x1920 design viewport, Compatibility renderer, and 60 FPS cap are configured.
- Tracked Android presets define a debug APK, release APK, and Gradle AAB. Package ID is `com.crownofvael.game`; version is `0.1.0` / code `1`.
- Android SDK is installed at `%LOCALAPPDATA%\Android\Sdk` with API 36 and 37 preview platforms, Build Tools 36.0.0/37.0.0, NDK 28.2.13676358, CMake 3.22.1, and adb. The Godot SDK path is set, but Godot's Java SDK path is blank. The shell Java is 8; Android Studio's JBR 25 is installed. Matching Godot 4.7.1 export templates are absent. `adb devices -l` found no device. APK/AAB export, install, and device tests therefore remain unverified.
- Store icon fallback is the existing 128x128 project SVG. Dedicated 192x192 and 432x432 adaptive icon assets are absent. No custom production splash branding asset is configured.
- Android permissions are minimized in the presets; internet is disabled while the external integrations are still mocks.
- The AAB Gradle preset declares minimum API 23 and target API 36. The APK preset uses Godot's prebuilt template defaults; inspect the exported manifest after templates are installed.

## Art and memory review

There are 120 PNG files (250 files total under `assets`, including import sidecars and notes), about 266 MiB of PNG source data. The largest PNG is a 1024x1536 Knight idle/attack/guard image at about 3.2 MiB on disk; enemy and boss sources reach 1536x1024; region backgrounds reach 941x1672. These images are not automatically reduced because source art should be reviewed first. Their RGBA decoded cost is roughly 4 bytes per pixel (about 6 MiB for 1024x1536, excluding mipmaps and engine overhead). No byte-identical PNG duplicates were found. Asset origins/licensing are not recorded in project metadata; this audit makes no licensing claim.

No real-device frame-time or memory sampling, long-run soak, or screen-switch memory profiling could be performed without an Android export/device. Desktop startup and automated smoke coverage are the available project checks. Repeated screen construction and region transitions should still be profiled on a representative Android handset.

## Release blockers

1. Configure Android SDK and supported JDK paths in Godot, install matching 4.7.1 APK templates and the Gradle template, then build/install/test the debug APK.
2. Supply and review store-grade app icons and splash branding.
3. Generate and securely back up a production keystore; verify release APK signing and build/test the AAB.
4. Replace or formally defer the mock billing, ads, cloud/account, and social providers; decide push/analytics; add production audio or sign off on silent launch.
5. Complete privacy, data safety, content rating, screenshots, fresh install/upgrade, crash monitoring, and physical-device QA in the release checklist.
