import 'package:flutter/material.dart';
import '../models/drawing_stroke.dart';

/// Available interactive tools in the story editor.
enum EditorTool {
  select,
  text,
  sticker,
  background,
  draw,
  shape,
  adjust,
  layers,
  template,
  timeline,
  animation,
  audio,
  cover,
}

/// Immutable snapshot of the transient user interaction state in the editor.
@immutable
class EditorState {
  const EditorState({
    required this.activePageId,
    this.selectedElementId,
    this.activeTool = EditorTool.select,
    this.isInteracting = false,
    this.showPageStrip = true,
    this.showTimeline = false,
    this.snapX,
    this.snapY,
    this.activeBrushType = DrawingBrushType.pen,
    this.activeBrushColor = Colors.white,
    this.activeBrushWidth = 0.008,
  });

  /// The currently displayed/edited page ID.
  final String activePageId;

  /// ID of the currently selected element, or null if canvas is tapped.
  final String? selectedElementId;

  /// The currently active tool panel / mode.
  final EditorTool activeTool;

  /// True during active gestures (drag, scale, rotate) to suppress heavy rebuilds.
  final bool isInteracting;

  /// Whether the page strip thumbnail bar at the bottom is visible.
  final bool showPageStrip;

  /// Whether the video timeline scrubber panel at the bottom is visible.
  final bool showTimeline;

  /// Active horizontal snap guideline normalized in `[0.0, 1.0]` (e.g. 0.5 for center), if snapping.
  final double? snapX;

  /// Active vertical snap guideline normalized in `[0.0, 1.0]` (e.g. 0.5 for center), if snapping.
  final double? snapY;

  /// Currently selected brush type for drawing mode.
  final DrawingBrushType activeBrushType;

  /// Currently selected brush color.
  final Color activeBrushColor;

  /// Currently selected normalized brush stroke width.
  final double activeBrushWidth;

  bool get isDrawingMode => activeTool == EditorTool.draw;

  EditorState copyWith({
    String? activePageId,
    String? selectedElementId,
    bool clearSelectedElement = false,
    EditorTool? activeTool,
    bool? isInteracting,
    bool? showPageStrip,
    bool? showTimeline,
    double? snapX,
    bool clearSnapX = false,
    double? snapY,
    bool clearSnapY = false,
    DrawingBrushType? activeBrushType,
    Color? activeBrushColor,
    double? activeBrushWidth,
  }) {
    return EditorState(
      activePageId: activePageId ?? this.activePageId,
      selectedElementId:
          clearSelectedElement
              ? null
              : (selectedElementId ?? this.selectedElementId),
      activeTool: activeTool ?? this.activeTool,
      isInteracting: isInteracting ?? this.isInteracting,
      showPageStrip: showPageStrip ?? this.showPageStrip,
      showTimeline: showTimeline ?? this.showTimeline,
      snapX: clearSnapX ? null : (snapX ?? this.snapX),
      snapY: clearSnapY ? null : (snapY ?? this.snapY),
      activeBrushType: activeBrushType ?? this.activeBrushType,
      activeBrushColor: activeBrushColor ?? this.activeBrushColor,
      activeBrushWidth: activeBrushWidth ?? this.activeBrushWidth,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorState &&
          runtimeType == other.runtimeType &&
          activePageId == other.activePageId &&
          selectedElementId == other.selectedElementId &&
          activeTool == other.activeTool &&
          isInteracting == other.isInteracting &&
          showPageStrip == other.showPageStrip &&
          showTimeline == other.showTimeline &&
          snapX == other.snapX &&
          snapY == other.snapY &&
          activeBrushType == other.activeBrushType &&
          activeBrushColor == other.activeBrushColor &&
          activeBrushWidth == other.activeBrushWidth;

  @override
  int get hashCode => Object.hash(
    activePageId,
    selectedElementId,
    activeTool,
    isInteracting,
    showPageStrip,
    showTimeline,
    snapX,
    snapY,
    activeBrushType,
    activeBrushColor,
    activeBrushWidth,
  );
}
