# Research Report: Issue #4 — Add Contact Circles (Google+ Circles-style grouping)

## Issue-Titel
**Add contact Circles (Google+ Circles-style grouping) with circle-based audience selection**

## Issue-Beschreibung (vollständig)
Implement private, named contact groups ("Circles") inspired by Google+ Circles, so users can organize Matrix contacts and use Circles as an audience selector for sharing/inviting.

### Acceptance Criteria:
1. Users can **create, rename, and delete** Circles (named contact groups).
2. Users can **add/remove Matrix users** to/from a Circle; a user can belong to **multiple Circles**.
3. Circles **persist across app restarts** (preferably across devices via Matrix account data).
4. Circle names/memberships are **private** to the user (not shared with other users/rooms).
5. At least one existing workflow supports selecting a Circle as **audience selector** (inviting people to a room / new group invite selection).
6. UI remains usable on **mobile without drag-and-drop** (touch-friendly add/remove).

---

## Problem/Root Cause

FF Chat currently derives "contacts" exclusively from `room.isDirectChat` (see `lib/pages/invitation_selection/invitation_selection.dart:41-44`):

```dart
final contacts = client.rooms
    .where((r) => r.isDirectChat)
    .map((r) => r.unsafeGetUserFromMemoryOrFallback(r.directChatMatrixID!))
    .toList();
```

There is **no grouping mechanism** — no named groups, no categories, no way to bulk-invite. Users must individually search or scroll through all direct chats when inviting to rooms. This makes the invitation flow cumbersome for users with many contacts.

---

## Betroffene Dateien

### Neue Dateien (zu erstellen)

| Datei | Komponente | SPDX vorhanden | Original Copyright | Fork Copyright | MODIFICATIONS |
|-------|------------|----------------|-------------------|----------------|---------------|
| `lib/utils/circles_config.dart` | Data Model + CirclesConfigExtension on Client | N/A (new) | N/A | Needs `© 2026 Simon` | Needs creation entry |
| `lib/pages/circles/circles_list.dart` | CirclesListController (StatefulWidget) | N/A (new) | N/A | Needs `© 2026 Simon` | Needs creation entry |
| `lib/pages/circles/circles_list_view.dart` | CirclesListView (StatelessWidget) | N/A (new) | N/A | Needs `© 2026 Simon` | Needs creation entry |
| `lib/pages/circles/circle_detail.dart` | CircleDetailController (StatefulWidget) | N/A (new) | N/A | Needs `© 2026 Simon` | Needs creation entry |
| `lib/pages/circles/circle_detail_view.dart` | CircleDetailView (StatelessWidget) | N/A (new) | N/A | Needs `© 2026 Simon` | Needs creation entry |

### Bestehende Dateien (zu ändern)

| Datei | Komponente | SPDX vorhanden | Original Copyright | Fork Copyright | MODIFICATIONS |
|-------|------------|----------------|-------------------|----------------|---------------|
| `lib/pages/invitation_selection/invitation_selection.dart` | InvitationSelectionController | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `lib/pages/invitation_selection/invitation_selection_view.dart` | InvitationSelectionView | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `lib/widgets/adaptive_dialogs/user_dialog.dart` | UserDialog | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `lib/config/routes.dart` | AppRoutes | ✅ Zeile 1 | ✅ Zeile 2 `© 2021-2026 Krille Fear` | ✅ Zeile 3 `© 2026 Simon` | ✅ Zeilen 5-8 |
| `lib/pages/settings/settings_view.dart` | SettingsView | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `lib/pages/settings/settings.dart` | SettingsController | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `lib/pages/chat_list/chat_list.dart` | ChatListController | ✅ Zeile 1 | ✅ Zeile 2 `© 2021-2026 FluffyChat Contributors` | ✅ Zeile 3 `© 2026 Simon` | ✅ Zeilen 5-9 |
| `lib/pages/new_private_chat/new_private_chat_view.dart` | NewPrivateChatView | ✅ Zeile 1 | ✅ Zeile 2 `© 2021-2026 Krille Fear` | ✅ Zeile 3 `© 2026 Simon` | ✅ Zeile 6 |
| `lib/pages/chat_list/chat_list_body.dart` | ChatListViewBody | ✅ Zeile 1 | ✅ Zeile 2 `© 2022-2026 FluffyChat Contributors` | ✅ Zeile 3 `© 2026 Simon` | ✅ Zeilen 5-7 |
| `lib/l10n/intl_en.arb` | Localization | N/A (JSON) | N/A | N/A | N/A |
| `CHANGELOG.md` | Changelog | N/A | N/A | N/A | N/A |

