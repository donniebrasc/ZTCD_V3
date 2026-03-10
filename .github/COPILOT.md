# Copilot Instructions for ZTCD_V3

## Project Overview

**ZTCD_V3** (Zero-Touch Car Diagnostics) is a multi-platform Flutter app for real-time vehicle diagnostics. It combines OBD-II data, phone sensors, GPS tracking, and AI-powered analysis via Google Gemini 2.5 Pro.

### App Structure — Three Tabs

| Tab | File | Purpose |
|-----|------|---------|
| OBD Diagnosis | `lib/pages/diagnosis_page.dart` | Real-time OBD-II data display and AI diagnostics |
| GPS Routes | `lib/pages/gps_routes_page.dart` | Live map, route tracking, AI route recommendations |
| Settings | `lib/pages/settings_page.dart` | API key input, OBD transport selection |

Additional pages: `lib/pages/damage_log_page.dart` (driving behaviour and trip history).

### Key Services

| Service | File | Description |
|---------|------|-------------|
| `OBDService` | `lib/services/obd_service.dart` | OBD-II connection and PID polling (simulation only; Bluetooth/USB not yet implemented) |
| `GeminiService` | `lib/services/gemini_service.dart` | Google Gemini 2.5 Pro AI integration with demo fallback |
| `LocationService` | `lib/services/location_service.dart` | GPS tracking and haversine distance calculation |
| `TripService` | `lib/services/trip_service.dart` | Trip persistence to `trips.json` via `path_provider` |
| `DamageService` | `lib/services/damage_service.dart` | Accelerometer/gyroscope event detection and scoring |
| `SettingsService` | `lib/services/settings_service.dart` | SharedPreferences-backed settings persistence |

---

## Build Configuration

### Toolchain Versions

| Tool | Version | Notes |
|------|---------|-------|
| Flutter | Stable channel (3.41.x+) | `flutter --version` to confirm |
| Dart | ≥ 3.0.0 | Declared in `pubspec.yaml` |
| Java | Temurin 17 | Required by AGP 8+ |
| Android Gradle Plugin (AGP) | **8.9.1** | Declared in `android/settings.gradle` |
| Kotlin | **2.1.0** | Declared in `android/gradle.properties` as `kotlinVersion` |
| Gradle Wrapper | 8.3.0+ | `android/gradle/wrapper/gradle-wrapper.properties` |
| `compileSdk` / `targetSdk` | **36** | `android/app/build.gradle` |
| `minSdk` | 21 | `android/app/build.gradle` |

### Key File Locations

| File | Purpose |
|------|---------|
| `android/app/build.gradle` | App-level Android build config |
| `android/settings.gradle` | Plugin version declarations (AGP, Kotlin) |
| `android/gradle.properties` | Gradle JVM args, AndroidX flags, `kotlinVersion` |
| `android/app/src/main/AndroidManifest.xml` | Android manifest with placeholder substitutions |
| `pubspec.yaml` | Flutter dependencies and version constraints |
| `.github/workflows/release.yml` | CI/CD workflow (build + optional signed release) |

---

## Common Development Tasks

```bash
# Install dependencies
flutter pub get

# Analyze code
flutter analyze

# Run tests
flutter test

# Build debug APK
flutter build apk --debug

# Build release APK (requires KEYSTORE_PATH and signing env vars)
flutter build apk --release

# Run on connected device
flutter run

# Clean build artifacts
flutter clean
```

### Optional API Keys (local development)

```bash
# Google Maps API key — affects map tile rendering only; all other features work without it
export MAPS_API_KEY=AIzaSy...

# Gemini API key — entered at runtime in the Settings tab, not a build-time variable
```

Alternatively, add `MAPS_API_KEY` to `android/gradle.properties` (not committed to version control):

```
MAPS_API_KEY=AIzaSy...
```

---

## CI/CD Workflow

The workflow `.github/workflows/release.yml` runs on every push to `main` and on pull requests targeting `main`. It can also be triggered manually via **Actions → Run workflow**.

### What It Does

1. **Always**: Builds a debug APK (`app-debug.apk`) and uploads it as the `app-debug-apk` artifact. No signing secrets required.
2. **If all four signing secrets are configured**: Builds a release APK and publishes/updates the GitHub Release tagged `ZTCDv1.0BETA`.

### Required GitHub Secrets

