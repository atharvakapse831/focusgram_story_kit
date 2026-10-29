import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/element_payloads.dart';
import '../models/story_canvas_spec.dart';
import '../models/story_element.dart';
import '../models/story_page.dart';
import '../models/story_project.dart';
import 'export_result.dart';

/// Renders a [StoryProject] or individual [StoryPage] off-screen to a raster image.
///
/// Ensures deterministic pixel export that mirrors the preview canvas geometry
/// while excluding selection chrome, handles, and editor controls.
class StoryStillImageExporter {
  const StoryStillImageExporter();

  /// Renders all pages of [project] sequentially and returns their export results.
  Future<List<StillImageExportResult>> exportProject(
    StoryProject project, {
    int? targetWidth,
    int? targetHeight,
  }) async {
    final results = <StillImageExportResult>[];
    for (final page in project.pages) {
      final res = await exportPage(
        page,
        project.canvasSpec,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      results.add(res);
    }
    return results;
  }

  /// Renders a single [page] to an offscreen PNG raster image.
  Future<StillImageExportResult> exportPage(
    StoryPage page,
    StoryCanvasSpec canvasSpec, {
    int? targetWidth,
    int? targetHeight,
  }) async {
    final width = targetWidth ?? canvasSpec.width.toInt();
    final height = targetHeight ?? canvasSpec.height.toInt();
    final canvasSize = Size(width.toDouble(), height.toDouble());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Paint background solid color
    final bgPaint = Paint()..color = page.backgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      bgPaint,
    );

    // 2. Paint visible elements in deterministic z-order
    for (final el in page.sortedElements) {
      if (!el.isVisible) continue;
      _paintElement(canvas, el, canvasSize);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List() ?? Uint8List(0);

    return StillImageExportResult(
      pageId: page.id,
      bytes: bytes,
      width: width,
      height: height,
      format: 'png',
      duration: page.duration,
    );
  }

  void _paintElement(Canvas canvas, StoryElement element, Size canvasSize) {
    final transform = element.transform;
    final center = transform.toScreenCenter(canvasSize);
    final size = transform.toScreenSize(canvasSize);

    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();

    // Position and rotate around element center
    canvas.translate(center.dx, center.dy);
    canvas.rotate(transform.rotation);
    canvas.translate(-size.width / 2.0, -size.height / 2.0);

    if (element.opacity < 1.0) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..color = Colors.white.withAlpha((element.opacity * 255).round()),
      );
    }

    final payload = element.payload;
    if (payload is TextElementPayload) {
      _paintText(canvas, payload, size);
    } else if (payload is CardElementPayload) {
      _paintCard(canvas, payload, size);
    } else {
      _paintGenericPlaceholder(canvas, payload, size);
    }

    if (element.opacity < 1.0) {
      canvas.restore();
    }

    canvas.restore();
  }

  void _paintText(Canvas canvas, TextElementPayload text, Size size) {
    // Draw background pill if configured
    if (text.backgroundColor != null) {
      final bgPaint = Paint()..color = text.backgroundColor!;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      );
      canvas.drawRRect(rrect, bgPaint);
    }

    final textSpan = TextSpan(
      text: text.text,
      style: TextStyle(
        fontSize: text.fontSize,
        color: text.textColor,
        fontWeight: text.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: text.isItalic ? FontStyle.italic : FontStyle.normal,
        fontFamily: text.fontFamily,
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

    // Title
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

    // Author
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
}
