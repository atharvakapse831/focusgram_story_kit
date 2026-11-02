import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'timeline_controller.dart';

/// Bidirectional synchronization coordinator between native [VideoPlayerController] and [StoryTimelineController].
class StoryTimelineSyncCoordinator {
  StoryTimelineSyncCoordinator({required this.timelineController});

  final StoryTimelineController timelineController;
  VideoPlayerController? _videoController;
  VoidCallback? _videoListener;
  bool _isSeekingNative = false;
  DateTime? _lastSyncTimestamp;

  /// Currently attached video player controller.
  VideoPlayerController? get videoController => _videoController;

  /// Attaches a [VideoPlayerController] to coordinate playback with the timeline.
  void attach(VideoPlayerController controller) {
    if (_videoController == controller) return;
    detach();

    _videoController = controller;
    _videoListener = _onVideoPositionChanged;
    controller.addListener(_videoListener!);

    // Sync initial state
    if (controller.value.isInitialized) {
      final vDuration = controller.value.duration;
      if (vDuration > Duration.zero) {
        timelineController.setTotalDuration(vDuration);
      }
    }
  }

  /// Detaches the current video player controller.
  void detach() {
    if (_videoController != null && _videoListener != null) {
      _videoController!.removeListener(_videoListener!);
    }
    _videoController = null;
    _videoListener = null;
  }

  /// Synchronizes a user-driven timeline seek to the underlying native video player.
  Future<void> syncSeekTo(Duration target, {bool exact = false}) async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    _isSeekingNative = true;
    try {
      await controller.seekTo(target);
    } finally {
      _isSeekingNative = false;
    }
  }

  /// Synchronizes playback command (play/pause) to the native video player.
  Future<void> syncPlayPause(bool isPlaying) async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (isPlaying && !controller.value.isPlaying) {
      // If we are at the end of the trim range, seek to start before playing
      if (controller.value.position >= timelineController.state.effectiveEnd) {
        await controller.seekTo(timelineController.state.effectiveStart);
      }
      await controller.play();
    } else if (!isPlaying && controller.value.isPlaying) {
      await controller.pause();
    }
  }

  void _onVideoPositionChanged() {
    final controller = _videoController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isSeekingNative) {
      return;
    }

    final nativePos = controller.value.position;
    final trimEnd = timelineController.state.effectiveEnd;
    final trimStart = timelineController.state.effectiveStart;

    // Handle sub-clip looping boundary:
    if (nativePos >= trimEnd && controller.value.isPlaying) {
      if (timelineController.state.isLooping) {
        controller.seekTo(trimStart);
        timelineController.seekTo(trimStart, exact: true);
        return;
      } else {
        controller.pause();
        timelineController.pause();
        return;
      }
    }

    // Rate-limit drift checks to avoid throttling Flutter main thread
    final now = DateTime.now();
    if (_lastSyncTimestamp != null &&
        now.difference(_lastSyncTimestamp!).inMilliseconds < 16) {
      return;
    }
    _lastSyncTimestamp = now;

    // Frame-rate-relative drift detection
    final driftMs =
        (nativePos.inMilliseconds -
                timelineController.currentPosition.inMilliseconds)
            .abs();
    final allowedToleranceMs = timelineController.syncToleranceMs;

    if (driftMs > allowedToleranceMs) {
      timelineController.seekTo(nativePos, exact: false);
    }
  }

  /// Disposes coordinator subscriptions.
  void dispose() {
    detach();
  }
}
