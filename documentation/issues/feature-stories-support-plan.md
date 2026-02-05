# Implementation Plan: Issue #1

## Problem
Rooms whose display name starts with `story:` should behave like “Stories” instead of normal chats: they must be detected, shown in a dedicated Stories section, excluded from the normal room list, and opened in a full-screen story viewer that shows timeline images (incl. encrypted) chronologically and marks the room as read.

## Solution
Implement prefix-based story-room detection (`story:` case-insensitive) and a minimal Stories UI:

- Add a small helper/extension to identify story rooms and produce a “display name without prefix”.
- Add a Stories bar (horizontal) in the chat list using the existing StatusMessageList UI pattern.
- Exclude story rooms from the normal `filteredRooms` list.
- Add a new story viewer page routed under `/rooms/story/:roomid`.
- In `onChatTap`, route story rooms to the story viewer.
- Story viewer loads timeline history, filters image events, displays them in chronological order, supports encrypted attachments via existing `MxcImage`/`downloadAndDecryptAttachment` patterns, and sets the read marker on open.

## Changes
1. `lib/utils/story_room_extension.dart`: add `isStoryRoom` + `storyDisplayName` helpers (prefix detection).
2. `lib/pages/chat_list/chat_list.dart`: route story-room taps to story viewer; exclude story rooms from normal filters.
3. `lib/pages/chat_list/chat_list_body.dart`: add a Stories section (horizontal bar) above filter chips; use existing avatar/ring patterns.
4. `lib/config/routes.dart`: add route `/rooms/story/:roomid` to open StoryViewer.
5. `lib/pages/stories/story_viewer.dart` (+ view if needed): implement full-screen story viewer using timeline image extraction; empty/error states; mark room as read.
6. `lib/pages/stories/stories_bar.dart` (optional): Stories horizontal list widget (reusing StatusMessageList visual approach).
7. `CHANGELOG.md`: add unreleased entry.

## AGPL Compliance Checklist

| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `lib/utils/story_room_extension.dart` | ❌ Add | n/a (new) | © 2026 Fork Maintainer | Add header + entry |
| `lib/pages/chat_list/chat_list.dart` | ❌ Add | preserve existing | © 2026 Fork Maintainer | Add header + entry |
| `lib/pages/chat_list/chat_list_body.dart` | ❌ Add | preserve existing | © 2026 Fork Maintainer | Add header + entry |
| `lib/config/routes.dart` | ❌ Add | preserve existing | © 2026 Fork Maintainer | Add header + entry |
| `lib/pages/stories/story_viewer.dart` | ❌ Add | n/a (new) | © 2026 Fork Maintainer | Add header + entry |
| `lib/pages/stories/stories_bar.dart` (if added) | ❌ Add | n/a (new) | © 2026 Fork Maintainer | Add header + entry |
| `CHANGELOG.md` | n/a | preserve existing | n/a | Add `[FORK]` entry |

## Testing
- Unit-style sanity: build/format/lint (existing CI).
- Manual:
  - Create/rename a room to `story:Test`.
  - Verify it appears only in Stories section, not normal list.
  - Tap opens full-screen viewer.
  - Viewer shows images chronologically; empty state when none.
  - Opening sets read marker (unread badge clears).
  - Non-story rooms behave unchanged.

## Edge Cases
- Display name null/empty → do not treat as story.
- Prefix with leading whitespace (e.g. `  story:`) → decide: trim before check (prefer trim).
- Case-insensitive detection (`Story:`).
- Encrypted images: ensure viewer uses existing decryption/download logic; graceful error UI on failure.
- Large timelines: cap history (e.g. request 100 events) and lazy load if needed later.
