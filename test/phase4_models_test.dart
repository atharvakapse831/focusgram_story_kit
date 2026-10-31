import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/models/element_payloads.dart';
import 'package:focusgram_story_kit/models/gradient_background.dart';
import 'package:focusgram_story_kit/models/story_element.dart';
import 'package:focusgram_story_kit/models/story_media_asset.dart';
import 'package:focusgram_story_kit/models/story_page.dart';
import 'package:focusgram_story_kit/models/story_template.dart';
import 'package:focusgram_story_kit/models/story_transform.dart';

void main() {
  group('Phase 4 Document Models & Serialization', () {
    test('ImageAdjustments round-trips and computes color matrix', () {
      const adj = ImageAdjustments(
        brightness: 0.2,
        contrast: 1.3,
        saturation: 1.1,
        warmth: 0.15,
        isFlippedHorizontally: true,
        isFlippedVertically: false,
        filterPreset: ImageFilterPreset.vintage,
      );

      final json = adj.toJson();
      final restored = ImageAdjustments.fromJson(json);

      expect(restored, equals(adj));
      expect(restored.hasAdjustments, isTrue);

      final matrix = restored.toColorMatrix();
      expect(matrix.length, equals(20)); // 4x5 ColorFilter matrix
    });

    test('DrawingStroke & DrawingElementPayload round-trip serialization', () {
      const stroke = DrawingStroke(
        points: [
          DrawingPoint(x: 0.1, y: 0.2),
          DrawingPoint(x: 0.3, y: 0.4),
          DrawingPoint(x: 0.5, y: 0.6),
        ],
        color: Colors.redAccent,
        strokeWidth: 0.015,
        opacity: 0.85,
        brushType: DrawingBrushType.neon,
      );

      const payload = DrawingElementPayload(strokes: [stroke]);
      final json = payload.toJson();
      final restored = DrawingElementPayload.fromJson(json);

      expect(restored.strokes.length, equals(1));
      expect(restored.strokes.first, equals(stroke));
      expect(restored, equals(payload));

      // Test discriminator factory
      final fromFactory = StoryElementPayload.fromJson('drawing', json);
      expect(fromFactory, isA<DrawingElementPayload>());
      expect(fromFactory, equals(payload));
    });

    test('ShapeElementPayload round-trip serialization', () {
      const shape = ShapeElementPayload(
        shapeType: ShapeType.star,
        fillColor: Colors.amber,
        strokeColor: Colors.white,
        strokeWidth: 3.0,
        cornerRadius: 12.0,
      );

      final json = shape.toJson();
      final restored = ShapeElementPayload.fromJson(json);

      expect(restored, equals(shape));

      final fromFactory = StoryElementPayload.fromJson('shape', json);
      expect(fromFactory, isA<ShapeElementPayload>());
      expect(fromFactory, equals(shape));
    });

    test(
      'Expanded TextElementPayload (outline, shadow, spacing) round-trips',
      () {
        const textPayload = TextElementPayload(
          text: 'Typography Test',
          fontSize: 32.0,
          textColor: Colors.white,
          backgroundColor: Colors.black87,
          textAlign: TextAlign.left,
          isBold: true,
          isItalic: false,
          fontFamily: 'Roboto',
          outlineColor: Colors.black,
          outlineWidth: 2.0,
          shadowColor: Colors.blueAccent,
          shadowBlurRadius: 8.0,
          shadowOffsetX: 2.0,
          shadowOffsetY: 4.0,
          lineSpacing: 1.4,
          letterSpacing: 2.5,
        );

        final json = textPayload.toJson();
        final restored = TextElementPayload.fromJson(json);

        expect(restored, equals(textPayload));
        expect(restored.outlineWidth, equals(2.0));
        expect(restored.shadowBlurRadius, equals(8.0));
        expect(restored.letterSpacing, equals(2.5));
      },
    );

    test('ImageElementPayload with adjustments round-trips', () {
      const imagePayload = ImageElementPayload(
        asset: StoryMediaAsset(
          id: 'asset_1',
          sourceType: StoryMediaSourceType.file,
          uri: '/path/to/img.png',
        ),
        fit: BoxFit.cover,
        adjustments: ImageAdjustments(
          brightness: -0.1,
          contrast: 1.2,
          filterPreset: ImageFilterPreset.sepia,
          isFlippedHorizontally: true,
        ),
      );

      final json = imagePayload.toJson();
      final restored = ImageElementPayload.fromJson(json);

      expect(restored, equals(imagePayload));
      expect(
        restored.adjustments.filterPreset,
        equals(ImageFilterPreset.sepia),
      );
      expect(restored.adjustments.isFlippedHorizontally, isTrue);
    });

    test('StoryGradientBackground round-trips and produces valid Gradient', () {
      const gradient = StoryGradientBackground(
        type: StoryGradientType.linear,
        colors: [Colors.purple, Colors.orange],
        stops: [0.0, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

      final json = gradient.toJson();
      final restored = StoryGradientBackground.fromJson(json);

      expect(restored, equals(gradient));
      expect(restored.toGradient(), isA<LinearGradient>());

      // Check presets
      expect(StoryGradientBackground.presets.length, greaterThanOrEqualTo(5));
    });

    test(
      'StoryPage with backgroundGradient and new element types round-trips',
      () {
        const page = StoryPage(
          id: 'page_phase4_1',
          duration: Duration(seconds: 7),
          backgroundColor: Colors.transparent,
          backgroundGradient: StoryGradientBackground.sunset,
          elements: [
            StoryElement(
              id: 'el_shape_1',
              type: StoryElementType.shape,
              transform: StoryTransform(
                x: 0.5,
                y: 0.5,
                width: 0.5,
                height: 0.5,
              ),
              payload: ShapeElementPayload(
                shapeType: ShapeType.rectangle,
                strokeColor: Colors.white,
              ),
            ),
            StoryElement(
              id: 'el_drawing_1',
              type: StoryElementType.drawing,
              transform: StoryTransform(
                x: 0.5,
                y: 0.5,
                width: 1.0,
                height: 1.0,
              ),
              payload: DrawingElementPayload(
                strokes: [
                  DrawingStroke(
                    points: [DrawingPoint(x: 0.2, y: 0.3)],
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ],
        );

        final json = page.toJson();
        final restored = StoryPage.fromJson(json);

        expect(restored.id, equals(page.id));
        expect(
          restored.backgroundGradient,
          equals(StoryGradientBackground.sunset),
        );
        expect(restored.elements.length, equals(2));
        expect(restored.elements[0].type, equals(StoryElementType.shape));
        expect(restored.elements[1].type, equals(StoryElementType.drawing));
        expect(restored, equals(page));
      },
    );

    test('StoryTemplate presets generate valid multi-element StoryPage', () {
      final templates = StoryTemplate.presets;
      expect(templates.length, greaterThanOrEqualTo(3));

      for (final tpl in templates) {
        final page = tpl.createPage('tpl_page_1');
        expect(page.id, equals('tpl_page_1'));
        expect(page.elements.isNotEmpty, isTrue);
      }
    });
  });
}
