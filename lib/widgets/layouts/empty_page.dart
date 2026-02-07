// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2019-2026 FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-07: Complete FluffyChat to FF Chat rebranding - Simon

import 'dart:math';

import 'package:flutter/material.dart';

class EmptyPage extends StatelessWidget {
  static const double _width = 400;
  const EmptyPage({super.key});
  @override
  Widget build(BuildContext context) {
    final width = min(MediaQuery.sizeOf(context).width, EmptyPage._width) / 2;
    final theme = Theme.of(context);
    return Scaffold(
      // Add invisible appbar to make status bar on Android tablets bright.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        alignment: Alignment.center,
        child: Image.asset(
          'assets/logo_transparent.png',
          color: theme.colorScheme.surfaceContainerHigh,
          width: width,
          height: width,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
