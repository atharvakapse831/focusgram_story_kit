import 'package:flutter/foundation.dart';

/// Supported storage/transport origins for media assets in a story project.
enum StoryMediaSourceType { network, file, memory, asset }

/// A media asset reference used for page backgrounds, image layers, or stickers.
@immutable
class StoryMediaAsset {
  const StoryMediaAsset({
    required this.id,
    required this.sourceType,
    required this.uri,
    this.mimeType,
    this.width,
    this.height,
    this.duration,
  });

  /// Stable identifier for the media asset.
  final String id;

  /// Origin type (network URL, local file path, asset bundle, or memory key).
  final StoryMediaSourceType sourceType;

  /// URI string or local filesystem path.
  final String uri;

  /// MIME type (e.g., 'image/png', 'image/jpeg', 'video/mp4').
  final String? mimeType;

  /// Native pixel width if known.
  final int? width;

  /// Native pixel height if known.
  final int? height;

  /// Asset playback duration if time-based.
  final Duration? duration;

  StoryMediaAsset copyWith({
    String? id,
    StoryMediaSourceType? sourceType,
    String? uri,
    String? mimeType,
    int? width,
    int? height,
    Duration? duration,
  }) {
    return StoryMediaAsset(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      uri: uri ?? this.uri,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceType': sourceType.name,
    'uri': uri,
    if (mimeType != null) 'mimeType': mimeType,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (duration != null) 'durationMs': duration!.inMilliseconds,
  };

  factory StoryMediaAsset.fromJson(Map<String, dynamic> json) {
    return StoryMediaAsset(
      id: json['id'] as String? ?? '',
      sourceType: StoryMediaSourceType.values.firstWhere(
        (e) => e.name == json['sourceType'],
        orElse: () => StoryMediaSourceType.network,
      ),
      uri: json['uri'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      duration:
          json['durationMs'] != null
              ? Duration(milliseconds: json['durationMs'] as int)
              : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryMediaAsset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sourceType == other.sourceType &&
          uri == other.uri &&
          mimeType == other.mimeType &&
          width == other.width &&
          height == other.height &&
          duration == other.duration;

  @override
  int get hashCode =>
      Object.hash(id, sourceType, uri, mimeType, width, height, duration);
}
