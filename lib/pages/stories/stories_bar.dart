// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-05: Add horizontal stories bar widget - Simon

import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/utils/story_room_extension.dart';
import 'package:fluffychat/widgets/avatar.dart';

class StoriesBar extends StatelessWidget {
  final List<Room> rooms;
  final void Function(Room) onTap;

  const StoriesBar({super.key, required this.rooms, required this.onTap});

  static const double height = 106;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: 8.0,
          right: 8.0,
          top: 8.0,
          bottom: 6.0,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        itemBuilder: (context, i) {
          final room = rooms[i];
          final label = room.storyDisplayName;
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
                      onTap: () => onTap(room),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primaryContainer,
                              theme.colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
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
