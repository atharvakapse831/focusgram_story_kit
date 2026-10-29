import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'story_element.dart';
import 'story_media_asset.dart';

/// Represents a single slide or screen within a multi-page story project.
@immutable
class StoryPage {
  const StoryPage({
    required this.id,
    this.duration = const Duration(seconds: 5),
    this.backgroundColor = Colors.black,
    this.backgroundAsset,
    this.elements = const [],
  });

  /// Stable identifier for this page.
  final String id;

  /// Default viewing duration when played in the viewer.
  final Duration duration;

  /// Solid background fill color.
  final Color backgroundColor;

  /// Optional background image/asset.
  final StoryMediaAsset? backgroundAsset;

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
    StoryMediaAsset? backgroundAsset,
    bool clearBackgroundAsset = false,
    List<StoryElement>? elements,
  }) {
    return StoryPage(
      id: id ?? this.id,
      duration: duration ?? this.duration,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundAsset:
          clearBackgroundAsset
              ? null
              : (backgroundAsset ?? this.backgroundAsset),
      elements: elements ?? this.elements,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'durationMs': duration.inMilliseconds,
    'backgroundColor': backgroundColor.toARGB32(),
    if (backgroundAsset != null) 'backgroundAsset': backgroundAsset!.toJson(),
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
      backgroundAsset:
          json['backgroundAsset'] != null
              ? StoryMediaAsset.fromJson(
                Map<String, dynamic>.from(json['backgroundAsset'] as Map),
              )
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
          runtimeType == other.runtimeType &&
          id == other.id &&
          duration == other.duration &&
          backgroundColor == other.backgroundColor &&
          backgroundAsset == other.backgroundAsset &&
          listEquals(elements, other.elements);

  @override
  int get hashCode => Object.hash(
    id,
    duration,
    backgroundColor,
    backgroundAsset,
    Object.hashAll(elements),
  );
}
