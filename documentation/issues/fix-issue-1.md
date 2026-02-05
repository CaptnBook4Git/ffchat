# Fix Documentation - Issue #1

**Branch:** feature/stories-support

## Problem

Story rooms (display name prefix "story:") should not behave like normal chats and need a dedicated Stories UI + viewer.

## Solution

Detect story rooms by prefix, show them in a Stories bar, exclude from the normal list, route taps to a full-screen story viewer that shows timeline images (incl. encrypted) and marks the room read.

## Changes

CHANGELOG.md; lib/config/routes.dart; lib/pages/chat_list/chat_list.dart; lib/pages/chat_list/chat_list_body.dart; lib/pages/new_group/new_group.dart; lib/utils/story_room_extension.dart; lib/pages/stories/stories_bar.dart; lib/pages/stories/story_viewer.dart; test/utils/test_client.dart

## Verification

Run tests. Manually: create/rename a room to 'story:Test', confirm it only appears in Stories bar, tap opens viewer, images show, empty state works, and unread clears after opening.

---
*Generated automatically for Issue #1*

