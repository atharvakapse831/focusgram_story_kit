import 'package:flutter/material.dart';

/// Renders visual snapping guideline indicators (center horizontal/vertical lines)
/// during interactive element drag gestures.
class SnappingGuidelinesOverlay extends StatelessWidget {
  const SnappingGuidelinesOverlay({
    super.key,
    this.snapX,
    this.snapY,
    required this.canvasSize,
  });

  final double? snapX;
  final double? snapY;
  final Size canvasSize;

  @override
  Widget build(BuildContext context) {
    if (snapX == null && snapY == null) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: canvasSize,
      painter: _SnappingGuidelinesPainter(snapX: snapX, snapY: snapY),
    );
  }
}

class _SnappingGuidelinesPainter extends CustomPainter {
  const _SnappingGuidelinesPainter({this.snapX, this.snapY});

  final double? snapX;
  final double? snapY;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint =
        Paint()
          ..color = Colors.cyanAccent.withAlpha(200)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    // Vertical guideline (e.g. Center X)
    if (snapX != null) {
      final x = snapX! * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Horizontal guideline (e.g. Center Y)
    if (snapY != null) {
      final y = snapY! * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnappingGuidelinesPainter oldDelegate) {
    return oldDelegate.snapX != snapX || oldDelegate.snapY != snapY;
  }
}
