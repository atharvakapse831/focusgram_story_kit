import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/focusgram_story_kit.dart';

void main() {
  group('StoryDraftRepository & Persistence', () {
    test(
      'AC-4: Save and restore preserves editable document structure',
      () async {
        final repo = InMemoryStoryDraftRepository();

        const project = StoryProject(
          id: 'draft_101',
          pages: [
            StoryPage(
              id: 'page_101_1',
              backgroundColor: Colors.indigo,
              elements: [
                StoryElement(
                  id: 'text_101',
                  type: StoryElementType.text,
                  transform: StoryTransform(x: 0.4, y: 0.6),
                  payload: TextElementPayload(text: 'Draft Content'),
                ),
              ],
            ),
          ],
        );

        // Save draft
        await repo.saveDraft(project);

        // List drafts
        final list = await repo.listDrafts();
        expect(list.length, equals(1));
        expect(list.first.id, equals('draft_101'));
        expect(list.first.pageCount, equals(1));

        // Restore draft
        final loaded = await repo.loadDraft('draft_101');
        expect(loaded, isNotNull);
        expect(loaded!.id, equals('draft_101'));
        expect(loaded.pages.length, equals(1));
        expect(
          loaded.pages.first.backgroundColor.toARGB32(),
          equals(Colors.indigo.toARGB32()),
        );
        expect(loaded.pages.first.elements.first.id, equals('text_101'));
        final payload =
            loaded.pages.first.elements.first.payload as TextElementPayload;
        expect(payload.text, equals('Draft Content'));

        // Delete draft
        await repo.deleteDraft('draft_101');
        final listAfterDelete = await repo.listDrafts();
        expect(listAfterDelete.isEmpty, isTrue);

        final loadedAfterDelete = await repo.loadDraft('draft_101');
        expect(loadedAfterDelete, isNull);
      },
    );
  });
}
