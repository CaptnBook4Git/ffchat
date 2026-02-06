# [FORK] Add visual ring indicator for unseen stories

**Type:** enhancement

## Description

The current implementation of the Stories bar in FF Chat displays a uniform gradient ring around all story avatars, regardless of whether there is new content available for the user. This lack of visual feedback makes it difficult for users to distinguish between rooms they have already caught up with and those containing new, unseen stories. This feature aims to improve the user experience by introducing a dynamic visual indicator that signals unread content.

By implementing a conditional styling mechanism, we can provide immediate visual feedback. Unseen stories will retain the vibrant, colored gradient ring that users expect from modern social messaging apps. Conversely, once a user has viewed all stories in a particular room, the ring will either disappear or transition to a muted grey color, clearly indicating that no new content is present.

This enhancement leverages existing read marker logic within the Matrix SDK. Since the app already sets a read marker when a story room is opened in the `StoryViewer`, we simply need to expose this state to the `StoriesBar` widget and update the decoration logic accordingly. This ensures consistency with other parts of the app, such as the chat list, where unread messages are already visually highlighted.

## Current Behavior

- Every story room in the stories bar displays the exact same gradient ring, providing no indication of whether the stories have been seen or not.
- File: `lib/pages/stories/stories_bar.dart` (lines 190-203)
- The decoration is currently hardcoded to use a `LinearGradient` with `theme.colorScheme.primary` and `theme.colorScheme.secondary`.

## Expected Behavior

- Rooms with unseen stories should display a vivid, colored gradient ring around the avatar.
- Rooms where all stories have been seen should display a muted grey ring or no ring at all.
- The "Add to Story" button should remain prominent with its current colored gradient.
- The visual state should update immediately after a user finishes viewing a story room.

## Motivation

Providing visual feedback for unread content is a standard UX pattern in modern communication apps (e.g., Instagram, WhatsApp). It helps users prioritize their attention and reduces the frustration of clicking into rooms only to find content they have already seen. This change aligns FF Chat with user expectations for a "Stories" feature.

## Codebase Analysis

### Affected Files
| File | Component | Relevance |
|------|-----------|-----------|
| `lib/pages/stories/stories_bar.dart` | StoriesBar | Main UI where the ring decoration is defined (lines 190-203). |
| `lib/pages/stories/story_viewer.dart` | StoryViewer | Logic for setting read markers (lines 129-135). |
| `lib/utils/story_room_extension.dart` | StoryRoomExtension | Potential location for a helper method `bool get hasUnseenStories`. |

### Current Implementation

The `StoriesBar` builds a list of story items. Inside the item builder, it creates a `Container` with a `BoxDecoration`:

```dart
// lib/pages/stories/stories_bar.dart:190
decoration: BoxDecoration(
  shape: BoxShape.circle,
  gradient: LinearGradient(
    colors: [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
    ],
  ),
),
```

This code does not currently check the unread status of the `room` object.

### Dependencies

- **Matrix SDK**: Relies on the `Room` object's `isUnread` and `hasNewMessages` properties to determine state.
- **Theme**: Uses the application's `ColorScheme` for colors.

## Upstream Status

- Related upstream issue: None found. This is a fork-specific UX enhancement for FF Chat.

## Suggested Implementation Plan

1. **State Detection**: Update the story item builder in `lib/pages/stories/stories_bar.dart` to determine if a room has unseen stories. This can be done using `room.hasNewMessages` or `room.isUnread`.
2. **Conditional Decoration**: Modify the `BoxDecoration` in `lib/pages/stories/stories_bar.dart:190-203` to use a different gradient or a solid grey color if the stories are already seen.
3. **Helper Extension (Optional)**: Add a getter `hasUnseenStories` to `lib/utils/story_room_extension.dart` to encapsulate the logic for checking unread stories.
4. **Sorting (Optional)**: Consider sorting rooms with unseen stories to the beginning of the list in `lib/pages/chat_list/chat_list.dart:179-187` or wherever the story rooms are filtered.

## Acceptance Criteria

- [ ] Unseen stories show a vibrant gradient ring.
- [ ] Seen stories show a muted grey ring or no ring.
- [ ] "Add to Story" button keeps its original colorful gradient.
- [ ] AGPL headers updated on all modified files (SPDX-License-Identifier, original copyright preserved, fork copyright 2026 Simon, MODIFICATIONS log).
- [ ] `CHANGELOG.md` updated with `[FORK]` entry.

## Technical Notes

- Ensure that the "own" story room also reflects this state (it should likely show a muted ring once the user has viewed their own stories).
- Check performance when calculating the unread state for many story rooms at once; use cached SDK properties if possible.
- The gradient transition should look smooth and consistent with the app's overall design language.

## Research References

- [Librarian Research Report: Visual Indicator for New/Unseen Stories]
- Instagram/WhatsApp UX patterns for stories.

---
*Generated by new-issue-agpl*
