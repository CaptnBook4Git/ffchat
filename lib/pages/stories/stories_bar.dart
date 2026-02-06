// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-05: Add horizontal stories bar widget - Simon
// - 2026-02-05: Add "add to story" action - Simon
// - 2026-02-06: Fix story room naming bug (Issue #15) - Simon
// - 2026-02-06: Update story room naming to use localpart (Issue #15) - Simon
// - 2026-02-06: Add solid ring indicator for unseen stories (Issue #27) - Simon

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat/send_file_dialog.dart';
import 'package:fluffychat/utils/file_selector.dart';
import 'package:fluffychat/utils/own_story_config.dart';
import 'package:fluffychat/utils/story_room_extension.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';

class StoriesBar extends StatefulWidget {
  final List<Room> rooms;
  final void Function(Room) onTap;

  const StoriesBar({super.key, required this.rooms, required this.onTap});

  static const double height = 106;

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  bool _adding = false;

  Future<void> _addToOwnStory(BuildContext context) async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      final client = Matrix.of(context).client;

      final roomResult = await showFutureLoadingDialog<Room>(
        context: context,
        future: () async {
          String? nameFallback;
          final localpart = client.userID?.localpart;
          if (localpart != null && localpart.isNotEmpty) {
            nameFallback = localpart;
          }
          return client.getOrCreateOwnStoryRoom(nameFallback: nameFallback);
        },
      );
      final storyRoom = roomResult.result;
      if (!context.mounted || roomResult.error != null || storyRoom == null) {
        return;
      }

      final files = await selectFiles(
        context,
        type: FileType.image,
        allowMultiple: true,
      );
      if (!context.mounted || files.isEmpty) return;

      await showAdaptiveDialog(
        context: context,
        builder: (c) => SendFileDialog(
          files: files,
          room: storyRoom,
          outerContext: context,
          threadRootEventId: null,
          threadLastEventId: null,
        ),
      );
      if (!context.mounted) return;

      context.go('/rooms/story/${storyRoom.id}');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = widget.rooms;
    final theme = Theme.of(context);
    return SizedBox(
      height: StoriesBar.height,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: 8.0,
          right: 8.0,
          top: 8.0,
          bottom: 6.0,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            final l10n = L10n.of(context);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                width: 64,
                child: Column(
                  children: [
                    AnimatedScale(
                      scale: 1.0,
                      duration: FluffyThemes.animationDuration,
                      curve: FluffyThemes.animationCurve,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(48),
                        onTap: _adding ? null : () => _addToOwnStory(context),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(48),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            height: 56,
                            width: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(48),
                            ),
                            child: _adding
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator.adaptive(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.add,
                                    color: theme.colorScheme.onSurface,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        l10n.addToStory,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final room = rooms[i - 1];
          final label = room.storyDisplayName;
          final hasUnseenStory = room.hasNewMessages;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  AnimatedScale(
                    scale: 1.0,
                    duration: FluffyThemes.animationDuration,
                    curve: FluffyThemes.animationCurve,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(48),
                      onTap: () => widget.onTap(room),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: hasUnseenStory
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(48),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(48),
                          ),
                          padding: const EdgeInsets.all(3.0),
                          child: Avatar(
                            name: label,
                            mxContent: room.avatar,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
