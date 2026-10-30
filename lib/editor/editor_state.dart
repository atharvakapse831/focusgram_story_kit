import 'package:flutter/foundation.dart';

/// Available interactive tools in the story editor.
enum EditorTool { select, text, sticker, background }

/// Immutable snapshot of the transient user interaction state in the editor.
@immutable
class EditorState {
  const EditorState({
    required this.activePageId,
    this.selectedElementId,
    this.activeTool = EditorTool.select,
    this.isInteracting = false,
    this.showPageStrip = true,
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

  EditorState copyWith({
    String? activePageId,
    String? selectedElementId,
    bool clearSelectedElement = false,
    EditorTool? activeTool,
    bool? isInteracting,
    bool? showPageStrip,
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
          showPageStrip == other.showPageStrip;

  @override
  int get hashCode => Object.hash(
    activePageId,
    selectedElementId,
    activeTool,
    isInteracting,
    showPageStrip,
  );
}
