import 'package:flutter/material.dart';
import '../../models/drawing_stroke.dart';
import '../editor_controller.dart';

/// Transparent interactive overlay that captures freehand touch gestures
/// and renders live in-progress drawing strokes on top of the canvas.
class DrawingCanvasOverlay extends StatefulWidget {
  const DrawingCanvasOverlay({super.key, required this.controller});

  final EditorController controller;

  @override
  State<DrawingCanvasOverlay> createState() => _DrawingCanvasOverlayState();
}

class _DrawingCanvasOverlayState extends State<DrawingCanvasOverlay> {
  final List<DrawingPoint> _currentPoints = [];

  void _onPanStart(DragStartDetails details, Size canvasSize) {
    setState(() {
      _currentPoints.clear();
      final local = details.localPosition;
      _currentPoints.add(
        DrawingPoint(
          x: (local.dx / canvasSize.width).clamp(0.0, 1.0),
          y: (local.dy / canvasSize.height).clamp(0.0, 1.0),
        ),
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size canvasSize) {
    setState(() {
      final local = details.localPosition;
      _currentPoints.add(
        DrawingPoint(
          x: (local.dx / canvasSize.width).clamp(0.0, 1.0),
          y: (local.dy / canvasSize.height).clamp(0.0, 1.0),
        ),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPoints.isNotEmpty) {
      final stroke = DrawingStroke(
        points: List.unmodifiable(_currentPoints),
        color: widget.controller.state.activeBrushColor,
        brushType: widget.controller.state.activeBrushType,
        strokeWidth: widget.controller.state.activeBrushWidth,
      );
      widget.controller.addDrawingStroke(stroke);
      setState(() => _currentPoints.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => _onPanStart(d, canvasSize),
          onPanUpdate: (d) => _onPanUpdate(d, canvasSize),
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            size: canvasSize,
            painter: _LiveStrokePainter(
              points: _currentPoints,
              color: widget.controller.state.activeBrushColor,
              brushType: widget.controller.state.activeBrushType,
              strokeWidth: widget.controller.state.activeBrushWidth,
            ),
          ),
        );
      },
    );
  }
}

class _LiveStrokePainter extends CustomPainter {
  const _LiveStrokePainter({
    required this.points,
    required this.color,
    required this.brushType,
    required this.strokeWidth,
  });

  final List<DrawingPoint> points;
  final Color color;
  final DrawingBrushType brushType;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth * size.width
          ..style = PaintingStyle.stroke
          ..strokeCap =
              brushType == DrawingBrushType.marker
                  ? StrokeCap.square
                  : StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    if (brushType == DrawingBrushType.neon) {
      final glowPaint =
          Paint()
            ..color = color.withAlpha(120)
            ..strokeWidth = strokeWidth * size.width * 2.5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      _drawPath(canvas, size, glowPaint);
    }

    _drawPath(canvas, size, paint);
  }

  void _drawPath(Canvas canvas, Size size, Paint paint) {
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

  @override
  bool shouldRepaint(covariant _LiveStrokePainter oldDelegate) => true;
}
