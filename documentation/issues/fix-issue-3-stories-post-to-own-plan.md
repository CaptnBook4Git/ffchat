# Implementation Plan: Issue #3

## Problem
Users can view stories, but there is no “Zur Story hinzufügen” flow to quickly post media into the user’s own story channel.

## Solution
Introduce a persistent per-account mapping to an “own story” room via Matrix account data type `ffchat.story` with `{ "room_id": "!…" }`. If missing, create a new private **encrypted** story room named with the existing `story:` prefix, store its room id, then upload/send selected images to that room using the existing `SendFileDialog`/`room.sendFileEvent` flow.

## Changes
1. `lib/utils/own_story_config.dart` (new)
   - Client extension to read/write `ffchat.story` account data.
   - Helper to resolve `Room? getOwnStoryRoom()` and to create one if missing.

2. `lib/pages/stories/stories_bar.dart`
   - Add an action/button “Zur Story hinzufügen”.
   - On tap: resolve/create own story room, pick image(s), send via existing dialog/flow, then navigate to `/rooms/story/:roomid`.

3. `lib/l10n/l10n.dart` (+ translations where required)
   - Add string(s) for “Zur Story hinzufügen”, errors (if needed).

4. (If needed) `lib/pages/stories/story_viewer.dart`
   - Optional: refresh after returning, or ensure it shows newly sent media.

## AGPL Compliance Checklist

| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `lib/pages/stories/stories_bar.dart` | ✅ Present | keep | update | add entry |
| `lib/utils/own_story_config.dart` (new) | ❌ Add | n/a | add | add entry |
| `lib/l10n/l10n.dart` | (check) | keep | update | add entry |
| `CHANGELOG.md` | n/a | keep | n/a | add entry |

## Testing
- Manual:
  1) Open chat list → stories row visible.
  2) Tap “Zur Story hinzufügen” → pick 1+ images.
  3) First time: room auto-created, images sent, navigates to viewer.
  4) Second time: reuses stored room_id and sends.
- Automated:
  - Run Flutter tests (existing suite).

## Edge Cases
- User cancels picker → no action.
- Upload too large / server limit → existing error snackbars.
- Account data not yet loaded → ensure `await client.accountDataLoading` before reading.
- Room id stored but room not in client cache → attempt `client.getRoomById`, else fallback to create new and overwrite mapping.
