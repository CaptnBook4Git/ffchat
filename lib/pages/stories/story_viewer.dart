// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (c) 2026 Simon
//
// MODIFICATIONS:
// - 2026-02-05: Add full-screen story viewer for room images - Simon
// - 2026-02-05: Use conditional assignment for page controller init - Simon
// - 2026-02-06: Implement autoplay, gestures, progress bar, video support, and auto-advance (Issue #6) - Simon

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:video_player/video_player.dart';

import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/story_room_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mxc_image.dart';

class StoryViewer extends StatefulWidget {
  final String roomId;
  final List<String>? storyRoomIds;

  const StoryViewer({super.key, required this.roomId, this.storyRoomIds});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class StoryMoment {
  final Event event;
  final Duration duration;

  const StoryMoment({required this.event, required this.duration});

  bool get isVideo => event.messageType == MessageTypes.Video;
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  Timeline? _timeline;
  Object? _error;
  bool _loading = true;

  List<StoryMoment> _moments = const [];
  int _momentIndex = 0;

  late final PageController _pageController;
  late final AnimationController _progressController;
  final ValueNotifier<bool> _paused = ValueNotifier(false);

  bool _isHolding = false;
  bool _isMediaLoading = false;
  bool _advancing = false;

  Room? get _room => Matrix.of(context).client.getRoomById(widget.roomId);

  List<String> _computeStoryRoomIdsFallback() {
    final rooms = Matrix.of(
      context,
    ).client.rooms.where((r) => r.isStory).toList();
    rooms.sort(
      (a, b) => b.latestEventReceivedTime.compareTo(a.latestEventReceivedTime),
    );
    return rooms.map((r) => r.id).toList();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _progressController = AnimationController(vsync: this)
      ..addStatusListener(_onProgressStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _timeline?.cancelSubscriptions();
    _timeline = null;

    _progressController
      ..removeStatusListener(_onProgressStatus)
      ..dispose();
    _pageController.dispose();
    _paused.dispose();
    super.dispose();
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goToNextMoment();
    }
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

      if (_moments.isNotEmpty) {
        _setMomentIndex(_momentIndex, restart: true);
      }
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

  Duration _durationForVideoEvent(Event event) {
    final infoMap = event.content.tryGetMap<String, Object?>('info');
    final durationMs = infoMap?.tryGet<int>('duration');
    if (durationMs != null && durationMs > 0) {
      return Duration(milliseconds: durationMs);
    }
    // Fallback for missing duration metadata.
    return const Duration(seconds: 10);
  }

  void _rebuildEvents() {
    final timeline = _timeline;
    if (timeline == null) {
      _moments = const [];
      return;
    }

    final events = timeline.events.filterByVisibleInGui().where((e) {
      return e.messageType == MessageTypes.Image ||
          (e.messageType == MessageTypes.Video &&
              PlatformInfos.supportsVideoPlayer);
    }).toList();

    events.sort((a, b) => a.originServerTs.compareTo(b.originServerTs));

    final moments = <StoryMoment>[];
    for (final e in events) {
      if (e.messageType == MessageTypes.Video) {
        moments.add(StoryMoment(event: e, duration: _durationForVideoEvent(e)));
      } else {
        moments.add(
          StoryMoment(event: e, duration: const Duration(seconds: 5)),
        );
      }
    }

    _moments = moments;
    if (_momentIndex >= _moments.length) {
      _momentIndex = _moments.isEmpty ? 0 : _moments.length - 1;
    }
  }

  void _updatePlayback() {
    final shouldPause = _isHolding || _isMediaLoading;
    _paused.value = shouldPause;
    if (shouldPause) {
      _progressController.stop();
      return;
    }

    if (_moments.isEmpty || _progressController.duration == null) return;
    if (!_progressController.isAnimating && _progressController.value < 1) {
      _progressController.forward();
    }
  }

  void _setMomentIndex(int index, {required bool restart}) {
    if (_moments.isEmpty) return;

    final nextIndex = index.clamp(0, _moments.length - 1);
    _advancing = false;

    setState(() {
      _momentIndex = nextIndex;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(_momentIndex);
    }

    final moment = _moments[_momentIndex];
    _isMediaLoading = moment.isVideo && PlatformInfos.supportsVideoPlayer;

    _progressController.duration = moment.duration;
    if (restart) {
      _progressController
        ..stop()
        ..value = 0;
    }
    _updatePlayback();

    if (!_isMediaLoading) {
      _progressController.forward(from: 0);
    }
  }

  void _goToPreviousMoment() {
    if (_moments.isEmpty) return;
    if (_momentIndex <= 0) return;
    _setMomentIndex(_momentIndex - 1, restart: true);
  }

  void _goToNextMoment() {
    if (_advancing) return;
    _advancing = true;

    if (_moments.isEmpty || _momentIndex >= _moments.length - 1) {
      _finishRoom();
      return;
    }

    _setMomentIndex(_momentIndex + 1, restart: true);
  }

  void _finishRoom() {
    final storyRoomIds = widget.storyRoomIds ?? _computeStoryRoomIdsFallback();
    final currentIndex = storyRoomIds.indexOf(widget.roomId);
    final nextRoomId =
        (currentIndex >= 0 && currentIndex < storyRoomIds.length - 1)
        ? storyRoomIds[currentIndex + 1]
        : null;

    if (nextRoomId == null) {
      if (mounted) context.pop();
      return;
    }

    context.go('/rooms/story/$nextRoomId', extra: storyRoomIds);
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
          : _moments.isEmpty
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
          : Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: (details) {
                      final width = MediaQuery.sizeOf(context).width;
                      final isLeft = details.localPosition.dx < width * 0.33;
                      if (isLeft) {
                        _goToPreviousMoment();
                      } else {
                        _goToNextMoment();
                      }
                    },
                    onLongPressStart: (_) {
                      _isHolding = true;
                      _updatePlayback();
                    },
                    onLongPressEnd: (_) {
                      _isHolding = false;
                      _updatePlayback();
                    },
                    onLongPressCancel: () {
                      _isHolding = false;
                      _updatePlayback();
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: _moments.length,
                      itemBuilder: (context, i) {
                        final moment = _moments[i];
                        final event = moment.event;

                        if (moment.isVideo &&
                            PlatformInfos.supportsVideoPlayer) {
                          return _StoryVideoPlayer(
                            key: ValueKey('story_video_${event.eventId}'),
                            event: event,
                            paused: _paused,
                            onLoadingChanged: (loading) {
                              if (!mounted) return;
                              if (i != _momentIndex) return;
                              setState(() {
                                _isMediaLoading = loading;
                              });
                              _updatePlayback();
                            },
                            onReady: (duration) {
                              if (!mounted) return;
                              if (i != _momentIndex) return;
                              final effective = duration ?? moment.duration;
                              setState(() {
                                _moments = List<StoryMoment>.of(_moments)
                                  ..[i] = StoryMoment(
                                    event: event,
                                    duration: effective,
                                  );
                                _progressController.duration = effective;
                                _isMediaLoading = false;
                              });
                              _updatePlayback();
                              _progressController.forward(from: 0);
                            },
                            onFinished: _goToNextMoment,
                          );
                        }

                        return AnimatedPadding(
                          duration: FluffyThemes.animationDuration,
                          curve: FluffyThemes.animationCurve,
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          child: Center(
                            child: MxcImage(
                              key: ValueKey(event.eventId),
                              event: event,
                              fit: BoxFit.contain,
                              isThumbnail: false,
                              animated: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, _) {
                              return Row(
                                children: List.generate(_moments.length, (i) {
                                  final value = i < _momentIndex
                                      ? 1.0
                                      : (i == _momentIndex
                                            ? _progressController.value
                                            : 0.0);
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: value,
                                          backgroundColor: Colors.white
                                              .withAlpha(48),
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                Colors.white,
                                              ),
                                          minHeight: 3,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: context.pop,
                                icon: const Icon(Icons.close),
                                color: Colors.white,
                                tooltip: l10n.close,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StoryVideoPlayer extends StatefulWidget {
  final Event event;
  final ValueListenable<bool> paused;
  final void Function(bool loading) onLoadingChanged;
  final void Function(Duration? duration) onReady;
  final VoidCallback onFinished;

  const _StoryVideoPlayer({
    super.key,
    required this.event,
    required this.paused,
    required this.onLoadingChanged,
    required this.onReady,
    required this.onFinished,
  });

  @override
  State<_StoryVideoPlayer> createState() => _StoryVideoPlayerState();
}

class _StoryVideoPlayerState extends State<_StoryVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _didNotifyReady = false;
  bool _didFinish = false;

  @override
  void initState() {
    super.initState();
    widget.paused.addListener(_onPausedChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndPlay();
    });
  }

  @override
  void didUpdateWidget(covariant _StoryVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paused != widget.paused) {
      oldWidget.paused.removeListener(_onPausedChanged);
      widget.paused.addListener(_onPausedChanged);
    }
    if (oldWidget.event.eventId != widget.event.eventId) {
      _disposeController();
      _loadAndPlay();
    }
  }

  void _onPausedChanged() {
    final c = _controller;
    if (c == null || !_isInitialized) return;
    if (widget.paused.value) {
      // ignore: unawaited_futures
      c.pause();
    } else {
      // ignore: unawaited_futures
      c.play();
    }
  }

  Future<void> _loadAndPlay() async {
    widget.onLoadingChanged(true);
    try {
      final videoFile = await widget.event.downloadAndDecryptAttachment();

      late final VideoPlayerController controller;
      if (kIsWeb) {
        final blob = html.Blob([videoFile.bytes], videoFile.mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        final tempDir = await getTemporaryDirectory();
        final fileName = Uri.encodeComponent(
          widget.event.attachmentOrThumbnailMxcUrl()!.pathSegments.last,
        );
        final file = File('${tempDir.path}/${fileName}_${videoFile.name}');
        if (await file.exists() == false) {
          await file.writeAsBytes(videoFile.bytes);
        }
        controller = VideoPlayerController.file(file);
      }

      await controller.initialize();
      await controller.setLooping(false);

      controller.addListener(() {
        if (_didFinish) return;
        final v = controller.value;
        if (!v.isInitialized) return;
        final duration = v.duration;
        if (duration == Duration.zero) return;
        if (v.position >= duration - const Duration(milliseconds: 150)) {
          _didFinish = true;
          widget.onFinished();
        }
      });

      _controller = controller;
      _isInitialized = true;
      widget.onLoadingChanged(false);

      if (!_didNotifyReady) {
        _didNotifyReady = true;
        widget.onReady(controller.value.duration);
      }

      _onPausedChanged();
      if (!widget.paused.value) {
        // ignore: unawaited_futures
        controller.play();
      }

      if (mounted) setState(() {});
    } catch (_) {
      widget.onLoadingChanged(false);
      rethrow;
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _didNotifyReady = false;
    _didFinish = false;
  }

  @override
  void dispose() {
    widget.paused.removeListener(_onPausedChanged);
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !_isInitialized) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}
