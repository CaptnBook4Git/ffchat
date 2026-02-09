// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear / FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-09: Add flexible chatroom types (Issue #25) - Simon
// - 2026-02-09: Add ChatLayoutFactory for pluggable layouts - Simon

import 'package:flutter/widgets.dart';

import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/layouts/bot_chat_layout.dart';
import 'package:fluffychat/pages/chat/layouts/normal_chat_layout.dart';
import 'package:fluffychat/pages/chat/layouts/notes_chat_layout.dart';
import 'package:fluffychat/utils/room_layout_type.dart';

abstract class ChatLayout {
  const ChatLayout();

  Widget build(BuildContext context, ChatController controller);
}

class ChatLayoutFactory {
  static Widget create(RoomLayoutType type, ChatController controller) {
    switch (type) {
      case RoomLayoutType.notes:
        return NotesChatLayout(controller: controller);
      case RoomLayoutType.bot:
        return BotChatLayout(controller: controller);
      case RoomLayoutType.normal:
      default:
        return NormalChatLayout(controller: controller);
    }
  }
}
