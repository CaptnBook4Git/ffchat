Jetzt habe ich ein vollständiges Bild. Hier ist der strukturierte Research-Report:

---

# Research Report: Issue #30 — Complete FluffyChat to FF Chat Rebranding

## Issue-Details

- **Issue-Titel**: `[FORK] chore(rebranding): Complete FluffyChat to FF Chat rebranding`
- **Issue-Nummer**: #30
- **Status**: OPEN
- **Labels**: keine

### Issue-Beschreibung (vollständig)
Das Issue umfasst die vollständige Umbenennung aller verbleibenden FluffyChat-Referenzen im Fork zu FF Chat. Es listet Logo-Dateien, Code-Änderungen nach Plattform (Snap, iOS, macOS, Linux, Fastlane, Docs, Build-Scripts, GitHub Workflows, pubspec, Tests, GitHub Templates), und explizite Ausnahmen (Matrix Account Data Keys wie `im.fluffychat.*` in `lib/utils/`).

---

## Problem / Root Cause

Das Rebranding von FluffyChat → FF Chat ist **teilweise** abgeschlossen. Während einige Assets (logo.png, info-logo.png, logo_transparent.png, logo.svg, Android mipmap ic_launcher PNGs) bereits das neue FF Chat-Logo (Teal Speech Bubble mit Doppel-Häkchen) enthalten, zeigen zahlreiche andere Assets noch das alte FluffyChat-Logo (Purple Cat Monster) und/oder enthalten „FluffyChat"-Text-Branding.

---

## Asset-Status-Analyse

### ✅ BEREITS ERSETZT (FF Chat Branding)
| Datei | Aktuelles Branding |
|-------|--------------------|
| `assets/logo.png` | ✅ FF Chat (Teal Speech Bubble) |
| `assets/info-logo.png` | ✅ FF Chat (Teal Speech Bubble) |
| `assets/logo_transparent.png` | ✅ FF Chat (Teal Speech Bubble) |
| `assets/logo.svg` | ✅ FF Chat (SVG, Teal Double-Check) |
| `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | ✅ FF Chat |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | ✅ FF Chat |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | ✅ FF Chat |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | ✅ FF Chat |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | ✅ FF Chat |
| `web/icons/Icon-512.png` | ✅ FF Chat (Teal Bubble, brand-neutral) |

### ❌ NOCH FLUFFYCHAT BRANDING (müssen ersetzt werden)
| Datei | Aktuelles Branding | Beschreibung |
|-------|--------------------|--------------|
| `assets/banner_transparent.png` | ❌ FluffyChat | Purple Cat + "fluffychat" Wordmark |
| `assets/banner.png` | ❌ FluffyChat | Purple Cat + "fluffychat" Wordmark |
| `assets/favicon.png` | ❌ FluffyChat | Purple Cat Face |
| `android/app/src/main/res/drawable-*/splash.png` (5 Dichten) | ❌ FluffyChat | Purple Cat + "fluffychat" Wordmark |
| `android/app/src/main/res/drawable/background.png` | ❌ FluffyChat | Solid Purple Background |
| `android/app/src/main/res/drawable-v21/background.png` | ❌ FluffyChat | Solid Purple Background |
| `android/app/src/main/res/drawable-night/background.png` | ❌ FluffyChat | (Night-Mode Background) |
| `android/app/src/main/res/drawable-night-v21/background.png` | ❌ FluffyChat | (Night-Mode Background) |
| `android/app/src/main/res/drawable-*/notifications_icon.png` (5 Dichten) | ❌ FluffyChat | White Cat Silhouette |
| `android/app/src/main/res/drawable/ic_launcher_foreground.xml` | ❌ FluffyChat | Purple Cat Vector Path (#4d3f92) |
| `android/app/src/main/res/drawable/ic_launcher_monochrome.xml` | ❌ FluffyChat | Cat Monochrome Vector Path (#4d3f92) |
| `android/app/src/main/res/drawable-anydpi-v24/notifications_icon.xml` | ❌ FluffyChat | Cat Vector Path (#4d3f92) |
| `android/fastlane/metadata/android/en-US/images/icon.png` | ❌ FluffyChat | Purple Cat Face |
| `android/fastlane/metadata/android/en-US/images/featureGraphic.png` | ❌ FluffyChat | Purple Cat + "fluffychat" Banner |
| `web/favicon.png` | ❌ FluffyChat | Purple Cat (aber kontextabhängig) |
| `snap/gui/fluffychat.png` | ❌ FluffyChat | Purple Cat Face |

---

## Betroffene Dateien — AGPL-Header-Status

### Dart-Dateien (Code-Referenzen auf Logo-Assets)

| Datei | Zeile | Referenz | SPDX vorhanden | Original Copyright | Fork Copyright | MODIFICATIONS |
|-------|-------|----------|----------------|-------------------|----------------|---------------|
| `lib/utils/platform_infos.dart` | 104 | `'assets/logo.png'` | ✅ AGPL-3.0-or-later | ✅ `2020-2026 FluffyChat Contributors` | ✅ `2026 Simon` | ✅ `2026-02-06: Rebranding` |
| `lib/widgets/lock_screen.dart` | 82 | `'assets/info-logo.png'` | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `lib/widgets/layouts/empty_page.dart` | 23 | `'assets/logo_transparent.png'` | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `lib/pages/login/login_view.dart` | 38 | `'assets/banner_transparent.png'` | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `lib/pages/intro/intro_page.dart` | 88 | `'./assets/banner_transparent.png'` | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |

### Konfigurationsdateien

| Datei | Zeile | Referenz | SPDX vorhanden | Original Copyright | Fork Copyright | MODIFICATIONS |
|-------|-------|----------|----------------|-------------------|----------------|---------------|
| `pubspec.yaml` | 107 | `image: "assets/info-logo.png"` (flutter_native_splash) | N/A (YAML) | N/A | N/A | N/A |
| `android/app/src/main/AndroidManifest.xml` | 39 | `android:icon="@mipmap/ic_launcher"` | ✅ AGPL-3.0-or-later | ✅ `2019-2026 FluffyChat Contributors` | ✅ `2026 Simon` | ✅ `2026-02-06/07` |

### Android XML-Dateien (Logo-Vektoren - müssen inhaltlich geändert werden)

| Datei | Komponente | SPDX vorhanden | Original Copyright | Fork Copyright | MODIFICATIONS |
|-------|------------|----------------|-------------------|----------------|---------------|
| `android/.../drawable/ic_launcher_foreground.xml` | Adaptive Icon Foreground (Cat Vector) | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `android/.../drawable/ic_launcher_monochrome.xml` | Adaptive Icon Monochrome (Cat Vector) | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `android/.../mipmap-anydpi-v26/ic_launcher.xml` | Adaptive Icon Def (refs foreground/mono) | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `android/.../values/ic_launcher_background.xml` | Icon Background Color (#FFFFFF) | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `android/.../drawable-anydpi-v24/notifications_icon.xml` | Notification Icon (Cat Vector) | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `android/.../drawable/launch_background.xml` | Splash Layout (refs `@drawable/splash`) | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `android/.../drawable-v21/launch_background.xml` | Splash Layout V21 | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `android/.../drawable-night/launch_background.xml` | Night Splash Layout | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |
| `android/.../drawable-night-v21/launch_background.xml` | Night Splash V21 | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT | ❌ FEHLT |

---

## ⚠️ BLOCKER: Neue Logo-Datei fehlt

**Die Datei `/Bilder/ffchat_no-bg.svg` existiert NICHT** — weder im Repository noch im übergeordneten Verzeichnis `/home/simon/Code/family-and-friends/`. 

**Vorhandenes FF Chat Logo**: `assets/logo.svg` enthält bereits das neue FF Chat Design (Teal Speech Bubble mit Doppel-Häkchen, `#06bbda`). Dieses SVG kann als Quelle für die Generierung aller fehlenden Assets verwendet werden.

