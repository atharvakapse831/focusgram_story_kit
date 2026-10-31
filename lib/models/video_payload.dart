import 'package:flutter/foundation.dart';
import 'story_media_asset.dart';

/// Target audio sample rate for video export and audio mixing.
enum AudioSampleRate {
  hz44100(44100),
  hz48000(48000);

  final int rate;
  const AudioSampleRate(this.rate);

  /// Sample rate expressed in Hz.
  int get sampleRateHz => rate;

  static AudioSampleRate fromInt(int? raw) {
    if (raw == 48000) return AudioSampleRate.hz48000;
    return AudioSampleRate.hz44100;
  }
}

/// Fitting strategy for video layers within canvas bounds.
enum VideoFitMode {
  cover,
  contain,
  fill;

  static VideoFitMode fromString(String? raw) {
    if (raw == null) return VideoFitMode.cover;
    switch (raw.toLowerCase().trim()) {
      case 'contain':
        return VideoFitMode.contain;
      case 'fill':
        return VideoFitMode.fill;
      case 'cover':
      default:
        return VideoFitMode.cover;
    }
  }
}

/// Sub-clip trim boundaries defining playback start and end offsets.
@immutable
class VideoTrimRange {
  const VideoTrimRange({this.start = Duration.zero, required this.end});

  final Duration start;
  final Duration end;

  /// Effective duration of this trimmed segment.
  Duration get duration => end - start;

  /// Checks if a timestamp falls within this trim interval.
  bool contains(Duration timestamp) => timestamp >= start && timestamp <= end;

  VideoTrimRange copyWith({Duration? start, Duration? end}) {
    final newStart = start ?? this.start;
    final newEnd = end ?? this.end;
    return VideoTrimRange(
      start: newStart,
      end: newEnd < newStart ? newStart : newEnd,
    );
  }

  Map<String, dynamic> toJson() => {
    'startMs': start.inMilliseconds,
    'endMs': end.inMilliseconds,
  };

