# ZTCD_V3

**Zero-Touch Car Diagnostics** — a comprehensive Flutter app for real-time vehicle diagnostics using OBD-II, phone sensors, GPS tracking, and AI-powered analysis via Google Gemini 2.5 Pro.

---

## Table of Contents

1. [Features Overview](#features-overview)
2. [Prerequisites & Setup](#prerequisites--setup)
3. [Usage & Testing Checklist](#usage--testing-checklist)
4. [Troubleshooting](#troubleshooting)
5. [Architecture Notes](#architecture-notes)
6. [Signed Releases & CI/CD](#signed-android-releases)
7. [Contributing](#contributing)

---

## Features Overview

ZTCD_V3 is organized into three main tabs, each covering a different aspect of vehicle health and trip monitoring.

### 🔌 OBD Diagnosis Tab

Real-time vehicle diagnostics via OBD-II.

| Feature | Details |
|---|---|
| **Connection modes** | Simulation (no hardware needed), Bluetooth Classic, USB Serial |
| **Live data display** | RPM, speed, coolant temp, throttle position, and more standard PIDs |
| **AI diagnostics** | Tap **Analyze** to send live OBD data to Google Gemini for a plain-language health report |
| **Demo mode** | When no Gemini API key is configured, the app returns a realistic demo response so you can still explore the UI |

> ℹ️ **Simulation mode** is the default. It generates realistic OBD-II values so you can explore every feature without physical hardware.

### 📊 Damage Log Tab

Driving behavior tracking and vehicle health scoring.

| Feature | Details |
|---|---|
| **Damage score** | 0–100 score updated in real time from accelerometer & gyroscope data |
| **Event detection** | Harsh braking, rapid acceleration, sharp cornering, overheating alerts |
| **Trip recording** | Each trip is saved with GPS waypoints, timestamps, and a damage timeline |
| **Persistence** | Trip history stored in `SharedPreferences`; survives app restarts |
| **Chart view** | fl_chart line graph of damage score over the course of each trip |

### 🗺️ GPS Routes Tab

Route tracking and AI-powered route optimization.

| Feature | Details |
|---|---|
| **Live map** | Google Maps with dark automotive styling, centered on your current position |
| **Live tracking toggle** | Tap **START TRACKING** / **STOP TRACKING** to turn real-time GPS tracking on or off for the map overlay (stopping tracking here does **not** save a route) |
| **Saved routes & trips** | Routes are persisted by the **Damage Log** tab via its trip recording (TripService). Use that tab to start/stop a trip when you want it saved to history. |
| **AI recommendations** | With a Gemini API key, tap **Suggest Route** for AI-generated alternatives based on traffic and your driving history |
| **No API key** | Map still renders (with a Google watermark if `MAPS_API_KEY` is not set); live tracking works fully offline |

---

## Prerequisites & Setup

### Required tools

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0 (`flutter --version`)
- Android SDK / Android Studio (or Xcode for iOS)
- Java 17+ (required by Android Gradle Plugin 8)

Run `flutter doctor` to confirm your toolchain is ready:

```bash
flutter doctor
```

### Optional API keys

| Key | Where to get it | What it unlocks |
|---|---|---|
| **Gemini API key** | [ai.google.dev](https://ai.google.dev) (free tier available) | Live AI diagnostics & route recommendations |
| **Google Maps API key** | [Google Cloud Console](https://console.cloud.google.com) → Maps SDK for Android | Full map tiles without watermark |

The app runs fully without either key — simulation mode and demo AI responses cover all features.

### Clone & run

```bash
# 1. Clone the repo
git clone https://github.com/donniebrasc/ZTCD_V3.git
cd ZTCD_V3

# 2. Install Flutter dependencies
flutter pub get

# 3. (Optional) Set your Gemini API key in the app
#    Settings → API Key → paste your key → Save

# 4. Run in debug mode on a connected device or emulator
flutter run

# Or build a debug APK
flutter build apk --debug
```

### Running tests

```bash
flutter test
```

---

## Usage & Testing Checklist

Use this checklist to manually verify that all features work correctly after a fresh install or code change.

### OBD Diagnosis

- [ ] **Simulation mode**: Open the app → OBD tab → connection mode is set to *Simulation* → tap **Connect** → live data values appear and update every second
- [ ] **Gemini demo mode**: Tap **Analyze** with no API key configured → response panel shows a realistic demo report (not an error)
- [ ] **Gemini live mode**: Go to **Settings** → enter a valid Gemini API key → return to OBD tab → tap **Analyze** → response contains actual Gemini output specific to the displayed OBD data
- [ ] **Bluetooth mode** *(requires hardware)*: Switch connection mode to *Bluetooth* → pair with an ELM327 adapter → **Connect** succeeds and live PIDs appear
- [ ] **USB mode** *(requires hardware)*: Switch to *USB* → plug in USB serial adapter → **Connect** succeeds

### Damage Log

- [ ] **Score updates**: Navigate to Damage tab while simulation is running → damage score changes as simulated sensor data varies
- [ ] **Event detection**: Physically shake the device (or simulate sensor spikes) → a new damage event entry appears in the log with a timestamp and event type
- [ ] **Trip recording**: Tap **Start Trip** → drive (or let simulation run) for >30 seconds → tap **Stop Trip** → trip appears in history list
- [ ] **Persistence**: Force-close the app → reopen → previous trips are still listed in Damage tab
- [ ] **Chart view**: Tap a saved trip → damage-over-time chart renders without error

### GPS Routes

- [ ] **Live tracking**: Open GPS tab on a physical device with GPS → blue dot moves as you move
- [ ] **Route recording**: Tap **Start** → move around → tap **Stop** → route appears in history with distance and damage summary
- [ ] **Route history**: Saved routes persist after app restart
- [ ] **AI route suggestion** *(requires Gemini API key)*: Tap **Suggest Route** → recommendation panel shows a route suggestion
- [ ] **No internet fallback**: Disable internet → open GPS tab → map tiles may be cached or blank, but the app does not crash

### Settings & Persistence

- [ ] Enter an API key in Settings → close Settings → reopen → key is still present
- [ ] Clear the API key → Analyze in OBD tab falls back to demo mode

---

## Troubleshooting

### ❓ "OBD connection failed" / nothing happens after tapping Connect

**Cause:** The default connection mode is *Simulation*, which always succeeds. If you switched to *Bluetooth* or *USB* without hardware, the connection will fail.  
**Fix:** Switch connection mode back to **Simulation** in the OBD tab header, or ensure the physical adapter is paired/plugged in.

---

### ❓ Map shows a watermark or gray tiles

**Cause:** `MAPS_API_KEY` is not configured, or the key is not authorized for *Maps SDK for Android*.  
**Fix:** Add your key as a GitHub Actions secret (`MAPS_API_KEY`) for CI builds, or inject it locally via `android/local.properties`:

```
MAPS_API_KEY=AIzaSy...
```

Route recording and GPS tracking still work without a Maps key — only tile rendering is affected.

---

### ❓ Damage events are not appearing

**Cause:** The device's accelerometer/gyroscope are required. Android emulators typically do not emulate these sensors.  
**Fix:** Run the app on a **physical Android device**, or use the built-in simulation mode which injects synthetic sensor data.

---

### ❓ Where is my trip data saved?

Trip history is stored in `SharedPreferences` on the device (no external database or server). Data persists until the app is uninstalled or **Settings → Clear Data** is used in Android system settings.

---

### ❓ Gemini returns "Demo Mode" — how do I enable live AI?

**Cause:** No Gemini API key is configured.  
**Fix:** Open **Settings** (tune/sliders icon in the top-right of any tab) → paste your key in the *Gemini API Key* field → tap **Save**. The next **Analyze** call will use the live Gemini 2.5 Pro model.

---

### ❓ `flutter pub get` fails with a dependency conflict

**Cause:** The vendored `flutter_bluetooth_serial` package has a broadened Dart SDK constraint; this is intentional. See [Architecture Notes](#architecture-notes) for details.  
**Fix:** Ensure you are using Flutter SDK ≥ 3.0 (`flutter --version`) and run `flutter pub get` again.

---

## Features: Capabilities & Limitations

| Status | Feature |
|---|---|
| ✅ | OBD-II simulation mode — no hardware required |
| ✅ | Sensor-based damage scoring (accelerometer & gyroscope) |
| ✅ | Demo AI responses when no Gemini API key is set |
| ✅ | Trip history persisted across app restarts |
| ✅ | Dark-theme automotive UI |
| ⚠️ | Live GPS tracking requires a physical device with GPS |
| ⚠️ | Live AI diagnostics & route suggestions require a Gemini API key |
| ⚠️ | Full map tiles (no watermark) require a Google Maps API key |
| ⚠️ | Bluetooth/USB OBD modes require a compatible ELM327 adapter |
| 📝 | Damage detection thresholds are currently hardcoded; customization requires a code change |

---

## Architecture Notes

### Vendored dependency: `flutter_bluetooth_serial`

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

---

## Contributing

Contributions are welcome! Please:

1. Fork the repo and create a feature branch from `main`.
2. Run `flutter analyze` and `flutter test` before opening a pull request.
3. Keep pull requests focused — one feature or fix per PR.
4. If you are adding a new dependency, explain why an existing package cannot cover the use case.
