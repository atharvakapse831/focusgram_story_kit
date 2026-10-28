import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/models/story_shared_content.dart';
import 'package:focusgram_story_kit/viewer/story_shared_content_card.dart';

void main() {
  group('StorySharedContentCard', () {
    testWidgets('renders title, description, username, and badge', (
      tester,
    ) async {
      const content = StorySharedContent(
        id: 'c1',
        type: StoryKitContentType.article,
        title: 'Building Resilient Microservices',
        description: 'Key patterns for enterprise reliability.',
        authorUsername: 'dev_lead',
        badgeText: 'ARTICLE',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StorySharedContentCard(content: content)),
        ),
      );

      expect(find.text('@dev_lead'), findsOneWidget);
      expect(find.text('Building Resilient Microservices'), findsOneWidget);
      expect(
        find.text('Key patterns for enterprise reliability.'),
        findsOneWidget,
      );
      expect(find.text('ARTICLE'), findsOneWidget);
      expect(find.text('Tap to open'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets('invokes onTap callback when card is tapped', (tester) async {
      var tapped = false;
      const content = StorySharedContent(
        id: 'c2',
        type: StoryKitContentType.shortVideo,
        title: '30s Architecture Tip',
        authorUsername: 'quick_tips',
        badgeText: 'SHORT',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StorySharedContentCard(
              content: content,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StorySharedContentCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets(
      'renders fallback elements when avatar and thumbnail are omitted',
      (tester) async {
        const content = StorySharedContent(
          id: 'c3',
          type: StoryKitContentType.note,
          title: 'Binary Tree Traversal',
          authorName: 'Anonymous Coder',
          badgeText: 'CODE',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: StorySharedContentCard(content: content)),
          ),
        );

        expect(find.text('Anonymous Coder'), findsOneWidget);
        expect(find.text('Binary Tree Traversal'), findsOneWidget);
        expect(find.text('CODE'), findsOneWidget);
        // Fallback avatar icon exists
        expect(find.byIcon(Icons.person), findsOneWidget);
      },
    );

    testWidgets(
      'renders distinct badges for all 6 content types plus unknown',
      (tester) async {
        final types = [
          (StoryKitContentType.imagePost, 'POST'),
          (StoryKitContentType.videoPost, 'FEED_VIDEO'),
          (StoryKitContentType.shortVideo, 'SHORT'),
          (StoryKitContentType.longVideo, 'VIDEO'),
          (StoryKitContentType.article, 'ARTICLE'),
          (StoryKitContentType.note, 'NOTE'),
          (StoryKitContentType.unknown, 'UNKNOWN'),
        ];

        for (final (type, badge) in types) {
          final content = StorySharedContent(
            id: 'item_${type.name}',
            type: type,
            title: 'Test Title for ${type.name}',
            badgeText: badge,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: StorySharedContentCard(content: content)),
            ),
          );

          expect(find.text(badge), findsOneWidget);
        }
      },
    );
  });
}
