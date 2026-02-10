// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2021-2026 Krille Fear / FluffyChat Contributors
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-09: Render im.ffchat.note content in timeline - Simon
// - 2026-02-09: Avoid rendering title twice by using note.body - Simon
// - 2026-02-09: Render note attachments below text - Simon
// - 2026-02-09: Support note attachments stored inside note content - Simon
// - 2026-02-09: Show square image previews for note attachments (Issue #25) - Simon
// - 2026-02-09: Open ImageViewer when tapping note image preview (Issue #25) - Simon
// - 2026-02-09: Render voice message attachments with waveform metadata (Issue #25) - Simon

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/pages/chat/events/html_message.dart';
import 'package:fluffychat/pages/chat/events/image_bubble.dart';
import 'package:fluffychat/pages/chat/events/message_download_content.dart';
import 'package:fluffychat/pages/chat/events/video_player.dart';
import 'package:fluffychat/pages/chat/events/audio_player.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';

/// Renders notes stored inside a normal `m.room.message` event.
///
/// Notes are detected via `im.ffchat.note` in the event content.
///
/// Format (recommended):
/// ```json
/// {
///   "msgtype": "m.text",
///   "body": "Title\n\nContent",
///   "format": "org.matrix.custom.html",
///   "formatted_body": "<h3>Title</h3><p>Content</p>",
///   "im.ffchat.note": {"title": "Title", "version": 1}
/// }
/// ```
class NoteEventContent extends StatelessWidget {
  final Event event;
  final Color textColor;
  final Color linkColor;
  final double fontSize;
  final bool selected;

