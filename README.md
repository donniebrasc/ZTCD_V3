# ZTCD_V3
Comprehensive multi-platform Flutter app for diagnostics using OBD-II, phone sensors, GPS tracking, and AI-powered analysis via Google Gemini 2.5 Pro. Features Multi-transport OBD-II Connection: Bluetooth Classic, USB Serial, and  Comprehensive PID Support OBD-II   integration for automated vehicle diagnosis map display route recommendations

---

## Feature Overview

| Feature | Status | Description |
|---|---|---|
| OBD-II multi-transport | ✅ | Bluetooth Classic, USB Serial, and simulation mode |
| Phone sensors | ✅ | Accelerometer + gyroscope for pothole/harsh-braking detection |
| GPS tracking | ✅ | Route recording with waypoints and distance calculation |
| AI analysis | ✅ | Google Gemini 2.5 Pro — demo mode fallback when no API key |
| Settings persistence | ✅ | SharedPreferences-backed OBD address, Gemini key, thresholds |

---

## Running the Tests

```bash
flutter pub get
flutter test
```

The test suite in `test/widget_test.dart` covers:
- App renders main scaffold with navigation bar
- `OBDData` model — empty factory, JSON round-trip, prompt string
- `DamageEvent` model — JSON round-trip for every event type, display names
- `Trip` model — start, copyWith, JSON round-trip, duration
- `LocationService.calculateDistance` — edge cases and haversine accuracy

---

## Troubleshooting

### Build fails with "Error parsing AndroidManifest.xml"

**Symptom:** `processDebugMainManifest` task fails with a `ManifestMerger2$MergeFailureException`.

**Cause:** Flutter auto-upgrades `build.gradle` when it detects an outdated Kotlin version, stripping the `manifestPlaceholders` entry that resolves `${MAPS_API_KEY}`.

**Fix:** Ensure `gradle.properties` has `kotlinVersion=2.1.0` or higher (already set in this repo). The `build.gradle` resolves the placeholder to an empty string when no key is supplied, so the build succeeds without a Maps API key.

### Kotlin version deprecation warning

**Symptom:** `Warning: Flutter support for your project's Kotlin version (1.9.10) will soon be dropped.`

**Fix:** `gradle.properties` now declares `kotlinVersion=2.1.0`. No action required.

### Google Maps shows "No API Key" watermark

**Cause:** `MAPS_API_KEY` secret is not configured in the repository.

**Fix:** Add the `MAPS_API_KEY` GitHub secret (see *Set GitHub Secrets* below). All app features other than the map tile display work without it.

### Release build skipped in CI

**Cause:** One or more signing secrets are missing.

**Fix:** Configure all four signing secrets together — see *Set GitHub Secrets* below. The debug APK artifact is always produced even without signing secrets.

---

## Vendored dependency: `flutter_bluetooth_serial`

`flutter_bluetooth_serial` 0.4.0 (the latest published version) is missing the
`android { namespace "..." }` declaration required by Android Gradle Plugin 8+.
Until a fixed version is published upstream, this repo vendors a patched copy
under `third_party/flutter_bluetooth_serial/` that adds only the namespace line.

`pubspec.yaml` uses `dependency_overrides` to point Flutter at the local copy:

```yaml
dependency_overrides:
  flutter_bluetooth_serial:
    path: third_party/flutter_bluetooth_serial
```

The vendored copy is identical to the 0.4.0 release except for:
- `android/build.gradle`: added `namespace 'io.github.edufolly.flutterbluetoothserial'` inside `android { … }`
- `pubspec.yaml`: broadened the Dart SDK constraint to `'>=2.12.0 <4.0.0'`

When an upstream release that includes the namespace fix is published, remove
the `third_party/` directory and the `dependency_overrides` block from
`pubspec.yaml`.

---

## Signed Android Releases

### 1. Generate a keystore (one-time, developer)

```bash
keytool -genkeypair -v \
  -keystore release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias my-key-alias
```

Keep `release.jks` **out of version control** (it is already ignored via `.gitignore`).

### 2. Set GitHub Secrets

In the repository → **Settings → Secrets and variables → Actions**, add:

| Secret name | Required | Value |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | ✅ yes | `base64 -w 0 release.jks` output |
| `ANDROID_KEYSTORE_PASSWORD` | ✅ yes | keystore password |
| `ANDROID_KEY_ALIAS` | ✅ yes | key alias (e.g. `my-key-alias`) |
| `ANDROID_KEY_PASSWORD` | ✅ yes | key password |
| `MAPS_API_KEY` | ☐ optional | Google Maps API key |

> **All four signing secrets must be configured together.**  
> The workflow will fail fast with a clear error message if `ANDROID_KEYSTORE_BASE64` is present but any of the other three are missing, rather than allowing a cryptic Gradle error to surface later.

### 3. Run a local signed build

Export the same environment variables before running Flutter:

```bash
export KEYSTORE_PATH=/path/to/release.jks
export ANDROID_KEYSTORE_PASSWORD=yourKeystorePassword
export ANDROID_KEY_ALIAS=my-key-alias
export ANDROID_KEY_PASSWORD=yourKeyPassword

flutter build apk --release
```

If `KEYSTORE_PATH` is not set the build falls back to the debug signing config automatically.

### 4. Release publishing (CI)

The workflow `.github/workflows/release.yml` runs automatically on every push to `main` (and can be triggered manually via **Actions → Run workflow**).

It will:
1. **Always** build a debug APK (`app-debug.apk`) and upload it as a workflow artifact — no signing secrets required.
2. If **all four** signing secrets are configured, also build a release APK and publish/update the GitHub Release tagged **`ZTCDv1.0BETA`**.
   - If `ANDROID_KEYSTORE_BASE64` is set but any of the other three secrets are missing, the workflow **fails immediately** with a clear error — no cryptic Gradle message.

If **none** of the signing secrets are configured the debug artifact is still produced and available to download.

### 5. Downloading the debug APK from GitHub Actions

1. Go to the repository on GitHub → **Actions**.
2. Click on any **Build & Release Android APK** workflow run.
3. Scroll to the bottom of the run summary page to the **Artifacts** section.
4. Click **`app-debug-apk`** to download the ZIP containing `app-debug.apk`.

> **Note:** The debug APK is signed with the Android debug key. It can be sideloaded on Android devices (enable *Install unknown apps* in Settings) but is **not suitable for Google Play Store distribution**.
