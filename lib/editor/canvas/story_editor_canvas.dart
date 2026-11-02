import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/element_payloads.dart';
import '../../models/story_element.dart';
import '../../models/story_media_asset.dart';
import '../../models/story_page.dart';
import '../../models/story_transform.dart';
import '../../models/video_payload.dart';
import '../editor_controller.dart';
import 'animated_element_box.dart';
import 'canvas_element_view.dart';
import 'canvas_video_view.dart';
import 'drawing_canvas_overlay.dart';
import 'selection_overlay.dart';
import 'snapping_guidelines.dart';

/// The interactive story canvas preview.
///
/// Handles canonical aspect-ratio letterboxing, layer rendering in deterministic
/// z-order, transform gesture manipulation (drag, scale, rotate), and selection chrome.
class StoryEditorCanvas extends StatefulWidget {
  const StoryEditorCanvas({super.key, required this.controller});

  final EditorController controller;

  @override
  State<StoryEditorCanvas> createState() => _StoryEditorCanvasState();
}

class _StoryEditorCanvasState extends State<StoryEditorCanvas> {
  // Gesture tracking state
  Offset? _initialFocalPoint;
  StoryTransform? _initialTransform;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final canvasSpec = widget.controller.project.canvasSpec;
        final page = widget.controller.activePage;
        final selectedId = widget.controller.state.selectedElementId;

