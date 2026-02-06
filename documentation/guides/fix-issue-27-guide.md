# Fix Issue #27 - Developer Guide

> **Ziel:** Erklärung wie Entwickler mit diesem Fix/Feature umgehen können.
> 
> **Zielpublikum:** Entwickler und AI-Agents.

---

# Story Ring Indicator Guide

To differentiate between seen and unseen stories, we use a solid ring indicator around the story icon.

- **Unseen Stories**: The ring uses the theme's primary color (`theme.colorScheme.primary`).
- **Seen Stories**: The ring uses a neutral/muted color (`theme.colorScheme.surfaceContainerHighest`).

The implementation uses `room.hasNewMessages` to detect if there are new stories.

Additionally, unseen story rooms are now sorted to the front of the stories bar in `ChatList`.


---

*Generated automatically for Issue #27*

