import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/focusgram_story_kit.dart';

void main() {
  group('StoryTransform Geometry & Hit-Testing', () {
    const canvasSize = Size(1000, 2000);

    test('toScreenCenter and toScreenSize map normalized units to pixels', () {
      const transform = StoryTransform(
        x: 0.5,
        y: 0.25,
        width: 0.4,
        height: 0.1,
        scale: 1.5,
      );

      final center = transform.toScreenCenter(canvasSize);
      expect(center.dx, equals(500.0));
      expect(center.dy, equals(500.0));

      final size = transform.toScreenSize(canvasSize);
      expect(size.width, equals(0.4 * 1000 * 1.5)); // 600.0
      expect(size.height, equals(0.1 * 2000 * 1.5)); // 300.0
    });

    test('containsPoint tests unrotated rect bounds', () {
      const transform = StoryTransform(
        x: 0.5,
        y: 0.5,
        width: 0.2, // 200px wide
        height: 0.1, // 200px high
      );

      // Center is (500, 1000), width=200 (400..600), height=200 (900..1100)
      expect(
        transform.containsPoint(const Offset(500, 1000), canvasSize),
        isTrue,
      );
      expect(
        transform.containsPoint(const Offset(450, 950), canvasSize),
        isTrue,
      );
      expect(
        transform.containsPoint(const Offset(600, 1100), canvasSize),
        isTrue,
      );

      // Outside
      expect(
        transform.containsPoint(const Offset(350, 1000), canvasSize),
        isFalse,
      );
      expect(
        transform.containsPoint(const Offset(500, 850), canvasSize),
        isFalse,
      );
    });

    test('containsPoint respects rotation matrix', () {
      // Rotate by 90 degrees (pi / 2)
      const transform = StoryTransform(
        x: 0.5,
        y: 0.5,
        width: 0.4, // 400px wide before rotation
        height: 0.1, // 200px high before rotation
        rotation: math.pi / 2.0,
      );

      // After 90 deg rotation, horizontal width becomes 200px (400..600) and vertical height becomes 400px (800..1200)
      expect(
        transform.containsPoint(const Offset(500, 1000), canvasSize),
        isTrue,
      );
      expect(
        transform.containsPoint(const Offset(500, 1150), canvasSize),
        isTrue,
      );

      // Point at (650, 1000): was inside if unrotated, but rotated it is outside (width is now 200)!
      expect(
        transform.containsPoint(const Offset(650, 1000), canvasSize),
        isFalse,
      );
    });

    test('clampToCanvas keeps elements accessible within viewport', () {
      const transform = StoryTransform(
        x: 2.0, // Way off to the right
        y: -1.0, // Way off to the top
        width: 0.4,
        height: 0.2,
      );

      final clamped = transform.clampToCanvas();
      expect(clamped.x, lessThan(2.0));
      expect(clamped.y, greaterThan(-1.0));
    });
  });
}
