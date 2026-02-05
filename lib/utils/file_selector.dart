// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-05: Add AGPL header - Simon

import 'package:flutter/widgets.dart';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';

import 'package:fluffychat/widgets/app_lock.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';

Future<List<XFile>> selectFiles(
  BuildContext context, {
  String? title,
  FileType type = FileType.any,
  bool allowMultiple = false,
}) async {
  final result = await AppLock.of(context).pauseWhile(
    showFutureLoadingDialog(
      context: context,
      future: () => FilePicker.platform.pickFiles(
        compressionQuality: 0,
        allowMultiple: allowMultiple,
        type: type,
      ),
    ),
  );
  return result.result?.xFiles ?? [];
}
