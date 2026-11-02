import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/models/element_payloads.dart';
import 'package:focusgram_story_kit/models/story_element.dart';
import 'package:focusgram_story_kit/models/story_transform.dart';
import 'package:focusgram_story_kit/timeline/timeline_controller.dart';
import 'package:focusgram_story_kit/timeline/video_transition_math.dart';

void main() {
  group('Phase 5 Timeline Engine & Clock Synchronization', () {
    test('StoryTimelineController play, pause, and advance', () {
      final controller = StoryTimelineController(
        initialDuration: const Duration(seconds: 10),
      );

      expect(controller.isPlaying, isFalse);
      expect(controller.currentPosition, Duration.zero);

      controller.play();
      expect(controller.isPlaying, isTrue);

      // Advance by 1 second
      controller.advance(const Duration(seconds: 1));
      expect(controller.currentPosition, const Duration(seconds: 1));

      // Advance to boundary
      controller.advance(const Duration(seconds: 10));
      // Since isLooping is true by default, it wraps back to effectiveStart
      expect(controller.currentPosition, Duration.zero);

      controller.pause();
      expect(controller.isPlaying, isFalse);
    });

    test('StoryTimelineController interactive scrubbing and normalization', () {
      final controller = StoryTimelineController(
        initialDuration: const Duration(seconds: 20),
      );

      controller.play();
      expect(controller.isPlaying, isTrue);

      controller.startScrubbing();
      expect(controller.isScrubbing, isTrue);
      expect(controller.isPlaying, isFalse); // Pauses while scrubbing

      controller.scrubToNormalized(0.5); // 50% of 20s = 10s
      expect(controller.currentPosition, const Duration(seconds: 10));

      controller.scrubToNormalized(0.75); // 75% of 20s = 15s
      expect(controller.currentPosition, const Duration(seconds: 15));

      controller.endScrubbing();
      expect(controller.isScrubbing, isFalse);
      expect(controller.currentPosition, const Duration(seconds: 15));
    });

    test('Video clip trimming and boundary clamping', () {
      final controller = StoryTimelineController(
        initialDuration: const Duration(seconds: 30),
        initialTrimRange: const VideoTrimRange(
          start: Duration(seconds: 5),
          end: Duration(seconds: 15),
        ),
      );

      expect(controller.currentPosition, const Duration(seconds: 5));
      expect(controller.state.effectiveDuration, const Duration(seconds: 10));

      // Seek before start clamps to start
      controller.seekTo(const Duration(seconds: 2));
      expect(controller.currentPosition, const Duration(seconds: 5));

      // Seek past end clamps to end
      controller.seekTo(const Duration(seconds: 25));
      expect(controller.currentPosition, const Duration(seconds: 15));
    });

    test('Clip splitting at intermediate timestamp', () {
      final controller = StoryTimelineController(
        initialDuration: const Duration(seconds: 20),
        initialTrimRange: const VideoTrimRange(
          start: Duration(seconds: 4),
          end: Duration(seconds: 16),
        ),
      );

      // Split at 10s
      final split = controller.splitAt(const Duration(seconds: 10));
      expect(split, isNotNull);
      expect(split!.first.start, const Duration(seconds: 4));
      expect(split.first.end, const Duration(seconds: 10));
      expect(split.second.start, const Duration(seconds: 10));
      expect(split.second.end, const Duration(seconds: 16));

      // Split outside boundaries returns null
      expect(controller.splitAt(const Duration(seconds: 2)), isNull);
      expect(controller.splitAt(const Duration(seconds: 20)), isNull);
    });

    test('Dynamic frame-rate-relative synchronization tolerance', () {
      expect(StoryTransitionMath.frameToleranceMs(60.0), closeTo(16.67, 0.01));
      expect(StoryTransitionMath.frameToleranceMs(30.0), closeTo(33.33, 0.01));
      expect(StoryTransitionMath.frameToleranceMs(24.0), closeTo(41.67, 0.01));

      final controller = StoryTimelineController(initialFrameRate: 60.0);
      expect(controller.syncToleranceMs, closeTo(16.67, 0.01));

      controller.setFrameRate(24.0);
      expect(controller.syncToleranceMs, closeTo(41.67, 0.01));
    });

    test('StoryTransitionMath time range gating', () {
      const element = StoryElement(
        id: 'el_timed',
        type: StoryElementType.text,
        transform: StoryTransform(x: 0, y: 0, width: 1, height: 1),
        visibleTimeRange: LayerTimeRange(
          start: Duration(seconds: 2),
          end: Duration(seconds: 6),
        ),
        payload: TextElementPayload(text: 'Timed Text'),
      );

      const canvasSize = Size(1080, 1920);

      // Before range: Hidden
      final before = StoryTransitionMath.computeElementVisualState(
        element: element,
        t: const Duration(seconds: 1),
        canvasSize: canvasSize,
      );
      expect(before.isVisible, isFalse);
      expect(before.opacity, 0.0);

      // Inside range: Visible
      final inside = StoryTransitionMath.computeElementVisualState(
        element: element,
        t: const Duration(seconds: 4),
        canvasSize: canvasSize,
      );
      expect(inside.isVisible, isTrue);
      expect(inside.opacity, 1.0);

      // After range: Hidden
      final after = StoryTransitionMath.computeElementVisualState(
        element: element,
        t: const Duration(seconds: 7),
        canvasSize: canvasSize,
      );
      expect(after.isVisible, isFalse);
      expect(after.opacity, 0.0);
    });

    test('StoryTransitionMath animation interpolation curves', () {
      const element = StoryElement(
        id: 'el_animated',
        type: StoryElementType.shape,
        transform: StoryTransform(x: 0, y: 0, width: 1, height: 1),
        visibleTimeRange: LayerTimeRange(
          start: Duration.zero,
          end: Duration(seconds: 10),
        ),
        animation: OverlayAnimationConfig(
          entranceType: OverlayAnimationType.fade,
          entranceDuration: Duration(seconds: 1),
          exitType: OverlayAnimationType.fade,
          exitDuration: Duration(seconds: 1),
          curveName: 'linear',
        ),
        payload: ShapeElementPayload(shapeType: ShapeType.rectangle),
      );

      const canvasSize = Size(1080, 1920);

      // Entrance mid-point (0.5s): opacity = 0.5
      final entranceMid = StoryTransitionMath.computeElementVisualState(
        element: element,
        t: const Duration(milliseconds: 500),
        canvasSize: canvasSize,
      );
      expect(entranceMid.isVisible, isTrue);
      expect(entranceMid.opacity, closeTo(0.5, 0.01));

      // Plateau state (5s): opacity = 1.0
      final plateau = StoryTransitionMath.computeElementVisualState(
        element: element,
        t: const Duration(seconds: 5),
        canvasSize: canvasSize,
      );
      expect(plateau.isVisible, isTrue);
      expect(plateau.opacity, closeTo(1.0, 0.01));

      // Exit mid-point (9.5s): opacity = 0.5
      final exitMid = StoryTransitionMath.computeElementVisualState(
        element: element,
        t: const Duration(milliseconds: 9500),
        canvasSize: canvasSize,
      );
      expect(exitMid.isVisible, isTrue);
      expect(exitMid.opacity, closeTo(0.5, 0.01));
    });
  });
}
