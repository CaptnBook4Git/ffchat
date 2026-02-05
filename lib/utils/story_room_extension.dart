// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-05: Detect story rooms by displayname prefix - Simon

import 'package:matrix/matrix.dart';

/// Stories are rooms whose display name starts with `story:`.
///
/// Detection rules:
/// - Leading whitespace is ignored.
/// - Prefix check is case-insensitive.
const String _storyPrefix = 'story:';

extension StoryRoomExtension on Room {
  /// Whether this room should be treated as a story room.
  bool get isStory {
    final displayName = getLocalizedDisplayname();
    if (displayName.isEmpty) return false;
    final normalized = displayName.trimLeft();
    return normalized.toLowerCase().startsWith(_storyPrefix);
  }

  /// Returns the display name without the `story:` prefix.
  ///
  /// If the room is not a story room, returns the full display name.
  String get storyDisplayName {
    final displayName = getLocalizedDisplayname();
    if (displayName.isEmpty) return displayName;
    final normalized = displayName.trimLeft();
    if (!normalized.toLowerCase().startsWith(_storyPrefix)) return displayName;
    return normalized.substring(_storyPrefix.length).trimLeft();
  }
}
