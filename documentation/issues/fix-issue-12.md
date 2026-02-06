# Fix Documentation - Issue #12

**Branch:** fix/issue-12-fix-changelog-link

## Problem

The changelog button in update notifications pointed to the official FluffyChat website, which lacks fork-specific details and is often out of date.

## Solution

Changed the URL in lib/config/app_config.dart to point to the fork's GitHub CHANGELOG.md and added AGPL-compliant headers.

## Changes

Modified lib/config/app_config.dart to point to the fork's CHANGELOG.md and added AGPL headers. Updated CHANGELOG.md.

## Verification

Manually verified the URL string and AGPL header compliance in the modified file.

---
*Generated automatically for Issue #12*

