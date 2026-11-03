import 'package:flutter/material.dart';
import '../models/element_payloads.dart';
import '../models/gradient_background.dart';
import '../models/story_element.dart';
import '../models/story_media_asset.dart';
import '../models/story_page.dart';
import '../models/story_project.dart';
import '../models/story_template.dart';
import '../models/story_transform.dart';
import '../timeline/timeline_controller.dart';
import 'command_history.dart';
import 'editor_commands.dart';
import 'editor_state.dart';

/// Central state management controller for a story editing session.
///
/// Implements [ChangeNotifier] to drive reactive UI updates while isolating
/// document state ([StoryProject]) from ephemeral interaction state ([EditorState]).
class EditorController extends ChangeNotifier {
  EditorController({
    StoryProject? initialProject,
    CommandHistory? history,
    StoryTimelineController? timelineController,
  }) : _history = history ?? CommandHistory(),
       _timelineController = timelineController {
    if (initialProject != null && initialProject.pages.isNotEmpty) {
      _project = initialProject;
      _state = EditorState(activePageId: initialProject.pages.first.id);
    } else {
      final defaultProj = StoryProject.create(
        id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
      );
      _project = defaultProj;
      _state = EditorState(activePageId: defaultProj.pages.first.id);
    }
    _lastSavedRevision = _project.revision;
  }

  late StoryProject _project;
  late EditorState _state;
  final CommandHistory _history;
  late int _lastSavedRevision;
  StoryTimelineController? _timelineController;

  /// Single source of truth timeline controller for video playback and animated layers.
  StoryTimelineController get timelineController {
    if (_timelineController == null) {
      final page = activePage;
      _timelineController = StoryTimelineController(
        initialDuration: page.duration,
        initialTrimRange: page.videoTrimRange,
      );
    }
    return _timelineController!;
  }

  /// Current serializable story document.
  StoryProject get project => _project;

  /// Ephemeral interaction state (active page, selected element, active tool).
  EditorState get state => _state;

  /// History manager tracking undoable/redoable operations.
  CommandHistory get history => _history;

  /// Whether changes have occurred since the last save.
  bool get isDirty => _project.revision != _lastSavedRevision;

  /// Currently active story slide/page.
  StoryPage get activePage {
    return _project.getPage(_state.activePageId) ?? _project.pages.first;
  }

  /// Currently selected visual element on the active page, if any.
  StoryElement? get selectedElement {
    if (_state.selectedElementId == null) return null;
    return activePage.getElement(_state.selectedElementId!);
  }

  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  // ---------------------------------------------------------------------------
  // Session & Interaction
  // ---------------------------------------------------------------------------

  /// Marks the current project revision as saved/persisted.
  void markSaved() {
    _lastSavedRevision = _project.revision;
    notifyListeners();
  }

  /// Switches the active slide to [pageId].
  void selectPage(String pageId) {
    if (_state.activePageId == pageId) return;
    final targetPage = _project.getPage(pageId);
    final isVideo = targetPage?.backgroundAsset?.isVideo == true;
    _state = _state.copyWith(
      activePageId: pageId,
      clearSelectedElement: true,
      showTimeline: isVideo ? true : _state.showTimeline,
    );
    if (targetPage != null && _timelineController != null) {
      _timelineController!.setTotalDuration(targetPage.duration);
      _timelineController!.setTrimRange(targetPage.videoTrimRange);
      _timelineController!.seekTo(
        targetPage.videoTrimRange?.start ?? Duration.zero,
      );
    }
    notifyListeners();
  }

  /// Selects or deselects an element on the active page.
  void selectElement(String? elementId) {
    if (_state.selectedElementId == elementId) return;
    _state = _state.copyWith(
      selectedElementId: elementId,
      clearSelectedElement: elementId == null,
    );
    notifyListeners();
  }

  /// Switches the active editing tool panel.
  void setTool(EditorTool tool) {
    if (_state.activeTool == tool) return;
    _state = _state.copyWith(activeTool: tool);
    notifyListeners();
  }

  /// Sets or exits freehand drawing mode.
  void setDrawingMode(bool enabled) {
    setTool(enabled ? EditorTool.draw : EditorTool.select);
  }

  /// Toggles visibility of the bottom page strip.
  void togglePageStrip() {
    _state = _state.copyWith(showPageStrip: !_state.showPageStrip);
    notifyListeners();
  }

