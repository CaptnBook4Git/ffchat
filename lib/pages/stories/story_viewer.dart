// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-05: Add full-screen story viewer for room images - Simon
// - 2026-02-05: Use conditional assignment for page controller init - Simon

import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mxc_image.dart';

class StoryViewer extends StatefulWidget {
  final String roomId;

  const StoryViewer({super.key, required this.roomId});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  Timeline? _timeline;
  Object? _error;
  bool _loading = true;
  List<Event> _imageEvents = const [];

  PageController? _pageController;

  Room? get _room => Matrix.of(context).client.getRoomById(widget.roomId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _timeline?.cancelSubscriptions();
    _timeline = null;
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final room = _room;
    if (room == null) {
      setState(() {
        _loading = false;
        _error = Exception('Room not found');
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await room.postLoad();

      final timeline = await room.getTimeline(onUpdate: _onTimelineUpdate);
      _timeline = timeline;

      await timeline.requestHistory(historyCount: 100);

      // Mark as read on open (same behavior as chat view).
      if (timeline.events.isNotEmpty) {
        // ignore: unawaited_futures
        timeline.setReadMarker(
          public: AppSettings.sendPublicReadReceipts.value,
        );
      }

      _rebuildEvents();

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  void _onTimelineUpdate() {
    if (!mounted) return;
    _rebuildEvents();
    setState(() {});
  }

  void _rebuildEvents() {
    final timeline = _timeline;
    if (timeline == null) {
      _imageEvents = const [];
      return;
    }

    final events = timeline.events
        .filterByVisibleInGui()
        .where((e) => e.messageType == MessageTypes.Image)
        .toList();

    events.sort((a, b) => a.originServerTs.compareTo(b.originServerTs));

    _imageEvents = events;

    _pageController ??= PageController(initialPage: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final room = _room;

    if (room == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.noRoomsFound)),
      );
    }

    final title = room.getLocalizedDisplayname();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${l10n.oopsSomethingWentWrong}\n\n$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
          : _imageEvents.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.nothingFound,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _imageEvents.length,
              itemBuilder: (context, i) {
                final event = _imageEvents[i];
                return AnimatedPadding(
                  duration: FluffyThemes.animationDuration,
                  curve: FluffyThemes.animationCurve,
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 10.0,
                      child: MxcImage(
                        key: ValueKey(event.eventId),
                        event: event,
                        fit: BoxFit.contain,
                        isThumbnail: false,
                        animated: true,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
