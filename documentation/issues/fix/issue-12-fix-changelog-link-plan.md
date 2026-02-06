# Implementation Plan: Issue #12

## Problem
The application currently notifies users when a new version is installed via a snackbar notification. This notification includes a "Changelog" button intended to inform users about the latest changes, bug fixes, and new features. However, this button is currently hardcoded to point to the official FluffyChat website's changelog.

This change is necessary to ensure that users receive accurate information that includes fork-specific modifications, which are marked with `[FORK]` in our repository. The upstream changelog is also frequently out of sync with the actual releases, leading to user confusion.

## Solution
Redirect that link to the fork's own `CHANGELOG.md` file hosted on GitHub.

## Changes
1. `lib/config/app_config.dart`:
   - Add AGPL-3.0-or-later header.
   - Update `changelogUrl` constant from `https://fluffy.chat/en/changelog/` to `https://github.com/CaptnBook4Git/ffchat/blob/main/CHANGELOG.md`.

## AGPL Compliance Checklist
| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `lib/config/app_config.dart` | ❌ Add | © 2021-2026 FluffyChat Contributors | © 2026 Simon | Add entry |

## Testing
- Verify that clicking the "Changelog" button opens `https://github.com/CaptnBook4Git/ffchat/blob/main/CHANGELOG.md`.

## Edge Cases
- None identified.
