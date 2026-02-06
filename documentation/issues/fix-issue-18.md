# Fix Documentation - Issue #18

**Branch:** fix/issue-18-rebranding-to-ff-cha

## Problem

The application was fully branded as 'FluffyChat', lacking fork identity and proper AGPL attribution for the fork.

## Solution

Updated all user-facing branding strings to 'FF Chat', added a FluffyChat attribution button in the About dialog, and ensured AGPL compliance with proper file headers.

## Changes

Modified lib/config/setting_keys.dart, lib/config/app_config.dart, lib/utils/platform_infos.dart, lib/l10n/intl_en.arb, android/app/src/main/AndroidManifest.xml, ios/Runner/Info.plist, web/index.html, web/manifest.json, linux/my_application.cc, macos/Runner/Configs/AppInfo.xcconfig, CHANGELOG.md. Updated all branding strings to 'FF Chat' and added AGPL-compliant attribution.

## Verification

Verified app name in UI, About dialog, and platform metadata. Checked AGPL headers for compliance.

---
*Generated automatically for Issue #18*

