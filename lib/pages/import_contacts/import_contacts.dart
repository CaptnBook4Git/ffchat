// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-06: Add contacts import controller page - Simon

import 'package:flutter/material.dart';

import 'import_contacts_view.dart';

class ImportContactsPage extends StatefulWidget {
  const ImportContactsPage({super.key});

  @override
  State<ImportContactsPage> createState() => ImportContactsController();
}

class ImportContactsController extends State<ImportContactsPage> {
  @override
  Widget build(BuildContext context) => ImportContactsView(this);
}
