# [FEATURE] Telegram-like dissolve/dust animation for message deletion

**Type:** enhancement / feature

## Description

This feature aims to implement a visually appealing "dissolve" or "dust" animation when a message is deleted (redacted) in FF Chat, similar to the effect seen in Telegram. Instead of the message bubble simply disappearing or being instantly replaced by a placeholder, it should appear to crumble into pixels or dust particles before finally being removed from the view.

The animation provides immediate visual feedback for the deletion action and enhances the overall user experience by adding a sense of weight and physical presence to the message bubbles. This effect should be smooth, performant, and consistent across different message types (text, images, etc.).

## Current Behavior

Currently, when a user selects a message and taps the delete icon:
1. The `redactEventsAction()` in `lib/pages/chat/chat.dart` (line 859) is triggered.
2. The Matrix SDK is called to redact the event.
3. The timeline updates, and the event's `.redacted` property becomes `true`.
4. The `ChatEventList` in `lib/pages/chat/chat_event_list.dart` (line 17) refreshes, and the `isVisibleInGui` getter in `lib/utils/matrix_sdk_extensions/filtered_timeline_extension.dart` (line 25) determines if the event should still be shown.
5. The message either vanishes instantly or is immediately replaced by a placeholder widget in `lib/pages/chat/events/message_content.dart` (line 29). There is no transition or animation.

## Expected Behavior

When a message is redacted (either by the local user or an incoming redaction from another user):
1. The message bubble should trigger a "dissolve" animation.
2. The animation should last approximately 500-800ms.
3. During the animation, the message should disintegrate into dust-like particles.
4. Once the animation completes, the message should either disappear or be replaced by the standard "Message deleted" placeholder.
5. The animation must be performant on mobile devices, ideally utilizing GPU-accelerated shaders.

## Motivation

Standard message deletion in many chat apps feels abrupt. Adding a high-quality animation like the "Thanos snap" effect makes the app feel more polished and premium. It also provides better visual cues to the user that an action has successfully taken place.

## Codebase Analysis

### Affected Files
| File | Component | Relevance |
|------|-----------|-----------|
| `lib/pages/chat/chat.dart` | ChatController | Logic to delay redaction state update until animation finishes. |
| `lib/pages/chat/chat_event_list.dart` | ChatEventList | Entry point for wrapping messages with the animation component. |
| `lib/pages/chat/events/message.dart` | Message Widget | The container widget for message bubbles that needs the animation wrap. |
| `lib/pages/chat/events/message_content.dart` | MessageContent | Handling the visual state transition between active and redacted. |
| `lib/utils/matrix_sdk_extensions/filtered_timeline_extension.dart` | isVisibleInGui | Logic to ensure redacted events remain visible long enough for the animation to play. |

### Current Implementation

The current deletion flow is handled in `lib/pages/chat/chat.dart` at line 859:
```dart
void redactEventsAction() async {
  // ... current implementation calls event.redactEvent()
}
```
The UI rendering is managed in `lib/pages/chat/chat_event_list.dart` (line 95), where `isVisibleInGui` is used to filter events.

### Dependencies
- Needs a package for the particle effect, such as `thanos_snap_effect`.
- Requires Flutter shader support (GLSL) to be enabled/configured.

## Upstream Status

- Related upstream issue: None found
- Upstream PR: None

## Suggested Implementation Plan

1. **Add Dependency:** Add `thanos_snap_effect` (or equivalent) to `pubspec.yaml` and register necessary shaders.
2. **State Management:** Update `ChatController` in `lib/pages/chat/chat.dart` (line 859) to maintain a set of event IDs currently undergoing dissolution.
3. **Wrap Message Widget:** In `lib/pages/chat/chat_event_list.dart` (line 17) or `lib/pages/chat/events/message.dart` (line 27), wrap the message bubble with the `Snappable` or dissolution component.
4. **Trigger Animation:** Intercept the redaction event. Instead of immediately hiding the event, trigger the animation first.
5. **Timeline Update:** Modify `isVisibleInGui` in `lib/utils/matrix_sdk_extensions/filtered_timeline_extension.dart` (line 25) to allow redacted events to remain visible if they are in the "dissolving" set.
6. **Completion:** Once the animation (500-800ms) ends, remove the event ID from the "dissolving" set and allow the UI to update to the final redacted state.

## Acceptance Criteria

- [ ] Message bubbles dissolve into particles upon deletion.
- [ ] Animation is smooth (60fps) on mid-range mobile devices.
- [ ] Works for both local redactions and redactions received from other users.
- [ ] Placeholder "Message deleted" appears correctly after the animation.
- [ ] AGPL headers updated on all modified files (SPDX-License-Identifier: AGPL-3.0-or-later).
- [ ] A `MODIFICATIONS` entry with the current date (2026-02-06) is added to the header of all changed files.
- [ ] `CHANGELOG.md` updated with `[FORK]` entry for the dissolve animation.

## Technical Notes

- Shader-based animations are significantly more performant than CPU-based particle systems.
- Need to handle edge cases like rapid multiple deletions or room switching during an active animation.
- Ensure the animation gracefully degrades if shaders are not supported on the target device.

## Research References

- [Thanos Snap Effect for Flutter](https://pub.dev/packages/thanos_snap_effect)

---
*Generated by new-issue-agpl*
