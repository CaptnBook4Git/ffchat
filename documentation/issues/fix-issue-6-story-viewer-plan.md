# Implementation Plan: Issue #6 - Story viewer: autoplay, tap navigation, hold-to-pause, and auto-advance

## Problem
The current `StoryViewer` in FluffyChat is very basic:
- It only shows images, no videos.
- It uses a vertical `PageView` without any autoplay or progress indicators.
- Users must manually scroll to see the next story.
- There's no gesture support for pausing or navigating through taps.
- It's limited to one room; it doesn't automatically move to the next story room.

## Solution
Enhance the `StoryViewer` with a modern "Stories" experience:
1.  **Autoplay & Progress**: Use an `AnimationController` to handle automatic advancement and drive a segmented progress bar.
2.  **Gestures**: Implement `GestureDetector` for tap-to-navigate (left 33%/right 67%) and long-press-to-pause.
3.  **Media Support**: Include videos in the story timeline and use their duration for playback.
4.  **Auto-Advance**: When a story room's moments are finished, automatically navigate to the next story room in the queue.

## Changes

### 1. `lib/pages/stories/story_viewer.dart`
- Update `_StoryViewerState` to use `SingleTickerProviderStateMixin`.
- Implement `AnimationController` for progress tracking.
- Enhance event filtering to include `MessageTypes.Video`.
- Add `StoryMoment` helper class to manage event and duration.
- Replace vertical `PageView` with a horizontal one (or managed view).
- Implement segmented progress bar UI.
- Add `GestureDetector` for navigation and pausing.
- Implement logic to transition between moments and rooms.

### 2. `lib/config/routes.dart`
- Ensure the `/rooms/story/:roomid` route can handle room transitions efficiently.

### 3. `lib/pages/chat_list/chat_list.dart`
- Verify `storyRooms` getter provides correctly sorted rooms for auto-advance.

## AGPL Compliance Checklist

| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `lib/pages/stories/story_viewer.dart` | ✅ | n/a (New) | © 2026 Simon | Update entry |
| `lib/config/routes.dart` | ✅ | © 2021-2026 Krille Fear | © 2026 Simon | Add entry |
| `lib/pages/chat_list/chat_list.dart` | ✅ | © 2021-2026 FluffyChat Contributors | © 2026 Simon | Add entry |

## Testing
1.  Open Story Viewer.
2.  Verify images stay for 5 seconds and advance automatically.
3.  Verify videos play for their full duration (if duration metadata exists).
4.  Verify tap on left/right edges navigates back/forward.
5.  Verify long press pauses the timer and progress bar.
6.  Verify that reaching the end of one story room triggers navigation to the next story room.
7.  Verify the progress bar segments match the number of story items.

## Edge Cases
- Videos with missing duration metadata (use fallback).
- Only one story room available (should close viewer at end).
- Rapid tapping through moments.
- Network lag during media loading (pause timer while loading).
