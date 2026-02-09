// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear / FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-09: Add structured notes input (Issue #25) - Simon
// - 2026-02-09: Send notes as formatted m.text with im.ffchat.note - Simon
// - 2026-02-09: Fix editing notes via m.replace + add attachments/tags - Simon
// - 2026-02-09: Allow creating room tags from notes input - Simon
// - 2026-02-09: Prefill title/content when switching into edit mode - Simon
// - 2026-02-09: Add multi-attachments + tags chips for notes - Simon
// - 2026-02-09: Capture file picker into note attachments (no extra events) - Simon
// - 2026-02-09: Add hashtag→tag parsing + safe close confirmation (Issue #25) - Simon
// - 2026-02-09: Add tag manager button next to attachments (Issue #25) - Simon
// - 2026-02-09: Show square image previews for attachments while composing (Issue #25) - Simon
// - 2026-02-09: Remove internal close button; close via Notes FAB only (Issue #25) - Simon
// - 2026-02-09: Add voice message recordings as note attachments (Issue #25) - Simon

import 'package:flutter/material.dart';

import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_emoji_picker.dart';
import 'package:fluffychat/pages/chat/reply_display.dart';
import 'package:fluffychat/pages/chat/recording_input_row.dart';
import 'package:fluffychat/pages/chat/recording_view_model.dart';
import 'package:fluffychat/utils/file_selector.dart';
import 'package:fluffychat/utils/room_tags_extension.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_text_input_dialog.dart';
import 'package:fluffychat/widgets/mxc_image.dart';

/// Specialized input for notes rooms: Title + Content.
///
/// Sends a `m.text` event with an additional `im.ffchat.note` object.
class NoteInputArea extends StatefulWidget {
  final ChatController controller;

  const NoteInputArea({super.key, required this.controller});

  @override
  State<NoteInputArea> createState() => NoteInputAreaState();
}

