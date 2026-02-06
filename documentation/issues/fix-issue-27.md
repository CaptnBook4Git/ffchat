# Fix Documentation - Issue #27

**Branch:** fix/issue-27-story-ring-indicator

## Problem

Der bisherige Gradient-Ring um Story-Icons bot keine visuelle Unterscheidung zwischen gesehenen und ungesehenen Stories. Zudem entsprach der Gradient nicht dem User-Wunsch nach einer flachen (Solid-Color) Optik.

## Solution

Ersatz des Gradienten durch eine Solid-Color-BoxDecoration. Nutzung von `room.hasNewMessages` zur Steuerung der Ring-Farbe (primär vs. neutral). Anpassung der Sortierung der Story-Räume.

## Changes

lib/pages/stories/stories_bar.dart, lib/pages/chat_list/chat_list.dart, CHANGELOG.md

## Verification

Visuelle Prüfung: Ring-Farbe ändert sich beim Betrachten der Story. Sortierung: Ungesehene Stories erscheinen links. AGPL-Header vorhanden.

---
*Generated automatically for Issue #27*

