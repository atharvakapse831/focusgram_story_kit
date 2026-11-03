import 'package:flutter/material.dart';
import 'drawing_stroke.dart';
import 'image_adjustments.dart';
import 'shape_payload.dart';
import 'story_media_asset.dart';
import 'story_shared_content.dart';
import 'video_payload.dart';

export 'drawing_stroke.dart';
export 'image_adjustments.dart';
export 'overlay_animation.dart';
export 'shape_payload.dart';
export 'video_payload.dart';

/// Base contract for payload data attached to a [StoryElement].
@immutable
abstract class StoryElementPayload {
  const StoryElementPayload();

  /// Stable discriminator string for JSON serialization.
  String get typeDiscriminator;

  /// Serializes payload-specific attributes to a JSON map.
  Map<String, dynamic> toJson();

  /// Deserializes a payload based on its `typeDiscriminator`.
  static StoryElementPayload fromJson(
    String discriminator,
    Map<String, dynamic> json,
  ) {
    switch (discriminator.toLowerCase().trim()) {
      case 'text':
        return TextElementPayload.fromJson(json);
      case 'image':
        return ImageElementPayload.fromJson(json);
      case 'sticker':
        return StickerElementPayload.fromJson(json);
      case 'card':
        return CardElementPayload.fromJson(json);
      case 'drawing':
        return DrawingElementPayload.fromJson(json);
      case 'shape':
        return ShapeElementPayload.fromJson(json);
      case 'video':
        return VideoElementPayload.fromJson(json);
      default:
        return UnknownElementPayload(rawType: discriminator, rawData: json);
    }
  }
}

/// Payload for rich text story elements with typography, outline, and drop shadows.
@immutable
class TextElementPayload extends StoryElementPayload {
  const TextElementPayload({
    required this.text,
    this.fontSize = 24.0,
    this.textColor = Colors.white,
    this.backgroundColor,
    this.textAlign = TextAlign.center,
    this.isBold = false,
    this.isItalic = false,
    this.fontFamily,
    this.outlineColor,
    this.outlineWidth = 0.0,
    this.shadowColor,
    this.shadowBlurRadius = 0.0,
    this.shadowOffsetX = 0.0,
    this.shadowOffsetY = 0.0,
    this.lineSpacing,
    this.letterSpacing,
  });

  final String text;
  final double fontSize;
  final Color textColor;
  final Color? backgroundColor;
  final TextAlign textAlign;
  final bool isBold;
  final bool isItalic;
  final String? fontFamily;

  // Phase 4 Typography Additions
  final Color? outlineColor;
  final double outlineWidth;
  final Color? shadowColor;
  final double shadowBlurRadius;
  final double shadowOffsetX;
  final double shadowOffsetY;
  final double? lineSpacing;
  final double? letterSpacing;

  @override
  String get typeDiscriminator => 'text';

