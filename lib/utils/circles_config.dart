// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-07: Create Circles data model and service layer (Issue #4) - Simon

import 'dart:convert';
import 'dart:math';

import 'package:matrix/matrix.dart';

class Circle {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> members;

  const Circle({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.members,
  });

  Circle copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? members,
  }) => Circle(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    members: members ?? this.members,
  );

  factory Circle.fromJson(Map<String, Object?> json) {
    final members = <String>[];
    final rawMembers = json['members'];
    if (rawMembers is List) {
      for (final m in rawMembers) {
        if (m is String && m.trim().isNotEmpty) {
          members.add(m.trim());
        }
      }
    }

    DateTime? parseDate(Object? v) {
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final createdAt = parseDate(json['created_at'])?.toUtc();
    final updatedAt = parseDate(json['updated_at'])?.toUtc();
    final now = DateTime.now().toUtc();

    return Circle(
      id: (json['id'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? createdAt ?? now,
      members: members,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'members': members,
  };
}

class _CirclesAccountData {
  final int version;
  final List<Circle> circles;

  const _CirclesAccountData({required this.version, required this.circles});

  factory _CirclesAccountData.empty() =>
      const _CirclesAccountData(version: 1, circles: []);

  factory _CirclesAccountData.fromJson(Object? content) {
    if (content is! Map) return _CirclesAccountData.empty();
    final versionRaw = content['version'];
    final version = versionRaw is int ? versionRaw : 1;
    final circles = <Circle>[];
    final rawCircles = content['circles'];
    if (rawCircles is List) {
      for (final raw in rawCircles) {
        if (raw is Map) {
          final mapped = raw.map((k, v) => MapEntry(k.toString(), v));
          final circle = Circle.fromJson(mapped);
          if (circle.id.isEmpty || circle.name.isEmpty) continue;
          circles.add(
            circle.copyWith(members: circle.members.toSet().toList()),
          );
        }
      }
    }
    return _CirclesAccountData(version: version, circles: circles);
  }

  Map<String, Object?> toJson() => {
    'version': version,
    'circles': circles.map((c) => c.toJson()).toList(),
  };
}

extension CirclesConfigExtension on Client {
  static const String circlesAccountDataType = 'im.ffchat.circles';

  _CirclesAccountData _circlesConfig() => _CirclesAccountData.fromJson(
    accountData[circlesAccountDataType]?.content,
  );

  List<Circle> get circles => _circlesConfig().circles;

  List<Circle> circlesForUser(String userId) =>
      circles.where((c) => c.members.contains(userId)).toList(growable: false);

  Future<void> _saveCircles(List<Circle> circles) async {
    await accountDataLoading;
    await setAccountData(
      userID!,
      circlesAccountDataType,
      _CirclesAccountData(version: 1, circles: circles).toJson(),
    );
  }

  String _newCircleId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    final token = base64UrlEncode(bytes).replaceAll('=', '');
    return 'c_$token';
  }

  Future<Circle> createCircle(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Circle name must not be empty');
    }
    final now = DateTime.now().toUtc();
    final circle = Circle(
      id: _newCircleId(),
      name: trimmed,
      createdAt: now,
      updatedAt: now,
      members: const [],
    );
    final updated = [...circles, circle];
    await _saveCircles(updated);
    return circle;
  }

  Future<void> renameCircle(String circleId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        newName,
        'newName',
        'Circle name must not be empty',
      );
    }
    final now = DateTime.now().toUtc();
    final updated = circles
        .map(
          (c) =>
              c.id == circleId ? c.copyWith(name: trimmed, updatedAt: now) : c,
        )
        .toList();
    await _saveCircles(updated);
  }

  Future<void> deleteCircle(String circleId) async {
    final updated = circles.where((c) => c.id != circleId).toList();
    await _saveCircles(updated);
  }

  Future<void> addMemberToCircle(String circleId, String userId) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now().toUtc();
    final updated = circles
        .map(
          (c) => c.id == circleId
              ? c.copyWith(
                  members: {...c.members, trimmed}.toList(),
                  updatedAt: now,
                )
              : c,
        )
        .toList();
    await _saveCircles(updated);
  }

  Future<void> removeMemberFromCircle(String circleId, String userId) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now().toUtc();
    final updated = circles
        .map(
          (c) => c.id == circleId
              ? c.copyWith(
                  members: c.members.where((m) => m != trimmed).toList(),
                  updatedAt: now,
                )
              : c,
        )
        .toList();
    await _saveCircles(updated);
  }
}
