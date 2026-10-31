import 'package:flutter/foundation.dart';
import 'element_payloads.dart';
import 'story_transform.dart';

/// Supported classifications for visual story elements.
enum StoryElementType {
  text,
  image,
  sticker,
  card,
  drawing,
  shape,
  unknown;

  static StoryElementType fromString(String? raw) {
    if (raw == null) return StoryElementType.unknown;
    switch (raw.toLowerCase().trim()) {
      case 'text':
        return StoryElementType.text;
      case 'image':
        return StoryElementType.image;
      case 'sticker':
        return StoryElementType.sticker;
      case 'card':
        return StoryElementType.card;
      case 'drawing':
        return StoryElementType.drawing;
      case 'shape':
        return StoryElementType.shape;
      default:
        return StoryElementType.unknown;
    }
  }
}

/// A discrete, transformable, and serializable visual layer within a story page.
@immutable
class StoryElement {
  const StoryElement({
    required this.id,
    required this.type,
    required this.transform,
    required this.payload,
    this.opacity = 1.0,
    this.zIndex = 0,
    this.isVisible = true,
    this.isLocked = false,
  }) : assert(
         opacity >= 0.0 && opacity <= 1.0,
         'opacity must be in [0.0, 1.0]',
       );

  /// Stable unique identifier for this element.
  final String id;

  /// High-level element category.
  final StoryElementType type;

  /// Normalized canvas transform (position, dimensions, rotation, scale).
  final StoryTransform transform;

  /// Layer opacity factor [0.0, 1.0].
  final double opacity;

  /// Stacking z-order index (higher values render on top).
  final int zIndex;

  /// Whether the element is currently visible on canvas and export.
  final bool isVisible;

  /// When true, prevents selection and interactive transformation.
  final bool isLocked;

  /// Typed element content (text styling, image asset, sticker, shared card, etc.).
  final StoryElementPayload payload;

  StoryElement copyWith({
    String? id,
    StoryElementType? type,
    StoryTransform? transform,
    StoryElementPayload? payload,
    double? opacity,
    int? zIndex,
    bool? isVisible,
    bool? isLocked,
  }) {
    return StoryElement(
      id: id ?? this.id,
      type: type ?? this.type,
      transform: transform ?? this.transform,
      payload: payload ?? this.payload,
      opacity: opacity ?? this.opacity,
      zIndex: zIndex ?? this.zIndex,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'transform': transform.toJson(),
    'opacity': opacity,
    'zIndex': zIndex,
    'isVisible': isVisible,
    'isLocked': isLocked,
    'payload': payload.toJson(),
  };

  factory StoryElement.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String? ?? 'unknown';
    final type = StoryElementType.fromString(typeString);
    final payloadJson = Map<String, dynamic>.from(
      json['payload'] as Map? ?? {},
    );

    return StoryElement(
      id: json['id'] as String? ?? '',
      type: type,
      transform: StoryTransform.fromJson(
        Map<String, dynamic>.from(json['transform'] as Map? ?? {}),
      ),
      payload: StoryElementPayload.fromJson(typeString, payloadJson),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      zIndex: json['zIndex'] as int? ?? 0,
      isVisible: json['isVisible'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryElement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          transform == other.transform &&
          opacity == other.opacity &&
          zIndex == other.zIndex &&
          isVisible == other.isVisible &&
          isLocked == other.isLocked &&
          payload == other.payload;

  @override
  int get hashCode => Object.hash(
    id,
    type,
    transform,
    opacity,
    zIndex,
    isVisible,
    isLocked,
    payload,
  );
}
