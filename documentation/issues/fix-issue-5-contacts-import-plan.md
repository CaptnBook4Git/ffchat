# Implementation Plan: Issue #5

## Problem
We need an in-app flow to import/sync device contacts (name, phone, email) and optionally match them to Matrix users (3PID lookup) while keeping privacy guarantees: local-only by default and no network lookup without explicit opt-in. The current WIP already adds a route/entry point and introduces contacts import code, but it does not compile yet and is missing required AGPL headers.

## Solution
Finish the contacts import feature as specified in Issue #5:

1. Provide a mobile-only “Import contacts” page with permission explanation/request and import/refresh/delete actions.
2. Store imported contacts locally in encrypted storage.
3. Keep Matrix matching OFF by default. When enabled and an identity server is available, perform privacy-preserving hashed 3PID lookup.
4. Fix current compilation issues (routing import, identity client API, URI handling, missing l10n keys, l10n header-file config).
5. Ensure AGPL compliance by adding the required SPDX + MODIFICATIONS headers to every modified/new Dart file and updating CHANGELOG in Phase 4.

## Changes
1. `lib/config/routes.dart`
   - Add missing import for `ImportContactsPage`.
   - Keep `NewPrivateChat(initialSearchTerm: ...)` behavior.

2. `lib/pages/import_contacts/import_contacts.dart`
   - Ensure controller wiring and platform gating is correct.

3. `lib/pages/import_contacts/import_contacts_view.dart`
   - Fix compile errors:
     - Replace invalid `Uri.isEmpty` checks.
     - Stop calling private identity client methods; use a public API.
   - Add/fix translations usage to match available keys.
   - Permission UX: explanation, denied/permanently denied handling.

4. `lib/utils/contacts/identity_lookup_client.dart`
   - Expose a public method for pepper/details retrieval (instead of private `_hashDetails`).
   - Keep hashing + retry on `M_INVALID_PEPPER`.

5. `lib/utils/contacts/contacts_repository.dart`
   - Verify encrypted storage schema + operations align with existing SQLCipher patterns.

6. `lib/utils/contacts/imported_contact.dart`
   - Verify data model covers required fields + normalization/dedup.

7. `lib/config/setting_keys.dart`
   - Ensure new settings keys are correct and used.

8. `lib/pages/new_private_chat/new_private_chat.dart`
   - Ensure `initialSearchTerm` behavior is safe (trim/empty, mounted checks).

9. `lib/pages/new_private_chat/new_private_chat_view.dart`
   - Keep mobile-only entry to Import Contacts.

10. `l10n.yaml`
   - Fix `header-file` path to correct location.

11. `lib/l10n/intl_en.arb` (and other locales if required by build)
   - Add missing keys used by Import Contacts UI.

12. `ios/Runner/Info.plist`
   - Update `NSContactsUsageDescription` to explicitly mention import + privacy/opt-in matching.

13. `android/app/src/main/AndroidManifest.xml`
   - Keep `READ_CONTACTS` permission; ensure it matches Android platform requirements.

## AGPL Compliance Checklist

All modified/new Dart files must contain the required header:

```dart
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-06: Implement device contacts import/sync groundwork (Issue #5) - Simon
```

| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `lib/config/setting_keys.dart` | ❌ Add | ✅ Keep/add | ❌ Add | ❌ Add entry |
| `lib/pages/new_private_chat/new_private_chat.dart` | ❌ Add | ✅ Keep/add | ❌ Add | ❌ Add entry |
| `lib/pages/new_private_chat/new_private_chat_view.dart` | ❌ Add | ✅ Keep/add | ❌ Add | ❌ Add entry |
| `lib/pages/import_contacts/import_contacts.dart` | ❌ Add | ✅ Add | ❌ Add | ❌ Add entry |
| `lib/pages/import_contacts/import_contacts_view.dart` | ❌ Add | ✅ Add | ❌ Add | ❌ Add entry |
| `lib/utils/contacts/contacts_repository.dart` | ❌ Add | ✅ Add | ❌ Add | ❌ Add entry |
| `lib/utils/contacts/identity_lookup_client.dart` | ❌ Add | ✅ Add | ❌ Add | ❌ Add entry |
| `lib/utils/contacts/imported_contact.dart` | ❌ Add | ✅ Add | ❌ Add | ❌ Add entry |

Notes:
- Non-Dart files (YAML/XML/lock/plist) do not use this header format.
- Phase 4 will also ensure `CHANGELOG.md` has a `[FORK]` entry.

## Testing
1. `flutter analyze`
2. `flutter test`
3. Manual (Android/iOS):
   - Open New Chat → Import contacts
   - Accept/deny permission and verify UI behavior
   - Import, refresh, search/filter, delete imported contacts
   - Toggle “Match contacts with Matrix users” (OFF by default)
   - Verify identity server lookup only happens when enabled

## Edge Cases
- Permission denied/permanently denied flows (needs settings deep-link or guidance).
- No identity server configured / `.well-known` lacks identity server.
- Contacts with multiple phone/email entries; dedup across contacts.
- Large address books (batching, UI responsiveness).
- Matching enabled but pepper invalid (retry once) / identity server errors.
