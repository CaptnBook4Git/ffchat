# Implementation Plan: Issue #11

## Problem
The Android build process for the FF Chat fork needs to be established, verified, and documented. Currently, the documentation is minimal and does not cover the specific requirements of the fork, such as the Rust toolchain for `flutter_vodozemac`, Java 17 requirements, and known workarounds for library pinning and NDK filters. There is also a pre-existing issue with `flutter gen-l10n` that blocks the build process.

## Solution
1. **Fix the blocker**: Resolve the `FileSystemException` related to `l10n_header.txt` during `flutter gen-l10n`.
2. **Verify the build**: Successfully perform a local Android debug build (`flutter build apk --debug`).
3. **Create comprehensive documentation**:
   - Create a new guide `documentation/guides/android-build.md` with detailed instructions.
   - Update `README.md` to point to the new guide and highlight key requirements.
4. **Compliance**: Ensure AGPL-3.0-or-later headers are updated in any modified source files and add a `[FORK]` entry to `CHANGELOG.md`.

## Changes
1. `lib/l10n/l10n.dart` (or related): Fix the `l10n_header.txt` path issue.
2. `documentation/guides/android-build.md`: **NEW** guide for Android builds.
3. `README.md`: Update Android build section and prerequisites.
4. `CHANGELOG.md`: Add fork entry.

## AGPL Compliance Checklist
| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `lib/...` (if changed for l10n) | ❌ Add | © 2021-2026 FluffyChat | © 2026 Simon | Add entry |
| `README.md` | N/A | N/A | N/A | N/A |
| `documentation/guides/android-build.md` | N/A | N/A | N/A | N/A |
| `CHANGELOG.md` | N/A | N/A | N/A | N/A |

## Testing
- Execute `flutter gen-l10n` to verify the fix.
- Execute `flutter build apk --debug --target-platform android-arm64`.
- (Optional) Install and run the APK on an emulator or device.

## Edge Cases
- Java version mismatch (local vs. CI).
- Rust toolchain and Android NDK compatibility.
- Signing issues for local builds.
