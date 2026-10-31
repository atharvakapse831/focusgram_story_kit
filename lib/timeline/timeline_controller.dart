import 'package:flutter/foundation.dart';
import '../models/video_payload.dart';
import 'timeline_state.dart';

/// Centralized state controller and single source of truth for story timeline playback and scrubbing.
class StoryTimelineController extends ChangeNotifier {
  StoryTimelineController({
    Duration initialDuration = const Duration(seconds: 15),
    VideoTrimRange? initialTrimRange,
    double initialFrameRate = 30.0,
  }) : _state = StoryTimelineState(
         totalDuration: initialDuration,
         trimRange: initialTrimRange,
         frameRate: initialFrameRate,
         currentPosition: initialTrimRange?.start ?? Duration.zero,
       );

  StoryTimelineState _state;
  bool _isScrubbing = false;

  /// Current immutable snapshot of the timeline state.
  StoryTimelineState get state => _state;

  /// Active playhead position.
  Duration get currentPosition => _state.currentPosition;

  /// Total duration of the timeline.
  Duration get totalDuration => _state.totalDuration;

  /// Whether playback is actively running.
  bool get isPlaying => _state.isPlaying;

  /// Whether the user is actively scrubbing the playhead.
  bool get isScrubbing => _isScrubbing;

  /// Active trim range boundaries.
  VideoTrimRange? get trimRange => _state.trimRange;

  /// Dynamic frame-rate-relative synchronization tolerance in milliseconds.
  double get syncToleranceMs => _state.syncToleranceMs;

  /// Commences playback.
  void play() {
    if (_state.isPlaying) return;
    _state = _state.copyWith(isPlaying: true);
    notifyListeners();
  }

  /// Pauses playback.
  void pause() {
    if (!_state.isPlaying) return;
    _state = _state.copyWith(isPlaying: false);
    notifyListeners();
  }

  /// Toggles between play and pause.
  void togglePlayPause() {
    if (_state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  /// Updates playhead position.
  ///
  /// When [exact] is true, seeks with exact keyframe commitment (e.g. on scrub release).
  /// Clamps [position] between [effectiveStart] and [effectiveEnd].
  void seekTo(Duration position, {bool exact = false}) {
    final start = _state.effectiveStart;
    final end = _state.effectiveEnd;

    Duration target = position;
    if (target < start) target = start;
    if (target > end) target = end;

    if (_state.currentPosition == target) return;
    _state = _state.copyWith(currentPosition: target);
    notifyListeners();
  }

  /// Advances playhead by elapsed [delta]. Loops or stops at boundaries.
  void advance(Duration delta) {
    if (!_state.isPlaying) return;

    final scaledDeltaUs = (delta.inMicroseconds * _state.playbackSpeed).toInt();
    final newPos =
        _state.currentPosition + Duration(microseconds: scaledDeltaUs);
    final end = _state.effectiveEnd;

    if (newPos >= end) {
      if (_state.isLooping) {
        seekTo(_state.effectiveStart);
      } else {
        seekTo(end);
        pause();
      }
    } else {
      seekTo(newPos);
    }
  }

  /// Initiates interactive scrubbing. Pauses playback during gesture.
  void startScrubbing() {
    _isScrubbing = true;
    pause();
    notifyListeners();
  }

  /// Updates playhead based on normalized [progress] in [0.0, 1.0].
  void scrubToNormalized(double progress) {
    final clamped = progress.clamp(0.0, 1.0);
    final startMs = _state.effectiveStart.inMilliseconds;
    final totalMs = _state.effectiveDuration.inMilliseconds;
    final targetMs = startMs + (totalMs * clamped).toInt();
    seekTo(Duration(milliseconds: targetMs), exact: false);
  }

  /// Commits scrubbing with exact frame precision.
  void endScrubbing() {
    _isScrubbing = false;
    seekTo(_state.currentPosition, exact: true);
    notifyListeners();
  }

  /// Updates the active trim boundaries.
  void setTrimRange(VideoTrimRange? range) {
    if (_state.trimRange == range) return;
    _state = _state.copyWith(trimRange: range, clearTrimRange: range == null);

    // Ensure current position stays within new bounds
    if (_state.currentPosition < _state.effectiveStart) {
      _state = _state.copyWith(currentPosition: _state.effectiveStart);
    } else if (_state.currentPosition > _state.effectiveEnd) {
      _state = _state.copyWith(currentPosition: _state.effectiveEnd);
    }
    notifyListeners();
  }

  /// Updates total timeline duration.
  void setTotalDuration(Duration duration) {
    if (_state.totalDuration == duration) return;
    _state = _state.copyWith(totalDuration: duration);
    if (_state.currentPosition > duration) {
      _state = _state.copyWith(currentPosition: duration);
    }
    notifyListeners();
  }

  /// Sets playback speed multiplier.
  void setPlaybackSpeed(double speed) {
    if (speed <= 0 || _state.playbackSpeed == speed) return;
    _state = _state.copyWith(playbackSpeed: speed);
    notifyListeners();
  }

  /// Sets target frame rate for dynamic sync tolerance.
  void setFrameRate(double fps) {
    if (fps <= 0 || _state.frameRate == fps) return;
    _state = _state.copyWith(frameRate: fps);
    notifyListeners();
  }

  /// Splits the active video clip or trim range into two contiguous sub-clips at [splitTime].
  ///
  /// Returns a tuple of `(VideoTrimRange first, VideoTrimRange second)`, or `null` if [splitTime]
  /// does not strictly fall between the clip start and end.
  ({VideoTrimRange first, VideoTrimRange second})? splitAt(Duration splitTime) {
    final start = _state.effectiveStart;
    final end = _state.effectiveEnd;

    if (splitTime <= start || splitTime >= end) {
      return null;
    }

    final first = VideoTrimRange(start: start, end: splitTime);
    final second = VideoTrimRange(start: splitTime, end: end);
    return (first: first, second: second);
  }
}
