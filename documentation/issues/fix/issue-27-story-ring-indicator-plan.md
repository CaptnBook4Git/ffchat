# Implementation Plan: Issue #27

## Problem
Das Issue beschreibt eine UX-Verbesserung für die Stories-Bar in FF Chat. Aktuell zeigt jeder Story-Raum denselben Gradient-Ring um den Avatar, unabhängig davon, ob neue/ungesehene Stories vorhanden sind. Der Farbverlauf (Gradient) soll durch eine Solid-Color ersetzt werden, die auf dem gewählten Theme basiert.

## Solution
1. In `lib/pages/stories/stories_bar.dart`:
   - Den `LinearGradient` beim "Add to Story"-Button und den Story-Room-Items durch eine einfarbige `BoxDecoration` (`color`) ersetzen.
   - Den Status `room.hasNewMessages` (und optional `room.isUnread`) nutzen, um zwischen einem farbigen Ring (ungesehene Stories) und einem neutralen/grauen Ring (gesehene Stories) zu unterscheiden.
2. Optional: In `lib/pages/chat_list/chat_list.dart` die Sortierung der `storyRooms` anpassen, so dass ungesehene Stories zuerst erscheinen.
3. AGPL-Header in allen modifizierten Dateien aktualisieren (Copyright & Modifications).

## Changes
1. `lib/pages/stories/stories_bar.dart`:
   - Zeile 122-130: Gradient entfernen, `color: theme.colorScheme.primary` setzen.
   - Zeile 193-201: Gradient entfernen, bedingte Farbe setzen:
     - `room.hasNewMessages || room.isUnread` ? `theme.colorScheme.primary` : `theme.colorScheme.surfaceContainerHighest`.
2. `lib/pages/chat_list/chat_list.dart`:
   - Sortierung im `storyRooms` Getter anpassen.

## AGPL Compliance Checklist
| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `lib/pages/stories/stories_bar.dart` | ✅ | © 2026 Simon | © 2026 Simon | Add entry for Issue #27 |
| `lib/pages/chat_list/chat_list.dart` | ✅ | © 2021-2026 FluffyChat | © 2026 Simon | Add entry for Issue #27 |

## Testing
- Story-Bar öffnen.
- Sicherstellen, dass der Ring um den eigenen Account ("Add Story") einfarbig ist.
- Sicherstellen, dass neue Stories einen farbigen Ring haben.
- Story ansehen und zurückkehren: Der Ring sollte nun grau/neutral sein.
- Optional: Prüfen, ob ungesehene Stories vorne sortiert sind.

## Edge Cases
- Keine Stories vorhanden: Bar sollte leer oder korrekt angezeigt werden.
- Theme-Wechsel: Farben müssen sich sofort anpassen.
- Story-Raum ohne Events: `hasNewMessages` sollte korrekt greifen.
