# Fix Issue #15 - Developer Guide

> **Ziel:** Erklärung wie Entwickler mit diesem Fix/Feature umgehen können.
> 
> **Zielpublikum:** Entwickler und AI-Agents.

---

## How to fix story room naming
When creating a story room, ensure you fetch the user's profile first to get a personalized name. Use `client.fetchOwnProfile()` and check for `displayName`. Pass `null` if the name is unavailable to allow the SDK to use its default fallback.

---

*Generated automatically for Issue #15*

