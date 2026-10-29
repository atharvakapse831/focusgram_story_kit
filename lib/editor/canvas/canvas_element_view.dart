import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/element_payloads.dart';
import '../../models/story_element.dart';
import '../../models/story_media_asset.dart';
import '../../viewer/story_shared_content_card.dart';

/// Renders the visual representation of a [StoryElement] based on its payload.
class CanvasElementView extends StatelessWidget {
  const CanvasElementView({super.key, required this.element});

  final StoryElement element;

  @override
  Widget build(BuildContext context) {
    if (!element.isVisible) return const SizedBox.shrink();

    final payload = element.payload;

    Widget content;
    if (payload is TextElementPayload) {
      content = _buildText(payload);
    } else if (payload is ImageElementPayload) {
      content = _buildImage(payload);
    } else if (payload is StickerElementPayload) {
      content = _buildSticker(payload);
    } else if (payload is CardElementPayload) {
      content = _buildCard(payload);
    } else {
      content = _buildUnknown(payload);
    }

    if (element.opacity < 1.0) {
      return Opacity(opacity: element.opacity.clamp(0.0, 1.0), child: content);
    }

    return content;
  }

  Widget _buildText(TextElementPayload textPayload) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration:
          textPayload.backgroundColor != null
              ? BoxDecoration(
                color: textPayload.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              )
              : null,
      child: Text(
        textPayload.text,
        textAlign: textPayload.textAlign,
        style: TextStyle(
          fontSize: textPayload.fontSize,
          color: textPayload.textColor,
          fontWeight: textPayload.isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: textPayload.isItalic ? FontStyle.italic : FontStyle.normal,
          fontFamily: textPayload.fontFamily,
        ),
      ),
    );
  }

  Widget _buildImage(ImageElementPayload imagePayload) {
    final asset = imagePayload.asset;
    switch (asset.sourceType) {
      case StoryMediaSourceType.file:
        return Image.file(
          File(asset.uri),
          fit: imagePayload.fit,
          errorBuilder: (_, __, ___) => _errorPlaceholder('Image not found'),
        );
      case StoryMediaSourceType.asset:
        return Image.asset(
          asset.uri,
          fit: imagePayload.fit,
          errorBuilder: (_, __, ___) => _errorPlaceholder('Asset missing'),
        );
      case StoryMediaSourceType.network:
      case StoryMediaSourceType.memory:
        if (asset.uri.isEmpty) return _errorPlaceholder('No URI');
        return CachedNetworkImage(
          imageUrl: asset.uri,
          fit: imagePayload.fit,
          placeholder:
              (_, __) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          errorWidget: (_, __, ___) => _errorPlaceholder('Network error'),
        );
    }
  }

  Widget _buildSticker(StickerElementPayload stickerPayload) {
    if (stickerPayload.assetUri.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: stickerPayload.assetUri,
        fit: BoxFit.contain,
        errorWidget:
            (_, __, ___) => const Icon(Icons.star, color: Colors.amber),
      );
    }
    return const Icon(Icons.star, size: 48, color: Colors.amber);
  }

  Widget _buildCard(CardElementPayload cardPayload) {
    return StorySharedContentCard(
      content: cardPayload.sharedContent,
      onTap: null, // Non-interactive preview in editor canvas
    );
  }

  Widget _buildUnknown(StoryElementPayload payload) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white54, width: 1),
      ),
      child: Text(
        '[${payload.typeDiscriminator}]',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  Widget _errorPlaceholder(String message) {
    return Container(
      color: Colors.black45,
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(color: Colors.white60, fontSize: 10),
      ),
    );
  }
}
