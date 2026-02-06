# feat: Add flexible chatroom types (Normal, Notes, Bot) with pluggable layouts

**Type:** feature

## Description

## Summary

Add a flexible room type system to FluffyChat that allows users to choose a chatroom type (Normal, Notes, Bot, etc.) when creating a room. Each room type uses a dedicated layout optimized for its purpose. The system should be variable and easy to extend — new layouts live in separate files and are registered via a factory pattern.

## Current State

### Room Creation
- `lib/pages/new_group/new_group.dart` defines `CreateGroupType { group, space, story }` enum
- UI uses `SegmentedButton<CreateGroupType>` in `new_group_view.dart` (lines 42-58)
- Three creation methods dispatch via `submitAction()` switch (line 136):
  - `_createGroup()` → `client.createGroupChat()` (line 71)
  - `_createSpace()` → `client.createRoom()` with `creationContent: {'type': RoomCreationTypes.mSpace}` (line 93)
  - `_createStory()` → `client.createRoom()` with name prefix `story:` (line 118)

### Chat View
- `lib/pages/chat/chat_view.dart` is a **single monolithic widget** (428 lines) — no layout switching mechanism exists
- `ChatEventList` (chat_event_list.dart) renders all messages via `Message()` widget — no layout delegation
- No factory or strategy pattern for different room presentations

### Room Type Detection
- **Spaces**: Use Matrix standard `creationContent` type field (`m.space`) — detected via `room.isSpace` (SDK room.dart:2608)
- **Stories**: Use fragile display name prefix `story:` — detected via fork extension `StoryRoomExtension` in `lib/utils/story_room_extension.dart`
- **No custom room type infrastructure** exists for additional types

### Bot/AI
- Only reference: `push_helper.dart:212` uses `MessageTypes.Notice` to style bot notifications
- Localization has `botMessages` string for notification suppression
- No dedicated bot room layout or AI integration

### Upstream
- No matching issues found in `krille-chan/fluffychat` for room types, notes rooms, or bot rooms — this is a **novel fork feature**

## Motivation

## Why This Feature

1. **Personal Notes**: Users want a "Notes to Self" room with an optimized layout — no avatars, no read receipts, simplified input, diary-style presentation. This is a common pattern in messaging apps (Telegram's Saved Messages, WhatsApp's personal chat).

2. **Bot/AI Communication**: As AI assistants become common, users need rooms optimized for bot interaction — structured message display, code block rendering, quick-action buttons, typing indicators that make sense for bots.

3. **Extensibility**: The current hard-coded room type system (group/space/story) doesn't scale. A pluggable layout system lets contributors add new room types (e.g., Kanban, Forum, Voice-focused) in isolated files without touching core chat logic.

4. **Better UX**: Different conversation types have fundamentally different UX needs. A one-size-fits-all chat view forces compromises.

## Implementation Plan

## Implementation Plan

### Phase 1: Room Type Infrastructure

#### 1.1 Define Room Layout Type System
Create `lib/utils/room_layout_type.dart`:
```dart
/// Defines the layout type for a room's chat view.
/// Stored as a custom Matrix state event: `ffchat.room_layout`
enum RoomLayoutType {
  normal,    // Standard group/DM chat
  notes,     // Personal notes — no avatars, simplified
  bot,       // AI/bot optimized — code blocks, actions
}

extension RoomLayoutTypeExtension on Room {
  RoomLayoutType get layoutType {
    final event = getState('ffchat.room_layout');
    final type = event?.content.tryGet<String>('layout');
    return RoomLayoutType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => RoomLayoutType.normal,
    );
  }

  Future<void> setLayoutType(RoomLayoutType type) async {
    await client.setRoomStateWithKey(
      id, 'ffchat.room_layout', '', {'layout': type.name},
    );
  }
}
```

#### 1.2 Metadata Storage Decision
**Recommended: Custom state event `ffchat.room_layout`**
- Mutable after creation (user can change room layout later)
- Doesn't conflict with Matrix spec room types
- Namespaced to avoid collisions
- Can carry additional layout configuration in future

Alternative (rejected): `creationContent` type field — immutable, can't change layout after room creation.

### Phase 2: Room Creation Flow

#### 2.1 Extend CreateGroupType or Add Layout Selection
In `lib/pages/new_group/new_group.dart`:
- Add `RoomLayoutType` selection to creation flow
- After room creation, set `ffchat.room_layout` state event
- Update `SegmentedButton` in `new_group_view.dart` with layout type chips

#### 2.2 Creation Methods
Each room type sets layout after creation:
```dart
final roomId = await client.createGroupChat(...);
await client.setRoomStateWithKey(
  roomId, 'ffchat.room_layout', '', {'layout': 'notes'},
);
```

### Phase 3: Pluggable Layout System

#### 3.1 Layout Factory
Create `lib/pages/chat/layouts/chat_layout_factory.dart`:
```dart
abstract class ChatLayout extends StatelessWidget {
  final ChatController controller;
  const ChatLayout(this.controller, {super.key});
}

class ChatLayoutFactory {
  static ChatLayout create(RoomLayoutType type, ChatController controller) {
    return switch (type) {
      RoomLayoutType.normal => NormalChatLayout(controller),
      RoomLayoutType.notes  => NotesChatLayout(controller),
      RoomLayoutType.bot    => BotChatLayout(controller),
    };
  }
}
```

