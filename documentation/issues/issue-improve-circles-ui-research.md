# Circles Feature Enhancement – Research Report

## Suggested Issue Title
**`[Enhancement] Improve Circles UI: More prominent placement & visually appealing design`**

## Issue Type
`enhancement` / `UI/UX`

---

## Current Behavior

The Circles feature (implemented in Issue #4) is **functional but hidden and visually plain**:

### Entry Points (buried)
1. **Settings page** (`lib/pages/settings/settings_view.dart:239-245`): A `ListTile` with `Icons.group_work_outlined` in the settings menu – deep in the navigation hierarchy.
2. **New Private Chat page** (`lib/pages/new_private_chat/new_private_chat_view.dart:164-172`): A `ListTile` in the "New Chat" flow – only visible when creating chats.
3. **User Dialog** (`lib/widgets/adaptive_dialogs/user_dialog.dart:244-295`): An "Add to Circle" popup when tapping on a user – useful but not discoverable.
4. **Invitation Selection filter chips** (`lib/pages/invitation_selection/invitation_selection_view.dart:89-109`): Circle-based filtering when inviting people to rooms.

### Visual Implementation (plain)
- **Circles List** (`lib/pages/circles/circles_list_view.dart:54-95`): A standard `ListView.builder` with `ListTile` items. Each item shows a generic `CircleAvatar` with `Icons.group_work_outlined`, the circle name, and a member count subtitle. No color coding, no member avatar preview, no visual differentiation.
- **Circle Detail** (`lib/pages/circles/circle_detail_view.dart:75-106`): A flat `ListView.separated` showing members as `ListTile` items with `Avatar` widget and a red remove button. No visual grouping, no card design.
- **No presence on the main Chat List screen** at all.

---

## Expected Behavior

Circles should be **prominent**, **visually engaging**, and **immediately accessible** from the main chat list – inspired by:
- **Instagram Close Friends**: Green ring around avatars, dedicated story ring color for close friends content
- **WhatsApp Close Friends** (launching 2026): Colored ring indicators on Status, custom lists with visual distinction
- **Telegram Folders/Categories**: Persistent tabs at the top of the chat list with customizable names

### Proposed Changes:

#### 1. **Circles Horizontal Bar on Chat List** (primary visibility improvement)
Add a horizontal scrollable bar (similar to the existing `StoriesBar`) that shows circles as colored avatar groups directly on the main chat list, positioned **below the stories bar and above the filter chips**.

#### 2. **Visual Circle Cards** (instead of plain ListTiles)
Replace the plain `ListTile` in the circles list with rich cards showing:
- Overlapping member avatar stack (up to 3-4 avatars)
- Circle color indicator (user-assignable)
- Member count badge
- Last activity timestamp

#### 3. **Circle Color/Emoji Customization**
Allow users to assign a color and/or emoji to each circle for quick visual recognition.

#### 4. **Filter Chip Integration on Chat List**
Add circle-based filter chips to the existing filter row (`ActiveFilter` enum), so users can filter the chat list by circle directly.

---

## Affected Files

| File | Component | Relevance |
|------|-----------|-----------|
| `lib/utils/circles_config.dart` | Data model (Circle class) | **MODIFY**: Add `color` and `emoji` fields to Circle model (lines 13-77) |
| `lib/pages/circles/circles_list_view.dart` | Circle list UI | **MODIFY**: Replace plain `ListTile` (lines 58-94) with visual cards showing avatar stacks |
| `lib/pages/circles/circle_detail_view.dart` | Circle detail UI | **MODIFY**: Add header card with color/emoji, improve member list layout (lines 48-106) |
| `lib/pages/circles/circles_list.dart` | Circle list controller | **MODIFY**: Add color/emoji selection methods |
| `lib/pages/circles/circle_detail.dart` | Circle detail controller | **MODIFY**: Add color picker action (lines 40-60) |
| `lib/pages/chat_list/chat_list_body.dart` | Chat list main body | **MODIFY**: Add circles horizontal bar below `StoriesBar` (after line 142) and circle filter chips (lines 153-184) |
| `lib/pages/chat_list/chat_list.dart` | Chat list controller & `ActiveFilter` enum | **MODIFY**: Extend `ActiveFilter` or add circle-based filtering (line 53) |
| `lib/pages/settings/settings_view.dart` | Settings entry point | **KEEP**: Retain as secondary entry point (lines 239-246) |
| `lib/pages/new_private_chat/new_private_chat_view.dart` | New chat entry point | **KEEP**: Retain as discovery point (lines 164-172) |
| `lib/config/routes.dart` | Route definitions | **KEEP**: Routes already exist at `/rooms/circles` (lines 222-237) |
| `lib/l10n/intl_en.arb` | Localization strings | **MODIFY**: Add new strings for circle colors, emoji, "My Circles" section header |
| `lib/pages/circles/circles_bar.dart` | **NEW FILE** | **ADD**: Horizontal scrollable bar widget (modeled after `StoriesBar` at `lib/pages/stories/stories_bar.dart`) |
| `lib/pages/circles/circle_avatar_stack.dart` | **NEW FILE** | **ADD**: Widget showing overlapping member avatars for a circle |
| `lib/pages/circles/circle_card.dart` | **NEW FILE** | **ADD**: Visual card widget for circle list items |

---

## Upstream Status

### Related Upstream Issues
- **[krille-chan/fluffychat#305](https://github.com/krille-chan/fluffychat/issues/305)** – "Contacts as modern messaging app" (OPEN, labeled `enhancement`, `Needs upstream fix`). This is directly related – it requests a modern contact list saved in Matrix, similar to how stories work. The upstream maintainer (krille-chan) authored it themselves, suggesting receptivity to this direction. **Our Circles feature is a fork-specific implementation of this concept.**

### No Upstream Circles Implementation
The upstream FluffyChat has no circles/contact grouping feature. Our fork's implementation via `im.ffchat.circles` account data is entirely fork-specific.

---

## Suggested Implementation Approach

### Phase 1: Circles Horizontal Bar (Main Visibility)

1. **READ**: `lib/pages/stories/stories_bar.dart` – Lines 89-229 to understand horizontal bar pattern
2. **ADD**: `lib/pages/circles/circles_bar.dart` – New widget modeled after `StoriesBar`:
   - Horizontal `ListView.builder` with height ~80px
   - First item: "All Circles" / "Manage" button → navigates to `/rooms/circles`
   - Each circle item: `CircleAvatar` stack of 2-3 member avatars, circle name below, optional color ring
   - Tap action: Navigate to circle detail or filter chat list
3. **MODIFY**: `lib/pages/chat_list/chat_list_body.dart:142` – Insert `CirclesBar` widget after `StoriesBar`:
   ```dart
   if (!controller.isSearchMode)
     StoriesBar(rooms: stories, onTap: controller.onChatTap),
   if (!controller.isSearchMode)
     CirclesBar(circles: client.circles), // NEW
   ```

### Phase 2: Avatar Stack Widget

4. **ADD**: `lib/pages/circles/circle_avatar_stack.dart` – New widget:
   - Takes `List<String>` of member user IDs
   - Renders up to 3 overlapping `Avatar` widgets (from `lib/widgets/avatar.dart`)
   - Shows "+N" badge for remaining members
   - Uses `client.rooms` to resolve direct chat avatars

### Phase 3: Enhanced Circle Data Model

5. **MODIFY**: `lib/utils/circles_config.dart:13-77` – Add to `Circle` class:
   ```dart
   final int? colorValue;  // Material color value (e.g., Colors.blue.value)
   final String? emoji;     // Optional emoji icon
   ```
   Update `fromJson`, `toJson`, `copyWith` accordingly.
   
6. **MODIFY**: `lib/utils/circles_config.dart:110-113` – Update `_CirclesAccountData.toJson` to include new fields

### Phase 4: Visual Circle Cards (List Redesign)

7. **ADD**: `lib/pages/circles/circle_card.dart` – New card widget:
   - `Card` with `InkWell` instead of `ListTile`
   - Left: `CircleAvatarStack` showing member preview
   - Center: Circle name (bold), member count, last updated
   - Right: Color dot indicator + popup menu
   - Optional colored left border strip matching circle color
   
8. **MODIFY**: `lib/pages/circles/circles_list_view.dart:54-95` – Replace `ListView.builder` with grid or card list:
   ```dart
   // Replace ListTile at line 58 with:
   CircleCard(circle: circle, onTap: ..., onRename: ..., onDelete: ...)
   ```

### Phase 5: Circle Detail Enhancement

9. **MODIFY**: `lib/pages/circles/circle_detail_view.dart:48-59` – Add header section:
   - Large `CircleAvatarStack` as hero
   - Circle name with edit icon
   - Color picker button
   - Emoji selector
   - Member count with visual badge

### Phase 6: Chat List Filter Integration

10. **MODIFY**: `lib/pages/chat_list/chat_list.dart:53` – Add circle-based filter variant or dynamic filter chip generation
11. **MODIFY**: `lib/pages/chat_list/chat_list_body.dart:153-166` – After the existing filter chips, conditionally add circle filter chips when circles exist

### Phase 7: Localization & AGPL

12. **MODIFY**: `lib/l10n/intl_en.arb` – Add new strings:
    - `myCircles`, `circleColor`, `circleEmoji`, `manageCircles`, `filterByCircle`
13. **AGPL Compliance**: Add SPDX headers to all new files, update MODIFICATIONS log in all modified files

---

## IMPLEMENTATION STEPS (Concrete Changes Per File)

### File 1: `lib/utils/circles_config.dart`
1. **READ**: Lines 13-77 to understand current `Circle` model
2. **MODIFY**: `circles_config.dart:14-18` – Add `colorValue` and `emoji` fields:
   ```dart
   final int? colorValue;
   final String? emoji;
   ```
3. **MODIFY**: `circles_config.dart:28-40` – Update `copyWith` to include new fields
4. **MODIFY**: `circles_config.dart:42-68` – Update `fromJson` to parse `color_value` and `emoji`
5. **MODIFY**: `circles_config.dart:71-77` – Update `toJson` to serialize new fields

### File 2: `lib/pages/circles/circles_bar.dart` (NEW)
1. **ADD**: New file modeled on `lib/pages/stories/stories_bar.dart` (lines 89-229)
2. Widget receives `List<Circle>` and `VoidCallback onManage`
3. Renders horizontal scroll with circle items showing avatar stacks
4. Each item ~64px wide with avatar stack + label, tappable to navigate

### File 3: `lib/pages/circles/circle_avatar_stack.dart` (NEW)
1. **ADD**: New `StatelessWidget` taking `List<String> memberIds`, `int maxAvatars = 3`, `double size = 24`
2. Uses `Stack` with `Positioned` to overlap avatars
3. Resolves display names via `client.rooms` direct chat lookup

### File 4: `lib/pages/circles/circle_card.dart` (NEW)
1. **ADD**: New `StatelessWidget` replacing `ListTile` in circles list
2. Uses `Card` with `Material` ripple, horizontal layout
3. Left: `CircleAvatarStack`, Center: name + subtitle, Right: color dot + menu

### File 5: `lib/pages/circles/circles_list_view.dart`
1. **READ**: Lines 43-96 to understand current layout
2. **MODIFY**: `circles_list_view.dart:54-95` – Replace `ListView.builder` with new card-based list
3. **MODIFY**: `circles_list_view.dart:38-41` – Enhance FAB with optional color selection on create

### File 6: `lib/pages/circles/circle_detail_view.dart`
1. **READ**: Lines 47-59 to understand header
2. **MODIFY**: `circle_detail_view.dart:48-59` – Add visual header with avatar stack and circle color
3. **MODIFY**: `circle_detail_view.dart:52-58` – Add color picker and emoji selector to actions

### File 7: `lib/pages/chat_list/chat_list_body.dart`
1. **READ**: Lines 133-186 to understand stories bar and filter placement
2. **MODIFY**: `chat_list_body.dart:142` – Add `CirclesBar` import and widget after `StoriesBar`:
   ```dart
   if (!controller.isSearchMode && client.circles.isNotEmpty)
     CirclesBar(circles: client.circles, onManage: () => context.go('/rooms/circles')),
   ```

### File 8: `lib/pages/chat_list/chat_list.dart`
1. **READ**: Line 53 to understand `ActiveFilter` enum
2. **MODIFY**: `chat_list.dart:53` – Optionally extend or add dynamic circle filters
3. **MODIFY**: `chat_list.dart:195-213` – Add circle-based room filtering logic (filter rooms by circle member DM rooms)

### File 9: `lib/l10n/intl_en.arb`
1. **MODIFY**: Add new localization keys:
   - `"myCircles": "My Circles"`
   - `"circleColor": "Circle color"`
   - `"circleEmoji": "Circle emoji"`
   - `"manageCircles": "Manage circles"`
   - `"filterByCircle": "Filter by circle"`

### File 10: `CHANGELOG.md`
1. **MODIFY**: Add `[FORK]` entry: `- [FORK] Improve Circles UI: horizontal bar, avatar stacks, color/emoji customization (Issue #XX)`

---

## Technical Considerations

| Area | Detail |
|------|--------|
| **Animations** | Use `FluffyThemes.animationDuration` and `FluffyThemes.animationCurve` (existing pattern in `stories_bar.dart:113-116`) for consistent animated transitions |
| **State Management** | Circles data is reactive via `client.onSync.stream` (already used in `circles_list_view.dart:26-27`). The `CirclesBar` should use the same `StreamBuilder` pattern |
| **Performance** | Avatar stack must lazy-load avatars. Use `Avatar` widget from `lib/widgets/avatar.dart` which already handles caching. Limit stack to 3-4 avatars max |
| **Data Migration** | New `colorValue`/`emoji` fields must be optional (nullable) in the `Circle` model to avoid breaking existing data. `_CirclesAccountData.fromJson` already handles missing fields gracefully |
| **AGPL Compliance** | All new files need `SPDX-License-Identifier: AGPL-3.0-or-later` + `Copyright (c) 2026 Simon` headers. Modified files need MODIFICATIONS entries |
| **Material You** | Use `theme.colorScheme` tokens consistently (as done in `circles_list_view.dart:60-61`). Circle colors should work with both light and dark themes |
| **Responsive** | The `CirclesBar` must work on both mobile (horizontal scroll) and desktop column mode (check `FluffyThemes.isColumnMode(context)`) |
| **Accessibility** | All interactive elements need tooltips (follow pattern in `circle_detail_view.dart:54,97`). Color indicators should not be sole differentiator (add emoji option) |
