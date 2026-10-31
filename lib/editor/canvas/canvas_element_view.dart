import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/element_payloads.dart';
import '../../models/story_element.dart';
import '../../models/story_media_asset.dart';
import '../../timeline/timeline_controller.dart';
import '../../viewer/story_shared_content_card.dart';
import 'canvas_video_view.dart';

/// Renders the visual representation of a [StoryElement] based on its payload.
class CanvasElementView extends StatelessWidget {
  const CanvasElementView({
    super.key,
    required this.element,
    this.timelineController,
  });

  final StoryElement element;
  final StoryTimelineController? timelineController;

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
    } else if (payload is DrawingElementPayload) {
      content = _buildDrawing(payload);
    } else if (payload is ShapeElementPayload) {
      content = _buildShape(payload);
    } else if (payload is VideoElementPayload) {
      content = _buildVideo(payload);
    } else {
      content = _buildUnknown(payload);
    }

    if (element.opacity < 1.0) {
      return Opacity(opacity: element.opacity.clamp(0.0, 1.0), child: content);
    }

    return content;
  }

  Widget _buildVideo(VideoElementPayload payload) {
    return CanvasVideoView(
      videoPayload: payload.video,
      timelineController: timelineController,
    );
  }

  Widget _buildText(TextElementPayload textPayload) {
    final shadows = <Shadow>[];
    if (textPayload.shadowColor != null &&
        (textPayload.shadowBlurRadius > 0 ||
            textPayload.shadowOffsetX != 0 ||
            textPayload.shadowOffsetY != 0)) {
      shadows.add(
        Shadow(
          color: textPayload.shadowColor!,
          offset: Offset(textPayload.shadowOffsetX, textPayload.shadowOffsetY),
          blurRadius: textPayload.shadowBlurRadius,
        ),
      );
    }

    final baseStyle = TextStyle(
      fontSize: textPayload.fontSize,
      fontWeight: textPayload.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: textPayload.isItalic ? FontStyle.italic : FontStyle.normal,
      fontFamily: textPayload.fontFamily,
      height: textPayload.lineSpacing,
      letterSpacing: textPayload.letterSpacing,
    );

    Widget textWidget;
    if (textPayload.outlineColor != null && textPayload.outlineWidth > 0.0) {
      textWidget = Stack(
        alignment: Alignment.center,
        children: [
          // Outline stroke behind
          Text(
            textPayload.text,
            textAlign: textPayload.textAlign,
            style: baseStyle.copyWith(
              foreground:
                  Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = textPayload.outlineWidth * 2
                    ..color = textPayload.outlineColor!,
            ),
          ),
          // Filled text in front
          Text(
            textPayload.text,
            textAlign: textPayload.textAlign,
            style: baseStyle.copyWith(
              color: textPayload.textColor,
              shadows: shadows.isNotEmpty ? shadows : null,
            ),
          ),
        ],
      );
    } else {
      textWidget = Text(
        textPayload.text,
        textAlign: textPayload.textAlign,
        style: baseStyle.copyWith(
          color: textPayload.textColor,
          shadows: shadows.isNotEmpty ? shadows : null,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration:
          textPayload.backgroundColor != null
              ? BoxDecoration(
                color: textPayload.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              )
              : null,
      child: textWidget,
    );
  }

  Widget _buildImage(ImageElementPayload imagePayload) {
    final asset = imagePayload.asset;
    Widget img;
    switch (asset.sourceType) {
      case StoryMediaSourceType.file:
        img = Image.file(
          File(asset.uri),
          fit: imagePayload.fit,
          errorBuilder: (_, __, ___) => _errorPlaceholder('Image not found'),
        );
        break;
      case StoryMediaSourceType.asset:
        img = Image.asset(
          asset.uri,
          fit: imagePayload.fit,
          errorBuilder: (_, __, ___) => _errorPlaceholder('Asset missing'),
        );
        break;
      case StoryMediaSourceType.network:
      case StoryMediaSourceType.memory:
        if (asset.uri.isEmpty) return _errorPlaceholder('No URI');
        img = CachedNetworkImage(
          imageUrl: asset.uri,
          fit: imagePayload.fit,
          placeholder:
              (_, __) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          errorWidget: (_, __, ___) => _errorPlaceholder('Network error'),
        );
        break;
    }

    // Apply color filter matrix if configured
    if (imagePayload.adjustments.hasAdjustments) {
      img = ColorFiltered(
        colorFilter: ColorFilter.matrix(
          imagePayload.adjustments.toColorMatrix(),
        ),
        child: img,
      );
    }

    // Apply mirror flip transforms
    if (imagePayload.adjustments.isFlippedHorizontally ||
        imagePayload.adjustments.isFlippedVertically) {
      img = Transform(
        transform: Matrix4.diagonal3Values(
          imagePayload.adjustments.isFlippedHorizontally ? -1.0 : 1.0,
          imagePayload.adjustments.isFlippedVertically ? -1.0 : 1.0,
          1.0,
        ),
        alignment: Alignment.center,
        child: img,
      );
    }

    return img;
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
    if (stickerPayload.assetUri.isEmpty &&
        stickerPayload.label != null &&
        stickerPayload.label!.isNotEmpty) {
      return Center(
        child: Text(
          stickerPayload.label!,
          style: const TextStyle(fontSize: 48),
        ),
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

  Widget _buildDrawing(DrawingElementPayload drawingPayload) {
    return CustomPaint(
      painter: _DrawingElementPainter(strokes: drawingPayload.strokes),
      size: Size.infinite,
    );
  }

  Widget _buildShape(ShapeElementPayload shapePayload) {
    return CustomPaint(
      painter: _ShapeElementPainter(payload: shapePayload),
      size: Size.infinite,
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

/// Custom painter for rendering freehand drawing strokes on canvas.
class _DrawingElementPainter extends CustomPainter {
  const _DrawingElementPainter({required this.strokes});

  final List<DrawingStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
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

      // Neon glow underlay
      if (stroke.brushType == DrawingBrushType.neon) {
        final glowPaint =
            Paint()
              ..color = stroke.color.withAlpha(120)
              ..strokeWidth = stroke.strokeWidth * size.width * 2.5
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        _drawStrokePath(canvas, stroke.points, size, glowPaint);
      }

      _drawStrokePath(canvas, stroke.points, size, paint);
    }
  }

  void _drawStrokePath(
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
      final p = points[i];
      path.lineTo(p.x * size.width, p.y * size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingElementPainter oldDelegate) => true;
}

/// Custom painter for rendering geometric vector shapes.
class _ShapeElementPainter extends CustomPainter {
  const _ShapeElementPainter({required this.payload});

  final ShapeElementPayload payload;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final strokePaint =
        Paint()
          ..color = payload.strokeColor
          ..strokeWidth = payload.strokeWidth
          ..style = PaintingStyle.stroke;

    final fillPaint =
        payload.fillColor != null
            ? (Paint()
              ..color = payload.fillColor!
              ..style = PaintingStyle.fill)
            : null;

    switch (payload.shapeType) {
      case ShapeType.rectangle:
        final rrect = RRect.fromRectAndRadius(
          rect.deflate(payload.strokeWidth / 2),
          Radius.circular(payload.cornerRadius),
        );
        if (fillPaint != null) canvas.drawRRect(rrect, fillPaint);
        if (payload.strokeWidth > 0) canvas.drawRRect(rrect, strokePaint);
        break;

      case ShapeType.circle:
        final center = rect.center;
        final radius =
            (math.min(rect.width, rect.height) - payload.strokeWidth) / 2;
        if (fillPaint != null) canvas.drawCircle(center, radius, fillPaint);
        if (payload.strokeWidth > 0) {
          canvas.drawCircle(center, radius, strokePaint);
        }
        break;

      case ShapeType.star:
        final starPath = _buildStarPath(rect);
        if (fillPaint != null) canvas.drawPath(starPath, fillPaint);
        if (payload.strokeWidth > 0) canvas.drawPath(starPath, strokePaint);
        break;

      case ShapeType.heart:
        final heartPath = _buildHeartPath(rect);
        if (fillPaint != null) canvas.drawPath(heartPath, fillPaint);
        if (payload.strokeWidth > 0) canvas.drawPath(heartPath, strokePaint);
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
        // Arrowhead
        final arrowHead =
            Path()
              ..moveTo(size.width, size.height / 2)
              ..lineTo(size.width - 14, size.height / 2 - 8)
              ..lineTo(size.width - 14, size.height / 2 + 8)
              ..close();
        final arrowHeadPaint =
            Paint()
              ..color = payload.strokeColor
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

  @override
  bool shouldRepaint(covariant _ShapeElementPainter oldDelegate) => true;
}
