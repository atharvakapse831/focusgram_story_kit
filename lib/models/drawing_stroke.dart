import 'package:flutter/material.dart';

/// Supported brush styles for freehand drawing.
enum DrawingBrushType {
  pen,
  marker,
  neon,
  eraser;

  static DrawingBrushType fromString(String? raw) {
    if (raw == null) return DrawingBrushType.pen;
    return DrawingBrushType.values.firstWhere(
      (e) => e.name.toLowerCase() == raw.toLowerCase().trim(),
      orElse: () => DrawingBrushType.pen,
    );
  }
}

/// A normalized 2D coordinate point within a drawing stroke in `[0.0, 1.0]`.
@immutable
class DrawingPoint {
  const DrawingPoint({required this.x, required this.y});

  final double x;
  final double y;

  Offset toOffset(Size canvasSize) =>
      Offset(x * canvasSize.width, y * canvasSize.height);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// A single continuous freehand stroke drawn on the story canvas.
@immutable
class DrawingStroke {
  const DrawingStroke({
    required this.points,
    this.color = Colors.white,
    this.strokeWidth = 0.008,
    this.opacity = 1.0,
    this.brushType = DrawingBrushType.pen,
  }) : assert(opacity >= 0.0 && opacity <= 1.0, 'opacity in [0, 1]');

  /// Normalized trajectory coordinates.
  final List<DrawingPoint> points;

  /// Stroke tint.
  final Color color;

  /// Stroke width normalized to canvas width (e.g. 0.008 ≈ 8.6px on a 1080 canvas).
  final double strokeWidth;

  /// Stroke opacity [0.0, 1.0].
  final double opacity;

  /// Brush rendering style.
  final DrawingBrushType brushType;

  DrawingStroke copyWith({
    List<DrawingPoint>? points,
    Color? color,
    double? strokeWidth,
    double? opacity,
    DrawingBrushType? brushType,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      brushType: brushType ?? this.brushType,
    );
  }

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => p.toJson()).toList(),
    'color': color.toARGB32(),
    'strokeWidth': strokeWidth,
    'opacity': opacity,
    'brushType': brushType.name,
  };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      points:
          (json['points'] as List<dynamic>? ?? [])
              .map(
                (p) =>
                    DrawingPoint.fromJson(Map<String, dynamic>.from(p as Map)),
              )
              .toList(),
      color: json['color'] != null ? Color(json['color'] as int) : Colors.white,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 0.008,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      brushType: DrawingBrushType.fromString(json['brushType'] as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingStroke &&
          color.toARGB32() == other.color.toARGB32() &&
          strokeWidth == other.strokeWidth &&
          opacity == other.opacity &&
          brushType == other.brushType &&
          _listEquals(points, other.points);

  static bool _listEquals(List<DrawingPoint> a, List<DrawingPoint> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    color,
    strokeWidth,
    opacity,
    brushType,
    Object.hashAll(points),
  );
}
