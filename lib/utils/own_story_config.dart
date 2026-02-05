// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-05: Add own story room account-data mapping - Simon
// - 2026-02-05: Validate stored room_id before use - Simon

import 'package:matrix/matrix.dart';

extension OwnStoryConfigExtension on Client {
  static const String ownStoryAccountDataType = 'ffchat.story';

  Future<String?> getOwnStoryRoomId() async {
    await roomsLoading;
    await accountDataLoading;

    final rawContent = accountData[ownStoryAccountDataType]?.content;
    final roomId = (rawContent as Map?)?['room_id'];
    if (roomId is! String) return null;
    final trimmed = roomId.trim();
    if (trimmed.isEmpty) return null;
    // Keep validation lightweight: room ids start with '!'.
    if (!trimmed.startsWith('!')) return null;
    return trimmed;
  }

  Future<void> setOwnStoryRoomId(String roomId) async {
    await accountDataLoading;
    await setAccountData(userID!, ownStoryAccountDataType, {'room_id': roomId});
  }

  Future<Room?> getOwnStoryRoom() async {
    final roomId = await getOwnStoryRoomId();
    if (roomId == null) return null;
    return getRoomById(roomId);
  }

  Future<Room> getOrCreateOwnStoryRoom({String? nameFallback}) async {
    final existingRoom = await getOwnStoryRoom();
    if (existingRoom != null) return existingRoom;

    final fallbackName = (nameFallback?.trim().isNotEmpty ?? false)
        ? nameFallback!.trim()
        : 'My Story';
    final roomName = fallbackName.startsWith('story:')
        ? fallbackName
        : 'story:$fallbackName';

    final roomId = await createGroupChat(
      enableEncryption: true,
      groupName: roomName,
      preset: CreateRoomPreset.privateChat,
      visibility: Visibility.private,
    );

    if (getRoomById(roomId) == null) {
      await waitForRoomInSync(roomId);
    }
    final room = getRoomById(roomId)!;

    // Best-effort: ensure the room ends up encrypted.
    if (!room.encrypted) {
      try {
        await room.enableEncryption();
      } catch (_) {
        // Ignore: if encryption can't be enabled, sending will still work.
      }
    }

    await setOwnStoryRoomId(room.id);
    return room;
  }
}
