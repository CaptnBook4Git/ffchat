# Fix Issue #30 - Developer Guide

> **Ziel:** Erklärung wie Entwickler mit diesem Fix/Feature umgehen können.
> 
> **Zielpublikum:** Entwickler und AI-Agents.

---

# Developer Guide: Logo Scaling & Rebranding

## Logo Dimensions
- Login Screen: Max 128x128px (`ConstrainedBox`)
- Intro Screen: Max 200x200px (`ConstrainedBox`)
- Android Splash (80dp base):
  - mdpi: 80px
  - hdpi: 120px
  - xhdpi: 160px
  - xxhdpi: 240px
  - xxxhdpi: 320px

## Implementation
Always use `ConstrainedBox` for logos in UI views to prevent them from filling the screen width. When generating splash assets, use 80dp as the reference size for the centered icon.

---

*Generated automatically for Issue #30*

