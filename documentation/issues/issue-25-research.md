# Issue #25 Research: Flexible Chatroom Types (Normal, Notes, Bot)

## Core Architecture
- **RoomLayoutType enum**: `{ normal, notes, bot }` stored as Matrix custom state event `ffchat.room_layout`
- **Room extension**: `layoutType` getter reads state, `setLayoutType()` writes via `setRoomStateWithKey()`
- **Factory pattern**: `ChatLayoutFactory.create(type, controller)` returns per-type layout widget

## Files to CREATE (5 new)
- `lib/utils/room_layout_type.dart` — Enum + Room extension
- `lib/pages/chat/layouts/chat_layout_factory.dart` — Factory + abstract base
- `lib/pages/chat/layouts/normal_chat_layout.dart` — Extracted from chat_view.dart body (lines 307-420)
- `lib/pages/chat/layouts/notes_chat_layout.dart` — Simplified: no avatars, no receipts, no typing
- `lib/pages/chat/layouts/bot_chat_layout.dart` — Code blocks, structured messages, thinking indicator

## Files to MODIFY (6 existing)
- `lib/pages/chat/chat.dart` (1418 lines, NO AGPL) — Add `layoutType` getter to ChatController
- `lib/pages/chat/chat_view.dart` (427 lines, NO AGPL) — Replace monolithic body with factory call
- `lib/pages/new_group/new_group.dart` (178 lines, HAS AGPL) — Extend CreateGroupType enum + add creation methods
- `lib/pages/new_group/new_group_view.dart` (NO AGPL) — Add layout type SegmentedButton segments
- `lib/l10n/intl_en.arb` — Add localization strings
- `CHANGELOG.md` — Add [FORK] entry

## AGPL Status Summary
- NEEDS HEADERS: chat_view.dart, chat.dart, new_group_view.dart
- ALREADY HAS: new_group.dart, chat_list.dart, circles_config.dart, own_story_config.dart, story_room_extension.dart, stories_bar.dart, story_viewer.dart

## Key Reference Patterns
- State events: `setRoomStateWithKey()` used in settings_emotes.dart for `im.ponies.room_emotes`
- Namespace: `im.ffchat.*` / `ffchat.*` used in app_config.dart, circles_config.dart, own_story_config.dart
- Room extension: StoryRoomExtension and OwnStoryConfigExtension demonstrate the pattern
- ChatController at chat.dart:97: `Room get room => sendingClient.getRoomById(roomId) ?? widget.room;`

## IMPLEMENTATION STEPS (Pflichtformat)

### 1. lib/utils/room_layout_type.dart (NEW)
- **ADD**: Create enum `RoomLayoutType` and `RoomLayoutTypeExtension` with `layoutType` getter and `setLayoutType` setter.
- **HEADER**: Add AGPL-3.0 header with Simon 2026.

### 2. lib/pages/chat/layouts/ (NEW DIRECTORY)
- **ADD**: `chat_layout_factory.dart`: Abstract `ChatLayout` class and `ChatLayoutFactory` with `create` method.
- **ADD**: `normal_chat_layout.dart`: Extract current `chat_view.dart` body.
- **ADD**: `notes_chat_layout.dart`: Implement simplified notes layout.
- **ADD**: `bot_chat_layout.dart`: Implement bot-optimized layout.

### 3. lib/pages/chat/chat.dart
- **READ**: Understand `ChatController` state management.
- **MODIFY**: Add `RoomLayoutType get layoutType` to `ChatController`.
- **HEADER**: Add AGPL-3.0 header.

### 4. lib/pages/chat/chat_view.dart
- **READ**: Identify body widget structure (lines 307-420).
- **MODIFY**: Replace body with `ChatLayoutFactory.create(controller.layoutType, controller)`.
- **HEADER**: Add AGPL-3.0 header.

### 5. lib/pages/new_group/new_group.dart
- **READ**: `CreateGroupType` enum and `submitAction()`.
- **MODIFY**: Add `notes` and `bot` to `CreateGroupType`. Update `_createGroup` or add new methods to set `ffchat.room_layout` state after creation.

### 6. lib/pages/new_group/new_group_view.dart
- **READ**: `SegmentedButton` implementation.
- **MODIFY**: Add segments for Notes and Bot.
- **HEADER**: Add AGPL-3.0 header.

### 7. lib/l10n/intl_en.arb
- **MODIFY**: Add labels for "Notes", "Bot", "Room Layout", etc.

### 8. CHANGELOG.md
- **MODIFY**: Add `[FORK] Add flexible chatroom types (Normal, Notes, Bot) (Issue #25)`
