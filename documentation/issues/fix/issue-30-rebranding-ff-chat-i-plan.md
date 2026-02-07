# Implementation Plan: Issue #30

## Problem
Das Rebranding von FluffyChat → FF Chat ist teilweise abgeschlossen. Während einige Assets bereits das neue FF Chat-Logo enthalten, zeigen zahlreiche andere Assets (Banner, Favicon, Android Splash-Screens, Notification Icons, Vector XMLs) noch das alte FluffyChat-Branding (Purple Cat Monster) und enthalten „FluffyChat"-Text-Branding.

## Solution
Vollständige Ersetzung aller verbleibenden FluffyChat-Assets durch FF Chat-Assets. Dies beinhaltet:
1. Generierung fehlender Raster-Assets aus `assets/logo.svg`.
2. Ersetzung von Binärdateien (PNG, Favicon).
3. Aktualisierung von Android Vector-XML-Dateien.
4. Hinzufügen fehlender AGPL-Header.
5. Aktualisierung des CHANGELOG.md.

## Changes

### 1. Binärdateien (Ersetzung)
- `assets/banner_transparent.png`
- `assets/banner.png`
- `assets/favicon.png`
- `android/app/src/main/res/drawable-*/splash.png` (5 Dichten)
- `android/app/src/main/res/drawable/background.png` (und Varianten)
- `android/app/src/main/res/drawable-*/notifications_icon.png` (5 Dichten)
- `android/fastlane/metadata/android/en-US/images/icon.png`
- `android/fastlane/metadata/android/en-US/images/featureGraphic.png`
- `web/favicon.png`
- `snap/gui/fluffychat.png`

### 2. Android XML-Dateien (Vektoren)
- `android/app/src/main/res/drawable/ic_launcher_foreground.xml`
- `android/app/src/main/res/drawable/ic_launcher_monochrome.xml`
- `android/app/src/main/res/drawable-anydpi-v24/notifications_icon.xml`

### 3. Dokumentation & AGPL
- Hinzufügen von AGPL-Headern zu allen modifizierten Dateien.
- Eintrag im `CHANGELOG.md`.

## AGPL Compliance Checklist
| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `android/app/src/main/res/drawable/ic_launcher_foreground.xml` | ❌ Add | ❌ Add | ✅ 2026 Simon | ✅ 2026-02-07 |
| `android/app/src/main/res/drawable/ic_launcher_monochrome.xml` | ❌ Add | ❌ Add | ✅ 2026 Simon | ✅ 2026-02-07 |
| `android/app/src/main/res/drawable-anydpi-v24/notifications_icon.xml` | ❌ Add | ❌ Add | ✅ 2026 Simon | ✅ 2026-02-07 |
| `lib/widgets/lock_screen.dart` | ❌ Add | ❌ Add | ✅ 2026 Simon | ✅ 2026-02-07 |
| `lib/widgets/layouts/empty_page.dart` | ❌ Add | ❌ Add | ✅ 2026 Simon | ✅ 2026-02-07 |
| `lib/pages/login/login_view.dart` | ❌ Add | ❌ Add | ✅ 2026 Simon | ✅ 2026-02-07 |
| `lib/pages/intro/intro_page.dart` | ❌ Add | ❌ Add | ✅ 2026 Simon | ✅ 2026-02-07 |

## Testing
- Manuelle Prüfung der Android Splash-Screens und Notification Icons.
- Überprüfung der App-Icons (Adaptive Icons) auf einem Emulator/Device.
- Verifizierung der UI-Elemente in der App (Login-View, Intro-Page).

## Edge Cases
- Beibehalten der `im.fluffychat.*` Matrix Keys (KEINE Änderung hier).
- Korrekte Skalierung der generierten Raster-Images für verschiedene Pixeldichten.