  const NoteEventContent({
    super.key,
    required this.event,
    required this.textColor,
    required this.linkColor,
    required this.fontSize,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final content = event.content;
    final note = (content is Map) ? content['im.ffchat.note'] : null;
    final title = (note is Map) ? note['title']?.toString().trim() : null;
    final body = (note is Map) ? note['body']?.toString().trim() : null;

    final attachmentsRaw = (note is Map) ? note['attachments'] : null;
    final attachments = <Map<String, dynamic>>[];
    if (attachmentsRaw is List) {
      for (final a in attachmentsRaw) {
        if (a is Map) attachments.add(a.cast<String, dynamic>());
      }
    }

    final hasTitle = title != null && title.isNotEmpty;
    final hasBody = body != null && body.isNotEmpty;

    String escapeHtml(String input) => input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    // IMPORTANT: Do NOT use event.formattedText for notes.
    // The note title is rendered separately. The HTML body may contain the
    // title too, which would lead to duplicated titles.
    final bodyText = body ?? '';
    final html = bodyText.isEmpty
        ? ''
        : AppSettings.renderHtml.value
        ? '<p>${escapeHtml(bodyText).replaceAll('\n', '<br />')}</p>'
        : escapeHtml(bodyText);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTitle)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              title!,
              style: TextStyle(
                fontSize: fontSize * 1.1,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        if (hasTitle && (hasBody || html.isNotEmpty))
          Divider(height: 1, color: textColor.withAlpha(48)),
        Padding(
          padding: EdgeInsets.fromLTRB(16, hasTitle ? 8 : 12, 16, 12),
          child: HtmlMessage(
            html: html,
            textColor: textColor,
            room: event.room,
            fontSize: fontSize,
            limitHeight: !selected,
            linkStyle: TextStyle(
              color: linkColor,
              fontSize: fontSize,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
            ),
            onOpen: (url) => UrlLauncher(context, url.url).launchUrl(),
            eventId: event.eventId,
          ),
        ),
        if (attachments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: attachments
                  .mapIndexed(
                    (i, a) => _NoteAttachmentContent(
                      attachment: a,
                      parentEvent: event,
                      textColor: textColor,
                      linkColor: linkColor,
                      selected: selected,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _NoteAttachmentContent extends StatelessWidget {
  final Map<String, dynamic> attachment;
  final Event parentEvent;
  final Color textColor;
  final Color linkColor;
  final bool selected;

  const _NoteAttachmentContent({
    required this.attachment,
    required this.parentEvent,
    required this.textColor,
    required this.linkColor,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final content = Map<String, dynamic>.from(attachment);
    final room = parentEvent.room;
    final json = <String, dynamic>{
      'type': EventTypes.Message,
      'event_id':
          '${parentEvent.eventId}::attachment:${content['url'] ?? content['body'] ?? ''}',
      'sender': parentEvent.senderId,
      'origin_server_ts': parentEvent.originServerTs.millisecondsSinceEpoch,
      'room_id': room.id,
      'content': content,
      'unsigned': parentEvent.unsigned ?? <String, dynamic>{},
    };
    final attachmentEvent = Event.fromJson(json, room);

    switch (attachmentEvent.messageType) {
      case MessageTypes.Image:
      case MessageTypes.Sticker:
        return _NoteAttachmentImagePreview(
          attachmentEvent: attachmentEvent,
          textColor: textColor,
          parentEvent: parentEvent,
        );
      case MessageTypes.Video:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: EventVideoPlayer(
            attachmentEvent,
            textColor: textColor,
            linkColor: linkColor,
          ),
        );
      case MessageTypes.Audio:
        // Voice messages are regular audio events with additional metadata.
        // AudioPlayerWidget will render waveform when org.matrix.msc1767.audio
        // is present.
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AudioPlayerWidget(
            attachmentEvent,
            color: textColor,
            linkColor: linkColor,
            fontSize: 14,
          ),
        );
      case MessageTypes.File:
      default:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: MessageDownloadContent(
            attachmentEvent,
            textColor: textColor,
            linkColor: linkColor,
          ),
        );
    }
  }
}

class _NoteAttachmentImagePreview extends StatelessWidget {
  final Event attachmentEvent;
  final Color textColor;
  final Event parentEvent;

  const _NoteAttachmentImagePreview({
    required this.attachmentEvent,
    required this.textColor,
    required this.parentEvent,
  });

  @override
  Widget build(BuildContext context) {
    final content = attachmentEvent.content;
    final size = 60.0;
    final radius = BorderRadius.circular(10);

    Uri? mxc;
    if (content is Map) {
      final url = content['url']?.toString();
      final fileUrl = (content['file'] is Map)
          ? (content['file'] as Map)['url']?.toString()
          : null;
      final raw = (fileUrl ?? url)?.trim();
      if (raw != null && raw.startsWith('mxc://')) {
        mxc = Uri.tryParse(raw);
      }
    }

    // Encrypted content (with `file`) must be rendered via attachment download.
    final isEncrypted = content is Map && content['file'] is Map;

    Widget child;
    if (isEncrypted) {
      child = MxcImage(
        event: attachmentEvent,
        width: size,
        height: size,
        fit: BoxFit.cover,
        isThumbnail: true,
        borderRadius: radius,
      );
    } else if (mxc != null) {
      final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
      child = FutureBuilder<Uri>(
        future: mxc.getThumbnailUri(
          attachmentEvent.room.client,
          width: size * devicePixelRatio,
          height: size * devicePixelRatio,
          method: ThumbnailMethod.scale,
        ),
        builder: (context, snapshot) {
          final httpUri = snapshot.data;
          if (httpUri == null) {
            return SizedBox(
              width: size,
              height: size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                child: const Center(
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                ),
              ),
            );
          }
          return SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: Theme.of(context).colorScheme.surfaceContainer,
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Image.network(
                  httpUri.toString(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.broken_image_outlined, color: textColor),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      child = SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
          child: Center(child: Icon(Icons.image_outlined, color: textColor)),
        ),
      );
    }

    final label = attachmentEvent.body.trim();
    final openViewer = () {
      showDialog<void>(
        context: context,
        builder: (_) => ImageViewer(attachmentEvent, outerContext: context),
      );
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(onTap: openViewer, child: child),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: openViewer,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
