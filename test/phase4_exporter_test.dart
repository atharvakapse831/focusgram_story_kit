import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/export/still_image_exporter.dart';
import 'package:focusgram_story_kit/models/element_payloads.dart';
import 'package:focusgram_story_kit/models/gradient_background.dart';
import 'package:focusgram_story_kit/models/story_canvas_spec.dart';
import 'package:focusgram_story_kit/models/story_element.dart';
import 'package:focusgram_story_kit/models/story_page.dart';
import 'package:focusgram_story_kit/models/story_project.dart';
import 'package:focusgram_story_kit/models/story_transform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4 Still Image Exporter Parity', () {
    testWidgets('Exports page with gradient, drawing, shapes, and typography', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const page = StoryPage(
          id: 'export_p4_page',
          backgroundGradient: StoryGradientBackground.sunset,
          elements: [
            // 1. Vector shape (rectangle)
            StoryElement(
              id: 'el_shape_rect',
              type: StoryElementType.shape,
              transform: StoryTransform(
                x: 0.5,
                y: 0.3,
                width: 0.7,
                height: 0.15,
              ),
              payload: ShapeElementPayload(
                shapeType: ShapeType.rectangle,
                strokeColor: Colors.white,
                fillColor: Colors.black54,
                cornerRadius: 12.0,
              ),
              zIndex: 1,
            ),
            // 2. Rich Typography
            StoryElement(
              id: 'el_rich_text',
              type: StoryElementType.text,
              transform: StoryTransform(
                x: 0.5,
                y: 0.3,
                width: 0.65,
                height: 0.12,
              ),
              payload: TextElementPayload(
                text: 'Phase 4 Export',
                fontSize: 28.0,
                textColor: Colors.white,
                outlineColor: Colors.black,
                outlineWidth: 2.0,
                shadowColor: Colors.blueAccent,
                shadowBlurRadius: 6.0,
                shadowOffsetX: 2.0,
                shadowOffsetY: 2.0,
                isBold: true,
              ),
              zIndex: 2,
            ),
            // 3. Freehand drawing layer
            StoryElement(
              id: 'el_drawing',
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
                    points: [
                      DrawingPoint(x: 0.2, y: 0.5),
                      DrawingPoint(x: 0.5, y: 0.55),
                      DrawingPoint(x: 0.8, y: 0.5),
                    ],
                    color: Colors.greenAccent,
                    strokeWidth: 0.01,
                    brushType: DrawingBrushType.neon,
                  ),
                ],
              ),
              zIndex: 3,
            ),
            // 4. Emoji sticker
            StoryElement(
              id: 'el_emoji_sticker',
              type: StoryElementType.sticker,
              transform: StoryTransform(
                x: 0.5,
                y: 0.75,
                width: 0.2,
                height: 0.1,
              ),
              payload: StickerElementPayload(
                stickerId: 'stk_fire',
                assetUri: '',
                label: '🔥',
              ),
              zIndex: 4,
            ),
          ],
        );

        const project = StoryProject(
          id: 'proj_export_p4',
          canvasSpec: StoryCanvasSpec(width: 540, height: 960),
          pages: [page],
        );

        const exporter = StoryStillImageExporter();
        final results = await exporter.exportProject(project);

        expect(results.length, equals(1));
        final res = results.first;

        expect(res.pageId, equals('export_p4_page'));
        expect(res.width, equals(540));
        expect(res.height, equals(960));
        expect(res.format, equals('png'));
        expect(res.bytes.isNotEmpty, isTrue);

        // Verify PNG magic header: [0x89, 0x50, 0x4E, 0x47]
        expect(res.bytes[0], equals(0x89));
        expect(res.bytes[1], equals(0x50));
        expect(res.bytes[2], equals(0x4E));
        expect(res.bytes[3], equals(0x47));
      });
    });
  });
}