---

## Empfohlener Lösungsansatz

### Architecture: Follow the `own_story_config.dart` Pattern

The codebase already has a proven pattern for storing user-specific config in Matrix account data via Client extensions:

1. **`lib/utils/own_story_config.dart`** — Extension on `Client`, uses `accountData['ffchat.story']` for read, `setAccountData(userID!, type, content)` for write.
2. **`lib/utils/account_config.dart`** — Extension on `Client`, uses `accountData['im.fluffychat.account_config']` with JSON model class.

The Circles feature should follow the same pattern:
- Account data event type: `im.ffchat.circles`
- Schema with versioning
- Extension on `Client` for CRUD

### Data Model (JSON Schema for account data)

```json
{
  "version": 1,
  "circles": [
    {
      "id": "uuid-1",
      "name": "Family",
      "created_at": "2026-02-07T00:00:00Z",
      "updated_at": "2026-02-07T00:00:00Z",
      "members": ["@alice:matrix.org", "@bob:example.com"]
    },
    {
      "id": "uuid-2",
      "name": "Work",
      "created_at": "2026-02-07T00:00:00Z",
      "updated_at": "2026-02-07T00:00:00Z",
      "members": ["@alice:matrix.org", "@charlie:matrix.org"]
    }
  ]
}
```

### UI Entry Points

1. **Settings → "Circles"** (new ListTile in `settings_view.dart:231`): Primary management screen.
2. **New Chat → "Circles"** (new ListTile in `new_private_chat_view.dart:161`): Quick access alongside "Create Group" and "Import Contacts".
3. **User Dialog → "Add to Circle"** (new action in `user_dialog.dart:186`): Context action when viewing a user profile.
4. **Invitation Selection → Circle filter** (new section in `invitation_selection_view.dart:86`): Audience selector when inviting to a room.

### UI Patterns to Reuse

- **`showModalActionPopup`** — For selecting a circle from a list (already used extensively in `chat_list.dart`, `settings.dart`, etc.)
- **`showTextInputDialog`** — For naming/renaming circles
- **`showOkCancelAlertDialog`** — For confirming delete
- **`showFutureLoadingDialog`** — For async operations with loading indicator
- **`AdaptiveModalAction`** — For circle selection actions
- **`Avatar` widget** — For user avatars in circle member lists
- **`ListTile`** — Standard list item pattern used everywhere

---

## Relevante Dokumentation

### Existing Plan
- `documentation/issues/fix/issue-4-add-contact-circles-plan.md` — Implementation plan already exists with file list and AGPL checklist
- `documentation/issues/issue-4-research.md` — Previous research (truncated in output but contains detailed analysis)
- `documentation/issues/issue-add-contact-circles-google-circles-style-grouping-.md` — Full issue specification

### Key Reference Patterns in Codebase

| Pattern | File | Line(s) | Purpose |
|---------|------|---------|---------|
| Account data extension | `lib/utils/own_story_config.dart` | 11-83 | `OwnStoryConfigExtension on Client` — read/write account data |
| Account config model | `lib/utils/account_config.dart` | 3-63 | `ApplicationAccountConfig.fromJson/toJson` — JSON model class |
| Modal action popup | `lib/widgets/adaptive_dialogs/show_modal_action_popup.dart` | 1-115 | Platform-adaptive bottom sheet / action sheet |
| Route registration | `lib/config/routes.dart` | 210-224 | `GoRoute` entries under `/rooms` |
| Settings entry | `lib/pages/settings/settings_view.dart` | 189-231 | ListTile patterns for settings menu |
| Contacts derivation | `lib/pages/invitation_selection/invitation_selection.dart` | 41-44 | `client.rooms.where((r) => r.isDirectChat)` |
| Contact list tile | `lib/pages/invitation_selection/invitation_selection_view.dart` | 158-201 | `_InviteContactListTile` with avatar, name, invite button |
| User dialog actions | `lib/widgets/adaptive_dialogs/user_dialog.dart` | 165-209 | Actions list with `AdaptiveDialogAction` |
| Filter chips | `lib/pages/chat_list/chat_list_body.dart` | 153-184 | `ActiveFilter` chip bar |

