# Set up and document Android build and testing process

**Type:** Task

## Description

The purpose of this issue is to establish and verify a reliable process for building and testing the Android version of the FluffyChat fork (`CaptnBook4Git/ffchat`). While the project inherits a complete Android infrastructure from the upstream repository, the build process for this fork needs to be validated locally to ensure all dependencies, particularly the Rust-based encryption libraries, are correctly integrated. This includes documenting any necessary pre-build scripts or environment configurations required for a successful build in Android Studio or via the CLI.

## Current Behavior

The Android build infrastructure is present in the codebase:
- Android project folder: `android/` (line 1+)
- Gradle configuration: `android/build.gradle.kts`
- CI/CD workflows: `.github/workflows/integrate.yaml`
- Build scripts: `scripts/prepare-android-release.sh` and `scripts/integration-check-release-build.sh`

However, there is currently no verified documentation specific to this fork on how to perform a clean local build and test run, and potential issues with dependency pinning (like the Tink library) need to be monitored.

## Expected Behavior

- Developers should be able to successfully build a debug APK and AAB locally.
- The application should run correctly on both Android emulators and physical devices.
- A clear, step-by-step guide for the Android build process, including pre-requisites and environment setup, should be available in the documentation.

## Motivation

Ensuring a stable Android build is critical for the deployment of the family-focused features of this fork. Since this project relies on specific versions of Flutter and external Rust libraries for encryption, a well-documented and verified build process prevents developer friction and ensures consistent releases.

## Codebase Analysis

### Affected Files
| File | Component | Relevance |
|------|-----------|-----------|
| `README.md` | Build documentation | Contains basic build instructions (lines 80-92) |
| `.github/workflows/versions.env` | Version pinning | Defines Flutter 3.38.8 and Java 17 requirements |
| `android/app/build.gradle.kts` | App Gradle config | Handles signing, dependencies, and SDK versions |
| `pubspec.yaml` | Flutter dependencies | Requires `flutter_vodozemac` which depends on Rust |
| `scripts/prepare-android-release.sh` | Release preparation | Automates keystore and property generation |
| `scripts/integration-check-release-build.sh` | Integration test | Scripted APK build and validation |

### Current Implementation
The current build process relies on Flutter's standard build commands but requires a specific environment (Flutter 3.38.8, Java 17) and the Rust toolchain for `flutter_vodozemac`. Some workarounds for library version pinning (Tink) and NDK filters are already present in the Gradle files.

### Dependencies
- **Flutter SDK**: 3.38.8 (pinned in `.github/workflows/versions.env`)
- **Java JDK**: 17
- **Rust Toolchain**: Mandatory for building encryption components.
- **Firebase Messaging (Optional)**: Can be added via `scripts/add-firebase-messaging.sh`.

## Upstream Status

- Several open issues in the upstream repository (`krille-chan/fluffychat`) such as #954, #1546, and #1216 indicate that Android build failures are common, highlighting the fragility of the build environment.

## Suggested Implementation Plan

1. **Verify Prerequisites**: Ensure local environment has Flutter 3.38.8, Java 17, and the Rust toolchain installed and correctly configured in the PATH.
2. **Environment Setup**: 
    - Run `flutter doctor` to verify the Flutter installation.
    - Check `rustc --version` and `java -version`.
3. **Execute Pre-build Scripts**: 
    - Run `flutter pub get` to fetch dependencies.
    - If needed for release testing, examine and potentially run `scripts/prepare-android-release.sh` (noting it requires environment variables for keys).
4. **Perform Debug Build**: 
    - Run `flutter build apk --debug` to verify the basic build flow.
5. **Run on Device/Emulator**: 
    - Use `flutter run` with an attached device or running emulator.
6. **Document Process**: Update the `README.md` or create a new developer guide in `documentation/guides/android-build.md` with the verified steps.

## Acceptance Criteria

- [ ] Successful local Android debug build (`flutter build apk --debug`).
- [ ] Application successfully launches on an Android emulator or physical device.
- [ ] Build process documentation is updated and verified.
- [ ] AGPL headers updated on all modified files.
- [ ] CHANGELOG.md updated with [FORK] entry.

## Technical Notes

- **Rust Requirement**: The `flutter_vodozemac` package requires the Rust toolchain to be installed on the build machine.
- **Library Workarounds**: Be aware of the existing Tink library version pinning workaround and NDK ABI filters in the Gradle configuration.
- **Firebase Messaging**: If testing push notifications, `scripts/add-firebase-messaging.sh` must be run, which requires a valid `google-services.json`.

## Research References

- Upstream Build Failures: krille-chan/fluffychat issues #954, #1546, #1216.
- Matrix Dart SDK and Vodozemac documentation.

---
*Generated by new-issue-agpl*
