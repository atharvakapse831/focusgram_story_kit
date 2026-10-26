import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/models/story_group_model.dart';
import 'package:focusgram_story_kit/models/story_item_model.dart';
import 'package:focusgram_story_kit/overlays/story_overlay.dart';
import 'package:focusgram_story_kit/viewer/story_kit_viewer.dart';

void main() {
  group('StoryKitViewer empty input', () {
    testWidgets('renders an empty state when there are no groups',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StoryKitViewer(groups: []),
        ),
      );

      expect(find.text('No stories available'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders an empty state when every group has no items',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StoryKitViewer(
            groups: [
              StoryGroupModel(
                userId: 'u1',
                username: 'empty-one',
              ),
              StoryGroupModel(
                userId: 'u2',
                username: 'empty-two',
              ),
            ],
          ),
        ),
      );

      expect(find.text('No stories available'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });


    testWidgets('overlay taps do not trigger story navigation',
        (tester) async {
      final interactions = <String, Map<String, dynamic>>{};
      final viewedGroups = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StoryKitViewer(
            groups: const [
              StoryGroupModel(
                userId: 'u1',
                username: 'viewer-test',
                items: [
                  StoryItemModel(
                    id: 'first',
                    mediaUrl: 'https://example.com/first.jpg',
                    type: StoryItemType.image,
                    overlays: [
                      LinkOverlay(
                        id: 'link1',
                        normalizedDx: 0.5,
                        normalizedDy: 0.5,
                        url: 'https://focusgram.example',
                        displayDomain: 'focusgram.example',
                      ),
                    ],
                  ),
                  StoryItemModel(
                    id: 'second',
                    mediaUrl: 'https://example.com/second.jpg',
                    type: StoryItemType.image,
                  ),
                ],
              ),
            ],
            onOverlayInteraction: (id, payload) => interactions[id] = payload,
            onGroupViewed: viewedGroups.add,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.link));
      await tester.pump();

      expect(interactions['link1']?['url'], 'https://focusgram.example');
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(viewedGroups, ['u1']);
      expect(tester.takeException(), isNull);
    });
  });
}
