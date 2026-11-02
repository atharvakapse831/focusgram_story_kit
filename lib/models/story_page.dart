import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'gradient_background.dart';
import 'image_adjustments.dart';
import 'story_element.dart';
import 'story_media_asset.dart';
import 'video_payload.dart';

/// Represents a single slide or screen within a multi-page story project.
@immutable
class StoryPage {
  const StoryPage({
    required this.id,
    this.duration = const Duration(seconds: 5),
    this.backgroundColor = Colors.black,
    this.backgroundGradient,
    this.backgroundAsset,
    this.imageAdjustments,
    this.videoTrimRange,
    this.audioPolicy,
    this.coverTimestamp,
    this.elements = const [],
  });

  /// Stable identifier for this page.
  final String id;

  /// Default viewing duration when played in the viewer.
  final Duration duration;

  /// Solid background fill color.
  final Color backgroundColor;

  /// Optional gradient background fill.
  final StoryGradientBackground? backgroundGradient;

  /// Optional background image/asset.
  final StoryMediaAsset? backgroundAsset;

  /// Optional non-destructive color adjustments and filters for background image.
  final ImageAdjustments? imageAdjustments;

  /// Optional trim boundaries for background video.
  final VideoTrimRange? videoTrimRange;

  /// Optional audio policy for background video or soundtrack.
  final VideoAudioPolicy? audioPolicy;

  /// Timestamp selected for video cover thumbnail.
  final Duration? coverTimestamp;

  /// Visual elements stacked on this page, ordered by increasing zIndex.
  final List<StoryElement> elements;

  /// Returns elements sorted deterministically by `zIndex`, tie-broken by index.
  List<StoryElement> get sortedElements {
    final list = List<StoryElement>.from(elements);
    list.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return list;
  }

  /// Finds an element by its ID.
  StoryElement? getElement(String id) {
    for (final el in elements) {
      if (el.id == id) return el;
    }
    return null;
  }

  StoryPage copyWith({
    String? id,
    Duration? duration,
    Color? backgroundColor,
    StoryGradientBackground? backgroundGradient,
    bool clearBackgroundGradient = false,
    StoryMediaAsset? backgroundAsset,
    bool clearBackgroundAsset = false,
    ImageAdjustments? imageAdjustments,
    bool clearImageAdjustments = false,
    VideoTrimRange? videoTrimRange,
    bool clearVideoTrimRange = false,
    VideoAudioPolicy? audioPolicy,
    bool clearAudioPolicy = false,
    Duration? coverTimestamp,
    bool clearCoverTimestamp = false,
    List<StoryElement>? elements,
  }) {
    return StoryPage(
      id: id ?? this.id,
      duration: duration ?? this.duration,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundGradient:
          clearBackgroundGradient
              ? null
              : (backgroundGradient ?? this.backgroundGradient),
      backgroundAsset:
          clearBackgroundAsset
              ? null
              : (backgroundAsset ?? this.backgroundAsset),
      imageAdjustments:
          clearImageAdjustments
              ? null
              : (imageAdjustments ?? this.imageAdjustments),
      videoTrimRange:
          clearVideoTrimRange ? null : (videoTrimRange ?? this.videoTrimRange),
      audioPolicy: clearAudioPolicy ? null : (audioPolicy ?? this.audioPolicy),
      coverTimestamp:
          clearCoverTimestamp ? null : (coverTimestamp ?? this.coverTimestamp),
      elements: elements ?? this.elements,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'durationMs': duration.inMilliseconds,
    'backgroundColor': backgroundColor.toARGB32(),
    if (backgroundGradient != null)
      'backgroundGradient': backgroundGradient!.toJson(),
    if (backgroundAsset != null) 'backgroundAsset': backgroundAsset!.toJson(),
    if (imageAdjustments != null)
      'imageAdjustments': imageAdjustments!.toJson(),
    if (videoTrimRange != null) 'videoTrimRange': videoTrimRange!.toJson(),
    if (audioPolicy != null) 'audioPolicy': audioPolicy!.toJson(),
    if (coverTimestamp != null)
      'coverTimestampMs': coverTimestamp!.inMilliseconds,
    'elements': elements.map((e) => e.toJson()).toList(),
  };

  factory StoryPage.fromJson(Map<String, dynamic> json) {
    return StoryPage(
      id: json['id'] as String? ?? '',
      duration:
          json['durationMs'] != null
              ? Duration(milliseconds: json['durationMs'] as int)
              : const Duration(seconds: 5),
      backgroundColor:
          json['backgroundColor'] != null
              ? Color(json['backgroundColor'] as int)
              : Colors.black,
      backgroundGradient:
          json['backgroundGradient'] != null
              ? StoryGradientBackground.fromJson(
                Map<String, dynamic>.from(json['backgroundGradient'] as Map),
              )
              : null,
      backgroundAsset:
          json['backgroundAsset'] != null
              ? StoryMediaAsset.fromJson(
                Map<String, dynamic>.from(json['backgroundAsset'] as Map),
              )
              : null,
      imageAdjustments:
          json['imageAdjustments'] != null
              ? ImageAdjustments.fromJson(
                Map<String, dynamic>.from(json['imageAdjustments'] as Map),
              )
              : null,
      videoTrimRange:
          json['videoTrimRange'] != null
              ? VideoTrimRange.fromJson(
                Map<String, dynamic>.from(json['videoTrimRange'] as Map),
              )
              : null,
      audioPolicy:
          json['audioPolicy'] != null
              ? VideoAudioPolicy.fromJson(
                Map<String, dynamic>.from(json['audioPolicy'] as Map),
              )
              : null,
      coverTimestamp:
          json['coverTimestampMs'] != null
              ? Duration(milliseconds: json['coverTimestampMs'] as int)
              : null,
      elements:
          (json['elements'] as List<dynamic>? ?? [])
              .map(
                (e) =>
                    StoryElement.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryPage &&
          id == other.id &&
          duration == other.duration &&
          backgroundColor.toARGB32() == other.backgroundColor.toARGB32() &&
          backgroundGradient == other.backgroundGradient &&
          backgroundAsset == other.backgroundAsset &&
          imageAdjustments == other.imageAdjustments &&
          videoTrimRange == other.videoTrimRange &&
          audioPolicy == other.audioPolicy &&
          coverTimestamp == other.coverTimestamp &&
          listEquals(elements, other.elements);

  @override
  int get hashCode => Object.hash(
    id,
    duration,
    backgroundColor,
    backgroundGradient,
    backgroundAsset,
    imageAdjustments,
    videoTrimRange,
    audioPolicy,
    coverTimestamp,
    Object.hashAll(elements),
  );
}