---

## IMPLEMENTATION STEPS (Pflichtformat)

### Phase 1: Data Layer (`lib/utils/circles_config.dart`) — NEW FILE

1. **ADD**: `lib/utils/circles_config.dart`
   - Create `Circle` class with fields: `id` (String/UUID), `name` (String), `createdAt` (DateTime), `updatedAt` (DateTime), `members` (List<String> of Matrix user IDs)
   - Add `Circle.fromJson(Map<String, dynamic>)` factory and `toJson()` method
   - Create `CirclesConfigExtension on Client` with:
     - `static const String circlesAccountDataType = 'im.ffchat.circles'`
     - `List<Circle> get circles` — reads from `accountData[circlesAccountDataType]`
     - `Future<void> _saveCircles(List<Circle> circles)` — writes via `setAccountData(userID!, type, content)`
     - `Future<Circle> createCircle(String name)` — generates UUID, appends to list, saves
     - `Future<void> renameCircle(String circleId, String newName)` — updates name + updatedAt
     - `Future<void> deleteCircle(String circleId)` — removes from list, saves
     - `Future<void> addMemberToCircle(String circleId, String userId)` — adds if not present
     - `Future<void> removeMemberFromCircle(String circleId, String userId)` — removes member
     - `List<Circle> circlesForUser(String userId)` — returns all circles containing this user
   - AGPL header: `SPDX-License-Identifier: AGPL-3.0-or-later`, `Copyright (c) 2026 Simon`, `MODIFICATIONS: - 2026-02-07: Create Circles data model and service layer - Simon`
   - **Reference pattern**: `lib/utils/own_story_config.dart:11-83` and `lib/utils/account_config.dart:3-63`

### Phase 2: Circles List UI (`lib/pages/circles/`) — NEW FILES

2. **ADD**: `lib/pages/circles/circles_list.dart`
   - `CirclesList` StatefulWidget, `CirclesListController` state
   - Methods: `createCircle()` (using `showTextInputDialog`), `deleteCircle(circleId)` (using `showOkCancelAlertDialog`), `renameCircle(circleId)` (using `showTextInputDialog`)
   - `build()` → `CirclesListView(this)`
   - AGPL header with fork copyright

3. **ADD**: `lib/pages/circles/circles_list_view.dart`
   - Scaffold with AppBar "Circles", FAB for "Add Circle"
   - `StreamBuilder` on `client.onSync.stream` for reactivity
   - `ListView.builder` showing circles from `client.circles`
   - Each item: `ListTile` with circle name, member count subtitle, trailing popup menu (rename/delete)
   - Empty state: "No circles yet" with prompt
   - **Reference pattern**: `new_group_view.dart` for layout, `settings_view.dart` for ListTile style

4. **ADD**: `lib/pages/circles/circle_detail.dart`
   - `CircleDetail` StatefulWidget with `circleId` parameter
   - Methods: `addMember()` (user search → select → add), `removeMember(userId)`, `renameCircle()`
   - `build()` → `CircleDetailView(this)`

5. **ADD**: `lib/pages/circles/circle_detail_view.dart`
   - Scaffold with AppBar showing circle name (editable)
   - Member list with `Avatar`, displayname, userId, remove button
   - FAB or button to add members (opens user search similar to `invitation_selection`)
   - **Reference pattern**: `invitation_selection_view.dart:158-201` for member list tiles

### Phase 3: Routing (`lib/config/routes.dart`) — MODIFY

