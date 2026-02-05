# Fix Documentation - Issue #5

**Branch:** fix/issue-5-contacts-import

## Problem

FluffyChat lacked the ability to import local device contacts to find Matrix users.

## Solution

Added a new Contact Import page and utility logic to request permissions, read contacts, and match them with Matrix IDs via an identity server.

## Changes

android/app/src/main/AndroidManifest.xml, ios/Runner/Info.plist, l10n.yaml, lib/config/routes.dart, lib/config/setting_keys.dart, lib/l10n/intl_en.arb, lib/pages/new_private_chat/new_private_chat.dart, lib/pages/new_private_chat/new_private_chat_view.dart, lib/pages/import_contacts/*, lib/utils/contacts/*, documentation/issues/issue-auto-update-story-room-avatar.md

## Verification

Open the 'New Chat' page, click 'Import device contacts', grant permissions, and verify that contacts are listed and can be matched/invited.

---
*Generated automatically for Issue #5*

