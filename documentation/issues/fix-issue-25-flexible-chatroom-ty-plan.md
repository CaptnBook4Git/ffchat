# Implementation Plan: Issue #25 (Expanded Notes Feature)

## Problem
1. **Live-Update Bug**: Changes to `ffchat.room_layout` don't trigger a rebuild because the event is not in the client's `importantStateEvents`.
2. **Notes Feature**: The user wants the Notes layout to support "Title + Content" for messages and an "Overview List".

## Solution
1. **Fix Live-Update**: Add `ffchat.room_layout` to `importantStateEvents` in `lib/utils/client_manager.dart`.
2. **Notes Data Format**: Use `im.ffchat.note` custom field in message content for `{ "title": "...", "body": "..." }`.
3. **Notes UI Implementation**:
   - **Note Input**: Replace standard text field in `NotesChatLayout` with a specialized `NoteInputArea` (Title field + Body field).
   - **Note Event Rendering**: Update `Message` widget or create a `NoteMessage` component for `NotesChatLayout` that displays the title prominently.
   - **Notes Overview**: Implement a `NotesOverviewDrawer` (Sidebar) that lists all messages with `im.ffchat.note` field.
4. **AGPL Compliance**: Ensure all new widgets have headers.

## Changes
1. `lib/utils/client_manager.dart`: Add `ffchat.room_layout` to `importantStateEvents`.
2. `lib/pages/chat/layouts/notes_chat_layout.dart`: Implement specialized UI (Input, Event List).
3. `lib/widgets/note_input_area.dart` (NEW): Specialized input for notes.
4. `lib/widgets/notes_overview_drawer.dart` (NEW): Sidebar for note navigation.
5. `lib/pages/chat/events/note_event_content.dart` (NEW): Renderer for note content.
6. `lib/l10n/intl_en.arb`: Add "Title", "Content", "Notes Overview" strings.

## AGPL Compliance Checklist
| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `lib/utils/client_manager.dart` | ✅ | ✅ | ✅ | Update log |
| `lib/widgets/note_input_area.dart` | ❌ Add | N/A (New) | © 2026 Simon | Add entry |
| `lib/widgets/notes_overview_drawer.dart` | ❌ Add | N/A (New) | © 2026 Simon | Add entry |

## Testing
1. Change room type and verify `ChatView` rebuilds immediately.
2. In a "Notes" room, type a title and body and send.
3. Verify the message is rendered with a bold title.
4. Open the "Notes Overview" and verify the note appears there.
5. Navigation: Tap a note in the overview and verify the chat scrolls to it.
