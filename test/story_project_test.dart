import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/focusgram_story_kit.dart';

void main() {
  group('StoryProject & Element Models Serialization', () {
    test(
      'AC-1: Round-trip preserves IDs, geometry, style, order, and media references',
      () {
        const original = StoryProject(
          id: 'proj_123',
          schemaVersion: 1,
          revision: 4,
          canvasSpec: StoryCanvasSpec(
            width: 1080,
            height: 1920,
            backgroundColor: Colors.blueGrey,
          ),
          metadata: {'authorId': 'user_42', 'tag': 'vacation'},
          pages: [
            StoryPage(
              id: 'page_1',
              duration: Duration(seconds: 7),
              backgroundColor: Colors.black,
              backgroundAsset: StoryMediaAsset(
                id: 'asset_bg',
                sourceType: StoryMediaSourceType.network,
                uri: 'https://example.com/bg.jpg',
                mimeType: 'image/jpeg',
                width: 1080,
                height: 1920,
              ),
              elements: [
                StoryElement(
                  id: 'el_text_1',
                  type: StoryElementType.text,
                  zIndex: 1,
                  opacity: 0.9,
                  transform: StoryTransform(
                    x: 0.5,
                    y: 0.3,
                    width: 0.8,
                    height: 0.15,
                    rotation: 0.25,
                    scale: 1.2,
                  ),
                  payload: TextElementPayload(
                    text: 'FocusGram Stories',
                    fontSize: 28,
                    textColor: Colors.amber,
                    backgroundColor: Colors.black54,
                    textAlign: TextAlign.center,
                    isBold: true,
                    isItalic: false,
                  ),
                ),
                StoryElement(
                  id: 'el_sticker_1',
                  type: StoryElementType.sticker,
                  zIndex: 2,
                  transform: StoryTransform(
                    x: 0.5,
                    y: 0.7,
                    width: 0.25,
                    height: 0.25,
                  ),
                  payload: StickerElementPayload(
                    stickerId: 'star_gold',
                    assetUri: 'https://example.com/star.png',
                    label: 'Gold Star',
                  ),
                ),
                StoryElement(
                  id: 'el_card_1',
                  type: StoryElementType.card,
                  zIndex: 3,
                  transform: StoryTransform(
                    x: 0.5,
                    y: 0.5,
                    width: 0.85,
                    height: 0.3,
                  ),
                  payload: CardElementPayload(
                    sharedContent: StorySharedContent(
                      id: 'post_99',
                      type: StoryKitContentType.article,
                      title: 'Flutter Architecture',
                      authorUsername: 'flutterdev',
                      badgeText: 'Article',
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

        final json = original.toJson();
        final restored = StoryProject.fromJson(json);

        expect(restored.id, equals('proj_123'));
        expect(restored.schemaVersion, equals(1));
        expect(restored.revision, equals(4));
        expect(restored.canvasSpec.width, equals(1080));
        expect(restored.canvasSpec.height, equals(1920));
        expect(restored.metadata?['authorId'], equals('user_42'));

        expect(restored.pages.length, equals(1));
        final page = restored.pages.first;
        expect(page.id, equals('page_1'));
        expect(page.duration, equals(const Duration(seconds: 7)));
        expect(page.backgroundAsset?.uri, equals('https://example.com/bg.jpg'));
        expect(page.elements.length, equals(3));

        // Verify Text Element
        final textEl = page.elements[0];
        expect(textEl.id, equals('el_text_1'));
        expect(textEl.type, equals(StoryElementType.text));
        expect(textEl.transform.rotation, closeTo(0.25, 0.001));
        expect(textEl.transform.scale, closeTo(1.2, 0.001));
        final textPayload = textEl.payload as TextElementPayload;
        expect(textPayload.text, equals('FocusGram Stories'));
        expect(textPayload.isBold, isTrue);

        // Verify Sticker Element
        final stickerEl = page.elements[1];
        expect(stickerEl.id, equals('el_sticker_1'));
        final stickerPayload = stickerEl.payload as StickerElementPayload;
        expect(stickerPayload.stickerId, equals('star_gold'));

        // Verify Card Element
        final cardEl = page.elements[2];
        expect(cardEl.id, equals('el_card_1'));
        final cardPayload = cardEl.payload as CardElementPayload;
        expect(cardPayload.sharedContent.title, equals('Flutter Architecture'));
        expect(
          cardPayload.sharedContent.type,
          equals(StoryKitContentType.article),
        );
      },
    );

    test(
      'Unknown element payload falls back gracefully to UnknownElementPayload',
      () {
        final json = {
          'id': 'el_future_1',
          'type': 'future_ai_hologram',
          'transform': {'x': 0.5, 'y': 0.5, 'width': 0.5, 'height': 0.5},
          'payload': {'modelId': 'gpt-9', 'prompt': 'render scene'},
        };

        final element = StoryElement.fromJson(json);
        expect(element.type, equals(StoryElementType.unknown));
        expect(element.payload, isA<UnknownElementPayload>());
        final unknownPayload = element.payload as UnknownElementPayload;
        expect(unknownPayload.rawType, equals('future_ai_hologram'));
        expect(unknownPayload.rawData['modelId'], equals('gpt-9'));
      },
    );

    test('toStoryGroupModel converts project into viewer-compatible group', () {
      const project = StoryProject(
        id: 'proj_demo',
        pages: [
          StoryPage(
            id: 'page_a',
            duration: Duration(seconds: 6),
            backgroundAsset: StoryMediaAsset(
              id: 'media_1',
              sourceType: StoryMediaSourceType.network,
              uri: 'https://example.com/photo.jpg',
            ),
            elements: [
              StoryElement(
                id: 'card_el',
                type: StoryElementType.card,
                transform: StoryTransform(),
                payload: CardElementPayload(
                  sharedContent: StorySharedContent(
                    id: 'art_1',
                    type: StoryKitContentType.article,
                    title: 'Clean Architecture',
                  ),
                ),
              ),
            ],
          ),
        ],
      );

      final group = project.toStoryGroupModel(
        userId: 'usr_1',
        username: 'alice',
      );

      expect(group.userId, equals('usr_1'));
      expect(group.username, equals('alice'));
      expect(group.items.length, equals(1));
      expect(group.items.first.id, equals('page_a'));
      expect(group.items.first.duration, equals(const Duration(seconds: 6)));
      expect(
        group.items.first.mediaUrl,
        equals('https://example.com/photo.jpg'),
      );
      expect(
        group.items.first.sharedContent?.title,
        equals('Clean Architecture'),
      );
    });
  });
}
