import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/story_element.dart';
import '../../models/story_media_asset.dart';
import '../../models/story_transform.dart';
import '../editor_controller.dart';
import 'canvas_element_view.dart';
import 'selection_overlay.dart';

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
                    color: page.backgroundColor,
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
                            _buildBackground(page.backgroundAsset!),

                          // 2. Elements rendered in deterministic z-order
                          for (final el in page.sortedElements)
                            _buildPositionedElement(el, canvasSize),

                          // 3. Selection overlay for currently active element
                          if (selectedId != null &&
                              page.getElement(selectedId) != null)
                            _buildSelectionChrome(
                              page.getElement(selectedId)!,
                              canvasSize,
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

  Widget _buildBackground(StoryMediaAsset asset) {
    switch (asset.sourceType) {
      case StoryMediaSourceType.file:
        return Image.file(
          File(asset.uri),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      case StoryMediaSourceType.asset:
        return Image.asset(
          asset.uri,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      case StoryMediaSourceType.network:
      case StoryMediaSourceType.memory:
        if (asset.uri.isEmpty) return const SizedBox.shrink();
        return CachedNetworkImage(
          imageUrl: asset.uri,
          fit: BoxFit.cover,
          placeholder:
              (_, __) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          errorWidget: (_, __, ___) => const SizedBox.shrink(),
        );
    }
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
        child: CanvasElementView(element: element),
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
    final point = details.localPosition;
    final elements = widget.controller.activePage.sortedElements.reversed;

    for (final el in elements) {
      if (!el.isLocked && el.transform.containsPoint(point, canvasSize)) {
        widget.controller.selectElement(el.id);
        return;
      }
    }

    // Tapped blank canvas area
    widget.controller.selectElement(null);
  }

  void _handleScaleStart(ScaleStartDetails details, Size canvasSize) {
    final point = details.localFocalPoint;
    final selected = widget.controller.selectedElement;

    // Check if touching current selected element or another selectable element
    String? targetId = selected?.id;
    if (selected == null ||
        !selected.transform.containsPoint(point, canvasSize)) {
      final elements = widget.controller.activePage.sortedElements.reversed;
      for (final el in elements) {
        if (!el.isLocked && el.transform.containsPoint(point, canvasSize)) {
          targetId = el.id;
          widget.controller.selectElement(el.id);
          break;
        }
      }
    }

    if (targetId != null) {
      final target = widget.controller.activePage.getElement(targetId);
      if (target != null) {
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

    final updatedTransform =
        _initialTransform!
            .copyWith(
              x: _initialTransform!.x + normalizedDx,
              y: _initialTransform!.y + normalizedDy,
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
