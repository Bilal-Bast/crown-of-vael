# Android release checklist

## Project configuration

- [x] Package ID: `com.crownofvael.game` (verify ownership/availability before store registration)
- [ ] Store-grade app icon: main 192x192 and adaptive foreground/background 432x432
- [x] Version name: `0.1.0` in `project.godot`
- [x] Version code: `1` in each Android preset; increment each upload
- [ ] Production signing key generated, securely backed up, and access documented
- [ ] Privacy policy published and linked in Play Console

## External services and compliance

- [ ] Production billing provider and transaction verification
- [ ] Production rewarded ads provider and callback verification
- [ ] Cloud save/account backend or explicit local-only product decision
- [ ] Friends/Guild/PvP backend or removed/deferred before public launch
- [ ] Production audio supplied, licensed, integrated, and mixed (or silent launch approved)
- [ ] Crash monitoring selected and validated
- [ ] Analytics decision and consent/data handling documented
- [ ] Content rating completed
- [ ] Data safety declaration completed against actual providers/data collection

## Build and QA

- [ ] Godot Android debug APK built from matching export templates
- [ ] Release APK built and signature verified
- [ ] Release AAB built with Gradle and target API 36 or current required target
- [ ] Store screenshots prepared and reviewed
- [ ] Feature graphic prepared and reviewed
- [ ] Fresh install test on physical Android device
- [ ] Upgrade install test using the same package ID and signing identity
- [ ] Portrait, back handling, lifecycle/save, and touch QA on physical Android device
- [ ] Memory/FPS soak test and logcat crash review
- [ ] Final APK/AAB hash, version, and signing certificate recorded
