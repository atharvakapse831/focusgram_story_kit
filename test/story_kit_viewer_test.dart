import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:focusgram_story_kit/models/story_group_model.dart';
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
  });
}
