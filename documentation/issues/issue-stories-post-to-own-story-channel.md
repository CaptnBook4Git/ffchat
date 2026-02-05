# Stories: Neue Stories im eigenen Story-Kanal posten

**Type:** enhancement

## Beschreibung

Das Stories-Feature ist in dieser FluffyChat-Fork bereits **in einer Basis-Variante** vorhanden:

- Story-Rooms werden aktuell über den Displaynamen-Prefix `story:` erkannt (`Room.isStory`).
- In der Chat-Liste gibt es eine `StoriesBar` (horizontaler Carousel).
- Es existiert eine Route `/rooms/story/:roomid` und ein `StoryViewer`, der Timeline-Images anzeigt.

Was noch fehlt, ist ein **klarer, schneller Posting-Flow**, damit Nutzer **neue Story-Inhalte in ihren eigenen Story-Kanal** posten können (ohne Umwege über Room-Erstellung oder normalen Chat-Input).

## Motivation

Ohne „Zur Story hinzufügen“ wirkt Stories aktuell passiv (nur Konsum/Viewer). Für ein echtes Stories-Erlebnis braucht es einen primären Einstiegspunkt zum Posten in den eigenen Story-Kanal. Zusätzlich sollte die App zuverlässig wissen, **welcher Room der eigene Story-Kanal ist** (statt rein über Namens-Heuristiken), um konsistent zu posten und UX-Kantenfälle zu vermeiden.

## Scope

**In scope**

- UI-Aktion „Zur Story hinzufügen“ in der Stories-UI (z.B. in/bei `StoriesBar`).
- Sicheres Ermitteln des „eigenen Story-Kanals“:
  - Falls noch nicht vorhanden: automatisches Erstellen eines privaten Story-Rooms.
  - Persistente Speicherung der eigenen Story-`roomId` (Account-bezogen), sodass Posting unabhängig von Roomnamen/Umbenennungen funktioniert.
- Medien-Auswahl (Kamera/Galerie) und Posten als `m.image` in den eigenen Story-Room.
- Wiederverwendung der existierenden Upload/Sende-Pfade (E2EE, Upload, Thumbnailing) via `room.sendFileEvent(...)`.
- Erfolgs-/Fehlerzustände inkl. Loading/Progress.

**Out of scope (für dieses Issue)**

- „Ephemeral“/Ablauf nach 24h (Retention/Client-Filter) – separiertes Issue.
- Privacy-/Audience Controls (wer darf meine Story sehen) – separiertes Issue.
- Story-Editor (Text/Sticker/Zeichnen) – separiertes Issue.
- Wechsel von Prefix-basiert zu Custom Room Type (`creationContent.type`) – separiertes Issue.

## Technische Hinweise / Integration Points

### Bestehende relevante Stellen

- Story-Erkennung/Anzeige:
  - `lib/utils/story_room_extension.dart` (`room.isStory`, `room.storyDisplayName`)
  - `lib/pages/stories/stories_bar.dart` (UI)
- Story-Viewer/Navigation:
  - `lib/pages/stories/story_viewer.dart`
  - `lib/config/routes.dart` (`/rooms/story/:roomid`)
- Story-Room-Erstellung (nur manuell über New Group UI):
  - `lib/pages/new_group/new_group.dart` (`_createStory()` erstellt Room mit Name `story:<...>`)
- Senden/Upload von Bildern:
  - `lib/pages/chat/input_bar.dart` und `lib/pages/chat/send_file_dialog.dart` (nutzen `room.sendFileEvent(file, ...)`)
  - (je nach Architektur zusätzlich `lib/pages/chat/chat.dart` für Kamera/Galerie-Flows)

### Empfohlene Architektur für „Own Story Channel“

