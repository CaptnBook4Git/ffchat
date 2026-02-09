// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear / FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-09: Add flexible chatroom types (Issue #25) - Simon
// - 2026-02-09: Store room layout type in custom state event - Simon

import 'package:matrix/matrix.dart';

/// Supported room layout types.
enum RoomLayoutType { normal, notes, bot }

extension RoomLayoutTypeCodec on RoomLayoutType {
  static const String eventType = 'ffchat.room_layout';
  static const String contentKey = 'type';

  static RoomLayoutType fromString(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'notes':
        return RoomLayoutType.notes;
      case 'bot':
        return RoomLayoutType.bot;
      case 'normal':
      default:
        return RoomLayoutType.normal;
    }
  }

  String get asString {
    switch (this) {
      case RoomLayoutType.normal:
        return 'normal';
      case RoomLayoutType.notes:
        return 'notes';
      case RoomLayoutType.bot:
        return 'bot';
    }
  }
}

extension RoomLayoutTypeRoomExtension on Room {
  /// Reads the room layout type from the custom state event.
  ///
  /// Missing or unknown values fall back to [RoomLayoutType.normal].
  RoomLayoutType get layoutType {
    final content = getState(RoomLayoutTypeCodec.eventType)?.content;
    final type = (content as Map?)?[RoomLayoutTypeCodec.contentKey];
    return RoomLayoutTypeCodec.fromString(type?.toString());
  }

  /// Writes the room layout type via a custom state event.
  Future<void> setLayoutType(RoomLayoutType type) => client.setRoomStateWithKey(
    id,
    RoomLayoutTypeCodec.eventType,
    '',
    {RoomLayoutTypeCodec.contentKey: type.asString},
  );
}
