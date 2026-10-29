import 'package:flutter/material.dart';

/// Defines the canonical canvas dimensions and styling for a story project.
@immutable
class StoryCanvasSpec {
  const StoryCanvasSpec({
    this.width = 1080.0,
    this.height = 1920.0,
    this.backgroundColor = Colors.black,
  }) : assert(width > 0, 'width must be positive'),
       assert(height > 0, 'height must be positive');

  /// Canvas width in canonical logical units (default 1080).
  final double width;

  /// Canvas height in canonical logical units (default 1920).
  final double height;

  /// Default canvas background color.
  final Color backgroundColor;

  /// Aspect ratio of the canvas (width / height, typically 9/16 = 0.5625).
  double get aspectRatio => width / height;

  /// Size object representing canonical dimensions.
  Size get size => Size(width, height);

  StoryCanvasSpec copyWith({
    double? width,
    double? height,
    Color? backgroundColor,
  }) {
    return StoryCanvasSpec(
      width: width ?? this.width,
      height: height ?? this.height,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'backgroundColor': backgroundColor.toARGB32(),
  };

  factory StoryCanvasSpec.fromJson(Map<String, dynamic> json) {
    return StoryCanvasSpec(
      width: (json['width'] as num?)?.toDouble() ?? 1080.0,
      height: (json['height'] as num?)?.toDouble() ?? 1920.0,
      backgroundColor:
          json['backgroundColor'] != null
              ? Color(json['backgroundColor'] as int)
              : Colors.black,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryCanvasSpec &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode => Object.hash(width, height, backgroundColor);
}