---

## Empfohlener Lösungsansatz

### Phase 1: Asset-Generierung (Voraussetzung)
1. Aus `assets/logo.svg` alle benötigten Raster-Assets generieren:
   - Splash-Screens (5 Dichten: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
   - Notification Icons (5 Dichten, weiße Silhouette)
   - Background-Images (Solid Teal statt Purple)
   - Banner (mit "FF Chat" Wordmark statt "fluffychat")
   - Favicon
   - Snap GUI Icon
   - Fastlane Icon + Feature Graphic
2. Android Adaptive Icon Vektoren (`ic_launcher_foreground.xml`, `ic_launcher_monochrome.xml`, `notifications_icon.xml`) mit FF Chat SVG-Paths ersetzen

### Phase 2: Asset-Ersetzung
3. **REPLACE**: Alle ❌-markierten Bild-Dateien durch neue FF Chat Assets
4. **REPLACE**: Android Vector-XML-Dateien mit neuen Paths

### Phase 3: Non-Logo Code-Änderungen (aus Issue #30)
5. Snap, iOS, macOS, Linux, Fastlane Metadata, Scripts, Workflows, pubspec, Tests, GitHub Templates — wie im Issue detailliert

### Phase 4: AGPL Compliance
6. AGPL-Header zu allen modifizierten Dateien hinzufügen
7. CHANGELOG.md aktualisieren

---

## IMPLEMENTATION STEPS (Logo-bezogen, Pflichtformat)

### Bilddateien (REPLACE — Binärdateien)

1. **REPLACE**: `assets/banner_transparent.png` — Neues FF Chat Banner (Teal Bubble + "FF Chat" Text)
2. **REPLACE**: `assets/banner.png` — Neues FF Chat Banner (mit Background)
3. **REPLACE**: `assets/favicon.png` — FF Chat Favicon (Teal Bubble)
4. **REPLACE**: `android/app/src/main/res/drawable-mdpi/splash.png` — FF Chat Splash (48dp)
5. **REPLACE**: `android/app/src/main/res/drawable-hdpi/splash.png` — FF Chat Splash (72dp)
6. **REPLACE**: `android/app/src/main/res/drawable-xhdpi/splash.png` — FF Chat Splash (96dp)
7. **REPLACE**: `android/app/src/main/res/drawable-xxhdpi/splash.png` — FF Chat Splash (144dp)
8. **REPLACE**: `android/app/src/main/res/drawable-xxxhdpi/splash.png` — FF Chat Splash (192dp)
9. **REPLACE**: `android/app/src/main/res/drawable/background.png` — Teal/neutral Hintergrund
10. **REPLACE**: `android/app/src/main/res/drawable-v21/background.png` — Teal/neutral Hintergrund
11. **REPLACE**: `android/app/src/main/res/drawable-night/background.png` — Dark-Mode Hintergrund
12. **REPLACE**: `android/app/src/main/res/drawable-night-v21/background.png` — Dark-Mode Hintergrund
13. **REPLACE**: `android/app/src/main/res/drawable-mdpi/notifications_icon.png` — FF Chat Silhouette
14. **REPLACE**: `android/app/src/main/res/drawable-hdpi/notifications_icon.png" — FF Chat Silhouette
15. **REPLACE**: `android/app/src/main/res/drawable-xhdpi/notifications_icon.png" — FF Chat Silhouette
16. **REPLACE**: `android/app/src/main/res/drawable-xxhdpi/notifications_icon.png" — FF Chat Silhouette
17. **REPLACE**: `android/app/src/main/res/drawable-xxxhdpi/notifications_icon.png" — FF Chat Silhouette
18. **REPLACE**: `android/fastlane/metadata/android/en-US/images/icon.png` — FF Chat Icon
19. **REPLACE**: `android/fastlane/metadata/android/en-US/images/featureGraphic.png` — FF Chat Banner
20. **REPLACE**: `web/favicon.png` — FF Chat Favicon
21. **REPLACE**: `snap/gui/fluffychat.png` — FF Chat Icon (+ Dateiname ggf. umbenennen)

### XML Vector-Dateien (MODIFY)

22. **MODIFY**: `android/app/src/main/res/drawable/ic_launcher_foreground.xml` — SVG-Paths durch FF Chat Speech Bubble Paths ersetzen, Farbe `#4d3f92` → `#06bbda`
23. **MODIFY**: `android/app/src/main/res/drawable/ic_launcher_monochrome.xml` — SVG-Paths durch FF Chat Monochrome-Paths ersetzen
24. **MODIFY**: `android/app/src/main/res/drawable-anydpi-v24/notifications_icon.xml` — SVG-Paths durch FF Chat Speech Bubble Paths ersetzen

### Dart-Dateien (MODIFY — AGPL Header hinzufügen falls geändert)

25. **READ**: `lib/pages/login/login_view.dart:38` — Referenziert `assets/banner_transparent.png` (wird umbenannt wenn nötig)
26. **READ**: `lib/pages/intro/intro_page.dart:88` — Referenziert `./assets/banner_transparent.png`
27. **READ**: `lib/widgets/lock_screen.dart:82` — Referenziert `assets/info-logo.png` (bereits FF Chat ✅)
28. **READ**: `lib/widgets/layouts/empty_page.dart:23` — Referenziert `assets/logo_transparent.png` (bereits FF Chat ✅)
29. **READ**: `lib/utils/platform_infos.dart:104` — Referenziert `assets/logo.png` (bereits FF Chat ✅)

### AGPL-Header für ALLE modifizierten Dateien (ADD Header)

30. **MODIFY**: Jede modifizierte Datei — AGPL-Header mit `SPDX-License-Identifier: AGPL-3.0-or-later`, Original Copyright erhalten, Fork Copyright `2026 Simon`, MODIFICATIONS mit Datum `2026-02-07`
31. **MODIFY**: `CHANGELOG.md:1` — `[FORK] Complete FluffyChat to FF Chat rebranding (Issue #30)` unter `## Unreleased`

---

## Relevante Dokumentation

- **flutter_native_splash**: Konfiguriert in `pubspec.yaml:104-107`, verwendet `assets/info-logo.png` — dieses ist bereits FF Chat ✅. Nach Änderung muss `flutter pub run flutter_native_splash:create` ausgeführt werden, um Web-Splash-Assets zu regenerieren.
- **Android Adaptive Icons**: Definiert in `mipmap-anydpi-v26/ic_launcher.xml`, referenziert `ic_launcher_foreground.xml`, `ic_launcher_monochrome.xml`, `ic_launcher_background` (Farbe #FFFFFF).
- **Android Splash**: `launch_background.xml` (4 Varianten) referenziert `@drawable/splash` und `@drawable/background`.
- **Matrix Account Data Keys**: Die `im.fluffychat.*` Keys in `lib/utils/` dürfen NICHT geändert werden (Kompatibilität mit existierenden Benutzerdaten, explizit im Issue dokumentiert).
