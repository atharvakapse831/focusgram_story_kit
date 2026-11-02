import 'package:flutter/material.dart';
import '../../models/story_element.dart';
import '../../timeline/timeline_controller.dart';
import '../../timeline/video_transition_math.dart';

/// Wraps canvas element content to apply time-ranged visibility gating, opacity fading,
/// and transition transformations driven by the active [StoryTimelineController].
class AnimatedElementBox extends StatelessWidget {
  const AnimatedElementBox({
    super.key,
    required this.element,
    required this.canvasSize,
    required this.child,
    this.timelineController,
  });

  final StoryElement element;
  final Size canvasSize;
  final Widget child;
  final StoryTimelineController? timelineController;

  @override
  Widget build(BuildContext context) {
    final tc = timelineController;
    if (tc == null) {
      return child;
    }

    return ListenableBuilder(
      listenable: tc,
      builder: (context, _) {
        final t = tc.currentPosition;
        final state = StoryTransitionMath.computeElementVisualState(
          element: element,
          t: t,
          canvasSize: canvasSize,
        );

        if (!state.isVisible) {
          return const SizedBox.shrink();
        }

        Widget output = child;
        if (state.transformMatrix != null) {
          output = Transform(
            transform: state.transformMatrix!,
            alignment: Alignment.center,
            child: output,
          );
        }

        if (state.opacity < 1.0) {
          output = Opacity(
            opacity: state.opacity.clamp(0.0, 1.0),
            child: output,
          );
        }

        return output;
      },
    );
  }
}
