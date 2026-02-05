# Add contact Circles (Google+ Circles-style grouping) with circle-based audience selection

**Type:** feature

## Description

Implement private, named contact groups (“Circles”) inspired by Google+ Circles, so users can organize Matrix contacts and use Circles as an audience selector for sharing/inviting.

## Google+ Circles behaviors/UX to replicate (relevant subset)
- **Create circle via “drop here to create a new circle”** in the Circles management view (drag/drop interaction) and then name it. (Google Help: “Organize your friends into circles”) 
- **Multi-membership**: the same person can be in multiple circles.
- **Circles are private**: circle titles are not disclosed to the people placed into them. (WebApps.SE quoting Google help)
- **Audience selection**: Circles are meant to make it easy to pick a subset of people when sharing.
- Optional/advanced concept from Google+: **Extended Circles** (“circles’ circles”). (Historical behavior; likely out of scope for v1)

## Current ffchat/FluffyChat baseline
- No device address-book import/sync.
- “Contacts” are derived from:
  - existing direct chats (`room.isDirectChat`) and
  - Matrix user directory search (`client.searchUserDirectory`).

Key files already in codebase:
- `lib/pages/invitation_selection/invitation_selection.dart` (contacts = direct chats)
- `lib/pages/new_private_chat/new_private_chat.dart` / `_view.dart` (directory search)
- `lib/widgets/adaptive_dialogs/user_dialog.dart` (user modal actions)
- `lib/pages/chat_list/chat_list.dart` (`ActiveFilter.messages` = direct chats)

## Proposed split into 2 issues
1) **This issue (Circles model & UI + audience selector integration)**
2) **Follow-up**: Device contacts import/sync and mapping to Matrix users (permissions, platform differences, identity lookup).

## Motivation

FluffyChat currently lacks a first-class way to organize people beyond “direct chats” and manual search. Google+ Circles demonstrated a clear UX model for grouping contacts and quickly choosing an audience, while keeping grouping private. Adding Circles enables faster room invitations, clearer organization for frequent contacts, and sets a foundation for future circle-based visibility/sharing features in this fork.

## Implementation Plan

1. Define a Circles data model:
   1) Circle (id, name, createdAt, updatedAt)
   2) Membership mapping (circleId -> list of Matrix userIds)
   3) Allow multi-membership.
2. Decide persistence mechanism:
   - Prefer Matrix account data (per-user, syncs across devices). Define a stable event type (e.g. `im.ffchat.circles`) and JSON schema with versioning.
   - Fallback: local storage only if account data proves insufficient.
3. Implement a Circles service layer:
   - CRUD for circles
   - add/remove member
   - list circles for a given user
   - migrate schema versions
4. Add UI for managing circles:
   - Circles list screen (create/rename/delete)
   - Circle detail screen (members list + add/remove)
   - Entry points: Settings and/or People/New Chat flows.
   - UX parity note: drag-and-drop is optional; provide touch-friendly add/remove first.
5. Integrate Circles as an “audience selector” in an existing workflow (v1):
   - Invitation flow: in `invitation_selection_view.dart`, add a Circles filter/section; selecting a circle preselects all members (excluding already-in-room users).
   - Alternative (if invite flow too coupled): New group creation: pick circles to invite.
6. Add privacy/visibility constraints:
   - Circles and circle names are local-only; never share circle metadata into rooms.
7. Add localization strings and minimal documentation.
8. Manual verification:
   - create circle, add members, rename/delete
   - members can be in multiple circles
   - inviting by circle adds the expected users.

## Follow-up issue pointer (not created here)
Create a second issue: “Import/sync device contacts and map to Matrix users”. It should cover permissions (iOS/Android), contact change listening, deduping, optional hashing, and UX for linking phone/email to Matrix IDs.

## Acceptance Criteria

- [ ] Users can create, rename, and delete Circles (named contact groups).
- [ ] Users can add/remove Matrix users to/from a Circle; a user can belong to multiple Circles.
- [ ] Circles persist across app restarts (and preferably across devices via Matrix account data).
- [ ] Circle names/memberships are private to the user (not shared with other users/rooms).
- [ ] At least one existing workflow supports selecting a Circle as an audience selector (initially: inviting people to a room / new group invite selection), applying members in bulk and excluding already-in-room users.
- [ ] UI remains usable on mobile without drag-and-drop (touch-friendly add/remove).

## Labels

feature, priority:low, ui, ux, contacts

---
*Generated automatically by neo-creator*

