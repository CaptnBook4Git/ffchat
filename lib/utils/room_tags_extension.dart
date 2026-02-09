// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear / FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-09: Add room tags state-event helpers (Issue #25) - Simon

import 'package:matrix/matrix.dart';

/// Room tags stored as a custom state event.
///
/// Event type: `im.ffchat.room_tags`
/// Content format:
/// ```json
/// {"tags": ["work", "family"], "version": 1}
/// ```
extension RoomTagsExtension on Room {
  static const String eventType = 'im.ffchat.room_tags';

  List<String> get roomTags {
    final content = getState(eventType)?.content;
    if (content is! Map) return const <String>[];
    final tags = (content as Map)['tags'];
    if (tags is! List) return const <String>[];
    return tags
        .whereType<Object?>()
        .map((e) => e?.toString().trim() ?? '')
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> setRoomTags(List<String> tags) async {
    final normalized =
        tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toSet().toList()
          ..sort();
    await client.setRoomStateWithKey(id, eventType, '', <String, Object?>{
      'tags': normalized,
      'version': 1,
    });
  }
}
