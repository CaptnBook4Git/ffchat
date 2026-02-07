# Implementation Plan: Issue #4 — Add Contact Circles

## Problem
FF Chat lacks a grouping mechanism for contacts. Users must scroll through all direct chats when inviting people to rooms. There is no way to organize contacts into private groups (Circles) for bulk actions or better organization.

## Solution
Implement "Circles" (Google+ style contact groups) using Matrix account data (`im.ffchat.circles`) for cross-device persistence.
- Service layer (`CirclesConfigExtension`) for CRUD on account data.
- Management UI in Settings and New Chat.
- Interaction UI in User Dialog (add/remove from circle).
- Audience selection UI in Invitation Selection (filter by circle).

## Changes

### 1. Data Layer & Logic
- **`lib/utils/circles_config.dart`**: New extension for `Client` to manage `im.ffchat.circles` account data.
- **`lib/l10n/intl_en.arb`**: New localization strings for Circles feature.

### 2. UI Components (Management)
- **`lib/pages/circles/circles_list.dart`**: List of all circles.
- **`lib/pages/circles/circles_list_view.dart`**: View for the list.
- **`lib/pages/circles/circle_detail.dart`**: Detail view for a single circle (edit name, manage members).
- **`lib/pages/circles/circle_detail_view.dart`**: View for the detail.

### 3. Integration Points
- **`lib/config/routes.dart`**: Register `/rooms/circles` and `/rooms/circles/:circleId`.
- **`lib/pages/settings/settings_view.dart`**: Add "Circles" to settings menu.
- **`lib/pages/new_private_chat/new_private_chat_view.dart`**: Add "Circles" to new chat options.
- **`lib/widgets/adaptive_dialogs/user_dialog.dart`**: Add "Add to Circle" action.
- **`lib/pages/invitation_selection/invitation_selection.dart`**: Add circle filtering logic.
- **`lib/pages/invitation_selection/invitation_selection_view.dart`**: Add circle filter chips UI.

## AGPL Compliance Checklist
| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `lib/utils/circles_config.dart` | ✅ Add | N/A | ✅ Add | ✅ Add |
| `lib/pages/circles/*.dart` | ✅ Add | N/A | ✅ Add | ✅ Add |
| `lib/config/routes.dart` | ✅ Exist | ✅ Keep | ✅ Keep | ✅ Add entry |
| `lib/pages/settings/settings_view.dart` | ✅ Add | ✅ Add | ✅ Add | ✅ Add entry |
| `lib/widgets/adaptive_dialogs/user_dialog.dart` | ✅ Add | ✅ Add | ✅ Add | ✅ Add entry |
| `lib/pages/invitation_selection/invitation_selection.dart` | ✅ Add | ✅ Add | ✅ Add | ✅ Add entry |
| `lib/pages/invitation_selection/invitation_selection_view.dart` | ✅ Add | ✅ Add | ✅ Add | ✅ Add entry |
| `lib/pages/new_private_chat/new_private_chat_view.dart` | ✅ Exist | ✅ Keep | ✅ Keep | ✅ Add entry |

## Testing
1. **Manual**: Create circle, add members via User Dialog, verify list in Settings.
2. **Manual**: Go to Invitation Selection in a room, filter by circle, verify list only shows members.
3. **Manual**: Delete circle, verify removal.
4. **Manual**: Persistence check (restart app).

## Edge Cases
- **No circles**: UI should show friendly empty state.
- **User already in circle**: "Add to circle" should show existing membership.
- **Large member lists**: Circle detail view should handle scrolling.
- **Network delay**: Saving to account data should show loading indicator.
