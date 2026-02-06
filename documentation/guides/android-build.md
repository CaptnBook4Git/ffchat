# Android Build & Test Guide

> **Goal:** Reliable process for building and testing the Android version of the FF Chat fork.
> 
> **Audience:** Developers and CI/CD systems.

---

## Prerequisites

To build FF Chat for Android, you need the following tools installed:

### 1. Flutter SDK
- **Version:** `3.38.8` (Pinned in CI)
- **Check:** `flutter --version`

### 2. Java Development Kit (JDK)
- **Version:** `17` (Zulu recommended, as used in CI)
- **Check:** `java -version`

### 3. Rust Toolchain
- **Channel:** `stable`
- **Targets:**
  - `aarch64-linux-android`
  - `armv7-linux-androideabi`
  - `i686-linux-android`
  - `x86_64-linux-android`
- **Check:** `rustc --version` and `rustup target list --installed`

### 4. Android SDK & NDK
- **NDK Version:** `28.x` (or newer)
- **Check:** `flutter doctor -v` to ensure Android toolchain is correctly configured.

---

## Environment Setup

1. **Flutter Doctor**: Run `flutter doctor` to ensure all dependencies are satisfied.
2. **Rust Targets**: Install required Android targets:
   ```bash
   rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
   ```

---

## Building the Application

### 1. Generate Localization Files
FF Chat uses `flutter_localizations`. You must generate the localization files before building:
```bash
flutter gen-l10n
```
*Note: If you encounter a `FileSystemException` with `l10n_header.txt`, ensure `l10n.yaml` has `header-file: l10n_header.txt` (relative to the `arb-dir`).*

### 2. Debug Build
To build a debug APK for a specific architecture (e.g., arm64):
```bash
flutter build apk --debug --target-platform android-arm64
```

### 3. Release Build
To build a release APK:
```bash
flutter build apk --release
```
*Note: You will need a valid `key.properties` file in the `android/` directory for signing.*

---

## Testing

### 1. Running on Emulator/Device
```bash
flutter run --debug
```

### 2. Integration Tests
FF Chat includes scripts for integration testing:
- `scripts/integration-check-release-build.sh`: Builds and verifies a release APK.
- `scripts/integration-start-avd.sh`: Starts a test Android Virtual Device.

---

## Troubleshooting

### Tink Library Conflict
If you see duplicate class errors related to `com.google.crypto.tink`, it is likely due to `unifiedpush_android`. The project forces Tink version `1.17.0` in `android/app/build.gradle.kts` to resolve this.

### NDK ABI Filter
To avoid issues with missing symbols in some NDK versions, ABI filters are applied in the Gradle configuration. See `android/app/build.gradle.kts` for details.

---

*Generated for Issue #11*
