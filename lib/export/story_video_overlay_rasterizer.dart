import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/element_payloads.dart';
import '../models/story_canvas_spec.dart';
import '../models/story_element.dart';
import '../models/story_page.dart';
import '../timeline/video_transition_math.dart';

/// Metadata for a single rasterized overlay frame.
@immutable
class OverlayFrameEntry {
  const OverlayFrameEntry({
    required this.timestampMs,
    required this.durationMs,
    required this.framePath,
  });

  /// Presentation timestamp in milliseconds relative to the start of the page.
  final int timestampMs;

  /// Duration in milliseconds for which this frame is displayed.
  final int durationMs;

  /// Absolute file path of the rendered PNG image.
  final String framePath;

  Map<String, dynamic> toJson() => {
    'timestampMs': timestampMs,
    'durationMs': durationMs,
    'path': framePath,
  };

  factory OverlayFrameEntry.fromJson(Map<String, dynamic> json) {
    return OverlayFrameEntry(
      timestampMs: json['timestampMs'] as int? ?? 0,
      durationMs: json['durationMs'] as int? ?? 33,
      framePath: json['path'] as String? ?? '',
    );
  }
}

/// Renders time-dependent canvas overlays (text, drawings, shapes, stickers, cards, animations)
/// to deterministic, transparent PNG frame sequences for native video compositing.
class StoryVideoOverlayRasterizer {
  const StoryVideoOverlayRasterizer();

  /// Checks whether [page] contains any animated or time-bounded elements.
  static bool hasAnimatedElements(StoryPage page) {
    for (final el in page.elements) {
      if (el.visibleTimeRange != null) return true;
      final anim = el.animation;
      if (anim != null &&
          (anim.entranceType != OverlayAnimationType.none ||
              anim.exitType != OverlayAnimationType.none)) {
        return true;
      }
    }
    return false;
  }

  /// Rasterizes overlay elements for [page] into [outputDir].
  ///
  /// If the page has no animations, outputs a single static frame spanning the page duration.
  /// If the page has animations, samples frames at [frameRate] (e.g. 30 fps) and deduplicates
  /// static periods.
  Future<List<OverlayFrameEntry>> rasterizePageOverlays({
    required StoryPage page,
    required StoryCanvasSpec canvasSpec,
    required Directory outputDir,
    int width = 1080,
    int height = 1920,
    double frameRate = 30.0,
    bool Function()? checkCancelled,
  }) async {
    // If there are no elements on the page, return empty list (no overlays needed)
    final renderableElements =
        page.sortedElements.where((e) => e.isVisible).toList();
    if (renderableElements.isEmpty) {
      return const [];
    }

    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    final canvasSize = Size(width.toDouble(), height.toDouble());
    final isAnimated = hasAnimatedElements(page);
    final pageDurationMs = page.duration.inMilliseconds;

    // 1. Static page optimization: single frame for entire duration
    if (!isAnimated) {
      final framePath = '${outputDir.path}/overlay_${page.id}_static.png';
      final file = File(framePath);
      final bytes = await renderFrameToPng(
        elements: renderableElements,
        timestamp: Duration.zero,
        canvasSize: canvasSize,
        width: width,
        height: height,
      );
      await file.writeAsBytes(bytes, flush: true);
      return [
        OverlayFrameEntry(
          timestampMs: 0,
          durationMs: pageDurationMs,
          framePath: framePath,
        ),
      ];
    }

    // 2. Animated page: sample timeline at target frameRate
    final stepMs = (1000.0 / (frameRate > 0 ? frameRate : 30.0)).round();
    final effectiveStep = stepMs > 0 ? stepMs : 33;
    final entries = <OverlayFrameEntry>[];

    var currentMs = 0;
    var frameIndex = 0;
    String? lastWrittenPath;
    String? lastSignature;

    while (currentMs < pageDurationMs) {
      if (checkCancelled != null && checkCancelled()) {
        return entries;
      }

      final t = Duration(milliseconds: currentMs);
      final frameDuration =
          (currentMs + effectiveStep > pageDurationMs)
              ? (pageDurationMs - currentMs)
              : effectiveStep;

      // Compute frame visual signature to detect identical consecutive frames
      final signature = _computeFrameSignature(
        renderableElements,
        t,
        canvasSize,
      );

      if (signature == lastSignature && lastWrittenPath != null) {
        // Reuse previous frame path with updated duration
        entries.add(
          OverlayFrameEntry(
            timestampMs: currentMs,
            durationMs: frameDuration,
            framePath: lastWrittenPath,
          ),
        );
      } else {
        final framePath =
            '${outputDir.path}/overlay_${page.id}_f${frameIndex.toString().padLeft(4, '0')}.png';
        final file = File(framePath);
        final bytes = await renderFrameToPng(
          elements: renderableElements,
          timestamp: t,
          canvasSize: canvasSize,
          width: width,
          height: height,
        );
        await file.writeAsBytes(bytes, flush: true);

        entries.add(
          OverlayFrameEntry(
            timestampMs: currentMs,
            durationMs: frameDuration,
            framePath: framePath,
          ),
        );

        lastWrittenPath = framePath;
        lastSignature = signature;
        frameIndex++;
      }

      currentMs += effectiveStep;
    }

    return entries;
  }

