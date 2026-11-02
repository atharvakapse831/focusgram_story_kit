import 'package:flutter/foundation.dart';
import 'video_payload.dart';

/// Policy dictating behavior when an imported video exceeds the maximum story page duration.
enum VideoDurationPolicy {
  /// Opens interactive trim controls allowing creator to select interval (Default).
  trimWindow,

  /// Automatically segments long video across consecutive story pages.
  segmentPages,

  /// Rejects the video with an informative prompt.
  rejectWithPrompt;

  static VideoDurationPolicy fromString(String? raw) {
    if (raw == null) return VideoDurationPolicy.trimWindow;
    switch (raw.toLowerCase().trim()) {
      case 'segmentpages':
      case 'segment_pages':
        return VideoDurationPolicy.segmentPages;
      case 'rejectwithprompt':
      case 'reject_with_prompt':
        return VideoDurationPolicy.rejectWithPrompt;
      case 'trimwindow':
      case 'trim_window':
      default:
        return VideoDurationPolicy.trimWindow;
    }
  }
}

/// Global host-application configuration for Story Kit video and editing parameters.
@immutable
class StoryKitConfiguration {
  const StoryKitConfiguration({
    this.maxStoryDuration = const Duration(seconds: 15),
    this.minStoryDuration = const Duration(seconds: 1),
    this.defaultVideoDurationPolicy = VideoDurationPolicy.trimWindow,
    this.defaultAudioSampleRate = AudioSampleRate.hz44100,
    this.defaultAudioBitrateKbps = 128,
    this.enableMultiPageSegmentation = true,
  });

  /// Host-configurable maximum duration for a single story page (e.g. 15s to 60s).
  final Duration maxStoryDuration;

  /// Minimum allowable duration for a story page or video clip.
  final Duration minStoryDuration;

  /// Default action taken when imported video duration exceeds [maxStoryDuration].
  final VideoDurationPolicy defaultVideoDurationPolicy;

  /// Default audio sample rate for export.
  final AudioSampleRate defaultAudioSampleRate;

  /// Default audio bitrate for export.
  final int defaultAudioBitrateKbps;

  /// Whether automatic segmentation across multiple pages is supported.
  final bool enableMultiPageSegmentation;

  StoryKitConfiguration copyWith({
    Duration? maxStoryDuration,
    Duration? minStoryDuration,
    VideoDurationPolicy? defaultVideoDurationPolicy,
    AudioSampleRate? defaultAudioSampleRate,
    int? defaultAudioBitrateKbps,
    bool? enableMultiPageSegmentation,
  }) {
    return StoryKitConfiguration(
      maxStoryDuration: maxStoryDuration ?? this.maxStoryDuration,
      minStoryDuration: minStoryDuration ?? this.minStoryDuration,
      defaultVideoDurationPolicy:
          defaultVideoDurationPolicy ?? this.defaultVideoDurationPolicy,
      defaultAudioSampleRate:
          defaultAudioSampleRate ?? this.defaultAudioSampleRate,
      defaultAudioBitrateKbps:
          defaultAudioBitrateKbps ?? this.defaultAudioBitrateKbps,
      enableMultiPageSegmentation:
          enableMultiPageSegmentation ?? this.enableMultiPageSegmentation,
    );
  }

  Map<String, dynamic> toJson() => {
    'maxStoryDurationMs': maxStoryDuration.inMilliseconds,
    'minStoryDurationMs': minStoryDuration.inMilliseconds,
    'defaultVideoDurationPolicy': defaultVideoDurationPolicy.name,
    'defaultAudioSampleRate': defaultAudioSampleRate.rate,
    'defaultAudioBitrateKbps': defaultAudioBitrateKbps,
    'enableMultiPageSegmentation': enableMultiPageSegmentation,
  };

  factory StoryKitConfiguration.fromJson(Map<String, dynamic> json) {
    return StoryKitConfiguration(
      maxStoryDuration: Duration(
        milliseconds: json['maxStoryDurationMs'] as int? ?? 15000,
      ),
      minStoryDuration: Duration(
        milliseconds: json['minStoryDurationMs'] as int? ?? 1000,
      ),
      defaultVideoDurationPolicy: VideoDurationPolicy.fromString(
        json['defaultVideoDurationPolicy'] as String?,
      ),
      defaultAudioSampleRate: AudioSampleRate.fromInt(
        json['defaultAudioSampleRate'] as int? ?? 44100,
      ),
      defaultAudioBitrateKbps: json['defaultAudioBitrateKbps'] as int? ?? 128,
      enableMultiPageSegmentation:
          json['enableMultiPageSegmentation'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryKitConfiguration &&
          runtimeType == other.runtimeType &&
          maxStoryDuration == other.maxStoryDuration &&
          minStoryDuration == other.minStoryDuration &&
          defaultVideoDurationPolicy == other.defaultVideoDurationPolicy &&
          defaultAudioSampleRate == other.defaultAudioSampleRate &&
          defaultAudioBitrateKbps == other.defaultAudioBitrateKbps &&
          enableMultiPageSegmentation == other.enableMultiPageSegmentation;

  @override
  int get hashCode => Object.hash(
    maxStoryDuration,
    minStoryDuration,
    defaultVideoDurationPolicy,
    defaultAudioSampleRate,
    defaultAudioBitrateKbps,
    enableMultiPageSegmentation,
  );
}
