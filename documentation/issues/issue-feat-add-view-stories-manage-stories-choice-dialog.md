# feat: Add "View Stories" / "Manage Stories" choice dialog for own Story Room

**Type:** feature

## Description

When tapping on your own Story Room in the Stories bar, a choice dialog (bottom sheet) should appear with two options:

1. **View Stories** — Opens the StoryViewer as it works today (full-screen slideshow)
2. **Manage Stories** — Opens the Story Room as a normal chat room, allowing the user to delete (redact) individual story images

Currently, tapping any story room (including your own) always opens the StoryViewer. There is no way to manage or delete individual story images without workarounds.

**Deletion behavior:** When images are deleted (redacted) via the normal chat room interface, they must no longer appear in the StoryViewer. This already works because `story_viewer.dart` uses `filterByVisibleInGui()` which excludes redacted events — no additional changes are needed for deletion sync.

## Motivation

Currently, users have no straightforward way to manage their own story content. Once an image is posted to a Story Room, there is no UI path to delete it. The Story Room is a normal Matrix room under the hood, so opening it as a regular chat room would expose the standard message deletion functionality. This feature gives users control over their own story content while keeping the implementation minimal — leveraging existing chat room functionality rather than building a custom management UI.

## Implementation Plan

### Phase 1: Own Story Room Detection Helper

**File:** `lib/utils/own_story_config.dart`
- Add a synchronous or cached `isOwnStoryRoom(Room room)` method to avoid async overhead on every tap
- Leverage the existing `getOwnStoryRoomId()` which reads from account data (`ffchat.story`)

### Phase 2: Choice Dialog in onChatTap()

**File:** `lib/pages/chat_list/chat_list.dart`
- In `onChatTap()` (lines 113-156), before the existing `if (room.isStory)` block:
  - Check if the tapped room is the user's own story room
  - If yes → show a `showModalActionPopup` or `showModalBottomSheet` with:
    - "View Stories" → navigates to `/rooms/story/${room.id}` (existing behavior)
    - "Manage Stories" → navigates to `/rooms/${room.id}` (opens as normal ChatPage)
  - If not own story room → keep existing behavior (go directly to StoryViewer)

### Phase 3: Localization Strings

**File:** `lib/l10n/intl_en.arb`
- Add new strings:
  - `viewStories`: "View Stories"
  - `manageStories`: "Manage Stories"
  - Optional: `storyOptions`: "Story Options" (dialog title)

### No Changes Needed (Already Working)

| File | Reason |
|------|--------|
| `lib/pages/stories/story_viewer.dart` | `_rebuildEvents()` uses `filterByVisibleInGui()` which already excludes redacted events |
| `lib/utils/matrix_sdk_extensions/filtered_timeline_extension.dart` | `isVisibleInGui` already checks `hideRedactedEvents` setting |
| `lib/config/routes.dart` | Route `/rooms/:roomid` already exists and handles any room as ChatPage |

## Acceptance Criteria

- [ ] Tapping own Story Room shows a choice dialog with "View Stories" and "Manage Stories"
- [ ] "View Stories" opens the StoryViewer (same as current behavior)
- [ ] "Manage Stories" opens the Story Room as a normal chat room
- [ ] In the normal chat room view, user can delete (redact) story images using existing deletion flow
- [ ] Deleted/redacted images no longer appear in StoryViewer
- [ ] Tapping other people's Story Rooms still opens StoryViewer directly (no dialog)
- [ ] New UI strings are properly localized (at minimum English)
- [ ] All modified files maintain existing SPDX headers and copyright notices

## Technical Notes

### Key Code References

| File | Location | Purpose |
|------|----------|---------|
| `lib/pages/chat_list/chat_list.dart` | L113-156 | `onChatTap()` — main entry point for room click handling |
| `lib/utils/own_story_config.dart` | L1-74 | `getOwnStoryRoomId()`, `getOwnStoryRoom()` — own story room identification |
| `lib/utils/story_room_extension.dart` | L1-36 | `isStory` check via displayname prefix `story:` |
| `lib/pages/stories/story_viewer.dart` | L172-202 | `_rebuildEvents()` — filters events for story display |
| `lib/utils/matrix_sdk_extensions/filtered_timeline_extension.dart` | L25-39 | `isVisibleInGui` — filters out redacted events |

### Technical Considerations

1. **Async detection:** `getOwnStoryRoomId()` reads from Matrix account data (async). Consider caching the own story room ID on login/sync to avoid async lookups on every tap.
2. **hideRedactedEvents setting:** Verify this is `true` by default, or force it in the story context. If `false`, redacted events might still appear as placeholders in the StoryViewer (though the message type filter in `_rebuildEvents` would likely exclude them anyway since redacted events lose their original type).
3. **Story identification:** Stories are identified by displayname prefix `story:` (not Matrix room type). The own story room is additionally tracked via account data key `ffchat.story`.
4. **Route reuse:** Opening as normal chat simply uses the existing `/rooms/:roomid` route — the ChatPage already handles any room type.

## Labels

enhancement, stories, UX

---
*Generated automatically by neo-creator*

