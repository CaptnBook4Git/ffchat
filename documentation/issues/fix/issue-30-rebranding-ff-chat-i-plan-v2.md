# Implementation Plan: Issue #30 (Scaling Fix)

## Problem
Logo im Splash-Screen passt von den Dimensionen nicht. Im Login-Screen ist es viel zu groß. Es muss deutlich kleiner sein.

## Solution
1. Login-Screen: Logo auf max 128x128px begrenzen.
2. Intro-Screen: Logo auf max 200x200px begrenzen und `fitWidth` entfernen.
3. Splash-Screen (Android): Die PNGs sind ca. 2.2x zu groß für ihre jeweilige Dichte. Sie werden durch korrekt skalierte Versionen (Basis 80dp) ersetzt.

## Changes
1. `lib/pages/login/login_view.dart`: `ConstrainedBox(128x128)` um Logo.
2. `lib/pages/intro/intro_page.dart`: `ConstrainedBox(200x200)` um Logo.
3. `android/app/src/main/res/drawable-*/splash.png`: Neue, kleinere PNGs.

## AGPL Compliance Checklist
| File | SPDX | Original Copyright | Fork Copyright | Modifications |
|------|------|-------------------|----------------|---------------|
| `lib/pages/login/login_view.dart` | ✅ | ✅ | ✅ | Update entry |
| `lib/pages/intro/intro_page.dart` | ✅ | ✅ | ✅ | Update entry |

## Testing
- Manueller Check der Logo-Größe im Login- und Intro-Screen.
- Emulator-Check des Splash-Screens.
