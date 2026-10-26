import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/story_group_model.dart';
import '../models/story_item_model.dart';
import '../overlays/story_overlay.dart';
import 'story_overlay_renderer.dart';

export '../overlays/story_overlay.dart'
    show OnOverlayInteraction;

/// Controller for explicitly pausing or resuming story playback.
class StoryKitViewerController {
  _StoryKitViewerState? _state;
  bool get isPaused => _state?._paused ?? false;
  void pause() => _state?._setPaused(true);
  void resume() => _state?._setPaused(false);
  void _attach(_StoryKitViewerState state) => _state = state;
  void _detach(_StoryKitViewerState state) {
    if (identical(_state, state)) _state = null;
  }
}

/// Instagram-class story viewer.
///
/// Ports the useful behaviors from flutter_story_view (per-item duration,
/// 30s video cap, hold-to-pause, video loading state,
/// 30%/70% tap zones) on top of FocusGram's group PageView architecture,
/// and renders the kit's interactive overlays above the media.
class StoryKitViewer extends StatefulWidget {
  final List<StoryGroupModel> groups;
  final StoryKitViewerController? controller;
  final int initialGroupIndex;
  final Duration defaultImageDuration;
  final Duration maxVideoDuration;
  final OnOverlayInteraction? onOverlayInteraction;
  final ValueChanged<String>? onGroupViewed;
  final VoidCallback? onViewerFinished;
  final Widget Function(BuildContext, StoryGroupModel)? headerBuilder;

  const StoryKitViewer({
    super.key,
    required this.groups,
    this.controller,
    this.initialGroupIndex = 0,
    this.defaultImageDuration = const Duration(seconds: 5),
    this.maxVideoDuration = const Duration(seconds: 30),
    this.onOverlayInteraction,
    this.onGroupViewed,
    this.onViewerFinished,
    this.headerBuilder,
  });

  @override
  State<StoryKitViewer> createState() => _StoryKitViewerState();
}

