// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-07: Add Circles list controller page (Issue #4) - Simon

import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/circles/circles_list_view.dart';
import 'package:fluffychat/utils/circles_config.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_text_input_dialog.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';

class CirclesList extends StatefulWidget {
  const CirclesList({super.key});

  @override
  CirclesListController createState() => CirclesListController();
}

class CirclesListController extends State<CirclesList> {
  Client get client => Matrix.of(context).client;

  Future<void> createCircle() async {
    final l10n = L10n.of(context);
    final name = await showTextInputDialog(
      context: context,
      title: l10n.createCircle,
      labelText: l10n.circleName,
      okLabel: l10n.create,
      cancelLabel: l10n.cancel,
      validator: (input) => input.trim().isEmpty ? l10n.pleaseFillOut : null,
    );
    if (name == null) return;
    await showFutureLoadingDialog(
      context: context,
      future: () => client.createCircle(name),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> renameCircle(String circleId, String currentName) async {
    final l10n = L10n.of(context);
    final name = await showTextInputDialog(
      context: context,
      title: l10n.renameCircle,
      labelText: l10n.circleName,
      initialText: currentName,
      okLabel: l10n.ok,
      cancelLabel: l10n.cancel,
      validator: (input) => input.trim().isEmpty ? l10n.pleaseFillOut : null,
    );
    if (name == null) return;
    await showFutureLoadingDialog(
      context: context,
      future: () => client.renameCircle(circleId, name),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> deleteCircle(String circleId) async {
    final l10n = L10n.of(context);
    final res = await showOkCancelAlertDialog(
      context: context,
      title: l10n.deleteCircle,
      message: l10n.deleteCircleConfirmation,
      isDestructive: true,
      okLabel: l10n.delete,
      cancelLabel: l10n.cancel,
    );
    if (res != OkCancelResult.ok) return;
    await showFutureLoadingDialog(
      context: context,
      future: () => client.deleteCircle(circleId),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => CirclesListView(this);
}
