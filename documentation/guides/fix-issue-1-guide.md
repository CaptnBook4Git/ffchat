# Fix Issue #1 - Developer Guide

> **Ziel:** Erklärung wie Entwickler mit diesem Fix/Feature umgehen können.
> 
> **Zielpublikum:** Entwickler und AI-Agents.

---

# Stories rooms via `story:` prefix

## Overview
Rooms whose display name starts with `story:` (case-insensitive, leading whitespace ignored) are treated as Stories.

## How it works
- Story rooms are detected via helper in `lib/utils/story_room_extension.dart`.
- Chat list shows a horizontal Stories bar (when story rooms exist) and excludes those rooms from the normal list.
- Tapping a story opens the story viewer route `/rooms/story/:roomid`.

## Manual test
1. Create or rename a room to `story:Test`.
2. Ensure it appears only in the Stories bar.
3. Tap it to open the full-screen viewer.
4. Verify images load in chronological order.
5. Verify unread clears after opening.

## Notes
- Viewer supports encrypted attachments using existing Matrix event download/decrypt patterns.


---

*Generated automatically for Issue #1*

