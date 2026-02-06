# Research Report: Issue #27 — Visual Ring Indicator for Unseen Stories

## Issue-Titel
**[FORK] Add visual ring indicator for unseen stories**

## Issue-Beschreibung (vollständig)
Das Issue beschreibt eine UX-Verbesserung für die Stories-Bar in FF Chat. Aktuell zeigt jeder Story-Raum denselben Gradient-Ring um den Avatar, unabhängig davon, ob neue/ungesehene Stories vorhanden sind. Es soll ein visueller Indikator hinzugefügt werden, der:
- **Ungesehene Stories**: Lebhaften, farbigen Ring anzeigt (basierend auf Theme-Farbe, **ohne Gradient**)
- **Gesehene Stories**: Gedämpften grauen Ring oder keinen Ring anzeigt
- **"Add to Story"-Button**: Behält seinen aktuellen farbigen Ring

## Problem / Root Cause

### Aktueller Zustand
Der Ring um Story-Icons wird in `lib/pages/stories/stories_bar.dart` an **zwei Stellen** mit einem `LinearGradient` definiert:

1. **"Add to Story"-Button** (Zeile 122–130):
   ```dart
   gradient: LinearGradient(
     colors: [
       theme.colorScheme.primary,
       theme.colorScheme.primaryContainer,
       theme.colorScheme.secondary,
     ],
     begin: Alignment.topLeft,
     end: Alignment.bottomRight,
   ),
   ```

2. **Story-Room-Items** (Zeile 193–201):
   ```dart
   gradient: LinearGradient(
     colors: [
       theme.colorScheme.primary,
       theme.colorScheme.primaryContainer,
       theme.colorScheme.secondary,
     ],
     begin: Alignment.topLeft,
     end: Alignment.bottomRight,
   ),
   ```

### Probleme laut User-Feedback:
- ❌ **Kein Unterschied** zwischen gesehenen und ungesehenen Stories
- ❌ **Farbverlauf (Gradient) gefällt nicht** → soll durch eine Solid-Color ersetzt werden
- ✅ Die Farbe basiert auf dem Theme → das passt und soll beibehalten werden

### Theme-Farb-Bezug
Die Farben kommen aus `theme.colorScheme.primary`, `theme.colorScheme.primaryContainer`, und `theme.colorScheme.secondary`. Diese werden vom Flutter Material-Theme gesetzt, welches wiederum vom User-Theme in `lib/config/themes.dart` (Zeile 28–31) und der Farbauswahl in `lib/pages/settings_style/settings_style_view.dart` beeinflusst wird.

### Read-Marker-Logik (SDK)
Die Matrix SDK bietet auf dem `Room`-Objekt:
- **`room.hasNewMessages`** (`matrix-6.0.0/lib/src/room.dart:604-626`): Vergleicht den Read-Marker-Timestamp mit dem Timestamp des letzten Events. `true` = es gibt ungelesene Nachrichten.
- **`room.isUnread`** (`room.dart:632`): `notificationCount > 0 || markedUnread`
- Der **StoryViewer** setzt bereits einen Read-Marker beim Öffnen (`lib/pages/stories/story_viewer.dart:130-135`): `timeline.setReadMarker(...)`

Das heißt: Sobald ein User eine Story anschaut, wird `hasNewMessages` für diesen Raum `false`, was als Basis für den visuellen Indikator genutzt werden kann.

## Betroffene Dateien

| Datei | Komponente | SPDX vorhanden | Original Copyright | Fork Copyright | MODIFICATIONS |
|-------|------------|----------------|-------------------|----------------|---------------|
| `lib/pages/stories/stories_bar.dart` | StoriesBar | ✅ | ❌ (reine Fork-Datei) | ✅ `© 2026 Simon` | ✅ 4 Einträge |
| `lib/utils/story_room_extension.dart` | StoryRoomExtension | ✅ | ❌ (reine Fork-Datei) | ✅ `© 2026 Simon` | ✅ 1 Eintrag |

**Hinweis**: `story_viewer.dart` and `own_story_config.dart` sind **nicht direkt betroffen** – dort wird der Read-Marker bereits korrekt gesetzt. Auch `chat_list.dart` und `chat_list_body.dart` benötigen keine Änderung, da die `StoriesBar` bereits die `rooms`-Liste und den `onTap`-Callback korrekt erhält.

## Empfohlener Lösungsansatz

### Schritt 1: Gradient durch Solid-Color ersetzen
In `lib/pages/stories/stories_bar.dart`:

**Für Story-Room-Items (Zeile 192–203)**:
```dart
// VORHER:
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [
      theme.colorScheme.primary,
      theme.colorScheme.primaryContainer,
      theme.colorScheme.secondary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.circular(48),
),

// NACHHER (ungesehen):
decoration: BoxDecoration(
  color: room.hasNewMessages || room.isUnread
      ? theme.colorScheme.primary
      : theme.colorScheme.surfaceContainerHighest, // grau/muted
  borderRadius: BorderRadius.circular(48),
),
```

**Für den "Add to Story"-Button (Zeile 121–131)**: Ebenfalls Gradient entfernen und durch Solid-Color ersetzen:
```dart
decoration: BoxDecoration(
  color: theme.colorScheme.primary,
  borderRadius: BorderRadius.circular(48),
),
```

### Schritt 2: Unseen-Detection
Die Logik ist simple da die SDK bereits alles bietet:
- `room.hasNewMessages` → prüft ob Read-Marker vor dem letzten Event liegt
- `room.isUnread` → prüft ob `notificationCount > 0`

Empfehlung: Verwende `room.hasNewMessages` als primären Check, da dies den Read-Marker-Timestamp-Vergleich nutzt, der bereits vom `StoryViewer` korrekt gesetzt wird.

### Schritt 3: Optional – Sortierung
Räume mit ungesehenen Stories könnten an den Anfang der Liste sortiert werden. Dies würde in `lib/pages/chat_list/chat_list.dart:179-187` im `storyRooms` Getter passieren:
```dart
rooms.sort((a, b) {
  final aUnseen = a.hasNewMessages ? 1 : 0;
  final bUnseen = b.hasNewMessages ? 1 : 0;
  if (aUnseen != bUnseen) return bUnseen - aUnseen;
  return b.latestEventReceivedTime.compareTo(a.latestEventReceivedTime);
});
```

### Schritt 4: AGPL-Header updaten
- `stories_bar.dart`: Neue MODIFICATIONS-Zeile hinzufügen
- Falls `chat_list.dart` geändert wird (Sortierung): Ebenfalls MODIFICATIONS updaten

### Schritt 5: CHANGELOG.md
Eintrag unter `## Unreleased`:
```
- [FORK] Add visual ring indicator for unseen stories (Issue #27)
```

## Relevante Dokumentation

### Matrix SDK Room Properties
- `Room.hasNewMessages` — vergleicht Read-Marker-Timestamp mit letztem Event-Timestamp (`matrix-6.0.0/lib/src/room.dart:604-626`)
- `Room.isUnread` — `notificationCount > 0 || markedUnread` (`room.dart:632`)
- `Timeline.setReadMarker()` — wird im `StoryViewer` beim Öffnen aufgerufen (`story_viewer.dart:132`)

### Theme-Integration
- Farben kommen von `Theme.of(context).colorScheme` (Material 3 ColorScheme)
- Konfiguration in `lib/config/themes.dart`
- User-Auswahl in `lib/pages/settings_style/settings_style_view.dart`
- **User-Wunsch**: Die Theme-basierte Farbgebung soll bleiben, nur der Gradient soll weg

### Existierende Pattern im Codebase
- Unread-Indikator in `lib/pages/chat_list/unread_bubble.dart:35-36` nutzt `theme.colorScheme.primary` vs `theme.colorScheme.primaryContainer` für unread/read
- Chat-List-Item in `lib/pages/chat_list/chat_list_item.dart:47,176,337` nutzt `room.isUnread` and `room.hasNewMessages` für visuelle Unterscheidung

---

## TODO LIST — Nächste konkrete Schritte

- [ ] **1. Feature-Branch erstellen**: `fix/issue-27-story-ring-indicator` von `main` abzweigen
- [ ] **2. `lib/pages/stories/stories_bar.dart` modifizieren**:
  - [ ] 2a. Story-Room-Items (Zeile 192–203): `gradient: LinearGradient(...)` durch `color: <conditional solid color>` ersetzen
  - [ ] 2b. "Add to Story"-Button (Zeile 121–131): `gradient: LinearGradient(...)` durch `color: theme.colorScheme.primary` ersetzen
  - [ ] 2c. Conditional Logic: `room.hasNewMessages` prüfen für farbigen vs. grauen Ring
- [ ] **3. Optional: Sortierung in `lib/pages/chat_list/chat_list.dart:179-187`**: Ungesehene Stories zuerst anzeigen
- [ ] **4. AGPL-Header updaten**: MODIFICATIONS-Eintrag mit Datum `2026-02-06` und Issue #27 Referenz in allen geänderten Dateien
- [ ] **5. CHANGELOG.md**: `[FORK]` Eintrag unter `## Unreleased` hinzufügen
- [ ] **6. Testen**: Visuell überprüfen, dass der Ring korrekt wechselt (farbig → grau) nach dem Betrachten einer Story
- [ ] **7. Commit & PR**: Änderungen committen und Pull Request erstellen