6. **READ**: `lib/config/routes.dart` — Zeilen 210-224 (between `importcontacts` and `newgroup` routes)
7. **MODIFY**: `lib/config/routes.dart:219` — Add two new GoRoute entries:
   ```dart
   GoRoute(
     path: 'circles',
     pageBuilder: (context, state) => defaultPageBuilder(
       context, state, const CirclesList(),
     ),
     redirect: loggedOutRedirect,
     routes: [
       GoRoute(
         path: ':circleId',
         pageBuilder: (context, state) => defaultPageBuilder(
           context, state,
           CircleDetail(circleId: state.pathParameters['circleId']!),
         ),
         redirect: loggedOutRedirect,
       ),
     ],
   ),
   ```
   - Add import: `import 'package:fluffychat/pages/circles/circles_list.dart';`
   - Add import: `import 'package:fluffychat/pages/circles/circle_detail.dart';`
   - Update MODIFICATIONS header: `- 2026-02-07: Add Circles management routes (Issue #4) - Simon`

### Phase 4: Entry Points — MODIFY

8. **READ**: `lib/pages/settings/settings_view.dart` — Zeilen 223-232 (Security ListTile + Divider)
9. **MODIFY**: `lib/pages/settings/settings_view.dart:231` — Add before the `Divider`:
   ```dart
   ListTile(
     leading: const Icon(Icons.group_work_outlined),
     title: Text(L10n.of(context).circles),
     tileColor: activeRoute.startsWith('/rooms/circles')
         ? theme.colorScheme.surfaceContainerHigh
         : null,
     onTap: () => context.go('/rooms/circles'),
   ),
   ```
   - Add AGPL header (currently missing): `SPDX-License-Identifier: AGPL-3.0-or-later`, `Copyright (c) 2021-2026 FluffyChat Contributors`, `Copyright (c) 2026 Simon`, `MODIFICATIONS: - 2026-02-07: Add Circles entry point (Issue #4) - Simon`

10. **READ**: `lib/pages/new_private_chat/new_private_chat_view.dart` — Zeilen 160-173 (Create Group + Import Contacts ListTiles)
11. **MODIFY**: `lib/pages/new_private_chat/new_private_chat_view.dart:161` — Add after "Create Group" ListTile:
    ```dart
    ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        foregroundColor: theme.colorScheme.onSurface,
        child: const Icon(Icons.group_work_outlined),
      ),
      title: Text(L10n.of(context).circles),
      onTap: () => context.go('/rooms/circles'),
    ),
    ```
    - Update MODIFICATIONS header: add `- 2026-02-07: Add Circles entry point (Issue #4) - Simon`

### Phase 5: User Dialog Integration — MODIFY

12. **READ**: `lib/widgets/adaptive_dialogs/user_dialog.dart` — Zeilen 186-203 (between "Send a message" and "Ignore user" actions)
13. **MODIFY**: `lib/widgets/adaptive_dialogs/user_dialog.dart:186` — Add new action after the "Send a message" action:
    ```dart
    AdaptiveDialogAction(
      bigButtons: true,
      borderRadius: AdaptiveDialogAction.centerRadius,
      onPressed: () {
        Navigator.of(context).pop();
        // Show circle selection popup
        _showAddToCirclePopup(context, client, profile.userId);
      },
      child: Text(L10n.of(context).addToCircle),
    ),
    ```
    - Add helper method `_showAddToCirclePopup` using `showModalActionPopup` to list existing circles + "Create new circle" option
    - Add AGPL header (currently missing)
    - Adjust `borderRadius` values for existing actions to accommodate the new action

### Phase 6: Invitation Selection Integration — MODIFY

14. **READ**: `lib/pages/invitation_selection/invitation_selection.dart` — Zeilen 31-51 (getContacts method)
15. **MODIFY**: `lib/pages/invitation_selection/invitation_selection.dart` — Add circle-related state:
    ```dart
    String? selectedCircleId;
    
    void selectCircle(String? circleId) {
      setState(() => selectedCircleId = circleId);
    }
    ```
    - Modify `getContacts()` to filter by selected circle when `selectedCircleId != null`:
      ```dart
      if (selectedCircleId != null) {
        final circle = client.circles.firstWhere((c) => c.id == selectedCircleId);
        contacts.retainWhere((u) => circle.members.contains(u.id));
      }
      ```
    - Add AGPL header (currently missing)

