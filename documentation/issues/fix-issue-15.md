# Fix Documentation - Issue #15

**Branch:** fix/issue-15-story-room-naming-fi

## Problem

Story rooms were created with the generic name 'story:Story' instead of the user's name.

## Solution

Modified stories_bar.dart to fetch the user's display name and pass it as a fallback during room creation.

## Changes

lib/pages/stories/stories_bar.dart: Fetch own profile and use display name for story room naming fallback.

## Verification

Create a new story room and verify it is named 'story:[User Name]' or 'story:My Story'.

---
*Generated automatically for Issue #15*

