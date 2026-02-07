# Fix Documentation - Issue #30

**Branch:** fix/issue-30-rebranding-ff-chat-i

## Problem

Legacy FluffyChat logos were still present, and the new FF Chat logo was rendered much too large on several screens, especially on Android splash and login views.

## Solution

Replaced all vector and binary assets. Applied size constraints in Flutter UI code and re-scaled Android splash PNGs to appropriate dimensions.

## Changes

- Updated Android XML vectors with FF Chat logo.
- Fixed logo scaling in Login (max 128px) and Intro (max 200px) screens.
- Re-generated and replaced Android splash PNGs with correctly scaled versions (80dp base).
- Added/Updated AGPL headers and CHANGELOG.md.

## Verification

Verified visual proportions on Android emulator and checked AGPL compliance for all modified files.

---
*Generated automatically for Issue #30*

