import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/assets/asset_provider.dart';
import 'package:focusgram_story_kit/editor/editor_controller.dart';
import 'package:focusgram_story_kit/editor/panels/drawing_toolbar.dart';
import 'package:focusgram_story_kit/editor/panels/layer_manager_sheet.dart';
import 'package:focusgram_story_kit/editor/panels/rich_text_editor_sheet.dart';
import 'package:focusgram_story_kit/editor/panels/shape_picker_sheet.dart';
import 'package:focusgram_story_kit/editor/panels/sticker_picker_sheet.dart';
import 'package:focusgram_story_kit/editor/panels/template_picker_sheet.dart';
import 'package:focusgram_story_kit/editor/story_kit_editor.dart';
import 'package:focusgram_story_kit/export/export_result.dart';
import 'package:focusgram_story_kit/localization/story_kit_strings.dart';
import 'package:focusgram_story_kit/models/element_payloads.dart';
import 'package:focusgram_story_kit/models/gradient_background.dart';
import 'package:focusgram_story_kit/models/story_element.dart';
import 'package:focusgram_story_kit/models/story_project.dart';
import 'package:focusgram_story_kit/models/story_transform.dart';
import 'package:focusgram_story_kit/theme/story_kit_theme.dart';

void main() {
  group('Phase 4 Story Kit Editor Widget Tests', () {
    testWidgets(
      'renders all Phase 4 top bar action buttons with custom strings',
      (tester) async {
        final controller = EditorController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoryKitEditor(
                controller: controller,
                config: const StoryKitEditorConfig(
                  strings: StoryKitStrings(),
                  theme: StoryKitEditorTheme.dark,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify action buttons exist in top bar
        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.byIcon(Icons.title), findsOneWidget); // Text
        expect(find.byIcon(Icons.draw), findsOneWidget); // Drawing
        expect(find.byIcon(Icons.category_outlined), findsOneWidget); // Shape
        expect(
          find.byIcon(Icons.sentiment_satisfied_alt),
          findsOneWidget,
        ); // Sticker
        expect(
          find.byIcon(Icons.palette_outlined),
          findsOneWidget,
        ); // Background
        expect(
          find.byIcon(Icons.dashboard_customize_outlined),
          findsOneWidget,
        ); // Template
        expect(find.byIcon(Icons.tune), findsOneWidget); // Adjust
        expect(find.byIcon(Icons.layers_outlined), findsOneWidget); // Layers
        expect(find.text('Export'), findsOneWidget);
      },
    );

    testWidgets(
      'freehand drawing mode switches top bar to DrawingToolbar and exits on Done',
      (tester) async {
        final controller = EditorController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: StoryKitEditor(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Drawing button
        await tester.tap(find.byIcon(Icons.draw));
        await tester.pumpAndSettle();

        // Expect DrawingToolbar to be visible
        expect(find.byType(DrawingToolbar), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget); // Pen
        expect(find.byIcon(Icons.brush), findsOneWidget); // Marker
        expect(find.byIcon(Icons.auto_awesome), findsOneWidget); // Neon
        expect(find.byIcon(Icons.cleaning_services), findsOneWidget); // Eraser

        // Tap Neon brush
        await tester.tap(find.byIcon(Icons.auto_awesome));
        await tester.pumpAndSettle();
        expect(controller.state.activeBrushType, DrawingBrushType.neon);

        // Tap Done button
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // DrawingToolbar is dismissed, back to standard editor
        expect(find.byType(DrawingToolbar), findsNothing);
        expect(controller.state.isDrawingMode, isFalse);
      },
    );

    testWidgets('adding text via RichTextEditorSheet adds a text element', (
      tester,
    ) async {
      final controller = EditorController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StoryKitEditor(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Text icon
      await tester.tap(find.byIcon(Icons.title));
      await tester.pumpAndSettle();

      // RichTextEditorSheet opens
      expect(find.byType(RichTextEditorSheet), findsOneWidget);

      // Enter text
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Hello Phase 4 Story');
      await tester.pumpAndSettle();

      // Tap Add
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify element was added
      expect(controller.activePage.elements.length, 1);
      final element = controller.activePage.elements.first;
      expect(element.type, StoryElementType.text);
      expect(
        (element.payload as TextElementPayload).text,
        'Hello Phase 4 Story',
      );
    });

    testWidgets('adding shape via ShapePickerSheet adds a shape element', (
      tester,
    ) async {
      final controller = EditorController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StoryKitEditor(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Shape icon
      await tester.tap(find.byIcon(Icons.category_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(ShapePickerSheet), findsOneWidget);

      // Select Circle shape
      await tester.tap(find.text('Circle'));
      await tester.pumpAndSettle();

      // Tap Add Shape
      await tester.tap(find.text('Add Shape'));
      await tester.pumpAndSettle();

      // Verify shape element was added
      expect(controller.activePage.elements.length, 1);
      final element = controller.activePage.elements.first;
      expect(element.type, StoryElementType.shape);
      expect(
        (element.payload as ShapeElementPayload).shapeType,
        ShapeType.circle,
      );
    });

    testWidgets(
      'adding sticker via StickerPickerSheet adds a sticker element',
      (tester) async {
        final controller = EditorController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoryKitEditor(
                controller: controller,
                config: const StoryKitEditorConfig(
                  assetProvider: DefaultStoryAssetProvider(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Sticker icon
        await tester.tap(find.byIcon(Icons.sentiment_satisfied_alt));
        await tester.pumpAndSettle();

        expect(find.byType(StickerPickerSheet), findsOneWidget);

        // Tap first available sticker emoji (e.g. 🔥)
        final stickerItem = find.text('🔥');
        expect(stickerItem, findsWidgets);
        await tester.tap(stickerItem.first);
        await tester.pumpAndSettle();

        // Verify sticker element was added
        expect(controller.activePage.elements.length, 1);
        final element = controller.activePage.elements.first;
        expect(element.type, StoryElementType.sticker);
        expect((element.payload as StickerElementPayload).label, '🔥');
      },
    );

    testWidgets(
      'selecting background gradient from sheet updates page gradient',
      (tester) async {
        final controller = EditorController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: StoryKitEditor(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Background icon
        await tester.tap(find.byIcon(Icons.palette_outlined));
        await tester.pumpAndSettle();

        // Tap Sunset preset
        final sunsetPreset = find.text('Sunset');
        expect(sunsetPreset, findsOneWidget);
        await tester.tap(sunsetPreset);
        await tester.pumpAndSettle();

        // Verify page background gradient updated
        expect(
          controller.activePage.backgroundGradient,
          StoryGradientBackground.sunset,
        );
      },
    );

    testWidgets(
      'applying a template via TemplatePickerSheet updates page layout',
      (tester) async {
        final controller = EditorController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: StoryKitEditor(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Templates icon
        await tester.tap(find.byIcon(Icons.dashboard_customize_outlined));
        await tester.pumpAndSettle();

        expect(find.byType(TemplatePickerSheet), findsOneWidget);

        // Tap Quote of the Day template
        await tester.tap(find.text('Quote of the Day'));
        await tester.pumpAndSettle();

        // Verify template elements applied
        expect(controller.activePage.elements.length, greaterThanOrEqualTo(2));
        expect(controller.activePage.backgroundGradient, isNotNull);
      },
    );

    testWidgets(
      'layer manager sheet allows toggling element lock and visibility',
      (tester) async {
        final controller = EditorController();
        const testElement = StoryElement(
          id: 'test_el_1',
          type: StoryElementType.text,
          transform: StoryTransform(x: 0.5, y: 0.5, width: 0.5, height: 0.2),
          payload: TextElementPayload(text: 'Layer Test'),
        );
        controller.addElement(testElement);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: StoryKitEditor(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Layers icon
        await tester.tap(find.byIcon(Icons.layers_outlined));
        await tester.pumpAndSettle();

        expect(find.byType(LayerManagerSheet), findsOneWidget);

        // Tap lock icon
        final lockIcon = find.byIcon(Icons.lock_open);
        expect(lockIcon, findsOneWidget);
        await tester.tap(lockIcon);
        await tester.pumpAndSettle();

        // Element is now locked
        expect(controller.activePage.getElement('test_el_1')!.isLocked, isTrue);

        // Tap visibility icon
        final visibleIcon = find.byIcon(Icons.visibility);
        expect(visibleIcon, findsOneWidget);
        await tester.tap(visibleIcon);
        await tester.pumpAndSettle();

        // Element is now hidden
        expect(
          controller.activePage.getElement('test_el_1')!.isVisible,
          isFalse,
        );
      },
    );

    testWidgets('still image export triggers onExport callback', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final controller = EditorController();
        List<StillImageExportResult>? exportResults;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoryKitEditor(
                controller: controller,
                onExport: (results) {
                  exportResults = results;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Export button
        await tester.tap(find.text('Export'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(exportResults, isNotNull);
        expect(exportResults!.length, 1);
        expect(exportResults!.first.bytes.isNotEmpty, isTrue);
      });
    });

    testWidgets('saving draft triggers onSaveDraft callback', (tester) async {
      final controller = EditorController();
      StoryProject? savedProject;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryKitEditor(
              controller: controller,
              onSaveDraft: (project) {
                savedProject = project;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save Draft button
      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();

      expect(savedProject, isNotNull);
      expect(savedProject!.id, controller.project.id);
    });
  });
}
