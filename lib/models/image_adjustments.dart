import 'package:flutter/material.dart';

/// Preset color filters applicable to story images.
enum ImageFilterPreset {
  none,
  sepia,
  grayscale,
  vintage,
  cool,
  warm,
  dramatic;

  static ImageFilterPreset fromString(String? raw) {
    if (raw == null) return ImageFilterPreset.none;
    return ImageFilterPreset.values.firstWhere(
      (e) => e.name.toLowerCase() == raw.toLowerCase().trim(),
      orElse: () => ImageFilterPreset.none,
    );
  }
}

/// Non-destructive image adjustment metadata and color transformation parameters.
@immutable
class ImageAdjustments {
  const ImageAdjustments({
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.warmth = 0.0,
    this.isFlippedHorizontally = false,
    this.isFlippedVertically = false,
    this.filterPreset = ImageFilterPreset.none,
  }) : assert(brightness >= -1.0 && brightness <= 1.0, 'brightness in [-1, 1]'),
       assert(contrast >= 0.0 && contrast <= 2.0, 'contrast in [0, 2]'),
       assert(saturation >= 0.0 && saturation <= 2.0, 'saturation in [0, 2]'),
       assert(warmth >= -1.0 && warmth <= 1.0, 'warmth in [-1, 1]');

  /// Standard default adjustments (no modifications).
  static const ImageAdjustments identity = ImageAdjustments();

  /// Brightness adjustment in `[-1.0, 1.0]`, where 0.0 is normal.
  final double brightness;

  /// Contrast multiplier in `[0.0, 2.0]`, where 1.0 is normal.
  final double contrast;

  /// Saturation multiplier in `[0.0, 2.0]`, where 1.0 is normal.
  final double saturation;

  /// Color temperature / warmth offset in `[-1.0, 1.0]`, where 0.0 is neutral.
  final double warmth;

  /// Whether the image is mirrored horizontally.
  final bool isFlippedHorizontally;

  /// Whether the image is mirrored vertically.
  final bool isFlippedVertically;

  /// Selected stylistic color filter preset.
  final ImageFilterPreset filterPreset;

  bool get hasAdjustments =>
      brightness != 0.0 ||
      contrast != 1.0 ||
      saturation != 1.0 ||
      warmth != 0.0 ||
      isFlippedHorizontally ||
      isFlippedVertically ||
      filterPreset != ImageFilterPreset.none;

  /// Generates a 4x5 color matrix suitable for `ColorFilter.matrix`.
  List<double> toColorMatrix() {
    // Start with base filter preset matrix
    List<double> matrix;
    switch (filterPreset) {
      case ImageFilterPreset.grayscale:
        matrix = <double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
        break;
      case ImageFilterPreset.sepia:
        matrix = <double>[
          0.393,
          0.769,
          0.189,
          0,
          0,
          0.349,
          0.686,
          0.168,
          0,
          0,
          0.272,
          0.534,
          0.131,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
        break;
      case ImageFilterPreset.vintage:
        matrix = <double>[
          0.9,
          0.1,
          0.1,
          0,
          20,
          0.1,
          0.8,
          0.1,
          0,
          10,
          0.1,
          0.1,
          0.6,
          0,
          30,
          0,
          0,
          0,
          1,
          0,
        ];
        break;
      case ImageFilterPreset.cool:
        matrix = <double>[
          0.8,
          0,
          0,
          0,
          0,
          0,
          0.9,
          0,
          0,
          5,
          0,
          0,
          1.2,
          0,
          25,
          0,
          0,
          0,
          1,
          0,
        ];
        break;
      case ImageFilterPreset.warm:
        matrix = <double>[
          1.2,
          0,
          0,
          0,
          25,
          0,
          1.0,
          0,
          0,
          10,
          0,
          0,
          0.8,
          0,
          -10,
          0,
          0,
          0,
          1,
          0,
        ];
        break;
      case ImageFilterPreset.dramatic:
        matrix = <double>[
          1.4,
          0,
          0,
          0,
          -20,
          0,
          1.4,
          0,
          0,
          -20,
          0,
          0,
          1.4,
          0,
          -20,
          0,
          0,
          0,
          1,
          0,
        ];
        break;
      case ImageFilterPreset.none:
        matrix = <double>[
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
        break;
    }

    // Apply brightness offset
    final bOffset = brightness * 100.0;
    matrix[4] += bOffset;
    matrix[9] += bOffset;
    matrix[14] += bOffset;

    // Apply contrast scale
    if (contrast != 1.0) {
      final t = (1.0 - contrast) / 2.0 * 255.0;
      matrix[0] *= contrast;
      matrix[6] *= contrast;
      matrix[12] *= contrast;
      matrix[4] += t;
      matrix[9] += t;
      matrix[14] += t;
    }

    // Apply warmth offset (red/blue shift)
    if (warmth != 0.0) {
      final w = warmth * 30.0;
      matrix[4] += w; // boost red
      matrix[14] -= w; // reduce blue
    }

    return matrix;
  }

  ImageAdjustments copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    bool? isFlippedHorizontally,
    bool? isFlippedVertically,
    ImageFilterPreset? filterPreset,
  }) {
    return ImageAdjustments(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      warmth: warmth ?? this.warmth,
      isFlippedHorizontally:
          isFlippedHorizontally ?? this.isFlippedHorizontally,
      isFlippedVertically: isFlippedVertically ?? this.isFlippedVertically,
      filterPreset: filterPreset ?? this.filterPreset,
    );
  }

  Map<String, dynamic> toJson() => {
    'brightness': brightness,
    'contrast': contrast,
    'saturation': saturation,
    'warmth': warmth,
    'isFlippedHorizontally': isFlippedHorizontally,
    'isFlippedVertically': isFlippedVertically,
    'filterPreset': filterPreset.name,
  };

  factory ImageAdjustments.fromJson(Map<String, dynamic> json) {
    return ImageAdjustments(
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.0,
      warmth: (json['warmth'] as num?)?.toDouble() ?? 0.0,
      isFlippedHorizontally: json['isFlippedHorizontally'] as bool? ?? false,
      isFlippedVertically: json['isFlippedVertically'] as bool? ?? false,
      filterPreset: ImageFilterPreset.fromString(
        json['filterPreset'] as String?,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageAdjustments &&
          runtimeType == other.runtimeType &&
          brightness == other.brightness &&
          contrast == other.contrast &&
          saturation == other.saturation &&
          warmth == other.warmth &&
          isFlippedHorizontally == other.isFlippedHorizontally &&
          isFlippedVertically == other.isFlippedVertically &&
          filterPreset == other.filterPreset;

  @override
  int get hashCode => Object.hash(
    brightness,
    contrast,
    saturation,
    warmth,
    isFlippedHorizontally,
    isFlippedVertically,
    filterPreset,
  );
}
