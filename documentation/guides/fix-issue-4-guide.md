# Fix Issue #4 - Developer Guide

> **Ziel:** Erklärung wie Entwickler mit diesem Fix/Feature umgehen können.
> 
> **Zielpublikum:** Entwickler und AI-Agents.

---

# Contact Circles Developer Guide

## Overview
Contact Circles allow users to organize their Matrix contacts into named groups for easier management and targeted invitation sending.

## Architecture

### Data Storage
Circles are stored in Matrix account data under the event type `im.ffchat.circles`. This follows the same pattern as `own_story_config.dart`.

```dart
// Data structure in account data
{
  "version": 1,
  "circles": [
    {
      "id": "uuid-string",
      "name": "Family",
      "members": ["@user1:matrix.org", "@user2:matrix.org"],
      "createdAt": "2026-02-07T...",
      "updatedAt": "2026-02-07T..."
    }
  ]
}
```

### Key Components

1. **CirclesConfigExtension** (`lib/utils/circles_config.dart`)
   - Extension on `Client` for circle operations
   - Methods: `getCircles()`, `saveCircles()`, `addCircle()`, `updateCircle()`, `deleteCircle()`
   - Handles JSON serialization/deserialization

2. **CirclesListPage** (`lib/pages/circles/circles_list.dart`)
   - Lists all circles with member counts
   - Create new circles via FAB
   - Navigate to circle detail for editing

3. **CircleDetailPage** (`lib/pages/circles/circle_detail.dart`)
   - View and edit circle members
   - Add members from contact picker
   - Remove members with swipe or button

4. **User Dialog Integration** (`lib/widgets/adaptive_dialogs/user_dialog.dart`)
   - "Add to Circle" action shows circle selection popup
   - Quick way to add contacts to circles from anywhere

5. **Invitation Selection Filter** (`lib/pages/invitation_selection/`)
   - Filter chips for each circle
   - Multi-select filtering (intersection of selected circles)

## Adding New Circle Features

To extend circles functionality:

1. Add new fields to the `Circle` class in `circles_config.dart`
2. Update `toJson()`/`fromJson()` methods
3. Increment the `version` field for migrations
4. Update the UI components as needed

## Localization

All user-facing strings are in `lib/l10n/intl_en.arb` with keys prefixed `circles*` or `addToCircle*`.

---

*Generated automatically for Issue #4*

