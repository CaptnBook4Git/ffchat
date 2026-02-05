// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-05: Initialize sqflite ffi for tests - Simon

// ignore_for_file: depend_on_referenced_packages

import 'dart:ffi';

import 'package:matrix/encryption/utils/key_verification.dart';
import 'package:matrix/matrix.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

Future<Client> prepareTestClient({
  bool loggedIn = false,
  Uri? homeserver,
  String id = 'FluffyChat Widget Test',
}) async {
  // sqflite_common_ffi defaults to loading `libsqlite3.so`, but on many Linux
  // environments only `libsqlite3.so.0` is present.
  open.overrideFor(
    OperatingSystem.linux,
    () => DynamicLibrary.open('libsqlite3.so.0'),
  );

  // Required for sqflite_common_ffi to locate libsqlite3.
  sqfliteFfiInit();

  homeserver ??= Uri.parse('https://fakeserver.notexisting');
  final client = Client(
    'FluffyChat Widget Tests',
    httpClient: FakeMatrixApi()
      ..api['GET']!['/.well-known/matrix/client'] = (req) => {},
    verificationMethods: {
      KeyVerificationMethod.numbers,
      KeyVerificationMethod.emoji,
    },
    importantStateEvents: <String>{
      'im.ponies.room_emotes', // we want emotes to work properly
    },
    database: await MatrixSdkDatabase.init(
      'test',
      // Use the non-isolate variant for tests. The isolate variant needs the
      // sqlite dynamic library lookup to be configured in the spawned isolate.
      database: await databaseFactoryFfiNoIsolate.openDatabase(':memory:'),
      sqfliteFactory: databaseFactoryFfiNoIsolate,
    ),
    supportedLoginTypes: {
      AuthenticationTypes.password,
      AuthenticationTypes.sso,
    },
  );
  await client.checkHomeserver(homeserver);
  if (loggedIn) {
    await client.login(
      LoginType.mLoginToken,
      identifier: AuthenticationUserIdentifier(user: '@alice:example.invalid'),
      password: '1234',
    );
  }
  return client;
}
