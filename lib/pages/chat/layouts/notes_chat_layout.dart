// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear / FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-09: Add flexible chatroom types (Issue #25) - Simon
// - 2026-02-09: Hide avatars/receipts/typing for notes layout - Simon
// - 2026-02-09: Integrate NoteInputArea + NotesOverviewDrawer - Simon
// - 2026-02-09: Add FAB to toggle note input visibility - Simon
// - 2026-02-09: Auto-open note input on edit + close cancels edit - Simon
// - 2026-02-09: Fix mobile input close/send overlap + add close confirmation (Issue #25) - Simon
// - 2026-02-09: Align notes FAB color with scroll-down FAB (Issue #25) - Simon
// - 2026-02-09: Remove duplicate close buttons; close via FAB only (Issue #25) - Simon
// - 2026-02-09: Fix confirmClose result typing (await nullable future) - Simon
// - 2026-02-09: Move FAB away from NoteInputArea send button on mobile (Issue #25) - Simon
// - 2026-02-09: Move add-note action to AppBar on mobile (Issue #25) - Simon

import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/note_input_area.dart';
import 'package:fluffychat/widgets/notes_overview_drawer.dart';

/// Notes layout: minimal UI (no wallpaper, no drag overlay).
///
/// Note: This intentionally keeps the existing event renderer.
/// Full "no avatars/receipts/typing" would require deeper refactors.
class NotesChatLayout extends StatefulWidget {
  final ChatController controller;

  const NotesChatLayout({super.key, required this.controller});

  @override
  State<NotesChatLayout> createState() => NotesChatLayoutState();
}

class NotesChatLayoutState extends State<NotesChatLayout> {
  bool _showInput = false;
  final GlobalKey<NoteInputAreaState> _noteInputKey =
      GlobalKey<NoteInputAreaState>();

  // Keep hardcoded as l10n additions are out of scope for this UI refinement.
  String _addNoteTooltip() => 'Add note';
  String _closeTooltip() => 'Close';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;

    final canSend =
        controller.room.canSendDefaultMessages &&
        controller.room.membership == Membership.join;
    final inputVisible = _showInput || controller.editEvent != null;

    // On mobile, the default bottom-end FAB overlaps the NoteInputArea send
    // button. Move it out of the way while the input is visible.
    final fabLocation = inputVisible
        ? FloatingActionButtonLocation.endTop
        : FloatingActionButtonLocation.endFloat;

    return Scaffold(
      key: controller.notesScaffoldKey,
      endDrawer: NotesOverviewDrawer(controller: controller),
      floatingActionButtonLocation: fabLocation,
      floatingActionButton: (!PlatformInfos.isMobile && canSend)
          ? FloatingActionButton(
              onPressed: () async {
                if (inputVisible) {
                  final state = _noteInputKey.currentState;
                  final shouldClose =
                      await (state?.confirmClose() ?? Future.value(true));
                  if (!shouldClose) return;
                  controller.cancelReplyEventAction();
                  if (!mounted) return;
                  setState(() => _showInput = false);
                  return;
                }
                setState(() => _showInput = true);
              },
              tooltip: inputVisible ? _closeTooltip() : _addNoteTooltip(),
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Icon(
                inputVisible ? Icons.close_outlined : Icons.add_outlined,
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: controller.clearSingleSelectedEvent,
                child: ChatEventList(
                  controller: controller,
                  showAvatars: false,
                  showReadReceipts: false,
                  showTypingIndicators: false,
                ),
              ),
            ),
            if (controller.showScrollDownButton)
              Divider(height: 1, color: theme.dividerColor),
            if (canSend && inputVisible)
              NoteInputArea(key: _noteInputKey, controller: controller),
          ],
        ),
      ),
    );
  }

  Future<void> toggleNoteInput() async {
    final controller = widget.controller;
    final canSend =
        controller.room.canSendDefaultMessages &&
        controller.room.membership == Membership.join;
    if (!canSend) return;

    final inputVisible = _showInput || controller.editEvent != null;
    if (inputVisible) {
      final state = _noteInputKey.currentState;
      final shouldClose = await (state?.confirmClose() ?? Future.value(true));
      if (!shouldClose) return;
      controller.cancelReplyEventAction();
      if (!mounted) return;
      setState(() => _showInput = false);
      return;
    }

    if (!mounted) return;
    setState(() => _showInput = true);
  }
}
