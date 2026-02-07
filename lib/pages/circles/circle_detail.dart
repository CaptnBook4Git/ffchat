// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-07: Add Circle detail controller page (Issue #4) - Simon

import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/circles/circle_detail_view.dart';
import 'package:fluffychat/utils/circles_config.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_modal_action_popup.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_text_input_dialog.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';

class CircleDetail extends StatefulWidget {
  final String circleId;

  const CircleDetail({super.key, required this.circleId});

  @override
  CircleDetailController createState() => CircleDetailController();
}

class CircleDetailController extends State<CircleDetail> {
  Client get client => Matrix.of(context).client;

  Circle? get circle {
    try {
      return client.circles.firstWhere((c) => c.id == widget.circleId);
    } catch (_) {
      return null;
    }
  }

  Future<void> renameCircle() async {
    final l10n = L10n.of(context);
    final current = circle;
    if (current == null) return;
    final name = await showTextInputDialog(
      context: context,
      title: l10n.renameCircle,
      labelText: l10n.circleName,
      initialText: current.name,
      okLabel: l10n.ok,
      cancelLabel: l10n.cancel,
      validator: (input) => input.trim().isEmpty ? l10n.pleaseFillOut : null,
    );
    if (name == null) return;
    await showFutureLoadingDialog(
      context: context,
      future: () => client.renameCircle(widget.circleId, name),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> addMember() async {
    final l10n = L10n.of(context);
    final current = circle;
    if (current == null) return;

    final contacts = client.rooms
        .where((r) => r.isDirectChat)
        .map((r) => r.unsafeGetUserFromMemoryOrFallback(r.directChatMatrixID!))
        .toList();
    contacts.sort(
      (a, b) => a.calcDisplayname().toLowerCase().compareTo(
        b.calcDisplayname().toLowerCase(),
      ),
    );

    const manualValue = '__manual__';
    final actions = <AdaptiveModalAction<String>>[
      AdaptiveModalAction(
        label: l10n.user,
        value: manualValue,
        icon: const Icon(Icons.edit_outlined),
        isDefaultAction: true,
      ),
      ...contacts.map(
        (u) => AdaptiveModalAction(
          label: '${u.calcDisplayname()} · ${u.id}',
          value: u.id,
          icon: Icon(
            current.members.contains(u.id)
                ? Icons.check_circle_outline
                : Icons.person_add_alt_outlined,
          ),
        ),
      ),
    ];

    final selected = await showModalActionPopup<String>(
      context: context,
      title: l10n.addMember,
      cancelLabel: l10n.cancel,
      actions: actions,
    );
    if (selected == null) return;

    String? userId;
    if (selected == manualValue) {
      userId = await showTextInputDialog(
        context: context,
        title: l10n.addMember,
        labelText: l10n.user,
        hintText: '@alice:example.org',
        okLabel: l10n.ok,
        cancelLabel: l10n.cancel,
        validator: (input) => input.trim().isEmpty ? l10n.pleaseFillOut : null,
      );
    } else {
      userId = selected;
    }

    if (userId == null || userId.trim().isEmpty) return;
    await showFutureLoadingDialog(
      context: context,
      future: () => client.addMemberToCircle(widget.circleId, userId!),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> removeMember(String userId) async {
    await showFutureLoadingDialog(
      context: context,
      future: () => client.removeMemberFromCircle(widget.circleId, userId),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => CircleDetailView(this);
}
