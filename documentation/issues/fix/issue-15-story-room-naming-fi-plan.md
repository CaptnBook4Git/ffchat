# Implementation Plan: Issue #15

## Problem
Story rooms werden "story:Story" statt "story:[User Name]" genannt. Dies liegt daran, dass in `stories_bar.dart` die lokalisierte Zeichenfolge "Story" als `nameFallback` übergeben wird, anstatt des Profilnamens des Benutzers.

## Solution
In `lib/pages/stories/stories_bar.dart` wird die Logik so geändert, dass der `localpart` der `userID` des Benutzers abgerufen wird. Dieser technische Name wird dann als `nameFallback` an `getOrCreateOwnStoryRoom` übergeben. Wenn kein Name vorhanden ist, wird `null` übergeben, was in `own_story_config.dart` zu einem Fallback auf "My Story" führt. Dies entspricht dem Wunsch des Benutzers, seinen "Usernamen" statt seines Anzeigenamens zu verwenden.

## Changes
1. **lib/pages/stories/stories_bar.dart**:
   - Die `_addToOwnStory` Funktion anpassen, um den `localpart` der `userID` abzurufen.
   - `nameFallback` mit dem `localpart` aktualisieren.

## AGPL Compliance Checklist
| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `lib/pages/stories/stories_bar.dart` | ✅ | ❌ (Fork-only) | ✅ © 2026 Simon | Add entry |

## Testing
- Erstellen eines neuen Story-Rooms.
- Verifizieren, dass der Raum "story:[User Name]" heißt (oder "story:My Story", falls kein Name gesetzt ist).

## Edge Cases
- Benutzer hat keinen Display Name gesetzt -> Fallback auf "My Story".
- Netzwerkfehler beim Abrufen des Profils -> Die SDK-Funktion sollte robust reagieren oder wir verwenden einen statischen Fallback.
