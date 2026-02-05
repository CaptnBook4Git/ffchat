import 'package:matrix/matrix.dart';

/// Custom room types used in FluffyChat beyond the standard Matrix types.
abstract class CustomRoomTypes {
  /// Room type for story rooms - ephemeral content shared with contacts.
  static const String story = 'family.stories';
}

/// Extension on [Room] to provide story-related functionality.
extension StoryRoomExtension on Room {
  /// Whether this room is a story room.
  ///
  /// Story rooms use the custom room type `family.stories` set during creation.
  /// This type is immutable and stored in the `m.room.create` state event.
  bool get isStory =>
      getState(EventTypes.RoomCreate)?.content.tryGet<String>('type') ==
      CustomRoomTypes.story;

  /// Gets the custom room type if set, or null for standard rooms.
  ///
  /// Standard Matrix room types include:
  /// - `m.space` for spaces
  /// - Custom types like `family.stories` for stories
  /// - null for regular rooms/DMs
  String? get customRoomType =>
      getState(EventTypes.RoomCreate)?.content.tryGet<String>('type');
}
