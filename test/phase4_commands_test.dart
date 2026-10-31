import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/editor/editor_controller.dart';
import 'package:focusgram_story_kit/models/element_payloads.dart';
import 'package:focusgram_story_kit/models/gradient_background.dart';
import 'package:focusgram_story_kit/models/story_element.dart';
import 'package:focusgram_story_kit/models/story_media_asset.dart';
import 'package:focusgram_story_kit/models/story_template.dart';
import 'package:focusgram_story_kit/models/story_transform.dart';

void main() {
  group('Phase 4 Editor Commands & Controller Logic', () {
    test('SetPageGradientCommand execute and undo', () {
      final controller = EditorController();
      expect(controller.activePage.backgroundGradient, isNull);

      controller.setPageGradient(StoryGradientBackground.sunset);
      expect(
        controller.activePage.backgroundGradient,
        equals(StoryGradientBackground.sunset),
      );
      expect(controller.canUndo, isTrue);

      controller.undo();
      expect(controller.activePage.backgroundGradient, isNull);

      controller.redo();
      expect(
        controller.activePage.backgroundGradient,
        equals(StoryGradientBackground.sunset),
      );
    });

    test('ToggleElementLockCommand and ToggleElementVisibilityCommand', () {
      final controller = EditorController();
      const el = StoryElement(
        id: 'el_lock_test',
        type: StoryElementType.shape,
        transform: StoryTransform(),
        payload: ShapeElementPayload(shapeType: ShapeType.circle),
        isLocked: false,
        isVisible: true,
      );
      controller.addElement(el);

      expect(
        controller.activePage.getElement('el_lock_test')!.isLocked,
        isFalse,
      );
      controller.toggleElementLock('el_lock_test');
      expect(
        controller.activePage.getElement('el_lock_test')!.isLocked,
        isTrue,
      );

      controller.undo();
      expect(
        controller.activePage.getElement('el_lock_test')!.isLocked,
        isFalse,
      );

      expect(
        controller.activePage.getElement('el_lock_test')!.isVisible,
        isTrue,
      );
      controller.toggleElementVisibility('el_lock_test');
      expect(
        controller.activePage.getElement('el_lock_test')!.isVisible,
        isFalse,
      );

      controller.undo();
      expect(
        controller.activePage.getElement('el_lock_test')!.isVisible,
        isTrue,
      );
    });

    test('AddDrawingStrokeCommand and ClearDrawingCommand with undo/redo', () {
      final controller = EditorController();
      const stroke1 = DrawingStroke(
        points: [DrawingPoint(x: 0.1, y: 0.1), DrawingPoint(x: 0.2, y: 0.2)],
        color: Colors.white,
      );
      const stroke2 = DrawingStroke(
        points: [DrawingPoint(x: 0.3, y: 0.3), DrawingPoint(x: 0.4, y: 0.4)],
        color: Colors.cyan,
      );

      controller.addDrawingStroke(stroke1);
      final drawingElId = 'drawing_${controller.activePage.id}';
      var drawingEl = controller.activePage.getElement(drawingElId);
      expect(drawingEl, isNotNull);
      var payload = drawingEl!.payload as DrawingElementPayload;
      expect(payload.strokes.length, equals(1));

      controller.addDrawingStroke(stroke2);
      drawingEl = controller.activePage.getElement(drawingElId);
      payload = drawingEl!.payload as DrawingElementPayload;
      expect(payload.strokes.length, equals(2));

      // Undo stroke 2
      controller.undo();
      drawingEl = controller.activePage.getElement(drawingElId);
      payload = drawingEl!.payload as DrawingElementPayload;
      expect(payload.strokes.length, equals(1));

      // Clear drawing
      controller.clearDrawing(drawingElId);
      expect(controller.activePage.getElement(drawingElId), isNull);

      // Undo clear
      controller.undo();
      drawingEl = controller.activePage.getElement(drawingElId);
      expect(drawingEl, isNotNull);
      payload = drawingEl!.payload as DrawingElementPayload;
      expect(payload.strokes.length, equals(1));
    });

    test('UpdateImageAdjustmentsCommand execute and undo', () {
      final controller = EditorController();
      const imgEl = StoryElement(
        id: 'el_adjust_test',
        type: StoryElementType.image,
        transform: StoryTransform(),
        payload: ImageElementPayload(
          asset: StoryMediaAsset(
            id: 'a1',
            sourceType: StoryMediaSourceType.file,
            uri: 'file:///photo.jpg',
          ),
          adjustments: ImageAdjustments.identity,
        ),
      );
      controller.addElement(imgEl);

      const newAdjustments = ImageAdjustments(
        brightness: 0.3,
        filterPreset: ImageFilterPreset.vintage,
      );
      controller.updateImageAdjustments('el_adjust_test', newAdjustments);

      var el = controller.activePage.getElement('el_adjust_test')!;
      var payload = el.payload as ImageElementPayload;
      expect(payload.adjustments, equals(newAdjustments));

      controller.undo();
      el = controller.activePage.getElement('el_adjust_test')!;
      payload = el.payload as ImageElementPayload;
      expect(payload.adjustments, equals(ImageAdjustments.identity));
    });

    test('ApplyTemplateCommand replaces layout with undo recovery', () {
      final controller = EditorController();
      final originalPageId = controller.activePage.id;
      expect(controller.activePage.elements.isEmpty, isTrue);

      controller.applyTemplate(StoryTemplate.quoteTemplate);
      expect(controller.activePage.id, equals(originalPageId));
      expect(controller.activePage.elements.isNotEmpty, isTrue);
      expect(
        controller.activePage.backgroundGradient,
        equals(StoryGradientBackground.midnight),
      );

      controller.undo();
      expect(controller.activePage.elements.isEmpty, isTrue);
      expect(controller.activePage.backgroundGradient, isNull);
    });

    test('Snap guidelines and brush settings update transient state', () {
      final controller = EditorController();

      controller.setSnapGuidelines(snapX: 0.5, snapY: 0.5);
      expect(controller.state.snapX, equals(0.5));
      expect(controller.state.snapY, equals(0.5));

      controller.setSnapGuidelines(snapX: null, snapY: null);
      expect(controller.state.snapX, isNull);
      expect(controller.state.snapY, isNull);

      controller.setBrushSettings(
        brushType: DrawingBrushType.neon,
        brushColor: Colors.purpleAccent,
        brushWidth: 0.02,
      );
      expect(controller.state.activeBrushType, equals(DrawingBrushType.neon));
      expect(controller.state.activeBrushColor, equals(Colors.purpleAccent));
      expect(controller.state.activeBrushWidth, equals(0.02));
    });
  });
}
