# Feature: Auto-update room avatar to latest image in family.stories rooms

**Type:** enhancement

## Description

This enhancement aims to improve the visual experience of "Stories" rooms by automatically updating the room's profile picture (avatar) to the most recently posted image. In rooms specifically designated as story rooms (using the custom room type `family.stories`), every time a user posts a new image, the room's avatar should be updated to reflect this latest content.

This ensures that the "Stories Bar" and the chat list always provide a fresh preview of the latest activity without requiring manual intervention from the users. The implementation should leverage the existing Matrix state event mechanism for room avatars.

## Current Behavior

Currently, the codebase identifies story rooms using a display name prefix-based detection (`story:` prefix), and there is no mechanism to automatically synchronize the room's avatar with its content.
- File: `lib/utils/story_room_extension.dart` (line 14-23)
- Detection is based on the string prefix rather than the official Matrix room type.
- No automatic update of the `m.room.avatar` state event exists.

## Expected Behavior

- Story rooms should be primarily identified by the custom room type `family.stories` in the `m.room.create` state event.
- When a new image message is received in a `family.stories` room, the room's avatar (`m.room.avatar`) should automatically be updated to the MXC URI of the new image.
- The room list and stories bar should reflect this updated avatar immediately.
- Compatibility with the legacy `story:` prefix should be maintained for a transition period.

## Motivation

The goal of the Stories feature is to provide a quick, visual overview of family updates. By showing the latest posted image as the room's avatar, users can see what's new at a glance in the chat list or the stories bar, significantly improving the UX and engagement.

## Codebase Analysis

### Affected Files
| File | Component | Relevance |
|------|-----------|-----------|
| `lib/utils/story_room_extension.dart` | StoryRoomExtension | Needs update for `family.stories` type detection. |
| `lib/pages/chat_list/chat_list_body.dart` | Chat List | Entry point for sync events and room list updates (line 70-77). |
| `lib/pages/stories/story_viewer.dart` | Story Viewer | Handles timeline loading and image filtering (line 68-118). |
| `lib/pages/new_group/new_group.dart` | Room Creation | Needs update to set the `family.stories` type on creation. |
| `lib/pages/chat_list/chat_list_item.dart` | UI Component | Renders the room avatar in the list (line 130-141). |

### Current Implementation
The `StoryRoomExtension` currently checks the localized display name for the `story:` prefix. The `ChatListBody` listens to `client.onSync` for updates but does not trigger any metadata changes based on message content.

### Dependencies
- Matrix SDK: Utilizes `room.setAvatar(file)` and `room.avatar` getter.
- `m.room.create`: Stores the immutable room type.
- `m.room.avatar`: State event to be updated.

## Upstream Status

- Related upstream issue: None found (FluffyChat does not have a native "Stories" feature of this kind).

## Suggested Implementation Plan

1. **Update Detection Logic**: Modify `lib/utils/story_room_extension.dart` to check for `family.stories` in the `m.room.create` state event content while maintaining the prefix check as a fallback.
2. **Implement Auto-Avatar Service**: 
    - Hook into the `client.onSync` stream in a global service or within the room controller.
    - Check if the room `isStory`.
    - If a new `m.room.message` with `msgtype: m.image` is detected, retrieve its MXC URI.
3. **Update Room Avatar**:
    - Verify if the current user has the required power level to send `m.room.avatar` state events.
    - If authorized, update the room avatar using the MXC URI of the image. Reuse the URI directly to avoid re-uploading.
4. **Refine Room Creation**: Update `lib/pages/new_group/new_group.dart` to include `creation_content: {'type': 'family.stories'}` when creating a story room.
5. **Verify UI Consistency**: Ensure `lib/widgets/avatar.dart` and `lib/pages/stories/stories_bar.dart` correctly pick up the state change.

## Acceptance Criteria

- [ ] `family.stories` room type is correctly identified.
- [ ] Room avatar updates automatically upon receiving a new image message in story rooms.
- [ ] Users with insufficient power levels do not cause errors (fail silently or log).
- [ ] Legacy `story:` prefix rooms still function (fallback).
- [ ] Room creation sets the correct custom type.
- [ ] AGPL headers updated on all modified files.
- [ ] CHANGELOG.md updated with [FORK] entry.

## Technical Notes

- **MXC URI Reuse**: It is critical to use the existing MXC URI from the message content to avoid unnecessary data usage and server load.
- **State Event Throttling**: If multiple images are posted rapidly, consider a small debounce or ensure the SDK handles concurrent state updates gracefully.

## Research References

- Matrix Spec Room Types: https://spec.matrix.org/v1.17/client-server-api/#types
- m.room.create Event: https://spec.matrix.org/v1.17/client-server-api/#mroom.create
- Matrix Dart SDK: `client.onSync` usage patterns.

---
*Generated by new-issue-agpl*
