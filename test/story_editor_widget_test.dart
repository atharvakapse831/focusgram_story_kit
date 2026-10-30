import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/focusgram_story_kit.dart';

void main() {
  group('StoryKitEditor Widget Interactions', () {
    testWidgets('Renders editor chrome, canvas, top bar, and page strip', (
      tester,
    ) async {
      final controller = EditorController();

      await tester.pumpWidget(
        MaterialApp(home: StoryKitEditor(controller: controller)),
      );
      await tester.pumpAndSettle();

      // Top bar icons
      expect(find.byTooltip('Close Editor'), findsOneWidget);
      expect(find.byTooltip('Undo'), findsOneWidget);
      expect(find.byTooltip('Redo'), findsOneWidget);
      expect(find.byTooltip('Add Text'), findsOneWidget);
      expect(find.byTooltip('Add Sticker'), findsOneWidget);
      expect(find.byTooltip('Change Background'), findsOneWidget);
      expect(find.byTooltip('Save Draft'), findsOneWidget);
      expect(find.text('Export'), findsOneWidget);

      // Canvas
      expect(find.byType(StoryEditorCanvas), findsOneWidget);

      // Page strip
      expect(find.byType(StoryPageStrip), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // Page 1 badge
    });

    testWidgets('Add sticker appends element to active page', (tester) async {
      final controller = EditorController();

      await tester.pumpWidget(
        MaterialApp(home: StoryKitEditor(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(controller.activePage.elements.isEmpty, isTrue);

      // Tap Add Sticker
      await tester.tap(find.byTooltip('Add Sticker'));
      await tester.pumpAndSettle();

      expect(controller.activePage.elements.length, equals(1));
      expect(
        controller.activePage.elements.first.type,
        equals(StoryElementType.sticker),
      );
      expect(
        controller.selectedElement?.id,
        equals(controller.activePage.elements.first.id),
      );
    });

    testWidgets(
      'AC-2: Page strip operations: add, duplicate, and delete pages',
      (tester) async {
        final controller = EditorController();

        await tester.pumpWidget(
          MaterialApp(home: StoryKitEditor(controller: controller)),
        );
        await tester.pumpAndSettle();

        expect(controller.project.pages.length, equals(1));

        // 1. Add page
        await tester.tap(find.byTooltip('Add Page'));
        await tester.pumpAndSettle();

        expect(controller.project.pages.length, equals(2));
        expect(
          controller.activePage.id,
          equals(controller.project.pages[1].id),
        );

        // 2. Duplicate page
        await tester.tap(find.byTooltip('Duplicate Active Page'));
        await tester.pumpAndSettle();

        expect(controller.project.pages.length, equals(3));

        // 3. Delete active page
        await tester.tap(find.byTooltip('Delete Active Page'));
        await tester.pumpAndSettle();

        expect(controller.project.pages.length, equals(2));
      },
    );

    testWidgets('Undo and redo buttons reflect controller history', (
      tester,
    ) async {
      final controller = EditorController();

      await tester.pumpWidget(
        MaterialApp(home: StoryKitEditor(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(controller.canUndo, isFalse);

      // Add a sticker
      await tester.tap(find.byTooltip('Add Sticker'));
      await tester.pumpAndSettle();

      expect(controller.canUndo, isTrue);

      // Tap Undo
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();

      expect(controller.activePage.elements.isEmpty, isTrue);
      expect(controller.canRedo, isTrue);

      // Tap Redo
      await tester.tap(find.byTooltip('Redo'));
      await tester.pumpAndSettle();

      expect(controller.activePage.elements.length, equals(1));
    });

    testWidgets(
      'Save draft invokes draft repository and onSaveDraft callback',
      (tester) async {
        final draftRepo = InMemoryStoryDraftRepository();
        StoryProject? savedProject;

        await tester.pumpWidget(
          MaterialApp(
            home: StoryKitEditor(
              draftRepository: draftRepo,
              onSaveDraft: (project) => savedProject = project,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Save Draft
        await tester.tap(find.byTooltip('Save Draft'));
        await tester.pumpAndSettle();

        expect(savedProject, isNotNull);
        final drafts = await draftRepo.listDrafts();
        expect(drafts.length, equals(1));
        expect(drafts.first.id, equals(savedProject!.id));
        expect(find.text('Draft saved successfully'), findsOneWidget);
      },
    );

    testWidgets(
      'Export button triggers onExport callback with still image results',
      (tester) async {
        List<StillImageExportResult>? exportResults;

        await tester.pumpWidget(
          MaterialApp(
            home: StoryKitEditor(
              onExport: (results) => exportResults = results,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Export button
        await tester.tap(find.text('Export'));
        await tester.pump();

        // Allow engine off-screen rasterization to complete
        await tester.runAsync(() async {
          for (var i = 0; i < 30 && exportResults == null; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
        });
        await tester.pump();

        expect(exportResults, isNotNull);
        expect(exportResults!.length, equals(1));
        expect(exportResults!.first.bytes.isNotEmpty, isTrue);
      },
    );
  });
}
