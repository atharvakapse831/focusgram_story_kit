import 'package:flutter/material.dart';
import 'element_payloads.dart';

/// Supported geometric vector shape primitives.
enum ShapeType {
  rectangle,
  circle,
  star,
  heart,
  line,
  arrow;

  static ShapeType fromString(String? raw) {
    if (raw == null) return ShapeType.rectangle;
    return ShapeType.values.firstWhere(
      (e) => e.name.toLowerCase() == raw.toLowerCase().trim(),
      orElse: () => ShapeType.rectangle,
    );
  }
}

/// Payload for customizable geometric shape overlays.
@immutable
class ShapeElementPayload extends StoryElementPayload {
  const ShapeElementPayload({
    required this.shapeType,
    this.fillColor,
    this.strokeColor = Colors.white,
    this.strokeWidth = 2.0,
    this.cornerRadius = 8.0,
  });

  /// The geometric primitive to draw.
  final ShapeType shapeType;

  /// Interior fill color (null for outline-only shapes).
  final Color? fillColor;

  /// Border / outline stroke color.
  final Color strokeColor;

  /// Border stroke thickness in screen pixels.
  final double strokeWidth;

  /// Rounded corner radius for rectangular shapes.
  final double cornerRadius;

  @override
  String get typeDiscriminator => 'shape';

  ShapeElementPayload copyWith({
    ShapeType? shapeType,
    Color? fillColor,
    bool clearFillColor = false,
    Color? strokeColor,
    double? strokeWidth,
    double? cornerRadius,
  }) {
    return ShapeElementPayload(
      shapeType: shapeType ?? this.shapeType,
      fillColor: clearFillColor ? null : (fillColor ?? this.fillColor),
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      cornerRadius: cornerRadius ?? this.cornerRadius,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'shapeType': shapeType.name,
    if (fillColor != null) 'fillColor': fillColor!.toARGB32(),
    'strokeColor': strokeColor.toARGB32(),
    'strokeWidth': strokeWidth,
    'cornerRadius': cornerRadius,
  };

  factory ShapeElementPayload.fromJson(Map<String, dynamic> json) {
    return ShapeElementPayload(
      shapeType: ShapeType.fromString(json['shapeType'] as String?),
      fillColor:
          json['fillColor'] != null ? Color(json['fillColor'] as int) : null,
      strokeColor:
          json['strokeColor'] != null
              ? Color(json['strokeColor'] as int)
              : Colors.white,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 8.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShapeElementPayload &&
          shapeType == other.shapeType &&
          fillColor?.toARGB32() == other.fillColor?.toARGB32() &&
          strokeColor.toARGB32() == other.strokeColor.toARGB32() &&
          strokeWidth == other.strokeWidth &&
          cornerRadius == other.cornerRadius;

  @override
  int get hashCode =>
      Object.hash(shapeType, fillColor, strokeColor, strokeWidth, cornerRadius);
}
