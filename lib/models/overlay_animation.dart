import 'package:flutter/material.dart';

/// Supported entrance and exit animation motion styles for story canvas layers.
enum OverlayAnimationType {
  none,
  fade,
  scale,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  bounce;

  static OverlayAnimationType fromString(String? raw) {
    if (raw == null) return OverlayAnimationType.none;
    switch (raw.toLowerCase().trim()) {
      case 'fade':
        return OverlayAnimationType.fade;
      case 'scale':
        return OverlayAnimationType.scale;
      case 'slideup':
      case 'slide_up':
        return OverlayAnimationType.slideUp;
      case 'slidedown':
      case 'slide_down':
        return OverlayAnimationType.slideDown;
      case 'slideleft':
      case 'slide_left':
        return OverlayAnimationType.slideLeft;
      case 'slideright':
      case 'slide_right':
        return OverlayAnimationType.slideRight;
      case 'bounce':
        return OverlayAnimationType.bounce;
      case 'none':
      default:
        return OverlayAnimationType.none;
    }
  }
}

/// Time-bounded visibility interval for an individual story element.
@immutable
class LayerTimeRange {
  const LayerTimeRange({this.start = Duration.zero, required this.end});

  final Duration start;
  final Duration end;

  /// Effective duration for which the element is visible.
  Duration get duration => end - start;

  /// Returns true if the element is visible at [timestamp].
  bool isVisibleAt(Duration timestamp) {
    return timestamp >= start && timestamp <= end;
  }

  /// Clamps the time range so it does not exceed the page's [pageDuration].
  LayerTimeRange clampTo(Duration pageDuration) {
    final clampedStart = start > pageDuration ? pageDuration : start;
    final clampedEnd = end > pageDuration ? pageDuration : end;
    return LayerTimeRange(
      start: clampedStart,
      end: clampedEnd < clampedStart ? clampedStart : clampedEnd,
    );
  }

  LayerTimeRange copyWith({Duration? start, Duration? end}) {
    final newStart = start ?? this.start;
    final newEnd = end ?? this.end;
    return LayerTimeRange(
      start: newStart,
      end: newEnd < newStart ? newStart : newEnd,
    );
  }

  Map<String, dynamic> toJson() => {
    'startMs': start.inMilliseconds,
    'endMs': end.inMilliseconds,
  };

  factory LayerTimeRange.fromJson(Map<String, dynamic> json) {
    final startMs = json['startMs'] as int? ?? 0;
    final endMs = json['endMs'] as int? ?? startMs;
    return LayerTimeRange(
      start: Duration(milliseconds: startMs),
      end: Duration(milliseconds: endMs < startMs ? startMs : endMs),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayerTimeRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Motion configuration for an element's entrance and exit transitions.
@immutable
class OverlayAnimationConfig {
  const OverlayAnimationConfig({
    this.entranceType = OverlayAnimationType.fade,
    this.entranceDuration = const Duration(milliseconds: 300),
    this.exitType = OverlayAnimationType.fade,
    this.exitDuration = const Duration(milliseconds: 300),
    this.curveName = 'easeInOut',
  });

  final OverlayAnimationType entranceType;
  final Duration entranceDuration;
  final OverlayAnimationType exitType;
  final Duration exitDuration;
  final String curveName;

  /// Resolves the string identifier to a Flutter [Curve].
  Curve get curve {
    switch (curveName.toLowerCase()) {
      case 'linear':
        return Curves.linear;
      case 'easein':
        return Curves.easeIn;
      case 'easeout':
        return Curves.easeOut;
      case 'bouncein':
        return Curves.bounceIn;
      case 'bounceout':
        return Curves.bounceOut;
      case 'elasticout':
        return Curves.elasticOut;
      case 'easeinout':
      default:
        return Curves.easeInOut;
    }
  }

  OverlayAnimationConfig copyWith({
    OverlayAnimationType? entranceType,
    Duration? entranceDuration,
    OverlayAnimationType? exitType,
    Duration? exitDuration,
    String? curveName,
  }) {
    return OverlayAnimationConfig(
      entranceType: entranceType ?? this.entranceType,
      entranceDuration: entranceDuration ?? this.entranceDuration,
      exitType: exitType ?? this.exitType,
      exitDuration: exitDuration ?? this.exitDuration,
      curveName: curveName ?? this.curveName,
    );
  }

  Map<String, dynamic> toJson() => {
    'entranceType': entranceType.name,
    'entranceDurationMs': entranceDuration.inMilliseconds,
    'exitType': exitType.name,
    'exitDurationMs': exitDuration.inMilliseconds,
    'curveName': curveName,
  };

  factory OverlayAnimationConfig.fromJson(Map<String, dynamic> json) {
    return OverlayAnimationConfig(
      entranceType: OverlayAnimationType.fromString(
        json['entranceType'] as String?,
      ),
      entranceDuration: Duration(
        milliseconds: json['entranceDurationMs'] as int? ?? 300,
      ),
      exitType: OverlayAnimationType.fromString(json['exitType'] as String?),
      exitDuration: Duration(
        milliseconds: json['exitDurationMs'] as int? ?? 300,
      ),
      curveName: json['curveName'] as String? ?? 'easeInOut',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverlayAnimationConfig &&
          runtimeType == other.runtimeType &&
          entranceType == other.entranceType &&
          entranceDuration == other.entranceDuration &&
          exitType == other.exitType &&
          exitDuration == other.exitDuration &&
          curveName == other.curveName;

  @override
  int get hashCode => Object.hash(
    entranceType,
    entranceDuration,
    exitType,
    exitDuration,
    curveName,
  );
}
