// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear / FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-09: Add flexible chatroom types (Issue #25) - Simon
// - 2026-02-09: Refactor body into pluggable layouts - Simon
// - 2026-02-09: Add notes overview drawer action for notes layout - Simon
// - 2026-02-09: Route notes drawer opening via controller notesScaffoldKey - Simon
// - 2026-02-09: Provide notes endDrawer at ChatView scaffold level - Simon
// - 2026-02-09: Align scroll-down FAB color with primaryContainer (Issue #25) - Simon
// - 2026-02-09: Show add-note button in AppBar on mobile (Issue #25) - Simon
// - 2026-02-09: Key notes layout to allow AppBar toggle (Issue #25) - Simon
// - 2026-02-09: Show add-note action only when user can send (Issue #25) - Simon

import 'package:flutter/material.dart';

import 'package:badges/badges.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_list_tile.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title.dart';

import 'package:fluffychat/pages/chat/encryption_button.dart';
import 'package:fluffychat/pages/chat/pinned_events.dart';
import 'package:fluffychat/utils/account_config.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/pages/chat/layouts/chat_layout_factory.dart';
import 'package:fluffychat/pages/chat/layouts/notes_chat_layout.dart';
import 'package:fluffychat/widgets/chat_settings_popup_menu.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/unread_rooms_badge.dart';
import 'package:fluffychat/utils/room_layout_type.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import '../../utils/stream_extension.dart';

enum _EventContextAction { info, report }

class ChatView extends StatelessWidget {
  final ChatController controller;

  const ChatView(this.controller, {super.key});

