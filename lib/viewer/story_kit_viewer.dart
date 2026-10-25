import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/story_group_model.dart';
import '../models/story_item_model.dart';

/// Signature for interaction callbacks (poll vote, quiz answer, etc.).
typedef OnOverlayInteraction = void Function(
  String overlayId,
  Map<String, dynamic> payload,
);

/// Instagram-class story viewer.
///
/// Ports the useful behaviors from flutter_story_view (per-item duration,
/// 30s video cap, hold-to-pause, video loading state,
/// 30%/70% tap zones) on top of FocusGram's group PageView architecture.
class StoryKitViewer extends StatefulWidget {
  final List<StoryGroupModel> groups;
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
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _progress;

  int _groupIndex = 0;
  int _itemIndex = 0;
  bool _paused = false;
  bool _chromeHidden = false;
  bool _videoLoading = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _groupIndex = widget.initialGroupIndex.clamp(0, widget.groups.length - 1);
    _pageController = PageController(initialPage: _groupIndex);
    _progress = AnimationController(vsync: this)
      ..duration = widget.defaultImageDuration
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _advance();
        }
      });
    _startItem();
    _notifyGroupViewed();
  }

  @override
  void dispose() {
    _progress.dispose();
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  StoryGroupModel get _group => widget.groups[_groupIndex];

  StoryItemModel get _item =>
      _group.items[_itemIndex.clamp(0, _group.items.length - 1)];

  void _notifyGroupViewed() => widget.onGroupViewed?.call(_group.userId);

  void _startItem() {
    _progress.stop();
    _progress.reset();
    if (_item.type == StoryItemType.video) {
      _loadVideo();
    } else {
      _videoController?.dispose();
      _videoController = null;
      _videoLoading = false;
      _progress.duration = _item.duration;
      _progress.forward();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadVideo() async {
    final url = _item.mediaUrl;
    _videoController?.dispose();
    _videoController = null;
    if (mounted) setState(() => _videoLoading = true);
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _videoController = controller;
      setState(() => _videoLoading = false);
      controller.play();
      // 30s cap: progress completes when the video reaches the cap, not by a
      // wall-clock timer — pausing the video also pauses the countdown.
      final total = controller.value.duration;
      final capped = total > widget.maxVideoDuration
          ? widget.maxVideoDuration
          : total;
      _progress.duration = capped;
      controller.addListener(_onVideoTick);
      _progress.forward();
    } catch (_) {
      // Media failure must never trap the viewer: advance as if the item
      // had played its default duration.
      if (!mounted) return;
      _videoLoading = false;
      _progress.duration = widget.defaultImageDuration;
      _progress.forward();
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
        : (position.inMilliseconds / capped.inMilliseconds).clamp(0.0, 1.0);
    _progress.value = fraction.clamp(0.0, 1.0);
    if (fraction >= 1.0) {
      controller.removeListener(_onVideoTick);
      _advance();
    }
  }

  void _advance() {
    if (_itemIndex < _group.items.length - 1) {
      setState(() => _itemIndex++);
      _startItem();
    } else if (_groupIndex < widget.groups.length - 1) {
      setState(() {
        _groupIndex++;
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
    if (_itemIndex > 0) {
      setState(() => _itemIndex--);
      _startItem();
    } else if (_groupIndex > 0) {
      setState(() {
        _groupIndex--;
        _itemIndex = _group.items.length - 1;
      });
      _pageController.jumpToPage(_groupIndex);
      _startItem();
      _notifyGroupViewed();
    } else {
      _startItem();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    final width = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < width * 0.30) {
      _previous();
    } else {
      _advance();
    }
  }

  void _setPaused(bool paused) {
    if (paused) {
      _progress.stop();
      _videoController?.pause();
    } else {
      _progress.forward();
      if (_videoController != null && _progress.value < 1.0) {
        _videoController?.play();
      }
    }
    setState(() => _paused = paused);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.groups.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  _buildMedia(_item),
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
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
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

          // Tap zones (30% prev / 70% next) outside overlay areas.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: _handleTapDown,
              onLongPressStart: (_) => _setPaused(true),
              onLongPressEnd: (_) {
                _setPaused(false);
                setState(() => _chromeHidden = false);
              },
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
