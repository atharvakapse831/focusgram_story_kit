import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/focusgram_story_kit.dart';

void main() {
  group('StoryStillImageExporter Deterministic Raster Export', () {
    test(
      'AC-5 & AC-6: Renders still image matching dimensions with valid PNG bytes',
      () async {
        const exporter = StoryStillImageExporter();

        const project = StoryProject(
          id: 'proj_export_test',
          canvasSpec: StoryCanvasSpec(
            width: 540,
            height: 960,
            backgroundColor: Colors.teal,
          ),
          pages: [
            StoryPage(
              id: 'page_exp_1',
              backgroundColor: Colors.teal,
              elements: [
                StoryElement(
                  id: 'el_txt',
                  type: StoryElementType.text,
                  transform: StoryTransform(
                    x: 0.5,
                    y: 0.5,
                    width: 0.6,
                    height: 0.2,
                  ),
                  payload: TextElementPayload(
                    text: 'Exported Story',
                    textColor: Colors.white,
                    backgroundColor: Colors.black87,
                  ),
                ),
                StoryElement(
                  id: 'el_card',
                  type: StoryElementType.card,
                  transform: StoryTransform(
                    x: 0.5,
                    y: 0.75,
                    width: 0.8,
                    height: 0.2,
                  ),
                  payload: CardElementPayload(
                    sharedContent: StorySharedContent(
                      id: 'c1',
                      type: StoryKitContentType.article,
                      title: 'Export Test',
                      authorUsername: 'tester',
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

        final results = await exporter.exportProject(project);

        expect(results.length, equals(1));
        final result = results.first;

        expect(result.pageId, equals('page_exp_1'));
        expect(result.width, equals(540));
        expect(result.height, equals(960));
        expect(result.format, equals('png'));
        expect(result.bytes.isNotEmpty, isTrue);

        // Verify standard PNG header magic bytes (0x89, 0x50, 0x4E, 0x47)
        expect(result.bytes[0], equals(0x89));
        expect(result.bytes[1], equals(0x50)); // 'P'
        expect(result.bytes[2], equals(0x4E)); // 'N'
        expect(result.bytes[3], equals(0x47)); // 'G'
      },
    );
  });
}
