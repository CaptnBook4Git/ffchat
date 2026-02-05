// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-06: Add encrypted local storage for imported contacts - Simon

import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:matrix/matrix.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fluffychat/utils/contacts/imported_contact.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/flutter_matrix_dart_sdk_database/cipher.dart';

import 'package:fluffychat/utils/matrix_sdk_extensions/flutter_matrix_dart_sdk_database/sqlcipher_stub.dart'
    if (dart.library.io) 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

class ContactsRepository {
  ContactsRepository._(this._clientName);

  final String _clientName;
  Database? _db;
  SQfLiteEncryptionHelper? _encryptionHelper;

  static final Map<String, ContactsRepository> _instances = {};

  static ContactsRepository forClientName(String clientName) {
    return _instances.putIfAbsent(
      clientName,
      () => ContactsRepository._(clientName),
    );
  }

  Future<Database> _openDb() async {
    if (kIsWeb) {
      throw UnsupportedError('Contacts storage is not supported on web.');
    }
    if (_db != null) return _db!;

    final cipher = await getDatabaseCipher();
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();

    final factory = createDatabaseFactoryFfi(
      ffiInit: SQfLiteEncryptionHelper.ffiInit,
    );

    databaseFactory = factory;

    final directory = PlatformInfos.isIOS || PlatformInfos.isMacOS
        ? await getLibraryDirectory()
        : await getApplicationSupportDirectory();
    final path = join(directory.path, 'contacts-$_clientName.sqlite');

    _encryptionHelper = cipher == null
        ? null
        : SQfLiteEncryptionHelper(factory: factory, path: path, cipher: cipher);
    await _encryptionHelper?.ensureDatabaseFileEncrypted();

    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: _encryptionHelper?.applyPragmaKey,
        onCreate: (db, version) async {
          await db.execute('''
CREATE TABLE contacts (
  id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  phones_json TEXT NOT NULL,
  emails_json TEXT NOT NULL,
  mxid TEXT,
  updated_at INTEGER NOT NULL
);
''');
          await db.execute(
            'CREATE INDEX idx_contacts_display_name ON contacts(display_name);',
          );
        },
      ),
    );

    return _db!;
  }

  Future<List<ImportedContact>> list({String? query, int limit = 500}) async {
    final db = await _openDb();
    final q = query?.trim();
    final rows = await db.query(
      'contacts',
      where: q == null || q.isEmpty ? null : 'display_name LIKE ?',
      whereArgs: q == null || q.isEmpty ? null : ['%$q%'],
      orderBy: 'display_name COLLATE NOCASE ASC',
      limit: limit,
    );
    return rows
        .map((r) => ImportedContact.fromDbRow(r.map((k, v) => MapEntry(k, v))))
        .toList();
  }

  Future<int> count() async {
    final db = await _openDb();
    final rows = await db.rawQuery('SELECT COUNT(*) as c FROM contacts');
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> upsertAll(List<ImportedContact> contacts) async {
    final db = await _openDb();
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final c in contacts) {
        batch.insert(
          'contacts',
          c.toDbRow(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> clear() async {
    final db = await _openDb();
    await db.delete('contacts');
  }

  Future<void> setMxid(String contactId, String? mxid) async {
    final db = await _openDb();
    await db.update(
      'contacts',
      {'mxid': mxid},
      where: 'id = ?',
      whereArgs: [contactId],
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> deleteDatabaseFile() async {
    await close();
    if (kIsWeb) return;

    final directory = PlatformInfos.isIOS || PlatformInfos.isMacOS
        ? await getLibraryDirectory()
        : await getApplicationSupportDirectory();
    final path = join(directory.path, 'contacts-$_clientName.sqlite');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
