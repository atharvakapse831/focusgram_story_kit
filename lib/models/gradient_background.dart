import 'package:flutter/material.dart';

/// Supported gradient classification styles.
enum StoryGradientType {
  linear,
  radial,
  sweep;

  static StoryGradientType fromString(String? raw) {
    if (raw == null) return StoryGradientType.linear;
    return StoryGradientType.values.firstWhere(
      (e) => e.name.toLowerCase() == raw.toLowerCase().trim(),
      orElse: () => StoryGradientType.linear,
    );
  }
}

/// Serializable gradient configuration for story page backgrounds.
@immutable
class StoryGradientBackground {
  const StoryGradientBackground({
    this.type = StoryGradientType.linear,
    required this.colors,
    this.stops,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  final StoryGradientType type;
  final List<Color> colors;
  final List<double>? stops;
  final Alignment begin;
  final Alignment end;

  // Preset gradients
  static const sunset = StoryGradientBackground(
    colors: [Color(0xFFFF5E62), Color(0xFFFF9966)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const ocean = StoryGradientBackground(
    colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const neon = StoryGradientBackground(
    colors: [Color(0xFFF355DA), Color(0xFF7000FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const midnight = StoryGradientBackground(
    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const berry = StoryGradientBackground(
    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const forest = StoryGradientBackground(
    colors: [Color(0xFF134E5E), Color(0xFF71B280)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<StoryGradientBackground> get presets => const [
    sunset,
    ocean,
    neon,
    midnight,
    berry,
    forest,
  ];

  /// Material Gradient representation for rendering in BoxDecorations and Paint shaders.
  Gradient toGradient() {
    switch (type) {
      case StoryGradientType.linear:
        return LinearGradient(
          colors: colors,
          stops: stops,
          begin: begin,
          end: end,
        );
      case StoryGradientType.radial:
        return RadialGradient(colors: colors, stops: stops);
      case StoryGradientType.sweep:
        return SweepGradient(colors: colors, stops: stops);
    }
  }

  StoryGradientBackground copyWith({
    StoryGradientType? type,
    List<Color>? colors,
    List<double>? stops,
    Alignment? begin,
    Alignment? end,
  }) {
    return StoryGradientBackground(
      type: type ?? this.type,
      colors: colors ?? this.colors,
      stops: stops ?? this.stops,
      begin: begin ?? this.begin,
      end: end ?? this.end,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'colors': colors.map((c) => c.toARGB32()).toList(),
    if (stops != null) 'stops': stops,
    'beginX': begin.x,
    'beginY': begin.y,
    'endX': end.x,
    'endY': end.y,
  };

  factory StoryGradientBackground.fromJson(Map<String, dynamic> json) {
    return StoryGradientBackground(
      type: StoryGradientType.fromString(json['type'] as String?),
      colors:
          (json['colors'] as List<dynamic>? ?? [0xFF000000, 0xFFFFFFFF])
              .map((c) => Color(c as int))
              .toList(),
      stops:
          (json['stops'] as List<dynamic>?)
              ?.map((s) => (s as num).toDouble())
              .toList(),
      begin: Alignment(
        (json['beginX'] as num?)?.toDouble() ?? 0.0,
        (json['beginY'] as num?)?.toDouble() ?? -1.0,
      ),
      end: Alignment(
        (json['endX'] as num?)?.toDouble() ?? 0.0,
        (json['endY'] as num?)?.toDouble() ?? 1.0,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryGradientBackground &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          begin == other.begin &&
          end == other.end &&
          _listEquals(colors, other.colors);

  static bool _listEquals(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].toARGB32() != b[i].toARGB32()) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(type, begin, end, Object.hashAll(colors));
}
