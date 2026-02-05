# Implement Stories rooms using "story:" prefix

**Type:** feature

## Description

Add a Stories experience in the FluffyChat fork: any room whose display name starts with "story:" should be treated as a Story and opened with the StoryViewerScreen (prototype in ff_chat/lib/screens/story_viewer_screen.dart). Story rooms should be detected in the chat list, surfaced in a Stories section, and not behave like normal chats. The viewer should read the room timeline, show image events in chronological order, support encrypted attachments, and mark the story as read when opened. Provide routing/navigation so tapping a story opens the full-screen viewer. Ensure rooms without the prefix continue to behave as standard chats.

## Motivation

FluffyChat currently treats all rooms as standard chats. Introducing story-like rooms enables a familiar ephemeral-media experience (à la Instagram/WhatsApp) while leveraging Matrix rooms. A dedicated Stories UI improves discoverability and avoids cluttering the main chat list with story rooms.

## Implementation Plan

1. Add a helper (e.g., in a new utility file) to detect story rooms based on display name prefix "story:" (case-insensitive) and normalized display name for presentation.
2. Update chat list filtering to surface a Stories section (e.g., above regular rooms) and ensure story rooms are excluded from standard chat list entries.
3. Add navigation route to open StoryViewerScreen for a given room (in lib/config/routes.dart).
4. Wire chat list item taps for story rooms to navigate to StoryViewerScreen instead of the normal chat view.
5. Integrate StoryViewerScreen from the prototype (ff_chat/lib/screens/story_viewer_screen.dart) into the FluffyChat fork under lib/screens/ or appropriate UI module, adapting dependencies and localization as needed.
6. Ensure StoryViewerScreen loads timeline images (including encrypted attachments), sorts chronologically, and marks room as read on open.
7. Add empty-state handling for story rooms without images and errors for failed loads.

## Acceptance Criteria

- [ ] Rooms with display name prefix "story:" are detected as story rooms (case-insensitive).
- [ ] Story rooms appear in a dedicated Stories section in the chat list UI and are not duplicated in the normal room list.
- [ ] Tapping a story room opens the StoryViewerScreen full-screen and does not open the standard chat view.
- [ ] StoryViewerScreen displays image events from the room timeline in chronological order and supports encrypted attachments.
- [ ] Opening a story marks the room as read (read marker set).
- [ ] Rooms without the prefix behave exactly as standard chats.
- [ ] Empty or error states are shown when no images are available or loading fails.

## Labels

feature, priority:low, stories, rooms, prefix

---
*Generated automatically by neo-creator*

