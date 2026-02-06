# Implementation Plan: Issue #18

## Problem
The app is currently fully branded as "FluffyChat". This includes the application name, UI strings, icons, and platform-specific metadata across Android, iOS, Web, Linux, macOS, and Windows. A rebranding to "FF Chat" (Family and Friends Chat) is required for the fork.

## Solution
Perform a comprehensive rebranding by updating configuration files, localization strings, platform metadata, and assets. Add AGPL-compliant attribution to FluffyChat in the About dialog. Ensure that critical identifiers (like Bundle IDs and URI schemes) remain unchanged to avoid breaking existing functionality and push notifications.

## Changes
### Phase 1: Core Configuration
1. `lib/config/setting_keys.dart`: Update default `applicationName` to 'FF Chat'.
2. `lib/config/app_config.dart`: Update `website`, `sourceCodeUrl`, and `supportUrl`.
3. `lib/utils/platform_infos.dart`: Add attribution to FluffyChat in the About dialog.

### Phase 2: Localization
1. `lib/l10n/intl_en.arb`: Update 5 primary branding strings.

### Phase 3: Platform Metadata
1. Android: `AndroidManifest.xml` label update.
2. iOS: `Info.plist` display name and usage descriptions.
3. Web: `index.html` and `manifest.json` titles.
4. Linux: `my_application.cc` window titles.
5. macOS: `AppInfo.xcconfig` product name.

### Phase 4: Compliance
1. Add missing SPDX headers to modified files.
2. Add `MODIFICATIONS` entries with current date.
3. Add Fork Copyright `© 2026 Simon`.

### Phase 5: Assets
1. (Manual/Separate) Replace 42 icon/logo assets.

## AGPL Compliance Checklist
| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `lib/config/setting_keys.dart` | ✅ | ✅ | ✅ Add | ✅ Add entry |
| `lib/config/app_config.dart` | ✅ | ✅ | ✅ Add | ✅ Add entry |
| `lib/utils/platform_infos.dart` | ❌ Add | ❌ Add | ✅ Add | ✅ Add entry |
| `lib/l10n/intl_en.arb` | N/A | N/A | N/A | N/A |
| `android/app/src/main/AndroidManifest.xml` | N/A | N/A | N/A | N/A |
| `ios/Runner/Info.plist` | N/A | N/A | N/A | N/A |
| `web/index.html` | N/A | N/A | N/A | N/A |
| `linux/my_application.cc` | N/A | N/A | N/A | N/A |
| `macos/Runner/Configs/AppInfo.xcconfig` | N/A | N/A | N/A | N/A |

## Testing
- Verify app name in UI (About dialog, AppBar).
- Verify app name on home screen (Android/iOS).
- Verify window titles (Linux/macOS/Windows).
- Run existing tests to ensure no regressions.

## Edge Cases
- Deep links and push notifications: Do NOT change `appId`, `scheme`, or server URLs.
- Localization: Only English is updated in this phase; others will fallback or remain as "FluffyChat".
