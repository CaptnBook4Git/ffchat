# Implementation Plan: Issue #21

## Problem
Currently, tapping your own Story Room in the Stories bar always opens the StoryViewer directly. There is no way to open the room as a normal chat to manage it (e.g., delete messages or the room itself).

## Solution
Add a choice dialog (bottom sheet) when tapping the user's own Story Room. The dialog will offer two options:
1. "View Stories": Opens the StoryViewer as before.
2. "Manage Stories": Opens the room as a normal chat.

## Changes
1. `lib/utils/own_story_config.dart`:
   - Add `bool isOwnStoryRoom(Room room)` to `OwnStoryConfigExtension`.
2. `lib/pages/chat_list/chat_list.dart`:
   - Update `onChatTap` to detect own story rooms and show a `showModalActionPopup`.
3. `lib/l10n/intl_en.arb`:
   - Add `viewStories`, `manageStories`, and `storyOptions` strings.

## AGPL Compliance Checklist
| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `lib/pages/chat_list/chat_list.dart` | ✅ | © 2021-2026 FluffyChat Contributors | ✅ © 2026 Simon | Add entry |
| `lib/utils/own_story_config.dart` | ✅ | ❌ | ✅ © 2026 Simon | Add entry |

## Testing
1. Tap a story room that is NOT your own -> Should open StoryViewer directly.
2. Tap your own story room -> Should show a dialog with "View Stories" and "Manage Stories".
3. Select "View Stories" -> Should open StoryViewer.
4. Select "Manage Stories" -> Should open the room as a normal chat.

## Edge Cases
- Account data `ffchat.story` not set: `isOwnStoryRoom` should return false.
- Dialog cancelled: No action should be taken.