class NoteInputAreaState extends State<NoteInputArea> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  final List<String> _selectedTags = <String>[];

  // Attachments are stored inside im.ffchat.note.attachments.
  // Existing attachments are stored as raw Matrix content maps.
  // Newly picked attachments are kept as local files until send.
  final List<_NoteAttachmentDraft> _attachments = <_NoteAttachmentDraft>[];

  String? _lastPrefilledEditEventId;

  Iterable<String> _extractHashtags(String input) sync* {
    // Dart RegExp doesn't support variable-length lookbehind, so we match a
    // non-word prefix explicitly.
    final re = RegExp(r'(^|[^0-9A-Za-z_])#([0-9A-Za-z_]+)');
    for (final m in re.allMatches(input)) {
      final tag = m.group(2);
      if (tag != null && tag.isNotEmpty) yield tag;
    }
  }

  void _prefillFromEditEvent() {
    final controller = widget.controller;
    final editEvent = controller.editEvent;
    if (editEvent == null) {
      _lastPrefilledEditEventId = null;
      return;
    }

    // Avoid overwriting while user is typing the same edit.
    if (_lastPrefilledEditEventId == editEvent.eventId) return;

    final timeline = controller.timeline;
    final display = timeline == null
        ? editEvent
        : editEvent.getDisplayEvent(timeline);
    final content = display.content;

    String title = '';
    String body = '';
    final tags = <String>[];

    final attachments = <Map<String, Object?>>[];

    if (content is Map) {
      final note = content['im.ffchat.note'];
      if (note is Map) {
        title = note['title']?.toString() ?? '';
        body = note['body']?.toString() ?? '';
        final rawTags = note['tags'];
        if (rawTags is List) {
          tags.addAll(
            rawTags
                .whereType<Object?>()
                .map((e) => e?.toString().trim() ?? '')
                .where((t) => t.isNotEmpty),
          );
        }

        final rawAttachments = note['attachments'];
        if (rawAttachments is List) {
          for (final a in rawAttachments) {
            if (a is Map) {
              attachments.add(a.cast<String, Object?>());
            }
          }
        }
      }
    }

    // Fallback for older notes without structured body.
    if (title.isEmpty && body.isEmpty) {
      final raw = display.body;
      final parts = raw.split('\n\n');
      title = parts.firstOrNull ?? '';
      body = parts.length > 1 ? parts.skip(1).join('\n\n') : '';
    }

    _titleController.text = title;
    _bodyController.text = body;

    _selectedTags
      ..clear()
      ..addAll(tags.toSet().toList()..sort());

    _attachments
      ..clear()
      ..addAll(
        attachments.map((a) => _NoteAttachmentDraft.existing(a)).toList(),
      );

    _lastPrefilledEditEventId = editEvent.eventId;
  }

  void _schedulePrefillFromEditEvent() {
    final editId = widget.controller.editEvent?.eventId;
    if (editId == null) return;
    if (_lastPrefilledEditEventId == editId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefillFromEditEvent();
    });
  }

  Future<void> _createTag() async {
    final controller = widget.controller;
    final input = await showTextInputDialog(
      context: context,
      title: 'Create tag',
      okLabel: L10n.of(context).ok,
      cancelLabel: L10n.of(context).cancel,
    );
    final tag = (input ?? '').trim();
    if (tag.isEmpty) return;
    final tags = controller.room.roomTags;
    if (!tags.contains(tag)) {
      await controller.room.setRoomTags([...tags, tag]);
    }
    if (!mounted) return;
    setState(() {
      if (!_selectedTags.contains(tag)) {
        _selectedTags.add(tag);
        _selectedTags.sort();
      }
    });
  }

  Future<void> _openTagManager() async {
    final controller = widget.controller;
    var roomTags = controller.room.roomTags;
    final selected = <String>{..._selectedTags};

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog.adaptive(
          title: const Text('Tags'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (roomTags.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('No tags yet.'),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...roomTags.map(
                        (t) => FilterChip(
                          label: Text(t),
                          selected: selected.contains(t),
                          onSelected: (isSelected) {
                            setDialogState(() {
                              if (isSelected) {
                                selected.add(t);
                              } else {
                                selected.remove(t);
                              }
                            });
                          },
                        ),
                      ),
                      ActionChip(
                        label: const Text('+'),
                        onPressed: () async {
                          final input = await showTextInputDialog(
                            context: context,
                            title: 'Create tag',
                            okLabel: L10n.of(context).ok,
                            cancelLabel: L10n.of(context).cancel,
                          );
                          final tag = (input ?? '').trim();
                          if (tag.isEmpty) return;
                          final existing = controller.room.roomTags;
                          if (!existing.contains(tag)) {
                            await controller.room.setRoomTags([
                              ...existing,
                              tag,
                            ]);
                          }
                          roomTags = controller.room.roomTags;
                          setDialogState(() {
                            selected.add(tag);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(L10n.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedTags
                    ..clear()
                    ..addAll(selected.toList()..sort());
                });
                Navigator.of(context).pop();
              },
              child: Text(L10n.of(context).ok),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAttachments({FileType type = FileType.any}) async {
    final picked = await selectFiles(context, allowMultiple: true, type: type);
    if (picked.isEmpty) return;
    setState(() {
      for (final x in picked) {
        _attachments.add(
          _NoteAttachmentDraft.local(
            x,
            msgtype: type == FileType.image ? MessageTypes.Image : null,
          ),
        );
      }
    });
  }

  String _attachmentLabel(_NoteAttachmentDraft a) {
    final name = a.fileName;
    if (name != null && name.trim().isNotEmpty) return name;
    final msgtype = a.msgtype;
    if (msgtype == MessageTypes.Image) return 'Image';
    if (msgtype == MessageTypes.Video) return 'Video';
    if (msgtype == MessageTypes.Audio) return 'Audio';
    return 'File';
  }

  Future<Map<String, Object?>> _uploadAttachmentXFile(XFile xfile) async {
    final room = widget.controller.room;
    final client = room.client;

    final bytes = await xfile.readAsBytes();
    final matrixFile = MatrixFile.fromMimeType(bytes: bytes, name: xfile.name);

    final encrypted = room.encrypted && client.fileEncryptionEnabled;

    Uri uploaded;
    EncryptedFile? encryptedFile;
    if (encrypted) {
      encryptedFile = await matrixFile.encrypt();
      final uploadFile = encryptedFile.toMatrixFile();
      uploaded = await client.uploadContent(
        uploadFile.bytes,
        filename: matrixFile.name,
        contentType: matrixFile.mimeType,
      );
    } else {
      uploaded = await client.uploadContent(
        matrixFile.bytes,
        filename: matrixFile.name,
        contentType: matrixFile.mimeType,
      );
    }

    return <String, Object?>{
      'msgtype': matrixFile.msgType,
      'body': matrixFile.name,
      'filename': matrixFile.name,
      if (!encrypted) 'url': uploaded.toString(),
      if (encrypted && encryptedFile != null)
        'file': <String, Object?>{
          'url': uploaded.toString(),
          'mimetype': matrixFile.mimeType,
          'v': 'v2',
          'key': <String, Object?>{
            'alg': 'A256CTR',
            'ext': true,
            'k': encryptedFile.k,
            'key_ops': <String>['encrypt', 'decrypt'],
            'kty': 'oct',
          },
          'iv': encryptedFile.iv,
          'hashes': <String, Object?>{'sha256': encryptedFile.sha256},
        },
      'info': <String, Object?>{...matrixFile.info},
    };
  }

  Future<Map<String, Object?>> _uploadVoiceMessageAttachment({
    required String path,
    required int duration,
    required List<int> waveform,
    required String? fileName,
  }) async {
    final xfile = XFile(path, name: fileName);
    final attachment = await _uploadAttachmentXFile(xfile);
    // Mark as voice message per MSC3245 and include waveform metadata per MSC1767.
    attachment['org.matrix.msc3245.voice'] = <String, Object?>{};
    attachment['org.matrix.msc1767.audio'] = <String, Object?>{
      'duration': duration,
      'waveform': waveform,
    };
    final info = (attachment['info'] is Map)
        ? Map<String, Object?>.from(attachment['info'] as Map)
        : <String, Object?>{};
    info['duration'] = duration;
    attachment['info'] = info;

    // Compatibility hint: some clients use MSC2097 recording metadata.
    attachment['org.matrix.msc2097.recording'] = <String, Object?>{};
    return attachment;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();

    // Prefill when we start already in edit mode.
    _prefillFromEditEvent();
  }

  @override
  void didUpdateWidget(covariant NoteInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    // React to controller switching into edit mode (same widget instance).
    if (oldWidget.controller.editEvent?.eventId !=
        widget.controller.editEvent?.eventId) {
      _prefillFromEditEvent();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendNote() async {
    final controller = widget.controller;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) return;

    final combinedBody = title.isEmpty
        ? body
        : body.isEmpty
        ? title
        : '$title\n\n$body';

    String escapeHtml(String input) => input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    final formattedBody = () {
      final escapedTitle = escapeHtml(title);
      final escapedBody = escapeHtml(body).replaceAll('\n', '<br />');
      if (title.isNotEmpty && body.isNotEmpty) {
        return '<h3>$escapedTitle</h3><p>$escapedBody</p>';
      }
      if (title.isNotEmpty) {
        return '<h3>$escapedTitle</h3>';
      }
      return '<p>$escapedBody</p>';
    }();

    final hashtagTags = <String>{
      ..._extractHashtags(title),
      ..._extractHashtags(body),
    };
    final normalizedTags = <String>{
      ..._selectedTags.map((t) => t.trim()).where((t) => t.isNotEmpty),
      ...hashtagTags.map((t) => t.trim()).where((t) => t.isNotEmpty),
    }.toList()..sort();

    final attachments = <Map<String, Object?>>[];
    for (final a in _attachments) {
      if (a.existing != null) {
        attachments.add(a.existing!);
        continue;
      }
      final local = a.local;
      if (local == null) continue;
      attachments.add(await _uploadAttachmentXFile(local));
    }

    final content = <String, Object?>{
      'msgtype': 'm.text',
      'body': combinedBody,
      if (combinedBody.isNotEmpty) ...{
        'format': 'org.matrix.custom.html',
        'formatted_body': formattedBody,
      },
      'im.ffchat.note': <String, Object?>{
        'title': title,
        'body': body,
        if (normalizedTags.isNotEmpty) 'tags': normalizedTags,
        if (attachments.isNotEmpty) 'attachments': attachments,
        'version': 1,
      },
    };

    final editEvent = controller.editEvent;
    if (editEvent != null) {
      // Edit existing note via MSC2676 (m.replace).
      final relatesTo = <String, Object?>{
        'rel_type': 'm.replace',
        'event_id': editEvent.eventId,
      };
      content['m.relates_to'] = relatesTo;
      content['m.new_content'] = Map<String, Object?>.from(content)
        ..remove('m.relates_to');
    }

    // MUST: use controller.room.client.sendEvent (API-level method on MatrixApi).
    final client = controller.room.client;
    final txnId = client.generateUniqueTransactionId();
    await client.sendMessage(
      controller.room.id,
      EventTypes.Message,
      txnId,
      content,
    );

    setState(() {
      _titleController.clear();
      _bodyController.clear();
      _selectedTags.clear();
      _attachments.clear();
    });

    // Clear edit state so next send creates a new note.
    if (editEvent != null) {
      controller.cancelReplyEventAction();
    }

    // Keep focus in body field for rapid note entry.
    controller.inputFocus.requestFocus();
  }

  bool get _hasDraftContent {
    if (_titleController.text.trim().isNotEmpty) return true;
    if (_bodyController.text.trim().isNotEmpty) return true;
    if (_selectedTags.isNotEmpty) return true;
    if (_attachments.isNotEmpty) return true;
    return false;
  }

  /// Returns true if it is ok to close the input.
  ///
  /// If the user confirms, this also resets the current draft.
  Future<bool> confirmClose() async {
    if (!_hasDraftContent) return true;

    final result = await showOkCancelAlertDialog(
      context: context,
      title: L10n.of(context).areYouSure,
      message: 'Reset this note draft?',
      okLabel: 'Reset',
      cancelLabel: 'Keep editing',
      useRootNavigator: true,
    );
    if (result != OkCancelResult.ok) return false;
    if (!mounted) return false;
    setState(() {
      _titleController.clear();
      _bodyController.clear();
      _selectedTags.clear();
      _attachments.clear();
    });
    return true;
  }

  bool _isImageAttachment(_NoteAttachmentDraft a) {
    final type = a.msgtype;
    if (type == MessageTypes.Image) return true;
    if (type == MessageTypes.Sticker) return true;

    final name = (a.local?.name ?? a.fileName ?? '').toLowerCase();
    return name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp') ||
        name.endsWith('.bmp') ||
        name.endsWith('.heic') ||
        name.endsWith('.heif');
  }

  Event _draftAttachmentToEvent(_NoteAttachmentDraft a, int index) {
    final room = widget.controller.room;
    final content = Map<String, dynamic>.from(
      a.existing ?? <String, Object?>{},
    );
    final json = <String, dynamic>{
      'type': EventTypes.Message,
      'event_id': 'note-draft-attachment-$index',
      'sender': room.client.userID,
      'origin_server_ts': DateTime.now().millisecondsSinceEpoch,
      'room_id': room.id,
      'content': content,
      'unsigned': <String, dynamic>{},
    };
    return Event.fromJson(json, room);
  }

  Widget _attachmentPreview(
    BuildContext context, {
    required _NoteAttachmentDraft attachment,
    required int index,
  }) {
    final size = 60.0;
    final radius = BorderRadius.circular(10);
    final theme = Theme.of(context);

    Widget preview;
    if (attachment.existing != null) {
      final e = _draftAttachmentToEvent(attachment, index);
      preview = MxcImage(
        event: e,
        width: size,
        height: size,
        fit: BoxFit.cover,
        isThumbnail: true,
        borderRadius: radius,
      );
    } else {
      final local = attachment.local;
      if (local == null) {
        preview = SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: theme.colorScheme.surfaceContainer,
            ),
            child: const Center(child: Icon(Icons.image_outlined)),
          ),
        );
      } else {
        preview = FutureBuilder<Uint8List>(
          future: local.readAsBytes(),
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes == null) {
              return SizedBox(
                width: size,
                height: size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    color: theme.colorScheme.surfaceContainer,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  ),
                ),
              );
            }
            return ClipRRect(
              borderRadius: radius,
              child: Image.memory(
                bytes,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => SizedBox(
                  width: size,
                  height: size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      color: theme.colorScheme.surfaceContainer,
                    ),
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    }

    return Stack(
      children: [
        SizedBox(width: size, height: size, child: preview),
        Positioned(
          right: 2,
          top: 2,
          child: InkWell(
            onTap: () => setState(() => _attachments.removeAt(index)),
            borderRadius: BorderRadius.circular(999),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withAlpha(220),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _schedulePrefillFromEditEvent();

    final controller = widget.controller;
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    final bottomSheetPadding = FluffyThemes.isColumnMode(context) ? 16.0 : 8.0;

    final roomTags = controller.room.roomTags;

    return RecordingViewModel(
      builder: (context, recordingViewModel) {
        if (recordingViewModel.isRecording) {
          // Recording UI, but instead of sending a separate event we add the
          // resulting audio as a note attachment draft.
          return Container(
            margin: EdgeInsets.all(bottomSheetPadding),
            constraints: const BoxConstraints(
              maxWidth: FluffyThemes.maxTimelineWidth,
            ),
            alignment: Alignment.center,
            child: Material(
              clipBehavior: Clip.hardEdge,
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: RecordingInputRow(
                  state: recordingViewModel,
                  onSend: (path, duration, waveform, fileName) async {
                    final uploaded = await _uploadVoiceMessageAttachment(
                      path: path,
                      duration: duration,
                      waveform: waveform,
                      fileName: fileName,
                    );
                    if (!mounted) return;
                    setState(() {
                      _attachments.add(_NoteAttachmentDraft.existing(uploaded));
                    });
                  },
                ),
              ),
            ),
          );
        }

        return Container(
          margin: EdgeInsets.all(bottomSheetPadding),
          constraints: const BoxConstraints(
            maxWidth: FluffyThemes.maxTimelineWidth,
          ),
          alignment: Alignment.center,
          child: Material(
            clipBehavior: Clip.hardEdge,
            color: controller.selectedEvents.isNotEmpty
                ? theme.colorScheme.tertiaryContainer
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReplyDisplay(controller),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: l10n.noteTitle,
                      border: InputBorder.none,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                if (roomTags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 0,
                        children: [
                          ...roomTags.map(
                            (t) => FilterChip(
                              label: Text(t),
                              selected: _selectedTags.contains(t),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    if (!_selectedTags.contains(t)) {
                                      _selectedTags.add(t);
                                      _selectedTags.sort();
                                    }
                                  } else {
                                    _selectedTags.remove(t);
                                  }
                                });
                              },
                            ),
                          ),
                          ActionChip(
                            label: const Text('+'),
                            onPressed: _createTag,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _attachments.mapIndexed((i, a) {
                          if (_isImageAttachment(a)) {
                            return _attachmentPreview(
                              context,
                              attachment: a,
                              index: i,
                            );
                          }
                          return InputChip(
                            label: Text(
                              _attachmentLabel(a),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onDeleted: () {
                              setState(() => _attachments.removeAt(i));
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _bodyController,
                    focusNode: controller.inputFocus,
                    decoration: InputDecoration(
                      hintText: l10n.noteContent,
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 8,
                    onSubmitted: (_) => _sendNote(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      PopupMenuButton<AddPopupMenuActions>(
                        useRootNavigator: true,
                        tooltip: l10n.addChatOrSubSpace,
                        icon: const Icon(Icons.add_circle_outline),
                        iconColor: theme.colorScheme.onPrimaryContainer,
                        onSelected: (choice) async {
                          switch (choice) {
                            case AddPopupMenuActions.image:
                              await _pickAttachments(type: FileType.image);
                              break;
                            case AddPopupMenuActions.file:
                              await _pickAttachments(type: FileType.any);
                              break;
                            default:
                              controller.onAddPopupMenuButtonSelected(choice);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: AddPopupMenuActions.image,
                            child: ListTile(
                              leading: const Icon(Icons.photo_outlined),
                              title: Text(L10n.of(context).sendImage),
                            ),
                          ),
                          PopupMenuItem(
                            value: AddPopupMenuActions.file,
                            child: ListTile(
                              leading: const Icon(Icons.attachment_outlined),
                              title: Text(L10n.of(context).sendFile),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: l10n.voiceMessage,
                        color: theme.colorScheme.onPrimaryContainer,
                        icon: const Icon(Icons.mic_none_outlined),
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  L10n.of(
                                    context,
                                  ).longPressToRecordVoiceMessage,
                                ),
                              ),
                            ),
                        onLongPress: () =>
                            recordingViewModel.startRecording(controller.room),
                      ),
                      IconButton(
                        tooltip: 'Tags',
                        color: theme.colorScheme.onPrimaryContainer,
                        icon: const Icon(Icons.tag_outlined),
                        onPressed: _openTagManager,
                      ),
                      IconButton(
                        tooltip: l10n.emojis,
                        color: theme.colorScheme.onPrimaryContainer,
                        icon: Icon(
                          controller.showEmojiPicker
                              ? Icons.keyboard
                              : Icons.add_reaction_outlined,
                        ),
                        onPressed: controller.emojiPickerAction,
                      ),
                      const Spacer(),
                      IconButton.filled(
                        tooltip: l10n.send,
                        onPressed: _sendNote,
                        icon: const Icon(Icons.send_outlined),
                      ),
                    ],
                  ),
                ),
                ChatEmojiPicker(controller),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NoteAttachmentDraft {
  final XFile? local;
  final Map<String, Object?>? existing;
  final String? localMsgtype;

  const _NoteAttachmentDraft._({this.local, this.existing, this.localMsgtype});

  factory _NoteAttachmentDraft.local(XFile file, {String? msgtype}) {
    final normalized = msgtype ?? _guessMsgtype(file.name);
    return _NoteAttachmentDraft._(local: file, localMsgtype: normalized);
  }

  factory _NoteAttachmentDraft.existing(Map<String, Object?> content) =>
      _NoteAttachmentDraft._(existing: content);

  static String? _guessMsgtype(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.heif')) {
      return MessageTypes.Image;
    }
    return null;
  }

  String? get fileName {
    if (existing != null) {
      return (existing!['body'] ?? existing!['filename'])?.toString();
    }
    return local?.name;
  }

  String? get msgtype => (existing?['msgtype'])?.toString() ?? localMsgtype;
}