  /// Toggles visibility of the video timeline scrubber.
  void toggleTimeline([bool? show]) {
    final next = show ?? !_state.showTimeline;
    if (_state.showTimeline == next) return;
    _state = _state.copyWith(showTimeline: next);
    notifyListeners();
  }

  /// Sets whether the user is actively dragging/scaling/rotating an element.
  void setInteracting(bool isInteracting) {
    if (_state.isInteracting == isInteracting) return;
    _state = _state.copyWith(isInteracting: isInteracting);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Document Mutations (Command-driven)
  // ---------------------------------------------------------------------------

  /// Executes an undoable [command] against the document.
  void execute(EditorCommand command) {
    _project = _history.execute(command, _project);
    notifyListeners();
  }

  /// Undoes the last document mutation.
  void undo() {
    if (!_history.canUndo) return;
    _project = _history.undo(_project);
    // Ensure active page ID and selection remain valid
    _sanitizeSelection();
    _syncTimelineWithActivePage();
    notifyListeners();
  }

  /// Redoes the previously undone document mutation.
  void redo() {
    if (!_history.canRedo) return;
    _project = _history.redo(_project);
    _sanitizeSelection();
    _syncTimelineWithActivePage();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Element Actions
  // ---------------------------------------------------------------------------

  /// Adds a new element to the active page and selects it.
  void addElement(StoryElement element) {
    execute(AddElementCommand(pageId: activePage.id, element: element));
    selectElement(element.id);
  }

  /// Removes the currently selected element from the active page.
  void removeSelectedElement() {
    final el = selectedElement;
    if (el == null) return;

    final index = activePage.elements.indexOf(el);
    execute(
      RemoveElementCommand(
        pageId: activePage.id,
        element: el,
        index: index >= 0 ? index : 0,
      ),
    );
    selectElement(null);
  }

  /// Updates an element's normalized transform.
  ///
  /// Set [isCoalescing] to true during live gesture drags/pinches to coalesce
  /// continuous updates into a single undo entry.
  void updateElementTransform(
    String elementId,
    StoryTransform newTransform, {
    bool isCoalescing = false,
  }) {
    final el = activePage.getElement(elementId);
    if (el == null) return;

    execute(
      TransformElementCommand(
        pageId: activePage.id,
        elementId: elementId,
        previousTransform: el.transform,
        newTransform: newTransform,
        isCoalescing: isCoalescing,
      ),
    );
  }

  /// Updates an element's content payload.
  void updateElementPayload(String elementId, StoryElementPayload newPayload) {
    final el = activePage.getElement(elementId);
    if (el == null) return;

    execute(
      UpdateElementPayloadCommand(
        pageId: activePage.id,
        elementId: elementId,
        previousPayload: el.payload,
        newPayload: newPayload,
      ),
    );
  }

  /// Adjusts an element's z-order.
  void bringForward(String elementId) {
    final el = activePage.getElement(elementId);
    if (el == null) return;
    execute(
      ReorderElementCommand(
        pageId: activePage.id,
        elementId: elementId,
        previousZIndex: el.zIndex,
        newZIndex: el.zIndex + 1,
      ),
    );
  }

  void sendBackward(String elementId) {
    final el = activePage.getElement(elementId);
    if (el == null) return;
    execute(
      ReorderElementCommand(
        pageId: activePage.id,
        elementId: elementId,
        previousZIndex: el.zIndex,
        newZIndex: (el.zIndex - 1).clamp(0, 999),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page Actions
  // ---------------------------------------------------------------------------

  /// Appends a new blank page to the project.
  void addPage() {
    final newPage = StoryPage(
      id:
          'page_${DateTime.now().millisecondsSinceEpoch}_${_project.pages.length + 1}',
    );
    execute(AddPageCommand(page: newPage));
    selectPage(newPage.id);
  }

  /// Duplicates the active page and all of its elements.
  void duplicateActivePage() {
    final current = activePage;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newElements =
        current.elements.map((el) {
          return el.copyWith(id: '${el.id}_dup_$timestamp');
        }).toList();

    final duplicated = StoryPage(
      id: 'page_${timestamp}_dup',
      duration: current.duration,
      backgroundColor: current.backgroundColor,
      backgroundAsset: current.backgroundAsset,
      elements: newElements,
    );

    final currentIndex = _project.pages.indexOf(current);
    execute(
      DuplicatePageCommand(
        sourcePageId: current.id,
        duplicatedPage: duplicated,
        insertIndex: currentIndex + 1,
      ),
    );
    selectPage(duplicated.id);
  }

  /// Deletes the currently active page (retains at least 1 page).
  void deleteActivePage() {
    if (_project.pages.length <= 1) return; // Prevent deleting only page

    final current = activePage;
    final currentIndex = _project.pages.indexOf(current);

    execute(RemovePageCommand(page: current, index: currentIndex));

    // Select adjacent page
    final newIndex = (currentIndex - 1).clamp(0, _project.pages.length - 1);
    selectPage(_project.pages[newIndex].id);
  }

  /// Reorders a page from [oldIndex] to [newIndex].
  void reorderPage(int oldIndex, int newIndex) {
    execute(ReorderPageCommand(oldIndex: oldIndex, newIndex: newIndex));
  }

  /// Appends a new page with a background media asset (photo or video).
  void addMediaPage(
    StoryMediaAsset asset, {
    Duration duration = const Duration(seconds: 5),
  }) {
    final isVideo = asset.isVideo;
    final newPage = StoryPage(
      id:
          'page_${DateTime.now().millisecondsSinceEpoch}_${_project.pages.length + 1}',
      duration: isVideo ? duration : const Duration(seconds: 5),
      backgroundAsset: asset,
      videoTrimRange: isVideo ? VideoTrimRange(end: duration) : null,
    );
    execute(AddPageCommand(page: newPage));
    selectPage(newPage.id);
  }

  /// Sets the background color or media asset for the active page.
  void setPageBackground({
    Color? color,
    StoryMediaAsset? asset,
    bool clearAsset = false,
  }) {
    final current = activePage;
    execute(
      SetPageBackgroundCommand(
        pageId: current.id,
        previousColor: current.backgroundColor,
        newColor: color ?? current.backgroundColor,
        previousAsset: current.backgroundAsset,
        newAsset: clearAsset ? null : (asset ?? current.backgroundAsset),
      ),
    );
  }

  /// Sets or clears the gradient background for the active page.
  void setPageGradient(StoryGradientBackground? gradient) {
    final current = activePage;
    execute(
      SetPageGradientCommand(
        pageId: current.id,
        previousGradient: current.backgroundGradient,
        newGradient: gradient,
      ),
    );
  }

  /// Toggles the lock flag on an element.
  void toggleElementLock(String elementId) {
    execute(
      ToggleElementLockCommand(pageId: activePage.id, elementId: elementId),
    );
  }

  /// Toggles visibility of an element on the canvas.
  void toggleElementVisibility(String elementId) {
    execute(
      ToggleElementVisibilityCommand(
        pageId: activePage.id,
        elementId: elementId,
      ),
    );
  }

  /// Appends a freehand stroke to the active page's drawing layer.
  void addDrawingStroke(DrawingStroke stroke) {
    execute(AddDrawingStrokeCommand(pageId: activePage.id, stroke: stroke));
  }

  /// Clears all strokes on the active page's drawing layer.
  void clearDrawing(String drawingElementId) {
    final el = activePage.getElement(drawingElementId);
    if (el == null || el.payload is! DrawingElementPayload) return;
    final payload = el.payload as DrawingElementPayload;
    execute(
      ClearDrawingCommand(
        pageId: activePage.id,
        drawingElementId: drawingElementId,
        previousStrokes: payload.strokes,
      ),
    );
  }

  /// Updates background image adjustments for the active page.
  void updatePageImageAdjustments(ImageAdjustments? newAdjustments) {
    final current = activePage;
    execute(
      UpdatePageImageAdjustmentsCommand(
        pageId: current.id,
        previousAdjustments: current.imageAdjustments,
        newAdjustments: newAdjustments,
      ),
    );
  }

  /// Updates image adjustments (brightness, contrast, saturation, filters).
  void updateImageAdjustments(
    String? elementId,
    ImageAdjustments newAdjustments,
  ) {
    if (elementId == null || elementId == 'background') {
      updatePageImageAdjustments(newAdjustments);
      return;
    }
    final el = activePage.getElement(elementId);
    if (el == null || el.payload is! ImageElementPayload) return;
    final payload = el.payload as ImageElementPayload;
    execute(
      UpdateImageAdjustmentsCommand(
        pageId: activePage.id,
        elementId: elementId,
        previousAdjustments: payload.adjustments,
        newAdjustments: newAdjustments,
      ),
    );
  }

  /// Applies a preset template to replace the active page layout.
  void applyTemplate(StoryTemplate template) {
    final current = activePage;
    final templated = template.createPage(current.id);
    execute(
      ApplyTemplateCommand(previousPage: current, templatedPage: templated),
    );
  }

  /// Updates transient alignment snap guideline indicators.
  void setSnapGuidelines({double? snapX, double? snapY}) {
    if (_state.snapX == snapX && _state.snapY == snapY) return;
    _state = _state.copyWith(
      snapX: snapX,
      clearSnapX: snapX == null,
      snapY: snapY,
      clearSnapY: snapY == null,
    );
    notifyListeners();
  }

  /// Updates transient brush configuration for drawing mode.
  void setBrushSettings({
    DrawingBrushType? brushType,
    Color? brushColor,
    double? brushWidth,
  }) {
    _state = _state.copyWith(
      activeBrushType: brushType,
      activeBrushColor: brushColor,
      activeBrushWidth: brushWidth,
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Phase 5 Video, Timeline & Animation Actions
  // ---------------------------------------------------------------------------

  /// Updates the trim boundaries for the active page's background video.
  void setVideoTrimRange(VideoTrimRange? range) {
    final page = activePage;
    execute(
      SetPageVideoTrimRangeCommand(
        pageId: page.id,
        newTrimRange: range,
        previousTrimRange: page.videoTrimRange,
      ),
    );
    _timelineController?.setTrimRange(range);
  }

  /// Updates the audio mixing/muting policy for the active page.
  void setAudioPolicy(VideoAudioPolicy? policy) {
    final page = activePage;
    execute(
      SetPageAudioPolicyCommand(
        pageId: page.id,
        newAudioPolicy: policy,
        previousAudioPolicy: page.audioPolicy,
      ),
    );
  }

  /// Updates the cover frame timestamp for the active page.
  void setCoverTimestamp(Duration? timestamp) {
    final page = activePage;
    execute(
      SetPageCoverTimestampCommand(
        pageId: page.id,
        newCoverTimestamp: timestamp,
        previousCoverTimestamp: page.coverTimestamp,
      ),
    );
  }

  /// Sets the time-bounded visibility range for a specific layer.
  void setElementTimeRange(String elementId, LayerTimeRange? range) {
    final page = activePage;
    final el = page.getElement(elementId);
    if (el == null) return;

    execute(
      SetElementTimeRangeCommand(
        pageId: page.id,
        elementId: elementId,
        newTimeRange: range,
        previousTimeRange: el.visibleTimeRange,
      ),
    );
  }

  /// Sets the entrance/exit animation configuration for a specific layer.
  void setElementAnimation(
    String elementId,
    OverlayAnimationConfig? animation,
  ) {
    final page = activePage;
    final el = page.getElement(elementId);
    if (el == null) return;

    execute(
      SetElementAnimationCommand(
        pageId: page.id,
        elementId: elementId,
        newAnimation: animation,
        previousAnimation: el.animation,
      ),
    );
  }

  /// Splits the active video page into two contiguous pages at [splitTime].
  void splitVideoClip(Duration splitTime) {
    final page = activePage;
    final newPageId = 'page_${DateTime.now().millisecondsSinceEpoch}_split';
    execute(
      SplitPageVideoClipCommand(
        pageId: page.id,
        newPageId: newPageId,
        splitTime: splitTime,
        previousPage: page,
      ),
    );
    _syncTimelineWithActivePage();
  }

  @override
  void dispose() {
    _timelineController?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  void _syncTimelineWithActivePage() {
    if (_timelineController != null) {
      final page = activePage;
      _timelineController!.setTotalDuration(page.duration);
      _timelineController!.setTrimRange(page.videoTrimRange);
      _timelineController!.seekTo(page.videoTrimRange?.start ?? Duration.zero);
    }
  }

  void _sanitizeSelection() {
    if (_project.getPage(_state.activePageId) == null) {
      _state = _state.copyWith(
        activePageId: _project.pages.first.id,
        clearSelectedElement: true,
      );
    } else if (selectedElement == null && _state.selectedElementId != null) {
      _state = _state.copyWith(clearSelectedElement: true);
    }
  }
}
