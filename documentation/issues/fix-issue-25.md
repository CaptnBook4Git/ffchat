# Fix Documentation - Issue #25

**Branch:** fix/issue-25-flexible-chatroom-ty

## Problem

Users needed specialized layouts for different room types (e.g., notes, bots) and a better notes experience with attachments and tagging.

## Solution

Implemented a flexible layout system and a comprehensive Notes feature set using standard Matrix events with custom extensions.

## Changes

- Added RoomLayoutType enum and Room extension for custom layouts.
- Implemented ChatLayoutFactory for Normal, Notes, and Bot rooms.
- Created Notes feature set: NoteInputArea (multi-attachments, voice, hashtags, tags), NoteEventContent (previews, image viewer), and NotesOverviewDrawer (fuzzy search, tag filtering, timestamps).
- Fixed live-update bug for room state events.
- Updated AGPL headers and CHANGELOG.md.

## Verification

Manual testing of note creation, editing, multi-attachments, voice notes, tag filtering, and mobile UI layout verified by the user.

---
*Generated automatically for Issue #25*