  List<Widget> _appBarActions(BuildContext context) {
    if (controller.selectMode) {
      return [
        if (controller.canEditSelectedEvents)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: L10n.of(context).edit,
            onPressed: controller.editSelectedEventAction,
          ),
        if (controller.selectedEvents.length == 1 &&
            controller.activeThreadId == null &&
            controller.room.canSendDefaultMessages)
          IconButton(
            icon: const Icon(Icons.message_outlined),
            tooltip: L10n.of(context).replyInThread,
            onPressed: () => controller.enterThread(
              controller.selectedEvents.single.eventId,
            ),
          ),
        IconButton(
          icon: const Icon(Icons.copy_outlined),
          tooltip: L10n.of(context).copyToClipboard,
          onPressed: controller.copyEventsAction,
        ),
        if (controller.canRedactSelectedEvents)
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            tooltip: L10n.of(context).redactMessage,
            onPressed: controller.redactEventsAction,
          ),
        if (controller.selectedEvents.length == 1)
          PopupMenuButton<_EventContextAction>(
            useRootNavigator: true,
            onSelected: (action) {
              switch (action) {
                case _EventContextAction.info:
                  controller.showEventInfo();
                  controller.clearSelectedEvents();
                  break;
                case _EventContextAction.report:
                  controller.reportEventAction();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (controller.canPinSelectedEvents)
                PopupMenuItem(
                  onTap: controller.pinEvent,
                  value: null,
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      const Icon(Icons.push_pin_outlined),
                      const SizedBox(width: 12),
                      Text(L10n.of(context).pinMessage),
                    ],
                  ),
                ),
              if (controller.canSaveSelectedEvent)
                PopupMenuItem(
                  onTap: () => controller.saveSelectedEvent(context),
                  value: null,
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      const Icon(Icons.download_outlined),
                      const SizedBox(width: 12),
                      Text(L10n.of(context).downloadFile),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: _EventContextAction.info,
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    const Icon(Icons.info_outlined),
                    const SizedBox(width: 12),
                    Text(L10n.of(context).messageInfo),
                  ],
                ),
              ),
              if (controller.selectedEvents.single.status.isSent)
                PopupMenuItem(
                  value: _EventContextAction.report,
                  child: Row(
                    mainAxisSize: .min,
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(L10n.of(context).reportMessage),
                    ],
                  ),
                ),
            ],
          ),
      ];
    } else if (!controller.room.isArchived) {
      return [
        if (controller.layoutType == RoomLayoutType.notes &&
            PlatformInfos.isMobile &&
            controller.room.canSendDefaultMessages &&
            controller.room.membership == Membership.join)
          IconButton(
            icon: const Icon(Icons.add_outlined),
            tooltip: L10n.of(context).newNotes,
            onPressed: controller.toggleNoteInput,
          ),
        if (controller.layoutType == RoomLayoutType.notes)
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.notes_outlined),
              tooltip: L10n.of(context).notesOverview,
              onPressed: () =>
                  controller.notesScaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        if (AppSettings.experimentalVoip.value &&
            Matrix.of(context).voipPlugin != null &&
            controller.room.isDirectChat)
          IconButton(
            onPressed: controller.onPhoneButtonTap,
            icon: const Icon(Icons.call_outlined),
            tooltip: L10n.of(context).placeCall,
          ),
        EncryptionButton(controller.room),
        ChatSettingsPopupMenu(controller.room, true),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (controller.room.membership == Membership.invite) {
      showFutureLoadingDialog(
        context: context,
        future: () => controller.room.join(),
        exceptionContext: ExceptionContext.joinRoom,
      );
    }
    final scrollUpBannerEventId = controller.scrollUpBannerEventId;

    return PopScope(
      canPop:
          controller.selectedEvents.isEmpty &&
          !controller.showEmojiPicker &&
          controller.activeThreadId == null,
      onPopInvokedWithResult: (pop, _) async {
        if (pop) return;
        if (controller.selectedEvents.isNotEmpty) {
          controller.clearSelectedEvents();
        } else if (controller.showEmojiPicker) {
          controller.emojiPickerAction();
        } else if (controller.activeThreadId != null) {
          controller.closeThread();
        }
      },
      child: StreamBuilder(
        stream: controller.room.client.onRoomState.stream
            .where((update) => update.roomId == controller.room.id)
            .rateLimit(const Duration(seconds: 1)),
        builder: (context, snapshot) => FutureBuilder(
          future: controller.loadTimelineFuture,
          builder: (BuildContext context, snapshot) {
            var appbarBottomHeight = 0.0;
            final activeThreadId = controller.activeThreadId;
            if (activeThreadId != null) {
              appbarBottomHeight += ChatAppBarListTile.fixedHeight;
            }
            if (controller.room.pinnedEventIds.isNotEmpty &&
                activeThreadId == null) {
              appbarBottomHeight += ChatAppBarListTile.fixedHeight;
            }
            if (scrollUpBannerEventId != null && activeThreadId == null) {
              appbarBottomHeight += ChatAppBarListTile.fixedHeight;
            }
            return Scaffold(
              appBar: AppBar(
                actionsIconTheme: IconThemeData(
                  color: controller.selectedEvents.isEmpty
                      ? null
                      : theme.colorScheme.onTertiaryContainer,
                ),
                backgroundColor: controller.selectedEvents.isEmpty
                    ? controller.activeThreadId != null
                          ? theme.colorScheme.secondaryContainer
                          : null
                    : theme.colorScheme.tertiaryContainer,
                automaticallyImplyLeading: false,
                leading: controller.selectMode
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: controller.clearSelectedEvents,
                        tooltip: L10n.of(context).close,
                        color: theme.colorScheme.onTertiaryContainer,
                      )
                    : activeThreadId != null
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: controller.closeThread,
                        tooltip: L10n.of(context).backToMainChat,
                        color: theme.colorScheme.onSecondaryContainer,
                      )
                    : FluffyThemes.isColumnMode(context)
                    ? null
                    : StreamBuilder<Object>(
                        stream: Matrix.of(context).client.onSync.stream.where(
                          (syncUpdate) => syncUpdate.hasRoomUpdate,
                        ),
                        builder: (context, _) => UnreadRoomsBadge(
                          filter: (r) => r.id != controller.roomId,
                          badgePosition: BadgePosition.topEnd(end: 8, top: 4),
                          child: const Center(child: BackButton()),
                        ),
                      ),
                titleSpacing: FluffyThemes.isColumnMode(context) ? 24 : 0,
                title: ChatAppBarTitle(controller),
                actions: _appBarActions(context),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(appbarBottomHeight),
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      PinnedEvents(controller),
                      if (activeThreadId != null)
                        SizedBox(
                          height: ChatAppBarListTile.fixedHeight,
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () =>
                                  controller.scrollToEventId(activeThreadId),
                              icon: const Icon(Icons.message),
                              label: Text(L10n.of(context).replyInThread),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    theme.colorScheme.onSecondaryContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (scrollUpBannerEventId != null &&
                          activeThreadId == null)
                        ChatAppBarListTile(
                          leading: IconButton(
                            color: theme.colorScheme.onSurfaceVariant,
                            icon: const Icon(Icons.close),
                            tooltip: L10n.of(context).close,
                            onPressed: () {
                              controller.discardScrollUpBannerEventId();
                              controller.setReadMarker();
                            },
                          ),
                          title: L10n.of(context).jumpToLastReadMessage,
                          trailing: TextButton(
                            onPressed: () {
                              controller.scrollToEventId(scrollUpBannerEventId);
                              controller.discardScrollUpBannerEventId();
                            },
                            child: Text(L10n.of(context).jump),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              floatingActionButton:
                  controller.showScrollDownButton &&
                      controller.selectedEvents.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 56.0),
                      child: FloatingActionButton(
                        onPressed: controller.scrollDown,
                        heroTag: null,
                        mini: true,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        child: const Icon(Icons.arrow_downward_outlined),
                      ),
                    )
                  : null,
              body: _ChatLayoutKeyed(controller: controller),
            );
          },
        ),
      ),
    );
  }
}

class _ChatLayoutKeyed extends StatelessWidget {
  final ChatController controller;
  const _ChatLayoutKeyed({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.layoutType == RoomLayoutType.notes) {
      return NotesChatLayout(
        key: controller.notesLayoutKey,
        controller: controller,
      );
    }
    return ChatLayoutFactory.create(controller.layoutType, controller);
  }
}
