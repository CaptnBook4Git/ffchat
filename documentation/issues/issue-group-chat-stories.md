# [FORK] Feature: Enable Stories within Group Chatrooms (Group Stories)

**Type:** enhancement

## Description

The objective of this feature is to extend the existing "Stories" functionality in FF Chat to support group-scoped stories. Currently, stories are primarily used as a personal status feature (similar to Instagram or WhatsApp Status), where each user has their own dedicated story room. However, there is a strong use case for enabling stories directly within specific group chats, allowing all members of that group to contribute stories that are only visible to other members of that same room.

When enabled for a group room, any member (subject to power levels) will be able to post content as a story instead of a regular message. These "Group Stories" will not be aggregated in the global stories bar but will instead appear in a dedicated UI element at the top of the specific chatroom they were posted in. This provides a way to share ephemeral content that is contextually relevant to the group without cluttering the main chat timeline.

This feature requires a new custom Matrix event type to distinguish story posts from regular messages, as well as a state event to toggle the feature on or off for any given room. The visibility of these stories should be restricted to the room members, ensuring privacy and scoped interaction.

Finally, the UI must be updated to include a stories bar within the chat view itself, and the chat input must allow users to choose whether they are sending a regular message or a story post.

## Current Behavior

Currently, FF Chat implements personal stories using a custom room detection logic.
- Story rooms are identified by a display name prefix `story:` in `lib/utils/story_room_extension.dart` (L14–L35).
- Each user typically has one personal story room tracked in account data as `ffchat.story` (see `lib/utils/own_story_config.dart`, L10–L72).
- Stories are displayed in a global `StoriesBar` (`lib/pages/stories/stories_bar.dart`, L26–L241) and viewed through a full-screen `StoryViewer` (`lib/pages/stories/story_viewer.dart`, L29–L637).
- Story messages are currently filtered out of regular chat timelines using a timeline extension (`lib/utils/matrix_sdk_extensions/filtered_timeline_extension.dart`, L5–L58).

## Expected Behavior

- **Room-level Toggle**: Room administrators can enable or disable the "Stories" feature for any group room via a new state event `ffchat.group_stories`.
- **Collaborative Posting**: If enabled, all members of the group can post story messages using a custom event type `ffchat.story_post`.
- **In-Room Visibility**: Group stories are displayed in a `GroupStoriesBar` at the top of the chat view (specifically in `lib/pages/chat/chat.dart`). These stories are NOT shown in the global stories list unless explicitly configured otherwise in the future.
- **Timeline Separation**: Story posts must be hidden from the regular chat message list to avoid clutter, utilizing and extending the existing `filtered_timeline_extension.dart`.
- **User Interface**: A dedicated button or option in `lib/pages/chat/chat_input_row.dart` and `lib/pages/chat/send_file_dialog.dart` will allow users to "Post as Story".

## Motivation

Enabling stories within group chats allows for a more dynamic and ephemeral way of sharing content within specific social circles or project groups. It prevents the main chat history from being filled with temporary reactions or status updates while still allowing members to share "moments" that expire after 24 hours. This aligns with modern messaging trends and enhances the "FF Chat" fork's unique feature set.

## Codebase Analysis

### Affected Files
| File | Component | Relevance |
|------|-----------|-----------|
| `lib/utils/story_room_extension.dart` | Room Extension | Update logic to handle group rooms with stories enabled. |
| `lib/pages/stories/stories_bar.dart` | StoriesBar Widget | Potential base for the new `GroupStoriesBar`. |
| `lib/pages/stories/story_viewer.dart` | Story Viewer | Needs to handle viewing stories from a specific room context. |
| `lib/pages/chat/chat.dart` | Chat View | Integration of the `GroupStoriesBar` at the top of the timeline. |
| `lib/pages/chat/chat_input_row.dart` | Chat Input | Add "Post as Story" trigger. |
| `lib/pages/chat_details/chat_details_view.dart` | Room Settings | Add toggle for "Enable Group Stories". |
| `lib/utils/matrix_sdk_extensions/filtered_timeline_extension.dart` | Timeline Filter | Exclude `ffchat.story_post` from the main message list. |

### Current Implementation
The current story logic is heavily centered around the `story:` room prefix. In `lib/utils/story_room_extension.dart`:
```dart
extension StoryRoomExtension on Room {
  bool get isStoryRoom => displayname.startsWith('story:');
  // ...
}
```
This needs to be broadened or supplemented with a check for the `ffchat.group_stories` state event.

### Dependencies
- **Matrix SDK**: Requires sending custom state events and message types.
- **Localization**: New strings required for settings and UI labels in `lib/l10n/intl_en.arb`.

## Upstream Status

- **MSC3588 (Stories As Rooms)**: This MSC exists but is closed and primarily covers personal stories.
- No existing MSC or upstream FluffyChat feature covers group-scoped stories. This is a fork-specific enhancement for FF Chat.

## Suggested Implementation Plan

1. **Phase 1: Configuration**: Create `lib/utils/group_stories_config.dart` to define constants for the new state event `ffchat.group_stories` and message type `ffchat.story_post`.
2. **Phase 2: Timeline Filtering**: Update `lib/utils/matrix_sdk_extensions/filtered_timeline_extension.dart` (L5–L58) to ensure `ffchat.story_post` events are filtered out of the standard chat view.
3. **Phase 3: Settings UI**: Add a toggle in `lib/pages/chat_details/chat_details_view.dart` (around L119–L255) to allow admins to send the `ffchat.group_stories` state event.
4. **Phase 4: Story Posting**: Modify `lib/pages/chat/chat_input_row.dart` and `lib/pages/chat/send_file_dialog.dart` to include an option to send media as an `ffchat.story_post`.
5. **Phase 5: Room UI**: Implement a `GroupStoriesBar` (potentially refactored from `lib/pages/stories/stories_bar.dart`) and insert it into the `Chat` view in `lib/pages/chat/chat.dart`.
6. **Phase 6: Viewing**: Update `StoryViewer` logic to support navigating through stories belonging to a specific group room.

## Acceptance Criteria

- [ ] Users can enable/disable "Group Stories" in room settings.
- [ ] Users can post images/videos as stories within a group room.
- [ ] Story posts do not appear in the regular chat timeline.
- [ ] A stories bar is visible at the top of the chat when group stories are enabled.
- [ ] Stories are only visible to members of the specific room.
- [ ] Stories expire (or are hidden) after 24 hours (client-side logic).
- [ ] **AGPL headers updated on all modified files** (SPDX-License-Identifier, Fork Copyright 2026, Modification log).
- [ ] **CHANGELOG.md updated with [FORK] entry**.

## Technical Notes

- **Permissions**: Ensure that only users with sufficient power levels can enable the feature. Posting stories should follow standard message sending permissions.
- **Performance**: The `GroupStoriesBar` should efficiently filter room events to find recent story posts without slowing down the chat view.
- **Namespace**: Continue using the `ffchat.*` namespace for custom events to avoid collisions with future upstream features.

## Research References

- User Request: Enable stories within group chats where all members can post.
- Existing Story Implementation: Scoped to personal story rooms.

---
*Generated by new-issue-agpl*
