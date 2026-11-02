import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/focusgram_story_kit.dart';

void main() {
  group('CommandHistory & Undo/Redo Engine', () {
    test('Executes, undoes, and redoes commands with revision tracking', () {
      final history = CommandHistory(maxDepth: 10);
      var project = StoryProject.create(id: 'proj_1');
      final pageId = project.pages.first.id;

      expect(project.revision, equals(0));
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);

      // 1. Add an element
      const element = StoryElement(
        id: 'el_1',
        type: StoryElementType.text,
        transform: StoryTransform(x: 0.5, y: 0.5),
        payload: TextElementPayload(text: 'Hello'),
      );

      project = history.execute(
        AddElementCommand(pageId: pageId, element: element),
        project,
      );

      expect(project.pages.first.elements.length, equals(1));
      expect(project.revision, equals(1));
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);

      // 2. Undo
      project = history.undo(project);
      expect(project.pages.first.elements.isEmpty, isTrue);
      expect(project.revision, equals(2));
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isTrue);

      // 3. Redo
      project = history.redo(project);
      expect(project.pages.first.elements.length, equals(1));
      expect(project.revision, equals(3));
      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
    });

    test(
      'AC-3: Transaction coalescing merges continuous gesture updates into one undo step',
      () {
        final history = CommandHistory();
        var project = StoryProject.create(id: 'proj_coalesce');
        final pageId = project.pages.first.id;

        const initialTransform = StoryTransform(x: 0.5, y: 0.5);
        const element = StoryElement(
          id: 'el_drag',
          type: StoryElementType.sticker,
          transform: initialTransform,
          payload: StickerElementPayload(stickerId: 's1', assetUri: ''),
        );

        project = history.execute(
          AddElementCommand(pageId: pageId, element: element),
          project,
        );

        // Simulate 5 high-frequency continuous gesture frames during drag
        for (var i = 1; i <= 5; i++) {
          project = history.execute(
            TransformElementCommand(
              pageId: pageId,
              elementId: 'el_drag',
              previousTransform: initialTransform,
              newTransform: StoryTransform(x: 0.5 + (i * 0.05), y: 0.5),
              isCoalescing: true,
            ),
            project,
          );
        }

        // Check that despite 5 updates, the undo stack has only 2 items (1 AddElement + 1 coalesced Transform)
        expect(history.undoCount, equals(2));
        expect(
          project.pages.first.elements.first.transform.x,
          closeTo(0.75, 0.001),
        );

        // Single undo reverts all the way back to initial pre-gesture position (0.5)!
        project = history.undo(project);
        expect(
          project.pages.first.elements.first.transform.x,
          closeTo(0.5, 0.001),
        );

        // Single redo restores to the final post-gesture position (0.75)!
        project = history.redo(project);
        expect(
          project.pages.first.elements.first.transform.x,
          closeTo(0.75, 0.001),
        );
      },
    );

    test('Respects maxDepth boundary limit', () {
      final history = CommandHistory(maxDepth: 3);
      var project = StoryProject.create(id: 'proj_limit');
      final pageId = project.pages.first.id;

      for (var i = 1; i <= 10; i++) {
        project = history.execute(
          AddElementCommand(
            pageId: pageId,
            element: StoryElement(
              id: 'el_$i',
              type: StoryElementType.text,
              transform: const StoryTransform(),
              payload: TextElementPayload(text: 'Item $i'),
            ),
          ),
          project,
        );
      }

      expect(history.undoCount, equals(3));
    });
  });
}