  /// Renders elements at [timestamp] to transparent PNG bytes.
  Future<Uint8List> renderFrameToPng({
    required List<StoryElement> elements,
    required Duration timestamp,
    required Size canvasSize,
    required int width,
    required int height,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    for (final el in elements) {
      if (!el.isVisible) continue;

      final visualState = StoryTransitionMath.computeElementVisualState(
        element: el,
        t: timestamp,
        canvasSize: canvasSize,
      );

      if (!visualState.isVisible || visualState.opacity <= 0.0) {
        continue;
      }

      _paintElement(canvas, el, visualState, canvasSize);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List() ?? Uint8List(0);
  }

  void _paintElement(
    Canvas canvas,
    StoryElement element,
    ElementVisualState visualState,
    Size canvasSize,
  ) {
    final transform = element.transform;
    final center = transform.toScreenCenter(canvasSize);
    final size = transform.toScreenSize(canvasSize);

    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();

    // 1. Position and base rotation around element center
    canvas.translate(center.dx, center.dy);
    canvas.rotate(transform.rotation);

    // 2. Animated transform matrix (scale, slide offset, bounce)
    if (visualState.transformMatrix != null) {
      canvas.transform(visualState.transformMatrix!.storage);
    }

    // 3. Offset to top-left of element bounding box
    canvas.translate(-size.width / 2.0, -size.height / 2.0);

    // 4. Effective opacity
    final effectiveOpacity = (element.opacity * visualState.opacity).clamp(
      0.0,
      1.0,
    );
    if (effectiveOpacity < 1.0) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..color = Colors.white.withAlpha((effectiveOpacity * 255).round()),
      );
    }

    final payload = element.payload;
    if (payload is TextElementPayload) {
      _paintText(canvas, payload, size);
    } else if (payload is DrawingElementPayload) {
      _paintDrawing(canvas, payload, size);
    } else if (payload is ShapeElementPayload) {
      _paintShape(canvas, payload, size);
    } else if (payload is StickerElementPayload) {
      _paintSticker(canvas, payload, size);
    } else if (payload is CardElementPayload) {
      _paintCard(canvas, payload, size);
    } else if (payload is VideoElementPayload) {
      _paintVideoPlaceholder(canvas, payload, size);
    } else {
      _paintGenericPlaceholder(canvas, payload, size);
    }

    if (effectiveOpacity < 1.0) {
      canvas.restore();
    }

    canvas.restore();
  }

  void _paintText(Canvas canvas, TextElementPayload text, Size size) {
    if (text.backgroundColor != null) {
      final bgPaint = Paint()..color = text.backgroundColor!;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, bgPaint);
    }

    final shadows = <Shadow>[];
    if (text.shadowColor != null &&
        (text.shadowBlurRadius > 0 ||
            text.shadowOffsetX != 0 ||
            text.shadowOffsetY != 0)) {
      shadows.add(
        Shadow(
          color: text.shadowColor!,
          offset: Offset(text.shadowOffsetX, text.shadowOffsetY),
          blurRadius: text.shadowBlurRadius,
        ),
      );
    }

    final baseStyle = TextStyle(
      fontSize: text.fontSize,
      fontWeight: text.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: text.isItalic ? FontStyle.italic : FontStyle.normal,
      fontFamily: text.fontFamily,
      height: text.lineSpacing,
      letterSpacing: text.letterSpacing,
    );

    if (text.outlineColor != null && text.outlineWidth > 0.0) {
      final outlineSpan = TextSpan(
        text: text.text,
        style: baseStyle.copyWith(
          foreground:
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = text.outlineWidth * 2
                ..color = text.outlineColor!,
        ),
      );
      final outlinePainter = TextPainter(
        text: outlineSpan,
        textAlign: text.textAlign,
        textDirection: TextDirection.ltr,
      );
      outlinePainter.layout(maxWidth: size.width - 24);
      final outlineOffset = Offset(
        (size.width - outlinePainter.width) / 2.0,
        (size.height - outlinePainter.height) / 2.0,
      );
      outlinePainter.paint(canvas, outlineOffset);
    }

