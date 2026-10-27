import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/models/story_group_model.dart';
import 'package:focusgram_story_kit/models/story_item_model.dart';
import 'package:focusgram_story_kit/overlays/story_overlay.dart';
import 'package:focusgram_story_kit/viewer/story_kit_viewer.dart';

void main() {
  group('StoryKitViewer lifecycle and navigation', () {
    testWidgets('controller pause/resume controls image playback',
        (tester) async {
      final controller = StoryKitViewerController();
      var finished = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StoryKitViewer(
            controller: controller,
            groups: const [
              StoryGroupModel(
                userId: 'u1',
                username: 'controller',
                items: [StoryItemModel(
                  id: 'one', mediaUrl: 'https://example.com/one.jpg',
                  type: StoryItemType.image,
                )],
              ),
            ],
            defaultImageDuration: const Duration(seconds: 1),
            onViewerFinished: () => finished++,
          ),
        ),
      );
      await tester.pump();
      controller.pause();
      expect(controller.isPaused, isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(finished, 0);
      controller.resume();
      expect(controller.isPaused, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(finished, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pauses story progression while app is backgrounded',
        (tester) async {
      var finished = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StoryKitViewer(
            groups: const [StoryGroupModel(
              userId: 'u1', username: 'lifecycle',
              items: [StoryItemModel(
                id: 'one', mediaUrl: 'https://example.com/one.jpg',
                type: StoryItemType.image,
              )],
            )],
            defaultImageDuration: const Duration(seconds: 1),
            onViewerFinished: () => finished++,
          ),
        ),
      );
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 2));
      expect(finished, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 2));
      expect(finished, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('advances items and skips empty groups safely',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: StoryKitViewer(
          groups: const [
            StoryGroupModel(userId: 'u1', username: 'first-group', items: [
              StoryItemModel(id: 'first', mediaUrl: 'https://example.com/first.jpg', type: StoryItemType.image),
              StoryItemModel(id: 'second', mediaUrl: 'https://example.com/second.jpg', type: StoryItemType.image),
            ]),
            StoryGroupModel(userId: 'u-empty', username: 'empty-group'),
            StoryGroupModel(userId: 'u2', username: 'second-group', items: [
              StoryItemModel(id: 'third', mediaUrl: 'https://example.com/third.jpg', type: StoryItemType.image),
            ]),
          ],
          headerBuilder: (_, group) => Text(group.username),
        ),
      ));
      await tester.pump();
      expect(find.text('first-group'), findsOneWidget);
      await tester.tapAt(const Offset(350, 400));
      await tester.pump();
      expect(find.text('first-group'), findsOneWidget);
      await tester.tapAt(const Offset(350, 400));
      await tester.pump();
      expect(find.text('second-group'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

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
      expect(find.byWidgetPredicate((widget) =>
        widget is CachedNetworkImage &&
        widget.imageUrl == 'https://example.com/second.jpg'), findsNothing);
      expect(viewedGroups, ['u1']);
      expect(tester.takeException(), isNull);
    });
  });
}
