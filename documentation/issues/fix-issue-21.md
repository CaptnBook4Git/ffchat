# Fix Documentation - Issue #21

**Branch:** fix/issue-21-story-choice-dialog

## Problem

Users could not easily manage their own stories because tapping the story room always opened the viewer. Additionally, the project build was broken due to missing localization keys and incorrect configuration.

## Solution

Implemented a choice dialog intercepting the tap on the own story room. Fixed `l10n.yaml` configuration and restored missing keys in `intl_en.arb`.

## Changes

- `lib/pages/chat_list/chat_list.dart`: Added tap interception for own story room to show choice dialog.
- `lib/utils/own_story_config.dart`: Added `isOwnStoryRoom` extension method.
- `lib/l10n/intl_en.arb`: Added `storyOptions`, `viewStories`, `manageStories`. Restored 340+ missing upstream keys.
- `l10n.yaml`: Fixed header-file path.
- `CHANGELOG.md`: Added entry for the feature.

## Verification

1. **Automated**: `flutter analyze` passed with 0 errors.
2. **Manual**: Verified that tapping the own story room shows the dialog with "View stories" and "Manage stories" options.
3. **Compliance**: Verified AGPL headers in all modified files.

---
*Generated automatically for Issue #21*