        return Center(
          child: AspectRatio(
            aspectRatio: canvasSpec.aspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return ClipRect(
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          page.backgroundGradient == null
                              ? page.backgroundColor
                              : null,
                      gradient: page.backgroundGradient?.toGradient(),
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) => _handleTapUp(details, canvasSize),
                      onScaleStart:
                          (details) => _handleScaleStart(details, canvasSize),
                      onScaleUpdate:
                          (details) => _handleScaleUpdate(details, canvasSize),
                      onScaleEnd: (details) => _handleScaleEnd(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        fit: StackFit.expand,
                        children: [
                          // 1. Background asset if present
                          if (page.backgroundAsset != null)
                            _buildBackground(page.backgroundAsset!, page),

                          // 2. Elements rendered in deterministic z-order
                          for (final el in page.sortedElements)
                            if (el.isVisible)
                              _buildPositionedElement(el, canvasSize),

                          // 3. Selection overlay for currently active element
                          if (!widget.controller.state.isDrawingMode &&
                              selectedId != null &&
                              page.getElement(selectedId) != null &&
                              page.getElement(selectedId)!.isVisible)
                            _buildSelectionChrome(
                              page.getElement(selectedId)!,
                              canvasSize,
                            ),

                          // 4. Snapping guidelines indicators
                          SnappingGuidelinesOverlay(
                            snapX: widget.controller.state.snapX,
                            snapY: widget.controller.state.snapY,
                            canvasSize: canvasSize,
                          ),

                          // 5. Drawing overlay when in freehand drawing mode
                          if (widget.controller.state.isDrawingMode)
                            Positioned.fill(
                              child: DrawingCanvasOverlay(
                                controller: widget.controller,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground(StoryMediaAsset asset, StoryPage page) {
    final isVideo =
        asset.mimeType?.contains('video') == true ||
        asset.uri.toLowerCase().endsWith('.mp4') ||
        asset.uri.toLowerCase().endsWith('.mov');

    if (isVideo) {
      final videoPayload = StoryVideoPayload(
        asset: asset,
        trimRange: page.videoTrimRange ?? VideoTrimRange(end: page.duration),
        audioPolicy: page.audioPolicy ?? const VideoAudioPolicy(),
        coverTimestamp: page.coverTimestamp,
      );
      return CanvasVideoView(
        videoPayload: videoPayload,
        timelineController: widget.controller.timelineController,
      );
    }

    Widget img;
    switch (asset.sourceType) {
      case StoryMediaSourceType.file:
        img = Image.file(
          File(asset.uri),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
        break;
      case StoryMediaSourceType.asset:
        img = Image.asset(
          asset.uri,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
        break;
      case StoryMediaSourceType.network:
      case StoryMediaSourceType.memory:
        if (asset.uri.isEmpty) return const SizedBox.shrink();
        img = CachedNetworkImage(
          imageUrl: asset.uri,
          fit: BoxFit.cover,
          placeholder:
              (_, __) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          errorWidget: (_, __, ___) => const SizedBox.shrink(),
        );
        break;
    }

    if (page.imageAdjustments?.hasAdjustments == true) {
      img = ColorFiltered(
        colorFilter: ColorFilter.matrix(page.imageAdjustments!.toColorMatrix()),
        child: img,
      );
      if (page.imageAdjustments!.isFlippedHorizontally ||
          page.imageAdjustments!.isFlippedVertically) {
        img = Transform(
          transform: Matrix4.diagonal3Values(
            page.imageAdjustments!.isFlippedHorizontally ? -1.0 : 1.0,
            page.imageAdjustments!.isFlippedVertically ? -1.0 : 1.0,
            1.0,
          ),
          alignment: Alignment.center,
          child: img,
        );
      }
    }

    return img;
  }

  Widget _buildPositionedElement(StoryElement element, Size canvasSize) {
    final transform = element.transform;
    final center = transform.toScreenCenter(canvasSize);
    final size = transform.toScreenSize(canvasSize);

    return Positioned(
      left: center.dx - size.width / 2.0,
      top: center.dy - size.height / 2.0,
      width: size.width,
      height: size.height,
      child: Transform.rotate(
        angle: transform.rotation,
        child: AnimatedElementBox(
          element: element,
          canvasSize: canvasSize,
          timelineController: widget.controller.timelineController,
          child: CanvasElementView(
            element: element,
            timelineController: widget.controller.timelineController,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionChrome(StoryElement element, Size canvasSize) {
    final transform = element.transform;
    final center = transform.toScreenCenter(canvasSize);
    final size = transform.toScreenSize(canvasSize);

    return Positioned(
      left: center.dx - size.width / 2.0,
      top: center.dy - size.height / 2.0,
      width: size.width,
      height: size.height,
      child: Transform.rotate(
        angle: transform.rotation,
        child: StorySelectionOverlay(
          size: size,
          onDelete: widget.controller.removeSelectedElement,
          onBringForward: () => widget.controller.bringForward(element.id),
          onSendBackward: () => widget.controller.sendBackward(element.id),
        ),
      ),
    );
  }

  void _handleTapUp(TapUpDetails details, Size canvasSize) {
    if (widget.controller.state.isDrawingMode) return;
    final point = details.localPosition;
    final elements = widget.controller.activePage.sortedElements.reversed;
    final currentTime = widget.controller.timelineController.currentPosition;

    for (final el in elements) {
      final inTimeRange = el.visibleTimeRange?.isVisibleAt(currentTime) ?? true;
      if (!el.isLocked &&
          el.isVisible &&
          inTimeRange &&
          el.transform.containsPoint(point, canvasSize)) {
        widget.controller.selectElement(el.id);
        return;
      }
    }

    // Tapped blank canvas area
    widget.controller.selectElement(null);
  }

  void _handleScaleStart(ScaleStartDetails details, Size canvasSize) {
    if (widget.controller.state.isDrawingMode) return;
    final point = details.localFocalPoint;
    final selected = widget.controller.selectedElement;
    final currentTime = widget.controller.timelineController.currentPosition;

    // Check if touching current selected element or another selectable element
    String? targetId = selected?.id;
    final selectedInTimeRange =
        selected?.visibleTimeRange?.isVisibleAt(currentTime) ?? true;
    if (selected == null ||
        selected.isLocked ||
        !selected.isVisible ||
        !selectedInTimeRange ||
        !selected.transform.containsPoint(point, canvasSize)) {
      final elements = widget.controller.activePage.sortedElements.reversed;
      for (final el in elements) {
        final inTimeRange =
            el.visibleTimeRange?.isVisibleAt(currentTime) ?? true;
        if (!el.isLocked &&
            el.isVisible &&
            inTimeRange &&
            el.transform.containsPoint(point, canvasSize)) {
          targetId = el.id;
          widget.controller.selectElement(el.id);
          break;
        }
      }
    }

    if (targetId != null) {
      final target = widget.controller.activePage.getElement(targetId);
      if (target != null && !target.isLocked && target.isVisible) {
        _initialFocalPoint = point;
        _initialTransform = target.transform;
        widget.controller.setInteracting(true);
      }
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, Size canvasSize) {
    final selected = widget.controller.selectedElement;
    if (selected == null ||
        _initialTransform == null ||
        _initialFocalPoint == null) {
      return;
    }

    // Normalized translation delta
    final delta = details.localFocalPoint - _initialFocalPoint!;
    final normalizedDx = delta.dx / canvasSize.width;
    final normalizedDy = delta.dy / canvasSize.height;

    var targetX = _initialTransform!.x + normalizedDx;
    var targetY = _initialTransform!.y + normalizedDy;

    double? snappedX;
    double? snappedY;

    // Center X snap (tolerance ~1.5% of canvas width)
    if ((targetX - 0.5).abs() < 0.015) {
      targetX = 0.5;
      snappedX = 0.5;
    }

    // Center Y snap (tolerance ~1.5% of canvas height)
    if ((targetY - 0.5).abs() < 0.015) {
      targetY = 0.5;
      snappedY = 0.5;
    }

    widget.controller.setSnapGuidelines(snapX: snappedX, snapY: snappedY);

    final updatedTransform =
        _initialTransform!
            .copyWith(
              x: targetX,
              y: targetY,
              scale: (_initialTransform!.scale * details.scale).clamp(0.2, 5.0),
              rotation:
                  (_initialTransform!.rotation + details.rotation) %
                  (2 * 3.141592653589793),
            )
            .clampToCanvas();

    widget.controller.updateElementTransform(
      selected.id,
      updatedTransform,
      isCoalescing: true,
    );
  }

  void _handleScaleEnd() {
    widget.controller.setSnapGuidelines(snapX: null, snapY: null);

    final selected = widget.controller.selectedElement;
    if (selected != null && _initialTransform != null) {
      // Commit final coalesced command
      widget.controller.updateElementTransform(
        selected.id,
        selected.transform,
        isCoalescing: false,
      );
    }

    _initialFocalPoint = null;
    _initialTransform = null;
    widget.controller.setInteracting(false);
  }
}