| Secret | Required for | Description |
|--------|-------------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Signed release | Base64-encoded keystore: `base64 -w0 release.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Signed release | Keystore password |
| `ANDROID_KEY_ALIAS` | Signed release | Key alias inside the keystore |
| `ANDROID_KEY_PASSWORD` | Signed release | Key password |
| `MAPS_API_KEY` | Optional | Google Maps tile rendering |

> All four signing secrets must be configured together. The workflow fails fast with a clear error if `ANDROID_KEYSTORE_BASE64` is set but any of the others are missing.

### Downloading the Debug APK

1. GitHub → **Actions** → click a completed **Build & Release Android APK** run.
2. Scroll to **Artifacts** → click **`app-debug-apk`** to download the ZIP.

---

## Known Issues and Solutions

### `applicationName` manifest placeholder

**Symptom:** Build fails with:
```
Attribute application@name requires a placeholder substitution but no value
for <applicationName> is provided.
```

**Cause:** `AndroidManifest.xml` uses `${applicationName}` but `build.gradle` did not supply it in `manifestPlaceholders`.

**Fix (already applied):** `android/app/build.gradle` `defaultConfig` block includes:
```groovy
manifestPlaceholders = [
    applicationName: "io.flutter.app.FlutterMultiDexApplication",
    MAPS_API_KEY: mapsKey,
]
```
Always keep `applicationName` in `manifestPlaceholders` — do not remove it.

---

### Kotlin version auto-downgrade

**Symptom:** Warning: `Flutter support for your project's Kotlin version (1.9.10) will soon be dropped.`

**Cause:** Flutter's Gradle plugin can silently downgrade the Kotlin version if it is not pinned.

**Fix (already applied):** `android/gradle.properties` pins `kotlinVersion=2.1.0`. The Kotlin plugin in `android/settings.gradle` reads this property:
```
id "org.jetbrains.kotlin.android" version "${kotlinVersion}" apply false
```
Keep `kotlinVersion` at **2.1.0** or higher.

---

### XML parse error in AndroidManifest.xml

**Symptom:** `processDebugMainManifest` fails with `ManifestMerger2$MergeFailureException`.

**Cause:** XML comments containing `--` are invalid in XML and cause a parse error.

**Fix (applied in PR #20):** Ensure no XML comments in `AndroidManifest.xml` contain `--`. Use single-line comments without double-hyphens.

---

### Vendored `flutter_bluetooth_serial`

**Context:** `flutter_bluetooth_serial` 0.4.0 is missing the `android { namespace }` block required by AGP 8+.

**Fix:** A patched copy lives in `third_party/flutter_bluetooth_serial/`. `pubspec.yaml` uses `dependency_overrides` to point Flutter at it:
```yaml
dependency_overrides:
  flutter_bluetooth_serial:
    path: third_party/flutter_bluetooth_serial
```
When an upstream release with the namespace fix is published, remove `third_party/` and the `dependency_overrides` block.

---

### Google Maps shows watermark / gray tiles

**Cause:** `MAPS_API_KEY` is not configured or the key lacks *Maps SDK for Android* permission.

**Fix:** Set the `MAPS_API_KEY` GitHub secret (for CI) or export it as an environment variable before building locally. GPS tracking works without it — only tile rendering is affected.

---

## Architecture Notes

- **OBD transports:** Only `simulation` is implemented. `bluetooth` and `usb` transports set the connection state to error (not yet implemented). See `lib/services/obd_service.dart`.
- **Trip persistence:** Trips are saved to `trips.json` in the app documents directory via `TripService` (`path_provider`), not `SharedPreferences`.
- **AI fallback:** When no Gemini API key is configured, `GeminiService` returns a realistic demo response so the UI can be explored without a key.
- **Plugin version centralization:** AGP and Kotlin versions are declared once in `android/settings.gradle` (with `apply false`). The `android/app/build.gradle` module applies plugins without repeating the version.

---

## Recent Fixes

| PR | Fix |
|----|-----|
| #20 | Fixed XML parse error in `AndroidManifest.xml` (invalid `--` in comments) |
| #21 / #22 | Added missing `applicationName` placeholder to `android/app/build.gradle` `manifestPlaceholders` |
| Kotlin | Updated `android/gradle.properties` to pin `kotlinVersion=2.1.0` |
| AGP | Updated `android/settings.gradle` to AGP 8.9.1 |