class _StoryKitViewerState extends State<StoryKitViewer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final PageController _pageController;
  late final AnimationController _progress;

  int _groupIndex = 0;
  int _itemIndex = 0;
  bool _paused = false;
  bool _lifecyclePaused = false;
  bool _chromeHidden = false;
  bool _videoLoading = false;
  VideoPlayerController? _videoController;
  int _videoLoadGeneration = 0;
  Offset? _tapDownPosition;

  bool get _hasPlayableContent =>
      widget.groups.any((group) => group.items.isNotEmpty);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller?._attach(this);
    _groupIndex = _resolveInitialGroupIndex();
    _pageController = PageController(initialPage: _groupIndex);
    _progress = AnimationController(vsync: this)
      ..duration = widget.defaultImageDuration
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _advance();
        }
      });

    if (_hasPlayableContent) {
      _startItem();
      _notifyGroupViewed();
    }
  }

  /// Picks a group that contains items without ever clamping against -1.
  ///
  /// Empty groups are ignored for playback. If the requested group and all
  /// groups after it are empty, the nearest preceding playable group is used.
  /// If no group contains an item, index zero is retained only as a safe
  /// controller index; [build] renders the empty state instead.
  int _resolveInitialGroupIndex() {
    if (widget.groups.isEmpty) return 0;

    final requestedIndex =
        widget.initialGroupIndex.clamp(0, widget.groups.length - 1).toInt();
    final nextPlayable =
        _findPlayableGroupIndex(requestedIndex, direction: 1);
    if (nextPlayable != -1) return nextPlayable;

    final previousPlayable =
        _findPlayableGroupIndex(requestedIndex - 1, direction: -1);
    return previousPlayable == -1 ? 0 : previousPlayable;
  }

  int _findPlayableGroupIndex(int start, {required int direction}) {
    for (var index = start;
        index >= 0 && index < widget.groups.length;
        index += direction) {
      if (widget.groups[index].items.isNotEmpty) return index;
    }
    return -1;
  }

  @override
  void didUpdateWidget(covariant StoryKitViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final shouldPause = state != AppLifecycleState.resumed;
    if (_lifecyclePaused == shouldPause) return;
    _lifecyclePaused = shouldPause;
    if (shouldPause) {
      _progress.stop();
      _videoController?.pause();
    } else if (!_paused && _hasPlayableContent) {
      if (_videoController != null && _progress.value < 1.0) {
        _videoController?.play();
      }
      _progress.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?._detach(this);
    // Invalidate any asynchronous initialize() still in flight.
    _videoLoadGeneration++;
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    _progress.dispose();
    _pageController.dispose();
    super.dispose();
  }

  StoryGroupModel get _group => widget.groups[_groupIndex];

  StoryItemModel get _item =>
      _group.items[_itemIndex.clamp(0, _group.items.length - 1).toInt()];

  void _notifyGroupViewed() {
    if (!_hasPlayableContent ||
        widget.groups.isEmpty ||
        widget.groups[_groupIndex].items.isEmpty) {
      return;
    }
    widget.onGroupViewed?.call(_group.userId);
  }

  void _startItem() {
    if (!_hasPlayableContent ||
        widget.groups.isEmpty ||
        _groupIndex >= widget.groups.length ||
        widget.groups[_groupIndex].items.isEmpty) {
      return;
    }

    _progress.stop();
    _progress.reset();
    if (_item.type == StoryItemType.video) {
      _loadVideo();
    } else {
      // An image transition invalidates any video initialization that has not
      // completed yet and releases the previous controller.
      _videoLoadGeneration++;
      final previousController = _videoController;
      _videoController = null;
      previousController?.removeListener(_onVideoTick);
      previousController?.dispose();
      _videoLoading = false;
      _progress.duration = _item.duration;
      if (!_paused && !_lifecyclePaused) _progress.forward();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadVideo() async {
    final generation = ++_videoLoadGeneration;
    final url = _item.mediaUrl;
    final previousController = _videoController;
    _videoController = null;
    previousController?.removeListener(_onVideoTick);
    previousController?.dispose();
    if (mounted) setState(() => _videoLoading = true);

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      if (!mounted || generation != _videoLoadGeneration) {
        controller.dispose();
        return;
      }
      _videoController = controller;
      setState(() => _videoLoading = false);
      if (!_paused && !_lifecyclePaused) controller.play();
      // 30s cap: progress completes when the video reaches the cap, not by a
      // wall-clock timer — pausing the video also pauses the countdown.
      final total = controller.value.duration;
      final capped = total > widget.maxVideoDuration
          ? widget.maxVideoDuration
          : total;
      _progress.duration = capped;
      controller.addListener(_onVideoTick);
      if (!_paused && !_lifecyclePaused) _progress.forward();
    } catch (_) {
      // The local controller is not installed until initialize succeeds, so
      // dispose it here even when the widget has already moved to another item.
      controller.dispose();
      if (!mounted || generation != _videoLoadGeneration) return;
      _videoLoading = false;
      _progress.duration = widget.defaultImageDuration;
      if (!_paused && !_lifecyclePaused) _progress.forward();
    }
  }

  void _onVideoTick() {
    final controller = _videoController;
    if (controller == null) return;
    final position = controller.value.position;
    final total = controller.value.duration;
    final capped = total > widget.maxVideoDuration
        ? widget.maxVideoDuration
        : total;
    final fraction = capped.inMilliseconds <= 0
        ? 1.0
        : (position.inMilliseconds / capped.inMilliseconds)
            .clamp(0.0, 1.0)
            .toDouble();

    if (fraction >= 1.0) {
      // Let the AnimationController's completed listener be the sole source
      // of advancement. Calling _advance() here as well can skip two items.
      controller.removeListener(_onVideoTick);
      _progress.value = 1.0;
      return;
    }
    _progress.value = fraction;
  }

  void _advance() {
    if (!_hasPlayableContent) return;

    if (_itemIndex < _group.items.length - 1) {
      setState(() => _itemIndex++);
      _startItem();
      return;
    }

    final nextGroup =
        _findPlayableGroupIndex(_groupIndex + 1, direction: 1);
    if (nextGroup != -1) {
      setState(() {
        _groupIndex = nextGroup;
        _itemIndex = 0;
      });
      _pageController.jumpToPage(_groupIndex);
      _startItem();
      _notifyGroupViewed();
    } else {
      widget.onViewerFinished?.call();
      Navigator.of(context).maybePop();
    }
  }

  void _previous() {
    if (!_hasPlayableContent) return;

    if (_itemIndex > 0) {
      setState(() => _itemIndex--);
      _startItem();
      return;
    }

    final previousGroup =
        _findPlayableGroupIndex(_groupIndex - 1, direction: -1);
    if (previousGroup != -1) {
      setState(() {
        _groupIndex = previousGroup;
        _itemIndex = _group.items.length - 1;
      });
      _pageController.jumpToPage(_groupIndex);
      _startItem();
      _notifyGroupViewed();
    } else {
      _startItem();
    }
  }

  void _recordTapDown(TapDownDetails details) {
    _tapDownPosition = details.globalPosition;
  }

  void _clearTapDown() {
    _tapDownPosition = null;
  }

  void _handleTap() {
    final position = _tapDownPosition;
    _tapDownPosition = null;
    if (position == null || !_hasPlayableContent) return;

    final width = MediaQuery.of(context).size.width;
    if (position.dx < width * 0.30) {
      _previous();
    } else {
      _advance();
    }
  }

  void _setPaused(bool paused) {
    if (paused) {
      _progress.stop();
      _videoController?.pause();
    } else if (!_lifecyclePaused) {
      _progress.forward();
      if (_videoController != null && _progress.value < 1.0) {
        _videoController?.play();
      }
    }
    setState(() => _paused = paused);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPlayableContent) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No stories available',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.groups.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final group = widget.groups[index];
              if (group.items.isEmpty) return const SizedBox.shrink();
              final pageItemIndex = index == _groupIndex ? _itemIndex : 0;
              final item = group.items[
                pageItemIndex.clamp(0, group.items.length - 1).toInt()
              ];
              return Stack(
                fit: StackFit.expand,
                children: [
                  _buildMedia(item),
                  // Keep navigation gestures below overlays so an overlay tap
                  // is handled by the overlay rather than the viewer's zones.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: _recordTapDown,
                      onTap: _handleTap,
                      onTapCancel: _clearTapDown,
                      onLongPressStart: (_) => _setPaused(true),
                      onLongPressEnd: (_) {
                        _setPaused(false);
                        if (mounted) {
                          setState(() => _chromeHidden = false);
                        }
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                  StoryOverlayRenderer(
                    overlays: item.overlays,
                    onOverlayInteraction: widget.onOverlayInteraction,
                    onOverlayInteractionStarted: () => _setPaused(true),
                  ),
                ],
              );
            },
          ),

          // Progress segments across the current group's items.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              children: List.generate(_group.items.length, (i) {
                final active = i == _itemIndex;
                final completed = i < _itemIndex;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: SizedBox(
                      height: 3,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        value: active
                            ? _progress.value
                            : (completed ? 1.0 : 0.0),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Header (host-provided or default).
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: _chromeHidden ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: widget.headerBuilder?.call(context, _group) ??
                  Row(
                    children: [
                      if (_group.avatarUrl != null)
                        CircleAvatar(
                          radius: 16,
                          backgroundImage:
                              CachedNetworkImageProvider(_group.avatarUrl!),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _group.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(StoryItemModel item) {
    if (item.type == StoryItemType.video && _videoController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    }
    if (_videoLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return CachedNetworkImage(
      imageUrl: item.mediaUrl,
      fit: BoxFit.cover,
      placeholder: (_, _) => const ColoredBox(color: Colors.black12),
      errorWidget: (_, _, _) => const ColoredBox(color: Colors.black54),
      width: double.infinity,
      height: double.infinity,
    );
  }
}
