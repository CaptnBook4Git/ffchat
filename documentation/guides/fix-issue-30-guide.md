# Fix Issue #30 - Developer Guide

> **Ziel:** Erklärung wie Entwickler mit diesem Fix/Feature umgehen können.
> 
> **Zielpublikum:** Entwickler und AI-Agents.

---

# Developer Guide: Rebranding Assets

When updating branding in FF Chat:
1. Use `assets/logo.svg` as the source of truth for the logo.
2. For Android Adaptive Icons, update path data in `android/app/src/main/res/drawable/ic_launcher_foreground.xml` and related files.
3. Ensure all modified files have the AGPL-3.0-or-later header.
4. Update `CHANGELOG.md` with the `[FORK]` prefix.

---

*Generated automatically for Issue #30*

