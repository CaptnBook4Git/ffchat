# Feature: Story Reactions - Allow emoji reactions and reply messages on story content sent to DM chat

**Type:** enhancement

## Description

This feature enhances the Story Viewer by allowing users to interact with stories through emoji reactions and direct message replies. Currently, the "Family and Friends" stories feature is limited to viewing content. By adding reactions and replies, we enable social engagement similar to major social media platforms, but within the secure Matrix ecosystem.

Reactions will be implemented as native Matrix reactions (`m.reaction`) on the story event itself, making them visible to all viewers of the story within the story room. Replies, however, will be treated as private interactions. When a user replies to a story with text, the app will send that message to a private Direct Message (DM) chat between the viewer and the creator, providing context by linking back to the story event.

## Current Behavior

- Users can view story rooms (identified by custom logic/prefixes).
- The story viewer in `lib/pages/stories/story_viewer.dart` shows the media content (images/videos) with a progress bar.
- There is no interactive UI for reacting or replying.
- No connection exists between the story viewer and private DM rooms for the purpose of story replies.

## Expected Behavior

1.  **Emoji Reactions**:
    - A reaction button (e.g., a smiley face icon) is visible on the story viewer UI.
    - Tapping it opens an emoji picker or a quick-select bar.
    - Selecting an emoji sends a native `m.reaction` event to the story room, targeting the specific media event being viewed.
    - The UI displays current reaction counts/emojis on the story content.

2.  **Message Replies**:
    - A text input field is present at the bottom of the story viewer.
    - When a user sends a message, it is NOT sent to the story room.
    - Instead, the app identifies or creates a private DM room with the story's creator.
    - The message is sent to that DM room.
    - The message should include a `matrix.to` link or a rich context reference to the story event so the creator knows which story is being discussed.

## Motivation

Engagement is a core part of the "Family and Friends" experience. Allowing users to quickly react with emojis or start a conversation based on a story makes the app more personal and interactive. Using native Matrix reactions ensures compatibility and standard behavior within the protocol.

## Codebase Analysis

### Affected Files

| File | Component | Relevance |
|------|-----------|-----------|
| `lib/pages/stories/story_viewer.dart` | `StoryViewer` | Primary UI where interaction buttons and input fields must be added. |
| `lib/pages/chat/events/message_reactions.dart` | `MessageReactions` | Reference for how reactions are displayed in FluffyChat. |
| `assets/l10n/intl_en.arb` | Localization | New strings for tooltips and placeholders. |

### Current Implementation

The `StoryViewer` in `lib/pages/stories/story_viewer.dart` uses a `Stack` (L322-479) to display the `PageView.builder` and a top-aligned overlay for progress bars and the close button. The state management handles the timeline of the story room and tracks the current "moment" (event).

### Dependencies

- **Matrix SDK**: Used for `room.sendReaction` and `client.startDirectChat`.
- **Localization**: Requires new keys in `L10n`.
- **DM Management**: Relies on the client's ability to resolve or create DM rooms with story creators.

## Upstream Status

- Related upstream issue: None (This is a feature specific to the Family and Friends fork).
- Upstream PR: None.

## Suggested Implementation Plan

1.  **Preparation**:
    - Add localized strings for "Reply to story...", "Send reaction", etc., in `assets/l10n/intl_en.arb`.
2.  **State Management**:
    - In `_StoryViewerState` (`lib/pages/stories/story_viewer.dart`), add a `TextEditingController` for the reply input.
    - Add a `FocusNode` to pause/resume story playback when the keyboard is active.
3.  **Reaction Logic**:
    - Implement a `_sendReaction(String emoji)` method.
    - It should use `_room.sendReaction(_moments[_momentIndex].event.eventId, emoji)`.
4.  **Reply Logic**:
    - Implement a `_sendReply(String text)` method.
    - Retrieve the creator ID from the current event: `_moments[_momentIndex].event.senderId`.
    - Use `Matrix.of(context).client.startDirectChat(senderId)` to get/create the DM room.
    - Construct the message body, including the `matrix.to` link for context.
    - Send the message to the DM room and clear the input.
5.  **UI Updates**:
    - Add a `Positioned` widget at the bottom of the `Stack` in `build` (`lib/pages/stories/story_viewer.dart`).
    - Include an `IconButton` for reactions and a `TextField` for replies.
    - Ensure the UI handles keyboard visibility (pausing the `_progressController` when typing).

## Acceptance Criteria

- [ ] Users can open an emoji picker from the Story Viewer.
- [ ] Selected emojis are sent as `m.reaction` to the story room.
- [ ] Users can type and send a text reply from the Story Viewer.
- [ ] Text replies appear in the private DM chat with the story creator.
- [ ] The reply message in the DM contains a link to the original story.
- [ ] Story playback pauses when the reply text field is focused.
- [ ] AGPL headers updated on all modified files.
- [ ] CHANGELOG.md updated with [FORK] entry.

## Technical Notes

- **Playback Interaction**: The `AnimationController` (`_progressController`) must be paused while the user is typing a reply to prevent the story from advancing mid-sentence.
- **Matrix.to Links**: Ensure the links use the appropriate format: `https://matrix.to/#/room_id/event_id`.
- **UI Contrast**: Since stories can be bright or dark, ensure the reaction/reply UI has appropriate contrast (e.g., semi-transparent dark background).

## Research References

- Matrix Spec on Reactions: https://spec.matrix.org/v1.12/client-server-api/#historical-handling-of-reactions
- FluffyChat Room Extensions: `lib/utils/story_room_extension.dart`

---
*Generated by new-issue-agpl*
