# Story viewer: autoplay, tap navigation, hold-to-pause, and auto-advance across story rooms

**Type:** enhancement

## Description

The fork already includes a basic Stories foundation:

- Story rooms are detected via a display name prefix (`story:`) (`lib/utils/story_room_extension.dart`).
- The chat list surfaces them as a horizontal Stories bar (`lib/pages/stories/stories_bar.dart`, wired in `lib/pages/chat_list/chat_list_body.dart`).
- Story rooms open a dedicated full-screen viewer route (`/rooms/story/:roomid`) (`lib/config/routes.dart`) which currently shows timeline images (`lib/pages/stories/story_viewer.dart`).

What is still missing is the core “WhatsApp/Instagram style” playback experience when viewing stories:

- Stories should **auto-progress** (images for a few seconds; videos for the full video duration).
- Users should be able to **pause** playback with **tap-and-hold**.
- Users should be able to **tap** to navigate:
  - tap **right side** → next story moment
  - tap **left side** → previous story moment
- When all story moments from one user/story room are finished, the viewer should automatically show the **next story room**.
- If no more story rooms exist, the viewer should **close**.

This issue focuses on the viewer/playback UX only (not on creating/posting stories).

## Current Behavior

The current `StoryViewer`:

- Only shows **images** (`MessageTypes.Image`) from the room timeline (filters in `lib/pages/stories/story_viewer.dart`, around lines 110-113).
- Uses a **vertical** `PageView.builder` (around lines 170-195) without any progress indicator.
- Has **no timer/autoplay**, no “tap left/right” navigation, and no “hold to pause”.
- Is scoped to a **single room** (`StoryViewer(roomId: ...)`) and does not auto-advance to other story rooms.

Story rooms are currently sorted in the chat list controller via `latestEventReceivedTime` (`lib/pages/chat_list/chat_list.dart`, `storyRooms` getter around lines 175-183), but the viewer does not consume this ordering.

## Expected Behavior

Inside the story viewer:

1. **Autoplay**
   - Image moments: show for a fixed duration (e.g. 5 seconds).
   - Video moments: show for the full video duration.
     - Prefer extracting duration from the event info map (`content.info.duration` in ms) (see existing parsing in `lib/pages/chat/events/video_player.dart`, around lines 53-56).
     - Fallback behavior when duration is missing must be defined (e.g. 10 seconds, or play until completion if video player reports duration).

2. **Gestures**
   - Tap-and-hold: pause the current moment’s progress.
   - Release: resume.
   - Tap right side: go to next moment.
   - Tap left side: go to previous moment.
   - The tap split should match common story UX (e.g. left 33% / right 67%) and be configurable if needed.

3. **Progress indicator**
   - Show segmented progress at the top (one segment per moment) reflecting completion/progress.
   - Hide or fade the progress segments while holding (optional, but matches common behavior).

4. **Auto-advance across story rooms**
   - When the last moment in the current story room completes, automatically open the next story room (using the same ordering as the Stories list).
   - When there is no next story room, close the viewer.
   - If a story room has no playable moments, it should be skipped automatically (or show an empty state and allow manual navigation).

## Motivation

Without autoplay and gesture navigation, Stories feel like a static image gallery rather than a story experience. The core value of Stories is fast, hands-on consumption with predictable controls and seamless transitions across users.

Adding this behavior will:

- Bring the viewer in line with user expectations from modern messaging apps.
- Reduce friction for consuming multiple stories.
- Provide the foundation for later additions (e.g., 24h expiry, reactions/replies, viewer list).

## Codebase Analysis

### Affected Files

| File | Component | Relevance |
|------|-----------|-----------|
| `lib/pages/stories/story_viewer.dart` | `StoryViewer` | Must implement autoplay + gestures + multi-room sequencing; currently images-only vertical PageView |
| `lib/config/routes.dart` | `/rooms/story/:roomid` route | Navigation entry point; may need extra params/state for sequencing |
| `lib/pages/chat_list/chat_list.dart` | `storyRooms` ordering | Provides ordering for “next story room” behavior |
| `lib/utils/story_room_extension.dart` | `Room.isStory` detection | Defines which rooms are story rooms |
| `lib/pages/chat/events/video_player.dart` | video duration parsing | Reference for extracting video duration from Matrix events |