    final textSpan = TextSpan(
      text: text.text,
      style: baseStyle.copyWith(
        color: text.textColor,
        shadows: shadows.isNotEmpty ? shadows : null,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: text.textAlign,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: size.width - 24);
    final textOffset = Offset(
      (size.width - textPainter.width) / 2.0,
      (size.height - textPainter.height) / 2.0,
    );
    textPainter.paint(canvas, textOffset);
  }

  void _paintDrawing(Canvas canvas, DrawingElementPayload drawing, Size size) {
    for (final stroke in drawing.strokes) {
      if (stroke.points.isEmpty) continue;

      final paint =
          Paint()
            ..strokeWidth = stroke.strokeWidth * size.width
            ..style = PaintingStyle.stroke
            ..strokeCap =
                stroke.brushType == DrawingBrushType.marker
                    ? StrokeCap.square
                    : StrokeCap.round
            ..strokeJoin = StrokeJoin.round;

      if (stroke.brushType == DrawingBrushType.eraser) {
        paint.blendMode = BlendMode.clear;
        paint.color = Colors.transparent;
      } else {
        paint.color = stroke.color.withAlpha(
          (stroke.opacity * 255).clamp(0, 255).round(),
        );
      }

      if (stroke.brushType == DrawingBrushType.neon) {
        final glowPaint =
            Paint()
              ..color = stroke.color.withAlpha(120)
              ..strokeWidth = stroke.strokeWidth * size.width * 2.5
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        _paintStrokePath(canvas, stroke.points, size, glowPaint);
      }

      _paintStrokePath(canvas, stroke.points, size, paint);
    }
  }

