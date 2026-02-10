// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear / FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-09: Add flexible chatroom types (Issue #25) - Simon
// - 2026-02-09: Extract normal layout from ChatView body - Simon

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_emoji_picker.dart';
import 'package:fluffychat/pages/chat/chat_event_list.dart';
import 'package:fluffychat/pages/chat/chat_input_row.dart';
import 'package:fluffychat/pages/chat/reply_display.dart';
import 'package:fluffychat/utils/account_config.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mxc_image.dart';

/// Standard chat layout (extracted from chat_view.dart lines 307-420).
class NormalChatLayout extends StatelessWidget {
  final ChatController controller;

  const NormalChatLayout({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomSheetPadding = FluffyThemes.isColumnMode(context) ? 16.0 : 8.0;

    final accountConfig = Matrix.of(context).client.applicationAccountConfig;

    return DropTarget(
      onDragDone: controller.onDragDone,
      onDragEntered: controller.onDragEntered,
      onDragExited: controller.onDragExited,
      child: Stack(
        children: <Widget>[
          if (accountConfig.wallpaperUrl != null)
            Opacity(
              opacity: accountConfig.wallpaperOpacity ?? 0.5,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: accountConfig.wallpaperBlur ?? 0.0,
                  sigmaY: accountConfig.wallpaperBlur ?? 0.0,
                ),
                child: MxcImage(
                  cacheKey: accountConfig.wallpaperUrl.toString(),
                  uri: accountConfig.wallpaperUrl,
                  fit: BoxFit.cover,
                  height: MediaQuery.sizeOf(context).height,
                  width: MediaQuery.sizeOf(context).width,
                  isThumbnail: false,
                  placeholder: (_) => Container(),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    onTap: controller.clearSingleSelectedEvent,
                    child: ChatEventList(controller: controller),
                  ),
                ),
                if (controller.showScrollDownButton)
                  Divider(height: 1, color: theme.dividerColor),
                if (controller.room.isExtinct)
                  Container(
                    margin: EdgeInsets.all(bottomSheetPadding),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chevron_right),
                      label: Text(L10n.of(context).enterNewChat),
                      onPressed: controller.goToNewRoomAction,
                    ),
                  )
                else if (controller.room.canSendDefaultMessages &&
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
                      child: controller.room.isAbandonedDMRoom == true
                          ? Row(
                              mainAxisAlignment: .spaceEvenly,
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                    foregroundColor: theme.colorScheme.error,
                                  ),
                                  icon: const Icon(Icons.archive_outlined),
                                  onPressed: controller.leaveChat,
                                  label: Text(L10n.of(context).leave),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                  ),
                                  icon: const Icon(Icons.forum_outlined),
                                  onPressed: controller.recreateChat,
                                  label: Text(L10n.of(context).reopenChat),
                                ),
                              ],
                            )
                          : Column(
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
          ),
          if (controller.dragging)
            Container(
              color: theme.scaffoldBackgroundColor.withAlpha(230),
              alignment: Alignment.center,
              child: const Icon(Icons.upload_outlined, size: 100),
            ),
        ],
      ),
    );
  }
}