### Current Implementation

- `StoryViewer` loads timeline history (`requestHistory(historyCount: 100)`), filters visible GUI events, keeps only image messages, sorts chronologically, and displays them with `MxcImage`.
- `ChatListController.onChatTap` routes story rooms to `/rooms/story/<roomId>`.

### Dependencies / Considerations

- Timeline updates: `StoryViewer` already subscribes to `onUpdate`; autoplay logic must remain stable as events update.
- Encrypted media: Images are displayed using `MxcImage` which handles decryption/download; video playback must also handle encrypted attachments consistently.
- Lifecycle: playback must pause when the route is not visible (background/app switch) and resume when visible.

## Upstream Status

- Related upstream issue: None found for story viewer autoplay/gesture behavior.
- Fork status: There is an existing fork issue about posting to an “own story channel” (#3). This issue is strictly about the viewer/playback experience.

## Implementation Plan

1. **Model “moments” from timeline events** (`lib/pages/stories/story_viewer.dart`)
   - Extend event selection to include both `MessageTypes.Image` and `MessageTypes.Video` (and optionally GIF if represented as image).
   - Sort chronologically and build a list of “moments” with:
     - event reference
     - computed duration (`Duration`) (fixed for images; derived for videos)

2. **Implement autoplay + segmented progress** (`lib/pages/stories/story_viewer.dart`)
   - Use an `AnimationController` as the progress driver for the current moment.
   - When controller completes: advance to next moment; when last moment completes: trigger room advance.
   - Render a segmented progress bar at the top using `LinearProgressIndicator`-style segments.

3. **Gestures (tap left/right + hold-to-pause)** (`lib/pages/stories/story_viewer.dart`)
   - Wrap the viewer in a `GestureDetector`:
     - `onLongPressStart` / `onLongPressEnd` (or `onTapDown`/`onTapUp` depending on desired feel) to pause/resume the animation controller.
     - `onTapUp` with position-based hit testing to decide left vs right action.
   - Ensure taps do not conflict with media widgets (e.g., allow image zoom only if explicitly desired; otherwise keep Stories UX simple).

4. **Video playback + pause integration** (`lib/pages/stories/story_viewer.dart`)
   - Reuse existing video playback approach (or a simplified variant) so that:
     - videos autoplay
     - holding pauses both the progress controller and the video
     - releasing resumes
   - Ensure encrypted downloads are supported similarly to existing video viewer code.

5. **Auto-advance to next story room** (`lib/pages/stories/story_viewer.dart`, `lib/pages/chat_list/chat_list.dart`)
   - Determine story-room order based on the same list used for the Stories bar (`ChatListController.storyRooms` sorting).
   - From the current room, find its index; after completion navigate to next room route:
     - `context.go('/rooms/story/<nextRoomId>')`
   - If no next room exists: close the viewer (`context.pop()`).
   - Define behavior when current room is not present in the story list (fallback: close on completion or just loop within the room).

## Acceptance Criteria

- [ ] Story viewer auto-plays moments without user interaction.
- [ ] Image moments show for a fixed duration (configurable constant).
- [ ] Video moments show for the full video duration (with a reasonable fallback if missing).
- [ ] Tap-and-hold pauses progress; release resumes.
- [ ] Tapping right side advances to next moment; tapping left side goes to previous moment.
- [ ] A segmented progress indicator is visible and reflects current progress.
- [ ] When all moments in a story room finish, the viewer automatically navigates to the next story room.
- [ ] When no more story rooms exist, the viewer closes.
- [ ] AGPL headers updated on all modified files.
- [ ] `CHANGELOG.md` updated with a `[FORK]` entry describing the enhancement.

## Technical Notes

- Recommended tap split: left 33% / right 67% (common “momentSwitcherFraction” style).
- Consider pausing playback when the app is backgrounded or route loses focus.
- Ensure that rooms with no playable moments do not dead-end the playback flow.

## Research References

- WhatsApp Status controls (pause/next/previous): https://www.businessinsider.com/reference/whatsapp-status
- Flutter gesture + story moment model reference: https://github.com/vanelizarov/flutter_stories

---
*Generated by new-issue-agpl*
