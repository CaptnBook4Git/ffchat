// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-07: Add Circles list UI (Issue #4) - Simon

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/circles/circles_list.dart';
import 'package:fluffychat/utils/circles_config.dart';

class CirclesListView extends StatelessWidget {
  final CirclesListController controller;

  const CirclesListView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);

    return StreamBuilder<Object>(
      stream: controller.client.onSync.stream,
      builder: (context, _) {
        final circles = [
          ...controller.client.circles,
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return Scaffold(
          appBar: AppBar(
            leading: const Center(child: BackButton()),
            title: Text(l10n.circles),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: controller.createCircle,
            icon: const Icon(Icons.add_outlined),
            label: Text(l10n.createCircle),
          ),
          body: circles.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      l10n.noCirclesYet,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.secondary),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: circles.length,
                  itemBuilder: (context, i) {
                    final circle = circles[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        foregroundColor: theme.colorScheme.onSurface,
                        child: const Icon(Icons.group_work_outlined),
                      ),
                      title: Text(circle.name),
                      subtitle: Text(
                        l10n.circleMembers(circle.members.length),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => context.go('/rooms/circles/${circle.id}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'rename':
                              controller.renameCircle(circle.id, circle.name);
                            case 'delete':
                              controller.deleteCircle(circle.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text(l10n.renameCircle),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              l10n.deleteCircle,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