#### 3.2 Layout Files (one per type)
```
lib/pages/chat/layouts/
├── chat_layout_factory.dart     # Factory + abstract base
├── normal_chat_layout.dart      # Default layout (extracted from chat_view.dart)
├── notes_chat_layout.dart       # Notes-optimized layout
└── bot_chat_layout.dart         # Bot-optimized layout
```

#### 3.3 Integrate into ChatView
In `lib/pages/chat/chat_view.dart`, replace monolithic body with:
```dart
body: ChatLayoutFactory.create(
  controller.room?.layoutType ?? RoomLayoutType.normal,
  controller,
),
```

### Phase 4: Individual Layouts

#### 4.1 Normal Layout
- Extract current `chat_view.dart` body into `NormalChatLayout`
- No functional changes, just structural refactor

#### 4.2 Notes Layout
- No user avatars or display names
- No read receipts / typing indicators
- Simplified input (no voice messages, no emoji reactions)
- Date-grouped entries (diary style)
- Optional: markdown rendering for note content

#### 4.3 Bot Layout
- Code block rendering with syntax highlighting
- Structured message display (cards, lists)
- Quick-action buttons for common bot commands
- "Thinking" indicator instead of typing indicator
- Optional: message rating (thumbs up/down)

### Phase 5: Navigation Updates

#### 5.1 Route Updates
In `lib/config/routes.dart` — no new routes needed. The factory pattern means all room types use `/rooms/:roomid`. Layout selection happens inside `ChatView`.

#### 5.2 Chat List Updates
In `lib/pages/chat_list/chat_list.dart`, `onChatTap()`:
- No changes needed — normal rooms already route to `/rooms/${room.id}`
- Layout selection happens in `ChatView` based on room state event

### Phase 6: Room Settings Integration
- Add layout type picker in room settings (so users can change layout after creation)
- Show current layout type in room info

## Acceptance Criteria

## Acceptance Criteria

### Must Have
- [ ] Users can select a room type (Normal, Notes, Bot) when creating a new room
- [ ] Room type is stored as `ffchat.room_layout` custom state event
- [ ] Chat view uses a layout factory to render the correct layout based on room type
- [ ] Each layout lives in its own file under `lib/pages/chat/layouts/`
- [ ] Normal layout preserves all current chat functionality (no regression)
- [ ] Notes layout has simplified UI (no avatars, no read receipts, no typing indicators)
- [ ] Bot layout has enhanced code block rendering
- [ ] Adding a new layout type requires only: adding enum value, creating layout file, adding factory case

### Should Have
- [ ] Room type can be changed after creation via room settings
- [ ] Room type is visible in room info/details
- [ ] Chat list shows visual indicator for room type (icon badge)

### Nice to Have
- [ ] Notes layout has date-grouped entries
- [ ] Bot layout has quick-action buttons
- [ ] Bot layout has message rating (thumbs up/down)
- [ ] Room type selection has preview/description in creation flow

## Technical Notes

## Technical Notes

### Files to Modify
| File | Change |
|------|--------|
| `lib/pages/new_group/new_group.dart` | Add layout type selection, set state event after creation |
| `lib/pages/new_group/new_group_view.dart` | Add layout type UI (chips/buttons) |
| `lib/pages/chat/chat_view.dart` | Replace monolithic body with `ChatLayoutFactory.create()` |
| `lib/pages/chat/chat.dart` | Add `layoutType` getter from room state |

### New Files
| File | Purpose |
|------|---------|
| `lib/utils/room_layout_type.dart` | `RoomLayoutType` enum + `Room` extension |
| `lib/pages/chat/layouts/chat_layout_factory.dart` | Factory + abstract base class |
| `lib/pages/chat/layouts/normal_chat_layout.dart` | Default layout (extracted from chat_view.dart) |
| `lib/pages/chat/layouts/notes_chat_layout.dart` | Notes-optimized layout |
| `lib/pages/chat/layouts/bot_chat_layout.dart` | Bot-optimized layout |

### Design Decisions
1. **State event vs creationContent**: Using custom state event `ffchat.room_layout` because it's mutable (layout can be changed after room creation) and doesn't conflict with Matrix spec types.
2. **Namespace**: `ffchat.*` prefix for all custom state events to avoid collisions.
3. **Factory pattern**: Chosen over inheritance/mixin for simplicity and explicit mapping.
4. **No new routes**: All room types use the same `/rooms/:roomid` route. Layout selection is internal to `ChatView`.
5. **Story pattern reference**: `lib/utils/story_room_extension.dart` serves as the model for the `Room` extension pattern — but we use state events instead of display name prefix for robustness.

### Risks & Mitigations
- **Risk**: Extracting normal layout from monolithic `chat_view.dart` could introduce regressions.
  **Mitigation**: Phase 4.1 is a pure refactor — extract without changing behavior, test thoroughly.
- **Risk**: Custom state events may not sync properly with all Matrix clients.
  **Mitigation**: Other clients will simply ignore `ffchat.room_layout` and show the default chat view. Graceful degradation.
- **Risk**: Layout type enum changes could break existing rooms.
  **Mitigation**: `orElse: () => RoomLayoutType.normal` fallback ensures unknown types default to normal.

### Upstream Compatibility
This is a **fork-only feature**. No upstream issues exist. The implementation uses custom namespaced state events (`ffchat.*`) that don't interfere with Matrix spec or upstream FluffyChat functionality. Other Matrix clients will simply ignore the custom state event and render rooms normally.

## Labels

enhancement, fork-feature

---
*Generated automatically by neo-creator*

