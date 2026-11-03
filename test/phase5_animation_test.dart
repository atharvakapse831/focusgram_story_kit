import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/models/element_payloads.dart';
import 'package:focusgram_story_kit/models/story_element.dart';
import 'package:focusgram_story_kit/models/story_transform.dart';
import 'package:focusgram_story_kit/timeline/video_transition_math.dart';

void main() {
  group('Phase 5 Animation Math & Visual State Parity Tests', () {
    const canvasSize = Size(1080, 1920);

    const element = StoryElement(
      id: 'anim_test_el_1',
      type: StoryElementType.text,
      payload: TextElementPayload(text: 'FocusGram'),
      transform: StoryTransform(),
      opacity: 0.9,
      visibleTimeRange: LayerTimeRange(
        start: Duration(seconds: 2),
        end: Duration(seconds: 8),
      ),
      animation: OverlayAnimationConfig(
        entranceType: OverlayAnimationType.fade,
        entranceDuration: Duration(milliseconds: 1000),
        exitType: OverlayAnimationType.scale,
        exitDuration: Duration(milliseconds: 1000),
      ),
    );

    test(
      'Element is completely invisible before visibleTimeRange.startTime',
      () {
        final state = StoryTransitionMath.computeElementVisualState(
          element: element,
          t: const Duration(seconds: 1),
          canvasSize: canvasSize,
        );

        expect(state.isVisible, isFalse);
        expect(state.opacity, equals(0.0));
      },
    );

    test('Element is completely invisible after visibleTimeRange.endTime', () {
      final state = StoryTransitionMath.computeElementVisualState(
        element: element,
        t: const Duration(seconds: 9),
        canvasSize: canvasSize,
      );

      expect(state.isVisible, isFalse);
      expect(state.opacity, equals(0.0));
    });

    test(
      'Entrance fade smoothly interpolates opacity from 0.0 to baseOpacity',
      () {
        // At t=2.0s (start): opacity ~ 0.0
        final startState = StoryTransitionMath.computeElementVisualState(
          element: element,
          t: const Duration(seconds: 2),
          canvasSize: canvasSize,
        );
        expect(startState.isVisible, isTrue);
        expect(startState.opacity, closeTo(0.0, 0.01));

        // At t=2.5s (midway through 1s entrance): opacity ~ 0.9 * 0.5 = 0.45
        final midState = StoryTransitionMath.computeElementVisualState(
          element: element,
          t: const Duration(milliseconds: 2500),
          canvasSize: canvasSize,
        );
        expect(midState.isVisible, isTrue);
        expect(midState.opacity, closeTo(0.45, 0.05));

        // At t=3.0s (end of entrance): opacity ~ baseOpacity (0.9)
        final endState = StoryTransitionMath.computeElementVisualState(
          element: element,
          t: const Duration(seconds: 3),
          canvasSize: canvasSize,
        );
        expect(endState.isVisible, isTrue);
        expect(endState.opacity, closeTo(0.9, 0.01));
      },
    );

    test('Exit scale reduces scale and opacity toward zero', () {
      // Exit range is [7.0s, 8.0s]
      // At t=7.5s (mid exit): opacity ~ 0.9 * 0.5 = 0.45
      final midExitState = StoryTransitionMath.computeElementVisualState(
        element: element,
        t: const Duration(milliseconds: 7500),
        canvasSize: canvasSize,
      );
      expect(midExitState.isVisible, isTrue);
      expect(midExitState.opacity, closeTo(0.45, 0.05));
      expect(midExitState.transformMatrix, isNotNull);
    });

    test('Slide transitions apply expected translation offset matrices', () {
      final slideEl = element.copyWith(
        animation: const OverlayAnimationConfig(
          entranceType: OverlayAnimationType.slideUp,
          entranceDuration: Duration(milliseconds: 1000),
        ),
      );

      final state = StoryTransitionMath.computeElementVisualState(
        element: slideEl,
        t: const Duration(milliseconds: 2500), // 50% through entrance
        canvasSize: canvasSize,
      );

      expect(state.isVisible, isTrue);
      expect(state.transformMatrix, isNotNull);

      // Verify non-identity translation vector
      final translation = state.transformMatrix!.getTranslation();
      expect(translation.y, greaterThan(0.0)); // offset upward
    });

    test(
      'Bounce entrance interpolates scale curve without crashing or NaN',
      () {
        final bounceEl = element.copyWith(
          animation: const OverlayAnimationConfig(
            entranceType: OverlayAnimationType.bounce,
            entranceDuration: Duration(milliseconds: 800),
          ),
        );

        for (var ms = 2000; ms <= 2800; ms += 100) {
          final state = StoryTransitionMath.computeElementVisualState(
            element: bounceEl,
            t: Duration(milliseconds: ms),
            canvasSize: canvasSize,
          );
          expect(state.isVisible, isTrue);
          expect(state.opacity, greaterThanOrEqualTo(0.0));
          expect(state.opacity.isNaN, isFalse);
        }
      },
    );
  });
}
