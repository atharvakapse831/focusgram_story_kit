import 'package:flutter/foundation.dart';
import '../models/video_payload.dart';
import 'video_transition_math.dart';

/// Immutable snapshot representing the playback, scrub, and boundary state of the story timeline.
@immutable
class StoryTimelineState {
  const StoryTimelineState({
    this.currentPosition = Duration.zero,
    this.totalDuration = const Duration(seconds: 15),
    this.isPlaying = false,
    this.isLooping = true,
    this.playbackSpeed = 1.0,
    this.trimRange,
    this.frameRate = 30.0,
  }) : assert(playbackSpeed > 0, 'playbackSpeed must be positive');

  /// Current playhead position relative to the start of the timeline.
  final Duration currentPosition;

  /// Total duration of the active story page or video clip.
  final Duration totalDuration;

  /// Whether timeline playback is actively progressing.
  final bool isPlaying;

  /// Whether playback automatically loops when reaching the end of the trim range or duration.
  final bool isLooping;

  /// Playback speed multiplier (e.g. 0.5x, 1.0x, 2.0x).
  final double playbackSpeed;

  /// Optional active sub-clip trim boundary.
  final VideoTrimRange? trimRange;

  /// Effective frame rate of the active video or preview canvas (defaults to 30.0 fps).
  final double frameRate;

  /// Dynamic synchronization tolerance in milliseconds:
  /// $$\pm \left(\frac{1000}{\text{frameRate}}\right) \text{ms}$$
  double get syncToleranceMs => StoryTransitionMath.frameToleranceMs(frameRate);

  /// Effective playback start point (trim start or zero).
  Duration get effectiveStart => trimRange?.start ?? Duration.zero;

  /// Effective playback end point (trim end or totalDuration).
  Duration get effectiveEnd => trimRange?.end ?? totalDuration;

  /// Effective playable duration.
  Duration get effectiveDuration {
    if (trimRange != null) return trimRange!.duration;
    return totalDuration;
  }

  /// Normalized progress factor [0.0, 1.0] within the effective playable window.
  double get normalizedProgress {
    final startMs = effectiveStart.inMilliseconds;
    final endMs = effectiveEnd.inMilliseconds;
    final totalMs = endMs - startMs;
    if (totalMs <= 0) return 0.0;
    final currentMs = currentPosition.inMilliseconds - startMs;
    return (currentMs / totalMs).clamp(0.0, 1.0);
  }

  StoryTimelineState copyWith({
    Duration? currentPosition,
    Duration? totalDuration,
    bool? isPlaying,
    bool? isLooping,
    double? playbackSpeed,
    VideoTrimRange? trimRange,
    bool clearTrimRange = false,
    double? frameRate,
  }) {
    return StoryTimelineState(
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      isPlaying: isPlaying ?? this.isPlaying,
      isLooping: isLooping ?? this.isLooping,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      trimRange: clearTrimRange ? null : (trimRange ?? this.trimRange),
      frameRate: frameRate ?? this.frameRate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryTimelineState &&
          runtimeType == other.runtimeType &&
          currentPosition == other.currentPosition &&
          totalDuration == other.totalDuration &&
          isPlaying == other.isPlaying &&
          isLooping == other.isLooping &&
          playbackSpeed == other.playbackSpeed &&
          trimRange == other.trimRange &&
          frameRate == other.frameRate;

  @override
  int get hashCode => Object.hash(
    currentPosition,
    totalDuration,
    isPlaying,
    isLooping,
    playbackSpeed,
    trimRange,
    frameRate,
  );
}
