import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/overlay_animation.dart';
import '../models/story_element.dart';

/// Computed visual state of a canvas element at an exact timestamp $t$.
@immutable
class ElementVisualState {
  const ElementVisualState({
    required this.isVisible,
    required this.opacity,
    this.transformMatrix,
  });

  final bool isVisible;
  final double opacity;
  final Matrix4? transformMatrix;

  static const hidden = ElementVisualState(
    isVisible: false,
    opacity: 0.0,
    transformMatrix: null,
  );

  static ElementVisualState identity({double opacity = 1.0}) {
    return ElementVisualState(
      isVisible: true,
      opacity: opacity.clamp(0.0, 1.0),
      transformMatrix: Matrix4.identity(),
    );
  }
}

/// Pure deterministic mathematical utilities for timeline animations and transitions.
class StoryTransitionMath {
  /// Evaluates normalized transition progress [0.0, 1.0] at timestamp [t].
  static double evaluateProgress({
    required Duration t,
    required Duration start,
    required Duration duration,
    Curve curve = Curves.easeInOut,
  }) {
    if (duration == Duration.zero) return 1.0;
    if (t < start) return 0.0;
    if (t >= start + duration) return 1.0;

    final elapsedUs = (t - start).inMicroseconds;
    final totalUs = duration.inMicroseconds;
    final linear = (elapsedUs / totalUs).clamp(0.0, 1.0);
    return curve.transform(linear);
  }

  /// Calculates the dynamic frame-rate-relative synchronization tolerance in milliseconds:
  /// $$\text{Tolerance}(\text{fps}) = \pm 1 \text{ frame duration} = \pm \left(\frac{1000}{\text{fps}}\right) \text{ms}$$
  static double frameToleranceMs(double fps) {
    final effectiveFps = fps <= 0 ? 30.0 : fps;
    return 1000.0 / effectiveFps;
  }

  /// Computes the exact visual state (matrix transform and opacity) for [element] at timestamp [t].
  static ElementVisualState computeElementVisualState({
    required StoryElement element,
    required Duration t,
    required Size canvasSize,
  }) {
    // 1. Time range gating: if element is outside its visibleTimeRange, it is completely hidden.
    final range = element.visibleTimeRange;
    if (range != null && !range.isVisibleAt(t)) {
      return ElementVisualState.hidden;
    }

    final anim = element.animation;
    if (anim == null) {
      return ElementVisualState.identity(opacity: element.opacity);
    }

    final rangeStart = range?.start ?? Duration.zero;
    final rangeEnd = range?.end ?? const Duration(seconds: 15);

    // 2. Entrance transition
    final entranceEnd = rangeStart + anim.entranceDuration;
    if (t < entranceEnd && anim.entranceType != OverlayAnimationType.none) {
      final p = evaluateProgress(
        t: t,
        start: rangeStart,
        duration: anim.entranceDuration,
        curve: anim.curve,
      );
      return _interpolateEntrance(
        element: element,
        progress: p,
        type: anim.entranceType,
        canvasSize: canvasSize,
      );
    }

    // 3. Exit transition
    final exitStart = rangeEnd - anim.exitDuration;
    if (t >= exitStart && anim.exitType != OverlayAnimationType.none) {
      final p = evaluateProgress(
        t: t,
        start: exitStart,
        duration: anim.exitDuration,
        curve: anim.curve,
      );
      return _interpolateExit(
        element: element,
        progress: p,
        type: anim.exitType,
        canvasSize: canvasSize,
      );
    }

    // 4. Stable sustained state
    return ElementVisualState.identity(opacity: element.opacity);
  }