16. **READ**: `lib/pages/invitation_selection/invitation_selection_view.dart` — Zeilen 76-86 (between search field and StreamBuilder)
17. **MODIFY**: `lib/pages/invitation_selection/invitation_selection_view.dart:76` — Add circle filter chips:
    ```dart
    // Circle filter section
    StreamBuilder(
      stream: room.client.onSync.stream,
      builder: (context, _) {
        final circles = room.client.circles;
        if (circles.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              FilterChip(
                selected: controller.selectedCircleId == null,
                onSelected: (_) => controller.selectCircle(null),
                label: Text(L10n.of(context).all),
              ),
              ...circles.map((circle) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  selected: controller.selectedCircleId == circle.id,
                  onSelected: (_) => controller.selectCircle(circle.id),
                  label: Text(circle.name),
                ),
              )),
            ],
          ),
        );
      },
    ),
    ```
    - Add AGPL header (currently missing)

### Phase 7: Localization — MODIFY

18. **MODIFY**: `lib/l10n/intl_en.arb` — Add localization strings (at end before closing `}`):
    ```json
    "circles": "Circles",
    "@circles": {},
    "createCircle": "Create circle",
    "@createCircle": {},
    "circleName": "Circle name",
    "@circleName": {},
    "deleteCircle": "Delete circle",
    "@deleteCircle": {},
    "deleteCircleConfirmation": "Are you sure you want to delete this circle? This cannot be undone.",
    "@deleteCircleConfirmation": {},
    "renameCircle": "Rename circle",
    "@renameCircle": {},
    "addToCircle": "Add to circle",
    "@addToCircle": {},
    "removeFromCircle": "Remove from circle",
    "@removeFromCircle": {},
    "noCirclesYet": "No circles yet. Create one to organize your contacts.",
    "@noCirclesYet": {},
    "circleMembers": "{count} members",
    "@circleMembers": { "placeholders": { "count": { "type": "int" } } },
    "createNewCircle": "Create new circle",
    "@createNewCircle": {},
    "addMember": "Add member",
    "@addMember": {}
    ```

### Phase 8: Changelog — MODIFY

19. **MODIFY**: `CHANGELOG.md:1` — Add under `## Unreleased` / `### Changed`:
    ```
    - [FORK] Add Contact Circles with circle-based audience selection (Issue #4)
    ```

### Phase 9: AGPL Compliance (for files missing headers)

20. **MODIFY** each file missing AGPL headers — Add to the **top** of each file:
    ```dart
    // SPDX-License-Identifier: AGPL-3.0-or-later
    // Copyright (c) 2021-2026 FluffyChat Contributors
    // Copyright (c) 2026 Simon
    //
    // MODIFICATIONS:
    // - 2026-02-07: [specific change] (Issue #4) - Simon
    ```
    Files needing this treatment:
    - `lib/pages/invitation_selection/invitation_selection.dart`
    - `lib/pages/invitation_selection/invitation_selection_view.dart`
    - `lib/widgets/adaptive_dialogs/user_dialog.dart`
    - `lib/pages/settings/settings_view.dart`
    - `lib/pages/settings/settings.dart` (only if modified)

    Files already having headers (just update MODIFICATIONS log):
    - `lib/config/routes.dart`
    - `lib/pages/chat_list/chat_list.dart` (only if modified)
    - `lib/pages/new_private_chat/new_private_chat_view.dart`

---

## Implementation Priority Order

| Step | Phase | Complexity | Dependencies |
|------|-------|------------|-------------|
| 1 | Data Layer | Medium | None — standalone |
| 2-5 | Circles UI | High | Step 1 (data model) |
| 6-7 | Routing | Low | Steps 2-5 (pages exist) |
| 8-11 | Entry Points | Low | Step 7 (routes registered) |
| 12-13 | User Dialog | Medium | Step 1 (data layer) |
| 14-17 | Invitation Selection | Medium | Step 1 (data layer) |
| 18 | Localization | Low | None — can be done first |
| 19 | Changelog | Low | After all code changes |
| 20 | AGPL Compliance | Low | During each file edit |

**Recommended order**: 18 → 1 → 2-5 → 6-7 → 8-11 → 12-13 → 14-17 → 20 → 19
