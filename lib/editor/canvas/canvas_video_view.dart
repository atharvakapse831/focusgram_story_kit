import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/story_media_asset.dart';
import '../../models/video_payload.dart';
import '../../timeline/timeline_controller.dart';

/// Canvas widget rendering active video playback with transform and aspect-ratio preservation.
class CanvasVideoView extends StatefulWidget {
  const CanvasVideoView({
    super.key,
    required this.videoPayload,
    this.timelineController,
    this.showControls = false,
  });

  final StoryVideoPayload videoPayload;
  final StoryTimelineController? timelineController;
  final bool showControls;

  @override
  State<CanvasVideoView> createState() => _CanvasVideoViewState();
}

class _CanvasVideoViewState extends State<CanvasVideoView> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    widget.timelineController?.addListener(_onTimelineChanged);
  }

  @override
  void didUpdateWidget(CanvasVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.videoPayload.asset.uri != oldWidget.videoPayload.asset.uri) {
      _disposePlayer();
      _initializePlayer();
    } else if (widget.videoPayload.audioPolicy !=
        oldWidget.videoPayload.audioPolicy) {
      _applyAudioPolicy();
    }

    if (widget.timelineController != oldWidget.timelineController) {
      oldWidget.timelineController?.removeListener(_onTimelineChanged);
      widget.timelineController?.addListener(_onTimelineChanged);
    }
  }

  void _onTimelineChanged() {
    final tc = widget.timelineController;
    final ctrl = _controller;
    if (tc == null || ctrl == null || !_isInitialized) return;

    if (tc.isPlaying && !ctrl.value.isPlaying) {
      ctrl.play();
    } else if (!tc.isPlaying && ctrl.value.isPlaying) {
      ctrl.pause();
    }

    // Sync position if difference is significant
    final driftMs =
        (ctrl.value.position.inMilliseconds - tc.currentPosition.inMilliseconds)
            .abs();
    if (driftMs > tc.syncToleranceMs) {
      ctrl.seekTo(tc.currentPosition);
    }
  }

  Future<void> _initializePlayer() async {
    final asset = widget.videoPayload.asset;
    if (asset.uri.isEmpty) return;

    try {
      VideoPlayerController ctrl;
      switch (asset.sourceType) {
        case StoryMediaSourceType.file:
          ctrl = VideoPlayerController.file(File(asset.uri));
          break;
        case StoryMediaSourceType.asset:
          ctrl = VideoPlayerController.asset(asset.uri);
          break;
        case StoryMediaSourceType.network:
        case StoryMediaSourceType.memory:
          ctrl = VideoPlayerController.networkUrl(Uri.parse(asset.uri));
          break;
      }

      _controller = ctrl;
      await ctrl.initialize();
      _applyAudioPolicy();
      ctrl.setLooping(widget.videoPayload.isLooping);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (_) {
      // In test or non-hardware environments, gracefully fall back to cover display
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _hasError = true;
        });
      }
    }
  }

  void _applyAudioPolicy() {
    final ctrl = _controller;
    if (ctrl == null || !_isInitialized) return;

    final policy = widget.videoPayload.audioPolicy;
    if (policy.muteOriginal) {
      ctrl.setVolume(0.0);
    } else {
      ctrl.setVolume(policy.originalVolume.clamp(0.0, 1.0));
    }
  }

  void _disposePlayer() {
    _controller?.removeListener(_onTimelineChanged);
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    widget.timelineController?.removeListener(_onTimelineChanged);
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized && _controller != null) {
      final ctrl = _controller!;
      BoxFit fit;
      switch (widget.videoPayload.fitMode) {
        case VideoFitMode.contain:
          fit = BoxFit.contain;
          break;
        case VideoFitMode.fill:
          fit = BoxFit.fill;
          break;
        case VideoFitMode.cover:
          fit = BoxFit.cover;
          break;
      }

      return ClipRect(
        child: SizedBox.expand(
          child: FittedBox(
            fit: fit,
            child: SizedBox(
              width: ctrl.value.size.width > 0 ? ctrl.value.size.width : 1080,
              height:
                  ctrl.value.size.height > 0 ? ctrl.value.size.height : 1920,
              child: VideoPlayer(ctrl),
            ),
          ),
        ),
      );
    }

    // Graceful fallback for preview / testing environments:
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam, color: Colors.white70, size: 48),
          const SizedBox(height: 8),
          Text(
            _hasError ? 'Video preview unavailable' : 'Loading video...',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
