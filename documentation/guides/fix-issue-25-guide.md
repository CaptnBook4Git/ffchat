# Fix Issue #25 - Developer Guide

> **Ziel:** Erklärung wie Entwickler mit diesem Fix/Feature umgehen können.
> 
> **Zielpublikum:** Entwickler und AI-Agents.

---

# Developer Guide: Flexible Chatroom Types & Notes

## Architecture
The feature uses a pluggable layout system. Each room can have a `ffchat.room_layout` state event that defines its `RoomLayoutType` (normal, notes, bot).

### Layout Factory
`ChatLayoutFactory` creates the appropriate widget based on the room's layout type. This allows for clean separation of concerns.

### Notes Implementation
Notes are standard `m.room.message` events with a custom `im.ffchat.note` content field.
- **Attachments**: Embedded in the note's content array.
- **Tags**: Managed via `im.ffchat.room_tags` state event and linked in the note's content.
- **Search**: Fuzzy search implemented in `NotesOverviewDrawer`.

## Adding new Layouts
1. Add type to `RoomLayoutType` enum.
2. Create layout widget in `lib/pages/chat/layouts/`.
3. Update `ChatLayoutFactory.create`.

---

*Generated automatically for Issue #25*

