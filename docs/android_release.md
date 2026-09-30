# Android build and signing

## Current project settings

- App label: `Crown of Vael`
- Android application ID: `com.crownofvael.game` (first Android identity; keep fixed after distribution)
- Portrait; 1080x1920 design viewport, 360x640 desktop preview, canvas item scaling with expanded aspect
- Compatibility renderer (OpenGL ES 3); target render rate 60 FPS
- Version name comes from `application/config/version` in `project.godot` (`0.1.0`). Increment `version/code` in every Android preset for each distributed build.
- Android exports include arm64-v8a only. Unneeded network, location, storage, and vibration permissions are disabled. Internet permission must be enabled only when a real network provider is integrated.
- APK presets use Godot's prebuilt Android templates. The Play AAB preset uses Gradle, API 23 minimum, API 36 target, and requires the installed Gradle build template.
- Empty launcher icon overrides intentionally fall back to the project SVG icon. Supply reviewed 192x192 main and 432x432 adaptive foreground/background art before store submission.

## Local build prerequisites and current status

The Android SDK is installed at `%LOCALAPPDATA%\Android\Sdk`: this audit found platforms 33, 34, 35, 36, and 37 previews, Build Tools 36.0.0 and 37.0.0, NDK 28.2.13676358, CMake 3.22.1, and `platform-tools\adb.exe`. `adb devices -l` found no attached device. Godot's existing Editor Settings already points at this SDK, but its Java SDK path is empty. `java` in PATH resolves to Java 8; Android Studio's bundled OpenJDK 25 is present at `C:\Program Files\Android\Android Studio\jbr` and Godot 4.7 supports newer JDKs, though it recommends 17. The Godot 4.7.1 export-template directory is empty. These missing templates and Java SDK selection prevented APK/AAB export in this audit.

Before exporting, set Godot Editor Settings' Java SDK Path to the Android Studio JBR (or a dedicated supported JDK 17 install), confirm the SDK path, and install matching 4.7.1 APK templates plus the Gradle build template. No global configuration was changed during this audit. Check that the installed SDK includes the Android platform/build tools and NDK/CMake packages required by the chosen export workflow.

Do not change global paths just for this repository. Set Java SDK Path and Android SDK Path in Godot Editor Settings on the build machine. Confirm with `java -version`, `adb devices -l`, and the Godot export dialog before installing anything.

## Debug APK

Install the matching Godot 4.7.1 Android export templates and configure SDK/JDK paths, then:

```powershell
& 'C:\path\to\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --export-debug 'Android Debug APK' '.godot/build/CrownOfVael-debug.apk'
adb install -r '.godot/build/CrownOfVael-debug.apk'
adb shell monkey -p com.crownofvael.game 1
```

The debug preset uses Godot's local debug signing defaults; it is for development installs only. Debug signed installs cannot be updated by a differently signed release build without uninstalling first.

## Release APK and Play AAB

The release APK preset uses the regular release template. The Play AAB preset uses Gradle and needs the Godot Android Gradle build template plus the Android 16 SDK (API 36). New Google Play app submissions and updates have required API 36 or higher since 2026-08-31; re-check the Play requirements on submission day. AAB builds should be tested through Play internal testing before public rollout.

Create a production keystore outside the repository and keep a secure offline backup. Example command (use a unique alias and strong private passwords interactively; never put credentials in source control):

```powershell
keytool -genkeypair -v -keystore 'D:\secure\crown-of-vael-release.jks' -alias crown-of-vael -keyalg RSA -keysize 2048 -validity 10000
```

Enter the keystore path, alias, and key password in the Android Release preset in Godot's export dialog or provide the documented `GODOT_ANDROID_KEYSTORE_RELEASE_*` environment variables to the export process. Do not store the values in `export_presets.cfg`, scripts, CI logs, or this repository. Losing the production signing key can prevent updates to the same store app; back it up and test recovery before release.

```powershell
& 'C:\path\to\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --export-release 'Android Release APK' '.godot/build/CrownOfVael-release.apk'
& 'C:\path\to\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --export-release 'Android Play AAB (Gradle)' '.godot/build/CrownOfVael-release.aab'
```

The production keystore is not present and no signed release export has been made in this workspace.

## Export versions and identity

`project.godot` owns the visible version name. Keep all three `version/code` values synchronized and increase the integer for every distributed Play build. Never change the package ID after publication. This checkout has no previous Android ID, so the configured reverse-DNS ID establishes the initial install/save identity.

Before publishing, verify the exported manifest's package, min/target SDK, requested permissions, orientation, version name/code, icon resources, backup policy, and signing certificate. Review the current Google Play target API requirement and Android behavior changes when the release is actually prepared.

## References

- [Godot 4.7 Android export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)
- [Godot 4.7 Gradle Android build](https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html)
- [Google Play target API requirement](https://developer.android.com/google/play/requirements/target-sdk)
