# Fix Documentation - Issue #3

**Branch:** fix/issue-3-stories-post-to-own

## Problem

Stories can be viewed, but users can’t quickly post media to their own story channel.

## Solution

Store a per-account own-story room mapping in Matrix account data (ffchat.story) and provide a “Zur Story hinzufügen” action to pick and upload images into that room.

## Changes

Added own story resolver/creator via account data; added add-to-story UI + l10n; ensured Stories bar visibility; l10n header configuration; updated CHANGELOG.

## Verification

Open chat list → tap “Zur Story hinzufügen” → pick image(s) → upload completes → StoryViewer opens; repeat to confirm room is reused.

---
*Generated automatically for Issue #3*

