# Fix Issue #21 - Developer Guide

> **Ziel:** Erklärung wie Entwickler mit diesem Fix/Feature umgehen können.
> 
> **Zielpublikum:** Entwickler und AI-Agents.

---

# Own Story Room Management

When tapping your own story room in the chat list, a dialog now appears offering two options:

1. **View stories**: Opens the story viewer to watch your stories.
2. **Manage stories**: Opens the chat view where you can see and delete your story messages.

## Implementation Details
- Uses `showModalActionPopup` for the choice dialog.
- Checks `client.isOwnStoryRoom(room)` to trigger the dialog.


---

*Generated automatically for Issue #21*