  static ElementVisualState _interpolateEntrance({
    required StoryElement element,
    required double progress,
    required OverlayAnimationType type,
    required Size canvasSize,
  }) {
    final baseOpacity = element.opacity;
    switch (type) {
      case OverlayAnimationType.fade:
        return ElementVisualState(
          isVisible: true,
          opacity: baseOpacity * progress,
          transformMatrix: Matrix4.identity(),
        );

      case OverlayAnimationType.scale:
        final scale = progress.clamp(0.001, 1.0);
        return ElementVisualState(
          isVisible: true,
          opacity: baseOpacity * progress,
          transformMatrix: Matrix4.diagonal3Values(scale, scale, 1.0),
        );

      case OverlayAnimationType.slideUp:
        final dy = (1.0 - progress) * (canvasSize.height * 0.25);
        return ElementVisualState(
          isVisible: true,
          opacity: baseOpacity * progress,
          transformMatrix: Matrix4.translationValues(0.0, dy, 0.0),
        );

      case OverlayAnimationType.slideDown:
        final dy = -(1.0 - progress) * (canvasSize.height * 0.25);
        return ElementVisualState(
          isVisible: true,
          opacity: baseOpacity * progress,
          transformMatrix: Matrix4.translationValues(0.0, dy, 0.0),
        );

      case OverlayAnimationType.slideLeft:
        final dx = (1.0 - progress) * (canvasSize.width * 0.25);
        return ElementVisualState(
          isVisible: true,
          opacity: baseOpacity * progress,
          transformMatrix: Matrix4.translationValues(dx, 0.0, 0.0),
        );

      case OverlayAnimationType.slideRight:
        final dx = -(1.0 - progress) * (canvasSize.width * 0.25);
        return ElementVisualState(
          isVisible: true,
          opacity: baseOpacity * progress,
          transformMatrix: Matrix4.translationValues(dx, 0.0, 0.0),
        );

      case OverlayAnimationType.bounce:
        // Damped sine bounce: overshoot and settle at 1.0
        final bounceScale =
            progress < 1.0
                ? (1.0 -
                    math.pow(2, -10 * progress) *
                        math.cos(progress * math.pi * 3))
                : 1.0;
        final clamped = bounceScale.clamp(0.0, 1.2).toDouble();
        return ElementVisualState(
          isVisible: true,
          opacity: baseOpacity * progress.clamp(0.0, 1.0),
          transformMatrix: Matrix4.diagonal3Values(clamped, clamped, 1.0),
        );

      case OverlayAnimationType.none:
        return ElementVisualState.identity(opacity: baseOpacity);
    }
  }

  static ElementVisualState _interpolateExit({
    required StoryElement element,
    required double progress,
    required OverlayAnimationType type,
    required Size canvasSize,
  }) {
    final baseOpacity = element.opacity;
    final remaining = 1.0 - progress;

    switch (type) {
      case OverlayAnimationType.fade:
        return ElementVisualState(
          isVisible: remaining > 0.0,
          opacity: baseOpacity * remaining,
          transformMatrix: Matrix4.identity(),
        );

      case OverlayAnimationType.scale:
        final scale = remaining.clamp(0.001, 1.0);
        return ElementVisualState(
          isVisible: remaining > 0.0,
          opacity: baseOpacity * remaining,
          transformMatrix: Matrix4.diagonal3Values(scale, scale, 1.0),
        );

      case OverlayAnimationType.slideUp:
        final dy = -progress * (canvasSize.height * 0.25);
        return ElementVisualState(
          isVisible: remaining > 0.0,
          opacity: baseOpacity * remaining,
          transformMatrix: Matrix4.translationValues(0.0, dy, 0.0),
        );

      case OverlayAnimationType.slideDown:
        final dy = progress * (canvasSize.height * 0.25);
        return ElementVisualState(
          isVisible: remaining > 0.0,
          opacity: baseOpacity * remaining,
          transformMatrix: Matrix4.translationValues(0.0, dy, 0.0),
        );

      case OverlayAnimationType.slideLeft:
        final dx = -progress * (canvasSize.width * 0.25);
        return ElementVisualState(
          isVisible: remaining > 0.0,
          opacity: baseOpacity * remaining,
          transformMatrix: Matrix4.translationValues(dx, 0.0, 0.0),
        );

      case OverlayAnimationType.slideRight:
        final dx = progress * (canvasSize.width * 0.25);
        return ElementVisualState(
          isVisible: remaining > 0.0,
          opacity: baseOpacity * remaining,
          transformMatrix: Matrix4.translationValues(dx, 0.0, 0.0),
        );

      case OverlayAnimationType.bounce:
        final scale = remaining.clamp(0.001, 1.0);
        return ElementVisualState(
          isVisible: remaining > 0.0,
          opacity: baseOpacity * remaining,
          transformMatrix: Matrix4.diagonal3Values(scale, scale, 1.0),
        );

      case OverlayAnimationType.none:
        return ElementVisualState.identity(opacity: baseOpacity);
    }
  }
}
