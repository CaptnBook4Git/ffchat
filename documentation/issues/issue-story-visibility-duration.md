# Feature: Story visibility duration with user-configurable defaults

**Type:** enhancement

## Description

This feature introduces a visibility duration for stories posted in FF Chat. Currently, stories persist indefinitely until manually removed, which contradicts the ephemeral nature of "stories" in modern messaging apps. 

With this enhancement, users will be prompted to select how long a story should remain visible when they post it. The system will provide sensible defaults (e.g., 24 hours) while allowing the user to choose a different duration up to a maximum of 7 days. 

To ensure a seamless user experience, a global default can be configured in the app settings. This setting will pre-select the duration in the posting dialog. Furthermore, a background service will be implemented to automatically redact stories once their expiration timestamp is reached.

## Current Behavior

Stories in FF Chat currently have no expiration mechanism. When a user posts an image to their story room, it remains there forever.
- File: `lib/pages/stories/stories_bar.dart` (line 41-86) handles the story posting trigger but does not include any duration metadata.
- File: `lib/pages/chat/send_file_dialog.dart` (line 72 in `stories_bar.dart`) is used to send the story files but lacks a duration selector.

## Expected Behavior

1. **Posting Prompt**: When posting a story via the `StoriesBar`, the user should be presented with a duration picker (or a dropdown in the `SendFileDialog`).
2. **Default Options**: Common durations like "1 hour", "12 hours", "24 hours" (default), "3 days", and "7 days" should be easily selectable.
3. **Maximum Limit**: The maximum allowed duration for a story is 7 days.
4. **Settings**: A new entry in "Chat Settings" allows users to define their preferred default duration for new stories.
5. **Auto-Redaction**: Stories that have passed their expiration date should be automatically redacted by the client.
6. **Viewer Feedback**: The `StoryViewer` should display the remaining time for the current story.

## Motivation

Stories are intended to be temporary updates. Indefinite persistence leads to cluttered story feeds and privacy concerns, as users might expect their stories to disappear after a day, similar to other platforms like Instagram or WhatsApp.

## Codebase Analysis

### Affected Files
| File | Component | Relevance |
|------|-----------|-----------|
| `lib/pages/chat/send_file_dialog.dart` | UI | Add duration picker for stories |
| `lib/pages/stories/stories_bar.dart` | UI | Pass story context and trigger the enhanced dialog |
| `lib/config/setting_keys.dart` | Config | Add `defaultStoryDuration` setting key |
| `lib/pages/settings_chat/settings_chat_view.dart` | UI | Add story duration settings UI |
| `lib/pages/stories/story_viewer.dart` | UI | Display remaining time for the story |
| `lib/utils/story_expiry_service.dart` | Service | **NEW**: Background service to handle redaction of expired events |

### Current Implementation
The current story posting flow in `lib/pages/stories/stories_bar.dart` (line 63-79) selects files and then opens the `SendFileDialog`. It does not pass any information about expiration. The `Matrix` SDK is used for sending, but since MSC2228 (Self-Destructing Events) is not yet part of the standard Matrix protocol in a widely supported way, we must use custom metadata in the event content (`chat.fluffy.story_expiry_ts`).

### Dependencies
- `matrix`: The underlying SDK for sending events and redactions.
- `shared_preferences` (via `AppConfig`): For storing the user's default duration preference.

## Upstream Status

- **Related upstream issue**: None found in `krille-chan/fluffychat`.
- **Upstream PR**: None.
- **Note**: This is a custom feature for the FF Chat fork. We are using client-side redaction because the Matrix protocol does not yet natively support server-side self-destructing events (MSC2228 is still in progress).

## Suggested Implementation Plan

1. **Phase 1: Configuration**: Add a new setting key in `lib/config/setting_keys.dart` and implement the UI in `lib/pages/settings_chat/settings_chat_view.dart` to allow users to set their default story duration.
2. **Phase 2: Metadata Support**: Modify `SendFileDialog` to include a duration picker when the target room is a story room. Add the calculated expiration timestamp to the event content under the key `chat.fluffy.story_expiry_ts`.
3. **Phase 3: Expiry Service**: Create `lib/utils/story_expiry_service.dart`. This service should scan story rooms for events with expiration metadata and trigger a redaction if the current time exceeds the expiration time.
4. **Phase 4: UI Enhancements**: Update `lib/pages/stories/story_viewer.dart` to read the `chat.fluffy.story_expiry_ts` metadata and show a countdown or "Time remaining" label.

## Acceptance Criteria

- [ ] Users are prompted for a duration when posting a story.
- [ ] Default duration can be customized in settings.
- [ ] Stories are automatically redacted after the selected duration (while the client is running).
- [ ] Story viewer shows the remaining time for each story.
- [ ] Max duration is strictly enforced at 7 days.
- [ ] **AGPL headers updated on all modified files.**
- [ ] **SPDX-License-Identifier: AGPL-3.0-or-later included.**
- [ ] **Original copyrights preserved, fork copyright (2026 Simon) added to modified files.**
- [ ] **CHANGELOG.md updated with [FORK] entry.**

## Technical Notes

- Since redaction depends on the client, it will only occur when the user who posted the story (or a room admin) is online with a client that implements this feature.
- The expiration timestamp should be stored as milliseconds since epoch for easy comparison.
- Consider edge cases where the system clock might be inaccurate.

## Research References

- Matrix MSC2228: Self-destructing events (Reference for why we use a custom implementation).
- FluffyChat Story Implementation: `lib/utils/story_room_extension.dart`.

---
*Generated by new-issue-agpl*
