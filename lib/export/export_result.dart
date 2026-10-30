import 'package:flutter/foundation.dart';
import '../overlays/story_overlay.dart';

/// Structured outcome of a deterministic still-image story export.
@immutable
class StillImageExportResult {
  const StillImageExportResult({
    required this.pageId,
    required this.bytes,
    required this.width,
    required this.height,
    this.format = 'png',
    this.overlays = const [],
    this.duration = const Duration(seconds: 5),
  });

  /// Identifier of the rendered page/slide.
  final String pageId;

  /// Encoded image raster bytes (e.g., PNG).
  final Uint8List bytes;

  /// Output pixel width.
  final int width;

  /// Output pixel height.
  final int height;

  /// Image container format ('png', 'jpeg').
  final String format;

  /// Structured interactive overlays extracted separately from raster pixels.
  final List<StoryOverlay> overlays;

  /// Recommended display duration for the rendered story slide.
  final Duration duration;
}