  factory VideoTrimRange.fromJson(Map<String, dynamic> json) {
    final startMs = json['startMs'] as int? ?? 0;
    final endMs = json['endMs'] as int? ?? startMs;
    return VideoTrimRange(
      start: Duration(milliseconds: startMs),
      end: Duration(milliseconds: endMs < startMs ? startMs : endMs),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoTrimRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Comprehensive audio policy configuration for story videos.
@immutable
class VideoAudioPolicy {
  const VideoAudioPolicy({
    this.muteOriginal = false,
    this.originalVolume = 1.0,
    this.musicAsset,
    this.musicVolume = 1.0,
    this.musicStartTime = Duration.zero,
    this.audioSampleRate = AudioSampleRate.hz44100,
    this.audioBitrateKbps = 128,
  }) : assert(
         originalVolume >= 0.0 && originalVolume <= 1.0,
         'originalVolume must be in [0.0, 1.0]',
       ),
       assert(
         musicVolume >= 0.0 && musicVolume <= 1.0,
         'musicVolume must be in [0.0, 1.0]',
       );

  /// Whether to completely mute original source audio track.
  final bool muteOriginal;

  /// Volume multiplier for original audio [0.0, 1.0].
  final double originalVolume;

  /// Optional attached background music or audio asset.
  final StoryMediaAsset? musicAsset;

  /// Volume multiplier for background music [0.0, 1.0].
  final double musicVolume;

  /// Start offset within background music asset.
  final Duration musicStartTime;

  /// Target audio sample rate for playback/export.
  final AudioSampleRate audioSampleRate;

  /// Target audio bitrate in kbps for export.
  final int audioBitrateKbps;

  /// Convenience getter for muting state.
  bool get isMuted => muteOriginal;

  /// Convenience getter for volume multiplier.
  double get volumeMultiplier => originalVolume;

  VideoAudioPolicy copyWith({
    bool? muteOriginal,
    double? originalVolume,
    StoryMediaAsset? musicAsset,
    bool clearMusicAsset = false,
    double? musicVolume,
    Duration? musicStartTime,
    AudioSampleRate? audioSampleRate,
    int? audioBitrateKbps,
  }) {
    return VideoAudioPolicy(
      muteOriginal: muteOriginal ?? this.muteOriginal,
      originalVolume: originalVolume ?? this.originalVolume,
      musicAsset: clearMusicAsset ? null : (musicAsset ?? this.musicAsset),
      musicVolume: musicVolume ?? this.musicVolume,
      musicStartTime: musicStartTime ?? this.musicStartTime,
      audioSampleRate: audioSampleRate ?? this.audioSampleRate,
      audioBitrateKbps: audioBitrateKbps ?? this.audioBitrateKbps,
    );
  }

  Map<String, dynamic> toJson() => {
    'muteOriginal': muteOriginal,
    'originalVolume': originalVolume,
    if (musicAsset != null) 'musicAsset': musicAsset!.toJson(),
    'musicVolume': musicVolume,
    'musicStartTimeMs': musicStartTime.inMilliseconds,
    'audioSampleRate': audioSampleRate.rate,
    'audioBitrateKbps': audioBitrateKbps,
  };

  factory VideoAudioPolicy.fromJson(Map<String, dynamic> json) {
    return VideoAudioPolicy(
      muteOriginal: json['muteOriginal'] as bool? ?? false,
      originalVolume: (json['originalVolume'] as num?)?.toDouble() ?? 1.0,
      musicAsset:
          json['musicAsset'] != null
              ? StoryMediaAsset.fromJson(
                Map<String, dynamic>.from(json['musicAsset'] as Map),
              )
              : null,
      musicVolume: (json['musicVolume'] as num?)?.toDouble() ?? 1.0,
      musicStartTime: Duration(
        milliseconds: json['musicStartTimeMs'] as int? ?? 0,
      ),
      audioSampleRate: AudioSampleRate.fromInt(
        json['audioSampleRate'] as int? ?? 44100,
      ),
      audioBitrateKbps: json['audioBitrateKbps'] as int? ?? 128,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoAudioPolicy &&
          runtimeType == other.runtimeType &&
          muteOriginal == other.muteOriginal &&
          originalVolume == other.originalVolume &&
          musicAsset == other.musicAsset &&
          musicVolume == other.musicVolume &&
          musicStartTime == other.musicStartTime &&
          audioSampleRate == other.audioSampleRate &&
          audioBitrateKbps == other.audioBitrateKbps;

  @override
  int get hashCode => Object.hash(
    muteOriginal,
    originalVolume,
    musicAsset,
    musicVolume,
    musicStartTime,
    audioSampleRate,
    audioBitrateKbps,
  );
}

/// Metadata and playback properties for video assets in FocusGram Story Kit.
@immutable
class StoryVideoPayload {
  const StoryVideoPayload({
    required this.asset,
    required this.trimRange,
    this.audioPolicy = const VideoAudioPolicy(),
    this.fitMode = VideoFitMode.cover,
    this.playbackSpeed = 1.0,
    this.coverTimestamp,
    this.isLooping = true,
  }) : assert(playbackSpeed > 0.0, 'playbackSpeed must be positive');

  /// Media asset reference (file path or remote URL).
  final StoryMediaAsset asset;

  /// In/out trim boundaries for playback.
  final VideoTrimRange trimRange;

  /// Audio mixing and muting parameters.
  final VideoAudioPolicy audioPolicy;

  /// Scaling and aspect ratio fit mode.
  final VideoFitMode fitMode;

  /// Playback speed multiplier (e.g. 0.5x, 1.0x, 2.0x).
  final double playbackSpeed;

  /// Timestamp selected for still image cover thumbnail.
  final Duration? coverTimestamp;

  /// Whether video should loop continuously on canvas/preview.
  final bool isLooping;

  /// Effective duration of trimmed playback.
  Duration get effectiveDuration => trimRange.duration;

  StoryVideoPayload copyWith({
    StoryMediaAsset? asset,
    VideoTrimRange? trimRange,
    VideoAudioPolicy? audioPolicy,
    VideoFitMode? fitMode,
    double? playbackSpeed,
    Duration? coverTimestamp,
    bool? isLooping,
  }) {
    return StoryVideoPayload(
      asset: asset ?? this.asset,
      trimRange: trimRange ?? this.trimRange,
      audioPolicy: audioPolicy ?? this.audioPolicy,
      fitMode: fitMode ?? this.fitMode,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      coverTimestamp: coverTimestamp ?? this.coverTimestamp,
      isLooping: isLooping ?? this.isLooping,
    );
  }

  Map<String, dynamic> toJson() => {
    'asset': asset.toJson(),
    'trimRange': trimRange.toJson(),
    'audioPolicy': audioPolicy.toJson(),
    'fitMode': fitMode.name,
    'playbackSpeed': playbackSpeed,
    if (coverTimestamp != null)
      'coverTimestampMs': coverTimestamp!.inMilliseconds,
    'isLooping': isLooping,
  };

  factory StoryVideoPayload.fromJson(Map<String, dynamic> json) {
    return StoryVideoPayload(
      asset: StoryMediaAsset.fromJson(
        Map<String, dynamic>.from(json['asset'] as Map? ?? {}),
      ),
      trimRange: VideoTrimRange.fromJson(
        Map<String, dynamic>.from(json['trimRange'] as Map? ?? {}),
      ),
      audioPolicy:
          json['audioPolicy'] != null
              ? VideoAudioPolicy.fromJson(
                Map<String, dynamic>.from(json['audioPolicy'] as Map),
              )
              : const VideoAudioPolicy(),
      fitMode: VideoFitMode.fromString(json['fitMode'] as String?),
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      coverTimestamp:
          json['coverTimestampMs'] != null
              ? Duration(milliseconds: json['coverTimestampMs'] as int)
              : null,
      isLooping: json['isLooping'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryVideoPayload &&
          runtimeType == other.runtimeType &&
          asset == other.asset &&
          trimRange == other.trimRange &&
          audioPolicy == other.audioPolicy &&
          fitMode == other.fitMode &&
          playbackSpeed == other.playbackSpeed &&
          coverTimestamp == other.coverTimestamp &&
          isLooping == other.isLooping;

  @override
  int get hashCode => Object.hash(
    asset,
    trimRange,
    audioPolicy,
    fitMode,
    playbackSpeed,
    coverTimestamp,
    isLooping,
  );
}
