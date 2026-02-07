// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-07: Add Circle detail UI (Issue #4) - Simon

import 'package:flutter/material.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/circles/circle_detail.dart';
import 'package:fluffychat/widgets/avatar.dart';

class CircleDetailView extends StatelessWidget {
  final CircleDetailController controller;

  const CircleDetailView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);

    return StreamBuilder<Object>(
      stream: controller.client.onSync.stream,
      builder: (context, _) {
        final circle = controller.circle;
        if (circle == null) {
          return Scaffold(
            appBar: AppBar(
              leading: const Center(child: BackButton()),
              title: Text(l10n.circles),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  l10n.oopsSomethingWentWrong,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          );
        }

        final members = [...circle.members]..sort();
        return Scaffold(
          appBar: AppBar(
            leading: const Center(child: BackButton()),
            title: Text(circle.name),
            actions: [
              IconButton(
                tooltip: l10n.renameCircle,
                onPressed: controller.renameCircle,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: controller.addMember,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text(l10n.addMember),
          ),
          body: members.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      l10n.circleMembers(0),
                      style: TextStyle(color: theme.colorScheme.secondary),
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final userId = members[i];
                    final display = userId.startsWith('@')
                        ? userId.substring(1).split(':').first
                        : userId.split(':').first;
                    return ListTile(
                      leading: Avatar(name: display, presenceUserId: userId),
                      title: Text(
                        display,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        userId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.colorScheme.secondary),
                      ),
                      trailing: IconButton(
                        tooltip: l10n.removeFromCircle,
                        onPressed: () => controller.removeMember(userId),
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