  void _paintStrokePath(
    Canvas canvas,
    List<DrawingPoint> points,
    Size size,
    Paint paint,
  ) {
    if (points.length == 1) {
      canvas.drawCircle(
        Offset(points.first.x * size.width, points.first.y * size.height),
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path();
    path.moveTo(points.first.x * size.width, points.first.y * size.height);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].x * size.width, points[i].y * size.height);
    }
    canvas.drawPath(path, paint);
  }

  void _paintShape(Canvas canvas, ShapeElementPayload shape, Size size) {
    final rect = Offset.zero & size;

    final strokePaint =
        Paint()
          ..color = shape.strokeColor
          ..strokeWidth = shape.strokeWidth
          ..style = PaintingStyle.stroke;

    final fillPaint =
        shape.fillColor != null
            ? (Paint()
              ..color = shape.fillColor!
              ..style = PaintingStyle.fill)
            : null;

    switch (shape.shapeType) {
      case ShapeType.rectangle:
        final rrect = RRect.fromRectAndRadius(
          rect.deflate(shape.strokeWidth / 2),
          Radius.circular(shape.cornerRadius),
        );
        if (fillPaint != null) canvas.drawRRect(rrect, fillPaint);
        if (shape.strokeWidth > 0) canvas.drawRRect(rrect, strokePaint);
        break;

      case ShapeType.circle:
        final center = rect.center;
        final radius =
            (math.min(rect.width, rect.height) - shape.strokeWidth) / 2;
        if (fillPaint != null) canvas.drawCircle(center, radius, fillPaint);
        if (shape.strokeWidth > 0) {
          canvas.drawCircle(center, radius, strokePaint);
        }
        break;

      case ShapeType.star:
        final starPath = _buildStarPath(rect);
        if (fillPaint != null) canvas.drawPath(starPath, fillPaint);
        if (shape.strokeWidth > 0) canvas.drawPath(starPath, strokePaint);
        break;

      case ShapeType.heart:
        final heartPath = _buildHeartPath(rect);
        if (fillPaint != null) canvas.drawPath(heartPath, fillPaint);
        if (shape.strokeWidth > 0) canvas.drawPath(heartPath, strokePaint);
        break;

      case ShapeType.line:
        canvas.drawLine(
          Offset(0, size.height / 2),
          Offset(size.width, size.height / 2),
          strokePaint,
        );
        break;

      case ShapeType.arrow:
        final p1 = Offset(0, size.height / 2);
        final p2 = Offset(size.width - 12, size.height / 2);
        canvas.drawLine(p1, p2, strokePaint);
        final arrowHead =
            Path()
              ..moveTo(size.width, size.height / 2)
              ..lineTo(size.width - 14, size.height / 2 - 8)
              ..lineTo(size.width - 14, size.height / 2 + 8)
              ..close();
        final arrowHeadPaint =
            Paint()
              ..color = shape.strokeColor
              ..style = PaintingStyle.fill;
        canvas.drawPath(arrowHead, arrowHeadPaint);
        break;
    }
  }

  Path _buildStarPath(Rect rect) {
    final path = Path();
    final center = rect.center;
    final rOuter = math.min(rect.width, rect.height) / 2;
    final rInner = rOuter * 0.45;
    const points = 5;
    var angle = -math.pi / 2;

    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? rOuter : rInner;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += math.pi / points;
    }
    path.close();
    return path;
  }

  Path _buildHeartPath(Rect rect) {
    final path = Path();
    final w = rect.width;
    final h = rect.height;

    path.moveTo(w * 0.5, h * 0.8);
    path.cubicTo(w * 0.2, h * 0.6, w * 0.05, h * 0.4, w * 0.05, h * 0.25);
    path.cubicTo(w * 0.05, h * 0.1, w * 0.25, h * 0.05, w * 0.5, h * 0.25);
    path.cubicTo(w * 0.75, h * 0.05, w * 0.95, h * 0.1, w * 0.95, h * 0.25);
    path.cubicTo(w * 0.95, h * 0.4, w * 0.8, h * 0.6, w * 0.5, h * 0.8);
    path.close();
    return path;
  }

  void _paintSticker(Canvas canvas, StickerElementPayload sticker, Size size) {
    if (sticker.label != null && sticker.label!.isNotEmpty) {
      final textSpan = TextSpan(
        text: sticker.label,
        style: TextStyle(fontSize: size.height * 0.7),
      );
      final painter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(
          (size.width - painter.width) / 2,
          (size.height - painter.height) / 2,
        ),
      );
    } else {
      _paintGenericPlaceholder(canvas, sticker, size);
    }
  }

  void _paintCard(Canvas canvas, CardElementPayload card, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF1E1E1E);
    final borderPaint =
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    final titleSpan = TextSpan(
      text:
          card.sharedContent.title.isNotEmpty
              ? card.sharedContent.title
              : 'Shared Content',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    final titlePainter = TextPainter(
      text: titleSpan,
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: size.width - 32);
    titlePainter.paint(canvas, const Offset(16, 16));

    if (card.sharedContent.authorUsername.isNotEmpty) {
      final authorSpan = TextSpan(
        text: '@${card.sharedContent.authorUsername}',
        style: const TextStyle(fontSize: 13, color: Colors.white70),
      );
      final authorPainter = TextPainter(
        text: authorSpan,
        textDirection: TextDirection.ltr,
      );
      authorPainter.layout(maxWidth: size.width - 32);
      authorPainter.paint(canvas, Offset(16, 20 + titlePainter.height));
    }
  }

  void _paintVideoPlaceholder(
    Canvas canvas,
    VideoElementPayload payload,
    Size size,
  ) {
    final boxPaint = Paint()..color = Colors.black87;
    final borderPaint =
        Paint()
          ..color = Colors.white54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, boxPaint);
    canvas.drawRRect(rrect, borderPaint);

    final span = TextSpan(
      text: 'VIDEO\n${payload.asset.duration?.inSeconds ?? 0}s',
      style: const TextStyle(fontSize: 14, color: Colors.white70),
    );
    final painter = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: size.width);
    painter.paint(
      canvas,
      Offset(
        (size.width - painter.width) / 2,
        (size.height - painter.height) / 2,
      ),
    );
  }

  void _paintGenericPlaceholder(
    Canvas canvas,
    StoryElementPayload payload,
    Size size,
  ) {
    final boxPaint = Paint()..color = Colors.grey.withAlpha(120);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, boxPaint);

    final span = TextSpan(
      text: payload.typeDiscriminator.toUpperCase(),
      style: const TextStyle(fontSize: 14, color: Colors.white),
    );
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr);
    painter.layout(maxWidth: size.width);
    painter.paint(
      canvas,
      Offset(
        (size.width - painter.width) / 2,
        (size.height - painter.height) / 2,
      ),
    );
  }

  String _computeFrameSignature(
    List<StoryElement> elements,
    Duration t,
    Size canvasSize,
  ) {
    final buffer = StringBuffer();
    for (final el in elements) {
      final vs = StoryTransitionMath.computeElementVisualState(
        element: el,
        t: t,
        canvasSize: canvasSize,
      );
      buffer.write(
        '${el.id}:${vs.isVisible}:${vs.opacity.toStringAsFixed(3)}:',
      );
      if (vs.transformMatrix != null) {
        final storage = vs.transformMatrix!.storage;
        buffer.write(
          '${storage[0].toStringAsFixed(3)},${storage[5].toStringAsFixed(3)},${storage[12].toStringAsFixed(1)},${storage[13].toStringAsFixed(1)};',
        );
      } else {
        buffer.write('none;');
      }
    }
    return buffer.toString();
  }
}
