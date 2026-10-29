import 'package:flutter/material.dart';
import 'story_media_asset.dart';
import 'story_shared_content.dart';

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
      default:
        return UnknownElementPayload(rawType: discriminator, rawData: json);
    }
  }
}

/// Payload for rich text story elements.
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
  });

  final String text;
  final double fontSize;
  final Color textColor;
  final Color? backgroundColor;
  final TextAlign textAlign;
  final bool isBold;
  final bool isItalic;
  final String? fontFamily;

  @override
  String get typeDiscriminator => 'text';

  TextElementPayload copyWith({
    String? text,
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
    TextAlign? textAlign,
    bool? isBold,
    bool? isItalic,
    String? fontFamily,
  }) {
    return TextElementPayload(
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textAlign: textAlign ?? this.textAlign,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      fontFamily: fontFamily ?? this.fontFamily,
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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextElementPayload &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          fontSize == other.fontSize &&
          textColor == other.textColor &&
          backgroundColor == other.backgroundColor &&
          textAlign == other.textAlign &&
          isBold == other.isBold &&
          isItalic == other.isItalic &&
          fontFamily == other.fontFamily;

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
  );
}

/// Payload for image layers (imported photos, stickers from local or remote assets).
@immutable
class ImageElementPayload extends StoryElementPayload {
  const ImageElementPayload({required this.asset, this.fit = BoxFit.contain});

  final StoryMediaAsset asset;
  final BoxFit fit;

  @override
  String get typeDiscriminator => 'image';

  ImageElementPayload copyWith({StoryMediaAsset? asset, BoxFit? fit}) {
    return ImageElementPayload(
      asset: asset ?? this.asset,
      fit: fit ?? this.fit,
    );
  }

  @override
  Map<String, dynamic> toJson() => {'asset': asset.toJson(), 'fit': fit.name};

  factory ImageElementPayload.fromJson(Map<String, dynamic> json) {
    return ImageElementPayload(
      asset: StoryMediaAsset.fromJson(
        Map<String, dynamic>.from(json['asset'] as Map? ?? {}),
      ),
      fit: BoxFit.values.firstWhere(
        (e) => e.name == json['fit'],
        orElse: () => BoxFit.contain,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageElementPayload &&
          runtimeType == other.runtimeType &&
          asset == other.asset &&
          fit == other.fit;

  @override
  int get hashCode => Object.hash(asset, fit);
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
