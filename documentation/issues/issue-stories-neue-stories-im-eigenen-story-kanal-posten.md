# Stories: Neue Stories im eigenen Story-Kanal posten

**Type:** enhancement

## Description

Das Stories-Feature ist in dieser FluffyChat-Fork bereits als Basis vorhanden (Story-Room-Erkennung über Displayname-Prefix `story:`, StoriesBar im Chat-List, Route `/rooms/story/:roomid`, StoryViewer mit Timeline-Images). Was aktuell fehlt, ist ein UX-Flow, um **neue Story-Inhalte schnell in den eigenen Story-Kanal zu posten**.

Gewünschtes Verhalten:
- Nutzer kann aus der Stories-UI heraus „Zur Story hinzufügen“ wählen.
- Es gibt genau einen „eigener Story-Kanal“ pro Account (persistente Zuordnung), in den gepostet wird.
- Falls kein eigener Story-Kanal existiert: App erstellt automatisch einen privaten Story-Room (Name mit `story:` Prefix) und merkt sich dessen `roomId`.
- Posting: Bild(er) aus Galerie/Kamera auswählen → als `m.image`/Attachment in den Story-Room senden (E2EE & Upload via bestehende `room.sendFileEvent(...)`-Pfade).
- Optional nach erfolgreichem Post den StoryViewer öffnen.

Integration Points:
- `lib/utils/story_room_extension.dart` (`room.isStory`, `room.storyDisplayName`)
- `lib/pages/stories/stories_bar.dart`
- `lib/pages/stories/story_viewer.dart`, `lib/config/routes.dart`
- `lib/pages/new_group/new_group.dart` (`_createStory()` via Name `story:<...>`)
- Senden/Upload: `lib/pages/chat/input_bar.dart`, `lib/pages/chat/send_file_dialog.dart`

## Motivation

Stories sind aktuell primär konsumierbar (Viewer), aber es fehlt ein schneller Weg, Inhalte zu veröffentlichen. Ein klarer „Zur Story hinzufügen“-Flow ist notwendig, damit Stories als Feature im Alltag nutzbar sind. Zusätzlich braucht es eine robuste Zuordnung des eigenen Story-Kanals pro Account, um konsistent zu posten (insb. über Geräte hinweg) und nicht von Roomnamen/Umbenennungen abzuhängen.

## Implementation Plan

1. Own-Story-Resolver implementieren (AccountData lesen/schreiben, Story-Room bei Bedarf erstellen).
2. UI-Einstieg „Zur Story hinzufügen“ in der StoriesBar ergänzen.
3. Medien-Auswahl (Galerie/Kamera) wiederverwendbar umsetzen und über `room.sendFileEvent(...)` in den eigenen Story-Room senden.
4. UX: Progress/Fehlerzustände und optional direktes Öffnen des StoryViewers nach erfolgreichem Post.
5. Manuelle Testszenarien (erster Post ohne Story-Room, Post mit vorhandener Story-RoomId, Abbruch/Fehler).

## Acceptance Criteria

- [ ] In der Stories-UI existiert eine Aktion „Zur Story hinzufügen“ (oder äquivalent), erreichbar ohne Umwege.
- [ ] Die App kann einen „eigenen Story-Kanal“ eindeutig bestimmen und die `roomId` accountbezogen persistent speichern.
- [ ] Falls kein eigener Story-Kanal existiert, wird beim ersten Posten automatisch ein privater Story-Room erstellt und gespeichert.
- [ ] Nutzer kann ein Bild (mindestens Galerie) auswählen und es wird als `m.image` in den eigenen Story-Room gepostet.
- [ ] Upload/Senden nutzt die bestehende `room.sendFileEvent(...)`-Pipeline (inkl. E2EE/Upload) und zeigt Loading/Fehlerzustände.
- [ ] Nach erfolgreichem Post kann der Nutzer das Ergebnis sehen (z.B. durch Öffnen des StoryViewers oder Aktualisierung der StoriesBar).

## Technical Notes

Bestehende Stories-Basis (Prefix `story:`) ist bereits integriert (StoriesBar, StoryViewer, Route `/rooms/story/:roomid`, CreateGroupType.story). Für dieses Issue soll die Prefix-Definition unverändert bleiben.

Persistenzvorschlag: Matrix Account Data (Custom Event Type, z.B. `im.fluffychat.story` oder projekt-spezifisch) mit `{ "room_id": "..." }`, um Multi-Device konsistent zu bleiben.

Relevante Code-Stellen:
- UI: `lib/pages/stories/stories_bar.dart`
- Viewer: `lib/pages/stories/story_viewer.dart`
- Routing: `lib/config/routes.dart`
- Story-Erkennung: `lib/utils/story_room_extension.dart`
- Senden/Upload: `lib/pages/chat/input_bar.dart`, `lib/pages/chat/send_file_dialog.dart` (nutzt `room.sendFileEvent(...)`)
- Room-Erstellung (Story): `lib/pages/new_group/new_group.dart` (`_createStory()`)

## Labels

enhancement, priority:medium, ui, stories-feature

---
*Generated automatically by neo-creator*

