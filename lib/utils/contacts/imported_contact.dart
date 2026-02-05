// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-06: Add imported contact model for local storage - Simon

import 'dart:convert';

class ImportedContact {
  final String id;
  final String displayName;
  final List<String> phoneNumbers;
  final List<String> emails;
  final String? mxid;
  final int updatedAt;

  const ImportedContact({
    required this.id,
    required this.displayName,
    required this.phoneNumbers,
    required this.emails,
    required this.updatedAt,
    this.mxid,
  });

  ImportedContact copyWith({
    String? displayName,
    List<String>? phoneNumbers,
    List<String>? emails,
    String? mxid,
    int? updatedAt,
  }) {
    return ImportedContact(
      id: id,
      displayName: displayName ?? this.displayName,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      emails: emails ?? this.emails,
      updatedAt: updatedAt ?? this.updatedAt,
      mxid: mxid ?? this.mxid,
    );
  }

  Map<String, Object?> toDbRow() {
    return {
      'id': id,
      'display_name': displayName,
      'phones_json': jsonEncode(phoneNumbers),
      'emails_json': jsonEncode(emails),
      'mxid': mxid,
      'updated_at': updatedAt,
    };
  }

  static ImportedContact fromDbRow(Map<String, Object?> row) {
    final phonesJson = row['phones_json']?.toString() ?? '[]';
    final emailsJson = row['emails_json']?.toString() ?? '[]';
    return ImportedContact(
      id: row['id']!.toString(),
      displayName: row['display_name']?.toString() ?? '',
      phoneNumbers: (jsonDecode(phonesJson) as List)
          .map((e) => e.toString())
          .toList(),
      emails: (jsonDecode(emailsJson) as List)
          .map((e) => e.toString())
          .toList(),
      mxid: row['mxid']?.toString(),
      updatedAt: (row['updated_at'] as int?) ?? 0,
    );
  }
}
