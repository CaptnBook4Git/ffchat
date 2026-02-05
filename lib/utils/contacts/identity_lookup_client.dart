// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-06: Add public API for identity hash details lookup - Simon
// - 2026-02-06: Fix pepper retry by re-hashing 3PID lookups - Simon

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix_api_lite/utils/logs.dart';

class IdentityLookupClient {
  final Uri baseUrl;
  final http.Client _http;

  IdentityLookupClient({required this.baseUrl, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  Future<HashDetails> hashDetails() async {
    final uri = baseUrl.replace(path: '/_matrix/identity/v2/hash_details');
    final res = await _http.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Identity server hash_details failed: ${res.statusCode} ${res.body}',
      );
    }
    final json = jsonDecode(res.body) as Map<String, Object?>;
    final algorithms =
        (json['algorithms'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final pepper = json['lookup_pepper']?.toString();
    if (pepper == null || pepper.isEmpty) {
      throw Exception('Identity server did not return lookup_pepper');
    }
    if (!algorithms.contains('sha256')) {
      throw Exception('Identity server does not support sha256');
    }
    return HashDetails(pepper: pepper, algorithm: 'sha256');
  }

  static String hashAddress({
    required String address,
    required String medium,
    required String pepper,
  }) {
    final input = '$address $medium $pepper';
    final digest = sha256.convert(utf8.encode(input));
    // URL-safe base64 without padding.
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static String threePidKey({
    required String medium,
    required String address,
  }) => '$medium:$address';

  Future<Map<String, String>> lookup3pids({
    required List<({String medium, String address})> threepids,
    int batchSize = 500,
  }) async {
    if (threepids.isEmpty) return const {};

    // Deduplicate inputs to keep payload size in check.
    final unique = <String, ({String medium, String address})>{};
    for (final pid in threepids) {
      final key = threePidKey(medium: pid.medium, address: pid.address);
      unique[key] = pid;
    }
    final pids = unique.values.toList(growable: false);

    // Pepper can change. Retry once with a fresh hash_details and re-hash.
    for (var attempt = 0; attempt < 2; attempt++) {
      final details = await hashDetails();

      final hashedToKey = <String, String>{};
      final allHashes = <String>[];
      for (final pid in pids) {
        final hash = hashAddress(
          address: pid.address,
          medium: pid.medium,
          pepper: details.pepper,
        );
        hashedToKey[hash] = threePidKey(
          medium: pid.medium,
          address: pid.address,
        );
        allHashes.add(hash);
      }

      final resolved = <String, String>{};
      try {
        for (var i = 0; i < allHashes.length; i += batchSize) {
          final batch = allHashes.sublist(
            i,
            (i + batchSize) > allHashes.length
                ? allHashes.length
                : (i + batchSize),
          );
          final batchResolved = await _lookupHashedOnce(
            hashedAddresses: batch,
            hashDetails: details,
          );
          for (final entry in batchResolved.entries) {
            final key = hashedToKey[entry.key];
            if (key != null) {
              resolved[key] = entry.value;
            }
          }
        }
        return resolved;
      } on _InvalidPepperException {
        if (attempt == 0) continue;
        return const {};
      }
    }

    return const {};
  }

  Future<Map<String, String>> _lookupHashedOnce({
    required List<String> hashedAddresses,
    required HashDetails hashDetails,
  }) async {
    if (hashedAddresses.isEmpty) return const {};

    final uri = baseUrl.replace(path: '/_matrix/identity/v2/lookup');
    final res = await _http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'addresses': hashedAddresses,
        'algorithm': hashDetails.algorithm,
        'pepper': hashDetails.pepper,
      }),
    );

    if (res.statusCode == 400) {
      try {
        final body = jsonDecode(res.body) as Map<String, Object?>;
        if (body['errcode']?.toString() == 'M_INVALID_PEPPER') {
          throw const _InvalidPepperException();
        }
      } catch (_) {
        // ignore
      }
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      Logs().w('Identity server lookup failed: ${res.statusCode} ${res.body}');
      return const {};
    }

    final json = jsonDecode(res.body);
    if (json is! Map) return const {};
    final mappings = json['mappings'];

    final out = <String, String>{};
    if (mappings is Map) {
      for (final entry in mappings.entries) {
        final key = entry.key.toString();
        final v = entry.value;
        if (v is String) {
          out[key] = v;
        } else if (v is Map && v['mxid'] != null) {
          out[key] = v['mxid'].toString();
        }
      }
      return out;
    }
    if (mappings is List) {
      for (final item in mappings) {
        if (item is Map && item['address'] != null && item['mxid'] != null) {
          out[item['address'].toString()] = item['mxid'].toString();
        }
      }
    }
    return out;
  }

  Future<Map<String, String>> lookupHashed({
    required List<String> hashedAddresses,
  }) async {
    if (hashedAddresses.isEmpty) return const {};
    final hashDetails = await this.hashDetails();
    try {
      return await _lookupHashedOnce(
        hashedAddresses: hashedAddresses,
        hashDetails: hashDetails,
      );
    } on _InvalidPepperException {
      // Cannot re-hash here because we only have hashed addresses.
      return const {};
    }
  }
}

class _InvalidPepperException implements Exception {
  const _InvalidPepperException();
}

class HashDetails {
  final String pepper;
  final String algorithm;

  const HashDetails({required this.pepper, required this.algorithm});
}
