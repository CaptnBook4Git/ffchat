# Add device contacts import/sync with optional Matrix user matching (groundwork for Circles)

**Type:** feature

## Description

Add an address-book import/sync feature to ffchat (FluffyChat fork) so users can import device contacts (names + phone/email identifiers), optionally refresh the imported set, and (optionally) match contacts to Matrix users. This is groundwork for the Circles feature (Google+ style contact grouping).

### Why
Currently ffchat/FluffyChat “contacts” are effectively derived from existing direct chats and manual Matrix user directory search. There is no device address-book import, which blocks Circles from being populated with the user’s real-world contacts.

### Requirements (v1)
- Android + iOS support.
- Explicit runtime permission request with clear rationale.
- One-time import + manual refresh.
- Normalize and deduplicate phone numbers/emails.
- Store imported contacts locally (encrypted if SQLCipher is used), allow delete.
- Optional Matrix matching:
  - Default: local-only (no network lookup).
  - Optional: identity server 3PID lookup (hashed addresses per Matrix Identity Service API) *only when user explicitly enables it and an identity server is configured*.
  - Otherwise: provide a manual “Find on Matrix” action using existing user directory search.

### Repo context
- `permission_handler` is already included.
- No contacts plugin is present (need to add one, e.g. `flutter_contacts`).
- 3PID settings exist: `lib/pages/settings_3pid/*`.
- Identity server is shown in homeserver settings; lookup is not implemented currently.


## Motivation

Importing device contacts is a common messenger baseline feature and is required groundwork for Circles. It enables users to quickly seed and maintain a contact list without manually searching Matrix IDs. Privacy-sensitive design is important: contact identifiers must not be uploaded or queried against a network service without explicit opt-in and transparency.

This issue proposes a v1 that is deliberately conservative: manual import and refresh, local storage, and optional Matrix matching only when the user chooses it and the homeserver/identity-server configuration supports it.

## Implementation Plan

1. **Research & decisions**
   1) Choose contacts access plugin (recommend evaluating `flutter_contacts` for Android+iOS, with support for light fetch + listener).
   2) Decide storage format and location (prefer existing encrypted DB/storage patterns; otherwise minimal local store via `shared_preferences` for small metadata + encrypted DB for payload).
   3) Decide matching approach for v1: local-only by default; optional identity-server lookup.

2. **Add dependency & platform configuration**
   1) Add contacts plugin to `pubspec.yaml` (e.g. `flutter_contacts`).
   2) Android: add `READ_CONTACTS` (and only `WRITE_CONTACTS` if needed later) to `AndroidManifest.xml`.
   3) iOS: add `NSContactsUsageDescription` to `Info.plist`.
   4) If using `permission_handler` for contacts, ensure iOS macros/Info.plist keys are aligned with current permission usage.

3. **Data model + normalization/dedup**
   1) Define `ImportedContact` model: stable `sourceId`, `displayName`, `phones[]`, `emails[]`, optional `photoHash/thumbnail`, `lastImportedAt`.
   2) Normalize:
      - Phones: E.164-like normalization if possible (at minimum strip whitespace, punctuation; keep leading `+`), keep original raw value.
      - Emails: lowercase + trim.
   3) Deduplicate identifiers across unified contacts (note: iOS/Android unify raw contacts; avoid double-counting).

4. **Import flow (v1)**
   1) Create a new UI page: “Import contacts” with explanation + privacy copy.
   2) Permission request flow:
      - If denied: show rationale and link to OS settings.
      - If granted: import.
   3) Import implementation:
      - Fetch contacts with minimal fields first, then optionally expand details.
      - Store locally.
      - Show results: count imported, count with phone/email.

5. **Refresh / incremental strategy (v1)**
   1) Provide a manual “Refresh” button.
   2) Implement basic change detection:
      - Compare contact IDs and identifier hashes to decide add/update/remove.
      - Optionally use plugin listener (`addListener`) to mark “needs refresh” indicator.

6. **Optional Matrix matching (v1)**
   1) UX: toggle “Try to match contacts to Matrix users” with clear warning that identifiers may be queried.
   2) If identity server configured:
      - Implement identity-service `/hash_details` + `/lookup` flow (sha256 + pepper).
      - Batch lookups; rate-limit and handle `M_INVALID_PEPPER` by refetching pepper once.
   3) If no identity server or user disabled matching:
      - Provide per-contact “Find on Matrix” action that opens existing user search (directory search).

7. **Privacy, security, and deletion**
   1) Default to local-only import.
   2) No background sync by default.
   3) Provide “Delete imported contacts data” action.
   4) Document what is stored locally and what is sent over network (only on opt-in).

8. **QA / verification**
   1) Test on Android + iOS simulators/devices: permission flows (grant/deny/permanent deny), import, refresh.
   2) Verify dedup results on contacts with multiple phone/email entries.
   3) Verify optional identity lookup path works when identity server present; otherwise manual search works.
   4) Ensure no contacts are accessed on web/desktop builds (feature hidden/disabled there for v1).

## Acceptance Criteria

- [ ] A new “Import contacts” entry point exists (at least in Settings; optionally also in New Chat).
- [ ] On Android and iOS, the app requests contacts permission with a clear user-facing explanation and handles denied/permanently-denied states.
- [ ] User can perform a one-time import of device contacts and sees a summary (total contacts imported, identifiers found).
- [ ] User can manually refresh the imported contacts; refresh updates adds/changes/removals in local store.
- [ ] Phone numbers and emails are normalized and deduplicated to prevent obvious duplicates.
- [ ] Imported contacts are stored locally and can be fully deleted via UI.
- [ ] Matrix matching is **off by default** and requires explicit opt-in.
- [ ] When enabled and an identity server is available, the app can perform hashed 3PID lookup (per Matrix Identity Service API) to associate some contacts with Matrix user IDs.
- [ ] When matching is disabled or identity server is unavailable, the UI offers a manual “Find on Matrix” action using existing user directory search.
- [ ] The feature is disabled/hidden on platforms where contacts are not supported (web/desktop) in v1.

## Technical Notes

Best-practice notes to incorporate:
- Use least-privilege: request only read access.
- Be conservative about background work; contact sync should be manual in v1.
- Identity lookup privacy: use `/hash_details` + `sha256` algorithm with pepper; never send plain identifiers unless explicitly chosen.

Relevant existing code/patterns in repo:
- 3PID management: `lib/pages/settings_3pid/*`
- Identity server display: `lib/pages/settings_homeserver/settings_homeserver_view.dart`
- User directory search patterns: `lib/pages/new_private_chat/*`, `lib/pages/invitation_selection/*`
- Permission patterns: location and other permission flows; `permission_handler` is already a dependency.

Suggested contact plugin:
- `flutter_contacts` (supports permission request and a change listener; has unified vs raw contact concept).

## Labels

feature, priority:low, contacts, android, ios, privacy, ux

---
*Generated automatically by neo-creator*

