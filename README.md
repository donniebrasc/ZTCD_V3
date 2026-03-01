# ZTCD_V3
Comprehensive multi-platform Flutter app for diagnostics using OBD-II, phone sensors, GPS tracking, and AI-powered analysis via Google Gemini 2.5 Pro. Features Multi-transport OBD-II Connection: Bluetooth Classic, USB Serial, and  Comprehensive PID Support OBD-II   integration for automated vehicle diagnosis map display route recommendations

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

| Secret name | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w 0 release.jks` output |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | key alias (e.g. `my-key-alias`) |
| `ANDROID_KEY_PASSWORD` | key password |
| `MAPS_API_KEY` | *(optional)* Google Maps API key |

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
1. Decode `ANDROID_KEYSTORE_BASE64` to a temporary file.
2. Build `app-release.apk` using the release signing config.
3. Create (or update) the GitHub Release tagged **`ZTCDv1.0BETA`** and attach the APK.
