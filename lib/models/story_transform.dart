import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Normalized coordinate transform defining position, dimensions, rotation,
/// and scale of an element relative to the canonical story canvas.
///
/// Coordinates and dimensions are normalized in `[0.0, 1.0]` relative to the
/// canvas bounds, ensuring deterministic layout across preview screens and
/// export rasters of varying pixel resolutions.
@immutable
class StoryTransform {
  const StoryTransform({
    this.x = 0.5,
    this.y = 0.5,
    this.width = 0.6,
    this.height = 0.2,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.anchorX = 0.5,
    this.anchorY = 0.5,
  }) : assert(scale > 0, 'scale must be positive');

  /// Normalized center X coordinate on the canvas [0.0, 1.0].
  final double x;

  /// Normalized center Y coordinate on the canvas [0.0, 1.0].
  final double y;

  /// Normalized width relative to canvas width [0.0, 1.0].
  final double width;

  /// Normalized height relative to canvas height [0.0, 1.0].
  final double height;

  /// Clockwise rotation in radians.
  final double rotation;

  /// Uniform scale factor (default 1.0).
  final double scale;

  /// Normalized horizontal anchor/pivot point (default 0.5 = center).
  final double anchorX;

  /// Normalized vertical anchor/pivot point (default 0.5 = center).
  final double anchorY;

  /// Returns the unscaled center position in pixels on a canvas of [canvasSize].
  Offset toScreenCenter(Size canvasSize) {
    return Offset(x * canvasSize.width, y * canvasSize.height);
  }

  /// Returns the scaled pixel dimensions on a canvas of [canvasSize].
  Size toScreenSize(Size canvasSize) {
    return Size(
      width * canvasSize.width * scale,
      height * canvasSize.height * scale,
    );
  }

  /// Returns the axis-aligned bounding [Rect] on [canvasSize] before rotation.
  Rect toScreenRect(Size canvasSize) {
    final center = toScreenCenter(canvasSize);
    final size = toScreenSize(canvasSize);
    return Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );
  }

  /// Evaluates whether [point] on [canvasSize] falls within this element's
  /// rotated and scaled bounding box.
  bool containsPoint(Offset point, Size canvasSize) {
    final center = toScreenCenter(canvasSize);
    final size = toScreenSize(canvasSize);

    if (size.width <= 0 || size.height <= 0) return false;

    // Translate point to local coordinate system centered at (0, 0)
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    // Inverse rotate point by -rotation
    final cosA = math.cos(-rotation);
    final sinA = math.sin(-rotation);
    final localX = dx * cosA - dy * sinA;
    final localY = dx * sinA + dy * cosA;

    final halfWidth = size.width / 2.0;
    final halfHeight = size.height / 2.0;

    return localX >= -halfWidth &&
        localX <= halfWidth &&
        localY >= -halfHeight &&
        localY <= halfHeight;
  }

  /// Clamps the center coordinates so at least [minVisibleFraction] of the element
  /// remains accessible within the canvas bounds [0.0, 1.0].
  StoryTransform clampToCanvas({double minVisibleFraction = 0.2}) {
    final halfW = (width * scale / 2.0) * (1.0 - minVisibleFraction);
    final halfH = (height * scale / 2.0) * (1.0 - minVisibleFraction);

    final minX = -halfW;
    final maxX = 1.0 + halfW;
    final minY = -halfH;
    final maxY = 1.0 + halfH;

    final clampedX = x.clamp(minX, maxX);
    final clampedY = y.clamp(minY, maxY);

    if (clampedX == x && clampedY == y) return this;

    return copyWith(x: clampedX, y: clampedY);
  }

  StoryTransform copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    double? scale,
    double? anchorX,
    double? anchorY,
  }) {
    return StoryTransform(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      anchorX: anchorX ?? this.anchorX,
      anchorY: anchorY ?? this.anchorY,
    );
  }

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': rotation,
    'scale': scale,
    'anchorX': anchorX,
    'anchorY': anchorY,
  };

  factory StoryTransform.fromJson(Map<String, dynamic> json) {
    return StoryTransform(
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      width: (json['width'] as num?)?.toDouble() ?? 0.6,
      height: (json['height'] as num?)?.toDouble() ?? 0.2,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      anchorX: (json['anchorX'] as num?)?.toDouble() ?? 0.5,
      anchorY: (json['anchorY'] as num?)?.toDouble() ?? 0.5,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryTransform &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height &&
          rotation == other.rotation &&
          scale == other.scale &&
          anchorX == other.anchorX &&
          anchorY == other.anchorY;

  @override
  int get hashCode =>
      Object.hash(x, y, width, height, rotation, scale, anchorX, anchorY);
}
