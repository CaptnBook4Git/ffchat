// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-05: Create story rooms via displayname prefix - Simon
// - 2026-02-09: Add flexible chatroom types (Issue #25) - Simon
// - 2026-02-09: Extend creation flow with notes/bot layout state - Simon

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart' as sdk;
import 'package:matrix/matrix.dart';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/new_group/new_group_view.dart';
import 'package:fluffychat/utils/file_selector.dart';
import 'package:fluffychat/utils/room_layout_type.dart';
import 'package:fluffychat/widgets/matrix.dart';

class NewGroup extends StatefulWidget {
  final CreateGroupType createGroupType;
  const NewGroup({this.createGroupType = CreateGroupType.group, super.key});

  @override
  NewGroupController createState() => NewGroupController();
}

class NewGroupController extends State<NewGroup> {
  TextEditingController nameController = TextEditingController();

  bool publicGroup = false;
  bool groupCanBeFound = false;

  Uint8List? avatar;

  Uri? avatarUrl;

  Object? error;

  bool loading = false;

  CreateGroupType get createGroupType =>
      _createGroupType ?? widget.createGroupType;

  CreateGroupType? _createGroupType;

  void setCreateGroupType(Set<CreateGroupType> b) =>
      setState(() => _createGroupType = b.single);

  void setPublicGroup(bool b) =>
      setState(() => publicGroup = groupCanBeFound = b);

  void setGroupCanBeFound(bool b) => setState(() => groupCanBeFound = b);

  void selectPhoto() async {
    final photo = await selectFiles(
      context,
      type: FileType.image,
      allowMultiple: false,
    );
    final bytes = await photo.singleOrNull?.readAsBytes();

    setState(() {
      avatarUrl = null;
      avatar = bytes;
    });
  }

  RoomLayoutType _selectedLayoutTypeForGroup() {
    switch (createGroupType) {
      case CreateGroupType.notes:
        return RoomLayoutType.notes;
      case CreateGroupType.bot:
        return RoomLayoutType.bot;
      case CreateGroupType.group:
      case CreateGroupType.space:
      case CreateGroupType.story:
        return RoomLayoutType.normal;
    }
  }

  Future<void> _createGroup() async {
    if (!mounted) return;
    final layoutType = _selectedLayoutTypeForGroup();
    final roomId = await Matrix.of(context).client.createGroupChat(
      visibility: groupCanBeFound
          ? sdk.Visibility.public
          : sdk.Visibility.private,
      preset: publicGroup
          ? sdk.CreateRoomPreset.publicChat
          : sdk.CreateRoomPreset.privateChat,
      groupName: nameController.text.isNotEmpty ? nameController.text : null,
      initialState: [
        if (avatar != null)
          sdk.StateEvent(
            type: sdk.EventTypes.RoomAvatar,
            content: {'url': avatarUrl.toString()},
          ),
        if (layoutType != RoomLayoutType.normal)
          sdk.StateEvent(
            type: RoomLayoutTypeCodec.eventType,
            stateKey: '',
            content: {RoomLayoutTypeCodec.contentKey: layoutType.asString},
          ),
      ],
    );
    if (!mounted) return;
    context.go('/rooms/$roomId/invite');
  }

  Future<void> _createSpace() async {
    if (!mounted) return;
    final spaceId = await Matrix.of(context).client.createRoom(
      preset: publicGroup
          ? sdk.CreateRoomPreset.publicChat
          : sdk.CreateRoomPreset.privateChat,
      creationContent: {'type': RoomCreationTypes.mSpace},
      visibility: publicGroup ? sdk.Visibility.public : null,
      roomAliasName: publicGroup
          ? nameController.text.trim().toLowerCase().replaceAll(' ', '_')
          : null,
      name: nameController.text.trim(),
      powerLevelContentOverride: {'events_default': 100},
      initialState: [
        if (avatar != null)
          sdk.StateEvent(
            type: sdk.EventTypes.RoomAvatar,
            content: {'url': avatarUrl.toString()},
          ),
      ],
    );
    if (!mounted) return;
    context.pop<String>(spaceId);
  }

  Future<void> _createStory() async {
    if (!mounted) return;
    final storyId = await Matrix.of(context).client.createRoom(
      preset: sdk.CreateRoomPreset.privateChat,
      name:
          'story:${nameController.text.isNotEmpty ? nameController.text.trim() : 'My Story'}',
      initialState: [
        if (avatar != null)
          sdk.StateEvent(
            type: sdk.EventTypes.RoomAvatar,
            content: {'url': avatarUrl.toString()},
          ),
      ],
    );
    if (!mounted) return;
    context.go('/rooms/story/$storyId');
  }

  void submitAction([dynamic _]) async {
    final client = Matrix.of(context).client;

    try {
      if (nameController.text.trim().isEmpty &&
          createGroupType == CreateGroupType.space) {
        setState(() => error = L10n.of(context).pleaseFillOut);
        return;
      }

      setState(() {
        loading = true;
        error = null;
      });

      final avatar = this.avatar;
      avatarUrl ??= avatar == null ? null : await client.uploadContent(avatar);

      if (!mounted) return;

      switch (createGroupType) {
        case CreateGroupType.group:
          await _createGroup();
        case CreateGroupType.notes:
          await _createGroup();
        case CreateGroupType.bot:
          await _createGroup();
        case CreateGroupType.space:
          await _createSpace();
        case CreateGroupType.story:
          await _createStory();
      }
    } catch (e, s) {
      sdk.Logs().d('Unable to create group', e, s);
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => NewGroupView(this);
}

enum CreateGroupType { group, notes, bot, space, story }