  TextElementPayload copyWith({
    String? text,
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    bool clearBackgroundColor = false,
    TextAlign? textAlign,
    bool? isBold,
    bool? isItalic,
    String? fontFamily,
    Color? outlineColor,
    bool clearOutline = false,
    double? outlineWidth,
    Color? shadowColor,
    bool clearShadow = false,
    double? shadowBlurRadius,
    double? shadowOffsetX,
    double? shadowOffsetY,
    double? lineSpacing,
    double? letterSpacing,
  }) {
    return TextElementPayload(
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor:
          clearBackgroundColor
              ? null
              : (backgroundColor ?? this.backgroundColor),
      textAlign: textAlign ?? this.textAlign,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      fontFamily: fontFamily ?? this.fontFamily,
      outlineColor: clearOutline ? null : (outlineColor ?? this.outlineColor),
      outlineWidth: outlineWidth ?? this.outlineWidth,
      shadowColor: clearShadow ? null : (shadowColor ?? this.shadowColor),
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      letterSpacing: letterSpacing ?? this.letterSpacing,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'text': text,
    'fontSize': fontSize,
    'textColor': textColor.toARGB32(),
    if (backgroundColor != null) 'backgroundColor': backgroundColor!.toARGB32(),
    'textAlign': textAlign.name,
    'isBold': isBold,
    'isItalic': isItalic,
    if (fontFamily != null) 'fontFamily': fontFamily,
    if (outlineColor != null) 'outlineColor': outlineColor!.toARGB32(),
    if (outlineWidth > 0.0) 'outlineWidth': outlineWidth,
    if (shadowColor != null) 'shadowColor': shadowColor!.toARGB32(),
    if (shadowBlurRadius > 0.0) 'shadowBlurRadius': shadowBlurRadius,
    if (shadowOffsetX != 0.0) 'shadowOffsetX': shadowOffsetX,
    if (shadowOffsetY != 0.0) 'shadowOffsetY': shadowOffsetY,
    if (lineSpacing != null) 'lineSpacing': lineSpacing,
    if (letterSpacing != null) 'letterSpacing': letterSpacing,
  };

  factory TextElementPayload.fromJson(Map<String, dynamic> json) {
    return TextElementPayload(
      text: json['text'] as String? ?? '',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
      textColor:
          json['textColor'] != null
              ? Color(json['textColor'] as int)
              : Colors.white,
      backgroundColor:
          json['backgroundColor'] != null
              ? Color(json['backgroundColor'] as int)
              : null,
      textAlign: TextAlign.values.firstWhere(
        (e) => e.name == json['textAlign'],
        orElse: () => TextAlign.center,
      ),
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      fontFamily: json['fontFamily'] as String?,
      outlineColor:
          json['outlineColor'] != null
              ? Color(json['outlineColor'] as int)
              : null,
      outlineWidth: (json['outlineWidth'] as num?)?.toDouble() ?? 0.0,
      shadowColor:
          json['shadowColor'] != null
              ? Color(json['shadowColor'] as int)
              : null,
      shadowBlurRadius: (json['shadowBlurRadius'] as num?)?.toDouble() ?? 0.0,
      shadowOffsetX: (json['shadowOffsetX'] as num?)?.toDouble() ?? 0.0,
      shadowOffsetY: (json['shadowOffsetY'] as num?)?.toDouble() ?? 0.0,
      lineSpacing: (json['lineSpacing'] as num?)?.toDouble(),
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextElementPayload &&
          text == other.text &&
          fontSize == other.fontSize &&
          textColor.toARGB32() == other.textColor.toARGB32() &&
          backgroundColor?.toARGB32() == other.backgroundColor?.toARGB32() &&
          textAlign == other.textAlign &&
          isBold == other.isBold &&
          isItalic == other.isItalic &&
          fontFamily == other.fontFamily &&
          outlineColor?.toARGB32() == other.outlineColor?.toARGB32() &&
          outlineWidth == other.outlineWidth &&
          shadowColor?.toARGB32() == other.shadowColor?.toARGB32() &&
          shadowBlurRadius == other.shadowBlurRadius &&
          shadowOffsetX == other.shadowOffsetX &&
          shadowOffsetY == other.shadowOffsetY &&
          lineSpacing == other.lineSpacing &&
          letterSpacing == other.letterSpacing;

  @override
  int get hashCode => Object.hash(
    text,
    fontSize,
    textColor,
    backgroundColor,
    textAlign,
    isBold,
    isItalic,
    fontFamily,
    outlineColor,
    outlineWidth,
    shadowColor,
    shadowBlurRadius,
    shadowOffsetX,
    shadowOffsetY,
    lineSpacing,
    letterSpacing,
  );
}

/// Payload for image layers with non-destructive adjustments and filters.
@immutable
class ImageElementPayload extends StoryElementPayload {
  const ImageElementPayload({
    required this.asset,
    this.fit = BoxFit.contain,
    this.adjustments = ImageAdjustments.identity,
  });

  final StoryMediaAsset asset;
  final BoxFit fit;
  final ImageAdjustments adjustments;

  @override
  String get typeDiscriminator => 'image';

  ImageElementPayload copyWith({
    StoryMediaAsset? asset,
    BoxFit? fit,
    ImageAdjustments? adjustments,
  }) {
    return ImageElementPayload(
      asset: asset ?? this.asset,
      fit: fit ?? this.fit,
      adjustments: adjustments ?? this.adjustments,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'asset': asset.toJson(),
    'fit': fit.name,
    'adjustments': adjustments.toJson(),
  };

  factory ImageElementPayload.fromJson(Map<String, dynamic> json) {
    return ImageElementPayload(
      asset: StoryMediaAsset.fromJson(
        Map<String, dynamic>.from(json['asset'] as Map? ?? {}),
      ),
      fit: BoxFit.values.firstWhere(
        (e) => e.name == json['fit'],
        orElse: () => BoxFit.contain,
      ),
      adjustments:
          json['adjustments'] != null
              ? ImageAdjustments.fromJson(
                Map<String, dynamic>.from(json['adjustments'] as Map),
              )
              : ImageAdjustments.identity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageElementPayload &&
          runtimeType == other.runtimeType &&
          asset == other.asset &&
          fit == other.fit &&
          adjustments == other.adjustments;

  @override
  int get hashCode => Object.hash(asset, fit, adjustments);
}

/// Payload for static/emoji/clipart stickers.
@immutable
class StickerElementPayload extends StoryElementPayload {
  const StickerElementPayload({
    required this.stickerId,
    required this.assetUri,
    this.label,
  });

  final String stickerId;
  final String assetUri;
  final String? label;

  @override
  String get typeDiscriminator => 'sticker';

  StickerElementPayload copyWith({
    String? stickerId,
    String? assetUri,
    String? label,
  }) {
    return StickerElementPayload(
      stickerId: stickerId ?? this.stickerId,
      assetUri: assetUri ?? this.assetUri,
      label: label ?? this.label,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'stickerId': stickerId,
    'assetUri': assetUri,
    if (label != null) 'label': label,
  };

  factory StickerElementPayload.fromJson(Map<String, dynamic> json) {
    return StickerElementPayload(
      stickerId: json['stickerId'] as String? ?? '',
      assetUri: json['assetUri'] as String? ?? '',
      label: json['label'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StickerElementPayload &&
          runtimeType == other.runtimeType &&
          stickerId == other.stickerId &&
          assetUri == other.assetUri &&
          label == other.label;

  @override
  int get hashCode => Object.hash(stickerId, assetUri, label);
}

/// Payload for FocusGram shared content cards (posts, articles, notes, videos).
@immutable
class CardElementPayload extends StoryElementPayload {
  const CardElementPayload({required this.sharedContent});

  final StorySharedContent sharedContent;

  @override
  String get typeDiscriminator => 'card';

  CardElementPayload copyWith({StorySharedContent? sharedContent}) {
    return CardElementPayload(
      sharedContent: sharedContent ?? this.sharedContent,
    );
  }

  @override
  Map<String, dynamic> toJson() => {'sharedContent': sharedContent.toJson()};

  factory CardElementPayload.fromJson(Map<String, dynamic> json) {
    return CardElementPayload(
      sharedContent: StorySharedContent.fromJson(
        Map<String, dynamic>.from(json['sharedContent'] as Map? ?? {}),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardElementPayload &&
          runtimeType == other.runtimeType &&
          sharedContent == other.sharedContent;

  @override
  int get hashCode => sharedContent.hashCode;
}

/// Payload for freehand drawings containing ordered strokes.
@immutable
class DrawingElementPayload extends StoryElementPayload {
  const DrawingElementPayload({this.strokes = const []});

  final List<DrawingStroke> strokes;

  @override
  String get typeDiscriminator => 'drawing';

  DrawingElementPayload copyWith({List<DrawingStroke>? strokes}) {
    return DrawingElementPayload(strokes: strokes ?? this.strokes);
  }

  @override
  Map<String, dynamic> toJson() => {
    'strokes': strokes.map((s) => s.toJson()).toList(),
  };

  factory DrawingElementPayload.fromJson(Map<String, dynamic> json) {
    return DrawingElementPayload(
      strokes:
          (json['strokes'] as List<dynamic>? ?? [])
              .map(
                (s) =>
                    DrawingStroke.fromJson(Map<String, dynamic>.from(s as Map)),
              )
              .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingElementPayload &&
          runtimeType == other.runtimeType &&
          _listEquals(strokes, other.strokes);

  static bool _listEquals(List<DrawingStroke> a, List<DrawingStroke> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(strokes);
}

/// Fallback payload for unknown or forward-compatible element types.
@immutable
class UnknownElementPayload extends StoryElementPayload {
  const UnknownElementPayload({required this.rawType, required this.rawData});

  final String rawType;
  final Map<String, dynamic> rawData;

  @override
  String get typeDiscriminator => rawType;

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(rawData);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnknownElementPayload &&
          runtimeType == other.runtimeType &&
          rawType == other.rawType;

  @override
  int get hashCode => rawType.hashCode;
}

/// Payload for in-canvas floating video story elements.
@immutable
class VideoElementPayload extends StoryElementPayload {
  const VideoElementPayload({required this.video});

  final StoryVideoPayload video;

  /// Convenience accessors delegating to [video].
  StoryMediaAsset get asset => video.asset;
  VideoTrimRange get trimRange => video.trimRange;
  VideoAudioPolicy get audioPolicy => video.audioPolicy;
  VideoFitMode get fitMode => video.fitMode;

  @override
  String get typeDiscriminator => 'video';

  VideoElementPayload copyWith({StoryVideoPayload? video}) {
    return VideoElementPayload(video: video ?? this.video);
  }

  @override
  Map<String, dynamic> toJson() => {'video': video.toJson()};

  factory VideoElementPayload.fromJson(Map<String, dynamic> json) {
    return VideoElementPayload(
      video: StoryVideoPayload.fromJson(
        Map<String, dynamic>.from(json['video'] as Map? ?? {}),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoElementPayload &&
          runtimeType == other.runtimeType &&
          video == other.video;

  @override
  int get hashCode => video.hashCode;
}
