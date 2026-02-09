// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear / FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-09: Add flexible chatroom types (Issue #25) - Simon
// - 2026-02-09: Reduce typing indicator for bot layout - Simon

import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_emoji_picker.dart';
import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:fluffychat/pages/chat/chat_input_row.dart';
import 'package:fluffychat/pages/chat/reply_display.dart';

/// Bot layout: optimized for bot conversations.
///
/// Currently: uses the same timeline renderer but can be extended
/// (e.g. structured cards, thinking indicator).
class BotChatLayout extends StatelessWidget {
  final ChatController controller;

  const BotChatLayout({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomSheetPadding = FluffyThemes.isColumnMode(context) ? 16.0 : 8.0;

    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: controller.clearSingleSelectedEvent,
              child: ChatEventList(
                controller: controller,
                showTypingIndicators: false,
              ),
            ),
          ),
          if (controller.showScrollDownButton)
            Divider(height: 1, color: theme.dividerColor),
          if (controller.room.canSendDefaultMessages &&
              controller.room.membership == Membership.join)
            Container(
              margin: EdgeInsets.all(bottomSheetPadding),
              constraints: const BoxConstraints(
                maxWidth: FluffyThemes.maxTimelineWidth,
              ),
              alignment: Alignment.center,
              child: Material(
                clipBehavior: Clip.hardEdge,
                color: controller.selectedEvents.isNotEmpty
                    ? theme.colorScheme.tertiaryContainer
                    : theme.colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    ReplyDisplay(controller),
                    ChatInputRow(controller),
                    ChatEmojiPicker(controller),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
