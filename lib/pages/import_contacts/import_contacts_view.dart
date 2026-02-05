// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-06: Implement contacts import UI and identity matching - Simon
// - 2026-02-06: Fix identity matching retry by delegating hashing to client - Simon

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/import_contacts/import_contacts.dart';
import 'package:fluffychat/utils/contacts/contacts_repository.dart';
import 'package:fluffychat/utils/contacts/identity_lookup_client.dart';
import 'package:fluffychat/utils/contacts/imported_contact.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';

class ImportContactsView extends StatefulWidget {
  final ImportContactsController controller;

  const ImportContactsView(this.controller, {super.key});

  @override
  State<ImportContactsView> createState() => ImportContactsViewState();
}

class ImportContactsViewState extends State<ImportContactsView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _loading = true;
  bool _permissionDenied = false;
  String? _error;
  int _count = 0;
  List<ImportedContact> _contacts = const [];

  bool _matchingEnabled = AppSettings.contactsMatchingEnabled.value;

  ContactsRepository get _repo {
    final clientName = Matrix.of(context).client.clientName;
    return ContactsRepository.forClientName(clientName);
  }

  @override
  void initState() {
    super.initState();
    _reload();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), _reload);
  }

  Future<void> _reload() async {
    if (!PlatformInfos.isMobile) {
      setState(() {
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final count = await _repo.count();
      final contacts = await _repo.list(
        query: _searchController.text,
        limit: 2000,
      );
      if (!mounted) return;
      setState(() {
        _count = count;
        _contacts = contacts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static String _normalizePhone(String phone) {
    final trimmed = phone.trim();
    final out = StringBuffer();
    for (final rune in trimmed.runes) {
      final c = String.fromCharCode(rune);
      final isDigit = c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
      if (isDigit) {
        out.write(c);
        continue;
      }
      if (c == '+' && out.isEmpty) {
        out.write(c);
      }
    }
    return out.toString();
  }

  Future<void> _importOrRefresh({required bool doMatching}) async {
    setState(() {
      _permissionDenied = false;
      _error = null;
    });

    final granted = await FlutterContacts.requestPermission();
    if (!granted) {
      if (!mounted) return;
      setState(() {
        _permissionDenied = true;
      });
      return;
    }

    final result = await showFutureLoadingDialog(
      context: context,
      future: () async {
        final raw = await FlutterContacts.getContacts(withProperties: true);
        final now = DateTime.now().millisecondsSinceEpoch;
        final imported = <ImportedContact>[];
        for (final c in raw) {
          final name = c.displayName.trim();
          final phones = <String>{};
          for (final p in c.phones) {
            final n = _normalizePhone(p.number);
            if (n.isNotEmpty) phones.add(n);
          }
          final emails = <String>{};
          for (final e in c.emails) {
            final n = _normalizeEmail(e.address);
            if (n.isNotEmpty) emails.add(n);
          }
          imported.add(
            ImportedContact(
              id: c.id,
              displayName: name.isEmpty ? L10n.of(context).unknownDevice : name,
              phoneNumbers: phones.toList()..sort(),
              emails: emails.toList()..sort(),
              updatedAt: now,
            ),
          );
        }

        await _repo.clear();
        await _repo.upsertAll(imported);
        await AppSettings.contactsLastImportAt.setItem(now);

        if (doMatching && _matchingEnabled) {
          await _runIdentityLookup(imported);
        }
      },
    );
    if (result.error != null) {
      setState(() {
        _error = result.error.toString();
      });
    }

    await _reload();
  }

  Future<void> _runIdentityLookup(List<ImportedContact> imported) async {
    final client = Matrix.of(context).client;
    final wellKnown = await client.getWellknown();
    final identityServerUrl = wellKnown.mIdentityServer?.baseUrl;
    if (identityServerUrl == null || identityServerUrl.toString().isEmpty) {
      return;
    }

    final identity = IdentityLookupClient(baseUrl: identityServerUrl);

    final pidsByContactId = <String, List<({String medium, String address})>>{};
    final allPids = <({String medium, String address})>[];
    for (final c in imported) {
      final pids = <({String medium, String address})>[];
      for (final email in c.emails) {
        pids.add((medium: 'email', address: email));
      }
      for (final phone in c.phoneNumbers) {
        pids.add((medium: 'msisdn', address: phone));
      }
      if (pids.isEmpty) continue;
      pidsByContactId[c.id] = pids;
      allPids.addAll(pids);
    }

    if (allPids.isEmpty) return;

    final resolved = await identity.lookup3pids(threepids: allPids);
    if (resolved.isEmpty) return;

    final updated = <ImportedContact>[];
    for (final c in imported) {
      final pids = pidsByContactId[c.id];
      if (pids == null) {
        updated.add(c);
        continue;
      }
      final mxid = pids
          .map(
            (pid) =>
                resolved[IdentityLookupClient.threePidKey(
                  medium: pid.medium,
                  address: pid.address,
                )],
          )
          .whereType<String>()
          .firstOrNull;
      updated.add(c.copyWith(mxid: mxid));
    }

    await _repo.upsertAll(updated);
  }

  Future<void> _deleteImported() async {
    final result = await showFutureLoadingDialog(
      context: context,
      future: () async {
        await _repo.clear();
        await AppSettings.contactsLastImportAt.setItem(0);
      },
    );
    if (result.error != null) {
      setState(() {
        _error = result.error.toString();
      });
    }
    await _reload();
  }

  Future<void> _startChat(String mxid) async {
    final client = Matrix.of(context).client;
    final router = GoRouter.of(context);
    final roomIdResult = await showFutureLoadingDialog(
      context: context,
      future: () => client.startDirectChat(mxid),
    );
    final roomId = roomIdResult.result;
    if (roomId == null) return;
    router.go('/rooms/$roomId');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!PlatformInfos.isMobile) {
      return Scaffold(
        appBar: AppBar(title: Text(L10n.of(context).importContacts)),
        body: Center(child: Text(L10n.of(context).featureNotAvailable)),
      );
    }

    final lastImportAt = AppSettings.contactsLastImportAt.value;
    final lastImportText = lastImportAt <= 0
        ? L10n.of(context).unknownDevice
        : DateTime.fromMillisecondsSinceEpoch(
            lastImportAt,
          ).toLocal().toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).importContacts),
        actions: [
          IconButton(
            tooltip: L10n.of(context).delete,
            onPressed: _count == 0 ? null : _deleteImported,
            icon: const Icon(Icons.delete_outlined),
          ),
        ],
      ),
      body: MaxWidthBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: L10n.of(context).search,
                  filled: true,
                  fillColor: theme.colorScheme.secondaryContainer,
                  prefixIcon: const Icon(Icons.search_outlined),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      L10n.of(context).importedContactsCount(_count),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                  Text(
                    '${L10n.of(context).lastSeenTime}: $lastImportText',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            SwitchListTile.adaptive(
              title: Text(L10n.of(context).importContactsMatchingTitle),
              subtitle: Text(L10n.of(context).importContactsMatchingSubtitle),
              value: _matchingEnabled,
              onChanged: (v) async {
                await AppSettings.contactsMatchingEnabled.setItem(v);
                setState(() {
                  _matchingEnabled = v;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _loading
                          ? null
                          : () => _importOrRefresh(doMatching: true),
                      icon: const Icon(Icons.sync_outlined),
                      label: Text(L10n.of(context).importNow),
                    ),
                  ),
                ],
              ),
            ),
            if (_permissionDenied)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  L10n.of(context).noPermission,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator.adaptive())
                  : _contacts.isEmpty
                  ? Center(child: Text(L10n.of(context).noResultsFound))
                  : ListView.builder(
                      itemCount: _contacts.length,
                      itemBuilder: (context, i) {
                        final c = _contacts[i];
                        final subtitle = <String>[
                          if (c.mxid != null) c.mxid!,
                          if (c.emails.isNotEmpty) c.emails.first,
                          if (c.phoneNumbers.isNotEmpty) c.phoneNumbers.first,
                        ].join(' · ');
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              c.displayName.isEmpty
                                  ? '?'
                                  : c.displayName.characters.first
                                        .toUpperCase(),
                            ),
                          ),
                          title: Text(c.displayName),
                          subtitle: subtitle.isEmpty ? null : Text(subtitle),
                          trailing: c.mxid == null
                              ? IconButton(
                                  tooltip: L10n.of(context).searchForUsers,
                                  onPressed: () {
                                    final query =
                                        c.emails.firstOrNull ??
                                        c.phoneNumbers.firstOrNull ??
                                        c.displayName;
                                    context.go(
                                      '/rooms/newprivatechat',
                                      extra: query,
                                    );
                                  },
                                  icon: const Icon(Icons.search_outlined),
                                )
                              : IconButton(
                                  tooltip: L10n.of(context).startConversation,
                                  onPressed: () => _startChat(c.mxid!),
                                  icon: const Icon(Icons.chat_bubble_outline),
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
