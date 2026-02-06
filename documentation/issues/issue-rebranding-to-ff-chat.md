# Rebranding Fluffy Chat to FF Chat

**Type:** Enhancement

## Description

This issue tracks the comprehensive rebranding of the FluffyChat fork to "FF Chat". The goal is to establish a distinct identity for this fork within the "Family and Friends" (FF) ecosystem while maintaining the core functionality of the original application. The rebranding involves updating the application name, titles, and visual assets across all supported platforms including Android, iOS, Web, Linux, macOS, and Windows.

Consistency is key for this rebranding effort. The name "FF Chat" must appear correctly in window titles, app drawer labels, browser tabs, and within the application's UI strings. Furthermore, all brand-specific icons and logos need to be replaced with the new "FF Chat" visual identity to ensure a professional and unified user experience.

While we are rebranding the visual and nominal aspects of the application, we must remain in full compliance with the GNU Affero General Public License (AGPL). This means that while we change the branding, we must preserve the original copyright notices and provide clear, visible attribution to the original FluffyChat project and its contributors within the application's "About" or "Info" section.

## Current Behavior

The application is currently branded as "FluffyChat".
- The default app name in configuration is "FluffyChat".
- UI strings in various languages refer to "FluffyChat".
- Platform-specific metadata (Android labels, iOS display names) use "FluffyChat".
- Icons and logos feature the FluffyChat branding.
- The "About" dialog lacks a specific attribution section for the "FF Chat" fork identity relative to its origin.

## Expected Behavior

- The application is consistently branded as "FF Chat" across all platforms.
- All logos, icons, and splash screens feature the "FF Chat" branding.
- The "About" dialog clearly states that "FF Chat" is a fork of FluffyChat with appropriate links.
- All functional Matrix chat features remain intact.

## Motivation

The rebranding is necessary to differentiate this fork from the upstream FluffyChat project. By adopting the "FF Chat" identity, we can tailor the messaging experience for our specific user base while avoiding confusion with the original project. This also allows us to build a unique brand presence for our fork.

## Codebase Analysis

### Affected Files
| File | Component | Relevance |
|------|-----------|-----------|
| `lib/config/setting_keys.dart` | Config | Default app name definition |
| `lib/l10n/intl_en.arb` | Localization | Primary UI strings |
| `lib/utils/platform_infos.dart` | UI/About | Attribution and versioning info |
| `android/app/src/main/AndroidManifest.xml` | Android | App label in launcher |
| `ios/Runner/Info.plist` | iOS | Bundle display name |
| `web/index.html` | Web | Browser tab title |
| `web/manifest.json` | Web | PWA name |
| `linux/my_application.cc` | Linux | Window title |
| `macos/Runner/Configs/AppInfo.xcconfig` | macOS | Product name |

### Current Implementation

The current implementation uses "FluffyChat" as a hardcoded string or a localized resource in several key locations:
- `lib/config/setting_keys.dart:57`: `static const String appName = 'FluffyChat';` (example)
- `lib/l10n/intl_en.arb`: Multiple lines (1056, 2151, 1243, 1431, 3190) contain "FluffyChat".
- `lib/utils/platform_infos.dart:50-94`: The logic for building the "About" dialog.
- `android/app/src/main/AndroidManifest.xml:29`: `android:label="FluffyChat"`.
- `ios/Runner/Info.plist`: `CFBundleDisplayName` set to "FluffyChat".
- `web/index.html:27,33`: `<title>` and metadata tags.
- `linux/my_application.cc:56,60`: Window title initialization.

### Dependencies
- **Assets:** The project depends on a variety of image assets in `assets/` and platform-specific resource folders (`android/app/src/main/res`, `ios/Runner/Assets.xcassets`, etc.) which must all be updated in unison.
- **Localization:** All 56 `.arb` files should ideally be updated, though `intl_en.arb` is the priority.

## Upstream Status

- Related upstream issue: None (this is a fork-specific branding change).
- Upstream PR: None.

## Suggested Implementation Plan

1. **Update Dart Config:** Modify `lib/config/setting_keys.dart` (Line 57) to change the default app name constant to "FF Chat".
2. **Update English Localization:** Edit `lib/l10n/intl_en.arb` (Lines 1056, 2151, 1243, 1431, 3190) to replace "FluffyChat" with "FF Chat".
3. **Update Platform Metadata:**
   - **Android:** Update `android/app/src/main/AndroidManifest.xml` (Line 29).
   - **iOS:** Update `ios/Runner/Info.plist` (`CFBundleDisplayName`).
   - **macOS:** Update `macos/Runner/Configs/AppInfo.xcconfig` (Line 8).
   - **Linux:** Update `linux/my_application.cc` (Lines 56, 60).
   - **Web:** Update `web/index.html` (Lines 27, 33) and `web/manifest.json` (Lines 2-3).
4. **Asset Replacement:**
   - Replace `assets/logo.png`, `assets/logo.svg`, `assets/logo_transparent.png`, and `assets/info-logo.png`.
   - Update Android mipmap icons in `android/app/src/main/res/mipmap-*/`.
   - Update iOS AppIcon set in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
   - Update Web icons in `web/icons/` and `web/favicon.png`.
   - Update Windows icon in `windows/runner/resources/app_icon.ico`.
5. **AGPL Attribution:** Modify `lib/utils/platform_infos.dart` (Lines 50-94) to ensure the "About" dialog includes a clear statement: "FF Chat is a fork of FluffyChat" with a link to `https://github.com/krille-chan/fluffychat`.

## Acceptance Criteria

- [ ] Application title is "FF Chat" on all platforms (Launchers, Taskbars, Titles).
- [ ] All brand assets (logos, icons) are updated to the "FF Chat" design.
- [ ] Primary English localization strings are updated.
- [ ] **AGPL Compliance:** "About" section contains visible attribution to FluffyChat with a link to the original source.
- [ ] AGPL headers are present on all modified source files.
- [ ] `CHANGELOG.md` updated with a `[FORK]` entry describing the rebranding.

## Technical Notes

- Ensure that any automated build scripts or CI/CD pipelines (like Fastlane or GitHub Actions) are also checked for hardcoded "FluffyChat" strings.
- Be careful with localization; some strings might be shared or used in contexts where "FluffyChat" is part of a URL or a specific technical identifier that shouldn't be changed.
- Asset sizes and density variants for icons must match the original specifications to prevent layout issues.

## Research References

- Research results provided by librarian regarding file locations and asset lists.
- Matrix Specification regarding room types and custom identifiers (for future reference if needed).

---
*Generated by new-issue-agpl*