1. **Persistenz der eigenen Story-RoomId**
   - Bevorzugt: Matrix Account Data (pro User), z.B. ein Custom AccountData Event:
     - Event-Type Vorschlag: `im.fluffychat.story` oder `family.story`
     - Inhalt: `{ "room_id": "!abc:server" }`
   - Alternative (falls Account Data nicht gewünscht): lokale Persistenz (z.B. shared prefs) – aber weniger robust bei Multi-Device.

2. **Auflösung/Erstellung**
   - Helper/Service (neu), der:
     - AccountData liest → `roomId` liefert, wenn vorhanden.
     - sonst: privaten Room erstellt (Name z.B. `story:My Story`, Avatar optional) → `roomId` in AccountData speichert.
   - Wiederverwendbar im UI (StoriesBar, ggf. Profil, etc.).

3. **Posting-Flow**
   - UI Entry: „+“/„Zur Story hinzufügen“ in `StoriesBar`.
   - Action:
     1) ensureOwnStoryRoom() → `Room ownStoryRoom`
     2) pick image(s) (Galerie/Kamera)
     3) send via `ownStoryRoom.sendFileEvent(...)` (für Bilder i.d.R. mit `shrinkImageMaxDimension` wie im Chat)
     4) optional: direkt `context.go('/rooms/story/${ownStoryRoom.id}')`

4. **Fehler-/UX-Handling**
   - Abbruch beim Picker → keine Side Effects.
   - Upload fehlgeschlagen → Snackbar/Dialog + Retry.
   - Room-Erstellung fehlgeschlagen → Fehlerdialog.

## Implementierungsplan (high level)

1. **Own Story Resolver**
   - Neue Utility/Service-Datei anlegen (z.B. `lib/utils/own_story_room.dart` oder `lib/services/stories/own_story_service.dart`).
   - Implementiere:
     - `Future<String?> loadOwnStoryRoomId(Client client)`
     - `Future<void> saveOwnStoryRoomId(Client client, String roomId)`
     - `Future<Room> ensureOwnStoryRoom(BuildContext context)` (oder ohne UI, abhängig vom Pattern)

2. **UI: „Zur Story hinzufügen“**
   - `lib/pages/stories/stories_bar.dart`: Add Button/Tile vor den Story-Avataren.
   - Trigger: Medien-Auswahl + Upload (siehe Schritt 3).

3. **Medien auswählen & senden**
   - Wiederverwende bestehende Picker/Send-Logik (vermeidet duplizierte Medien-Pipeline).
   - Wenn sinnvoll: Extract common sending helper (z.B. aus `Chat`/`InputBar`) für Wiederverwendung.

4. **Routing nach erfolgreichem Post**
   - Optional: nach Send direkt StoryViewer öffnen.

5. **Tests/Manuelle Verifikation**
   - Manuell:
     - Account ohne bestehenden Own-Story: „Zur Story hinzufügen“ → Room wird erstellt, Upload erfolgreich.
     - Account mit bestehendem Own-Story (AccountData gesetzt): Upload geht in denselben Room.
     - Story erscheint im Viewer und in der StoriesBar.

## Acceptance Criteria

- [ ] In der Stories-UI existiert eine Aktion „Zur Story hinzufügen“ (oder äquivalent), erreichbar ohne Umwege.
- [ ] Die App kann einen „eigenen Story-Kanal“ eindeutig bestimmen und die `roomId` accountbezogen persistent speichern.
- [ ] Falls kein eigener Story-Kanal existiert, wird beim ersten Posten automatisch ein privater Story-Room erstellt und gespeichert.
- [ ] Nutzer kann ein Bild (mindestens Galerie) auswählen und es wird als `m.image` in den eigenen Story-Room gepostet.
- [ ] Upload/Senden nutzt die bestehende `room.sendFileEvent(...)`-Pipeline (inkl. E2EE/Upload) und zeigt Loading/Fehlerzustände.
- [ ] Nach erfolgreichem Post kann der Nutzer das Ergebnis sehen (z.B. durch Öffnen des StoryViewers oder Aktualisierung der StoriesBar).

## Labels

enhancement, priority:medium, ui, stories-feature
