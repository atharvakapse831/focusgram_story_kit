import 'package:flutter/material.dart';
import '../assets/asset_provider.dart';
import '../draft/draft_repository.dart';
import '../draft/in_memory_draft_repository.dart';
import '../export/export_result.dart';
import '../export/still_image_exporter.dart';
import '../localization/story_kit_strings.dart';
import '../media/capture_adapter.dart';
import '../media/media_picker_adapter.dart';
import '../models/gradient_background.dart';
import '../models/story_element.dart';
import '../models/story_project.dart';
import '../theme/story_kit_theme.dart';
import 'canvas/story_editor_canvas.dart';
import 'canvas/story_page_strip.dart';
import 'editor_controller.dart';
import 'panels/animation_picker_sheet.dart';
import 'panels/audio_settings_sheet.dart';
import 'panels/cover_picker_sheet.dart';
import 'panels/drawing_toolbar.dart';
import 'panels/image_adjustment_sheet.dart';
import 'panels/layer_manager_sheet.dart';
import 'panels/rich_text_editor_sheet.dart';
import 'panels/shape_picker_sheet.dart';
import 'panels/sticker_picker_sheet.dart';
import 'panels/template_picker_sheet.dart';
import 'panels/timeline_scrubber.dart';

/// Configuration options for the [StoryKitEditor] UI.
@immutable
class StoryKitEditorConfig {
  const StoryKitEditorConfig({
    this.enablePageStrip = true,
    this.enableUndoRedo = true,
    this.enableDrafts = true,
    this.enableDrawing = true,
    this.enableShapes = true,
    this.enableTemplates = true,
    this.enableLayers = true,
    this.enableAdjustments = true,
    this.enableStickers = true,
    this.enableGradients = true,
    this.enableTimeline = true,
    this.enableAnimation = true,
    this.enableAudioSettings = true,
    this.theme = StoryKitEditorTheme.dark,
    this.strings = const StoryKitStrings(),
    this.assetProvider = const DefaultStoryAssetProvider(),
    this.mediaPickerAdapter,
    this.captureAdapter,
    this.availableColors = const [
      Colors.black,
      Color(0xFF1E1E1E),
      Color(0xFF2C3E50),
      Color(0xFF8E44AD),
      Color(0xFFC0392B),
      Color(0xFFD35400),
      Color(0xFF27AE60),
    ],
  });

  final bool enablePageStrip;
  final bool enableUndoRedo;
  final bool enableDrafts;
  final bool enableDrawing;
  final bool enableShapes;
  final bool enableTemplates;
  final bool enableLayers;
  final bool enableAdjustments;
  final bool enableStickers;
  final bool enableGradients;
  final bool enableTimeline;
  final bool enableAnimation;
  final bool enableAudioSettings;
  final StoryKitEditorTheme theme;
  final StoryKitStrings strings;
  final StoryAssetProvider assetProvider;
  final StoryMediaPickerAdapter? mediaPickerAdapter;
  final StoryCaptureAdapter? captureAdapter;
  final List<Color> availableColors;
}

/// The top-level FocusGram story editor screen widget.
///
/// Coordinates document state, history, canvas manipulation, rich text editing,
/// freehand drawing, geometric shapes, categorized stickers, gradient presets,
/// layer reordering, template application, draft persistence, and deterministic raster export.
class StoryKitEditor extends StatefulWidget {
  const StoryKitEditor({
    super.key,
    this.controller,
    this.initialProject,
    this.draftRepository,
    this.config = const StoryKitEditorConfig(),
    this.onClose,
    this.onExport,
    this.onSaveDraft,
  });

  /// Injected controller. If null, an internal [EditorController] is instantiated and owned.
  final EditorController? controller;

  /// Optional initial document to populate the editor.
  final StoryProject? initialProject;

  /// Draft storage backend for save/restore operations.
  final StoryDraftRepository? draftRepository;

  /// Feature toggles, semantic theme tokens, strings, and asset providers.
  final StoryKitEditorConfig config;

  /// Fired when the user dismisses the editor.
  final VoidCallback? onClose;

  /// Fired when the user successfully renders and exports the story slides.
  final ValueChanged<List<StillImageExportResult>>? onExport;

  /// Fired when the user saves the draft.
  final ValueChanged<StoryProject>? onSaveDraft;

  @override
  State<StoryKitEditor> createState() => _StoryKitEditorState();
}

class _StoryKitEditorState extends State<StoryKitEditor> {
  late final EditorController _controller;
  late final bool _ownsController;
  late final StoryDraftRepository _draftRepo;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = EditorController(initialProject: widget.initialProject);
      _ownsController = true;
    }

    _draftRepo = widget.draftRepository ?? InMemoryStoryDraftRepository();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  String? get _targetImageElementId {
    final selId = _controller.state.selectedElementId;
    if (selId != null) {
      final el = _controller.activePage.getElement(selId);
      if (el != null && el.type == StoryElementType.image) return selId;
    }
    for (final el in _controller.activePage.elements) {
      if (el.type == StoryElementType.image) return el.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.config.theme;
    final strings = widget.config.strings;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final isDrawing = _controller.state.isDrawingMode;

            return Stack(
              children: [
                // 1. Main Column: Top bar (or Drawing Toolbar) + Canvas + Page Strip
                Column(
                  children: [
                    if (isDrawing)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: DrawingToolbar(
                          controller: _controller,
                          onDone: () => _controller.setDrawingMode(false),
                        ),
                      )
                    else
                      _buildTopBar(context),
                    Expanded(child: StoryEditorCanvas(controller: _controller)),
                    if (widget.config.enableTimeline &&
                        _controller.state.showTimeline &&
                        !isDrawing)
                      TimelineScrubber(
                        controller: _controller,
                        onOpenAnimationSheet:
                            widget.config.enableAnimation
                                ? () => _openAnimationSheet(context)
                                : null,
                        onOpenAudioSheet:
                            widget.config.enableAudioSettings
                                ? () => _openAudioSheet(context)
                                : null,
                        onOpenCoverSheet: () => _openCoverSheet(context),
                      ),
                    if (widget.config.enablePageStrip &&
                        _controller.state.showPageStrip &&
                        !isDrawing)
                      StoryPageStrip(controller: _controller),
                  ],
                ),

                // 2. Exporting progress modal overlay
                if (_isExporting)
                  Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          strings.exportingStory,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = widget.config.theme;
    final strings = widget.config.strings;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      color: theme.topBarColor,
      child: Row(
        children: [
          // Close button
          IconButton(
            icon: Icon(Icons.close, color: theme.primaryIconColor),
            tooltip: strings.closeEditor,
            onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
          ),

          // Scrollable tools row for fluid responsiveness across screen sizes
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Undo / Redo
                  if (widget.config.enableUndoRedo) ...[
                    IconButton(
                      icon: Icon(
                        Icons.undo,
                        color:
                            _controller.canUndo
                                ? theme.primaryIconColor
                                : theme.disabledIconColor,
                      ),
                      tooltip: strings.undo,
                      onPressed: _controller.canUndo ? _controller.undo : null,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.redo,
                        color:
                            _controller.canRedo
                                ? theme.primaryIconColor
                                : theme.disabledIconColor,
                      ),
                      tooltip: strings.redo,
                      onPressed: _controller.canRedo ? _controller.redo : null,
                    ),
                  ],

                  // Add Text
                  IconButton(
                    icon: Icon(Icons.title, color: theme.primaryIconColor),
                    tooltip: strings.addText,
                    onPressed: () => _openTextEditor(context),
                  ),

                  // Freehand Drawing Mode
                  if (widget.config.enableDrawing)
                    IconButton(
                      icon: Icon(Icons.draw, color: theme.primaryIconColor),
                      tooltip: strings.draw,
                      onPressed: () => _controller.setDrawingMode(true),
                    ),

                  // Vector Shapes
                  if (widget.config.enableShapes)
                    IconButton(
                      icon: Icon(
                        Icons.category_outlined,
                        color: theme.primaryIconColor,
                      ),
                      tooltip: strings.addShape,
                      onPressed: () => _openShapePicker(context),
                    ),

                  // Categorized Stickers
                  if (widget.config.enableStickers)
                    IconButton(
                      icon: Icon(
                        Icons.sentiment_satisfied_alt,
                        color: theme.primaryIconColor,
                      ),
                      tooltip: strings.addSticker,
                      onPressed: () => _openStickerPicker(context),
                    ),

                  // Change Background (solid + gradients)
                  IconButton(
                    icon: Icon(
                      Icons.palette_outlined,
                      color: theme.primaryIconColor,
                    ),
                    tooltip: strings.changeBackground,
                    onPressed: () => _showBackgroundPickerSheet(context),
                  ),

                  // Story Templates
                  if (widget.config.enableTemplates)
                    IconButton(
                      icon: Icon(
                        Icons.dashboard_customize_outlined,
                        color: theme.primaryIconColor,
                      ),
                      tooltip: strings.templates,
                      onPressed: () => _openTemplatePicker(context),
                    ),

                  // Image Adjustments
                  if (widget.config.enableAdjustments)
                    IconButton(
                      icon: Icon(Icons.tune, color: theme.primaryIconColor),
                      tooltip: strings.adjust,
                      onPressed: () => _handleAdjustPress(context),
                    ),

                  // Layer Manager
                  if (widget.config.enableLayers)
                    IconButton(
                      icon: Icon(
                        Icons.layers_outlined,
                        color: theme.primaryIconColor,
                      ),
                      tooltip: strings.layers,
                      onPressed: () => _openLayerManager(context),
                    ),

                  // Toggle Page Strip
                  if (widget.config.enablePageStrip)
                    IconButton(
                      icon: Icon(
                        Icons.view_carousel_outlined,
                        color:
                            _controller.state.showPageStrip
                                ? theme.accentColor
                                : theme.secondaryIconColor,
                      ),
                      tooltip: strings.togglePageStrip,
                      onPressed: _controller.togglePageStrip,
                    ),

                  // Toggle Timeline
                  if (widget.config.enableTimeline)
                    IconButton(
                      icon: Icon(
                        Icons.movie_filter_outlined,
                        color:
                            _controller.state.showTimeline
                                ? theme.accentColor
                                : theme.secondaryIconColor,
                      ),
                      tooltip: strings.timeline,
                      onPressed: _controller.toggleTimeline,
                    ),

                  // Save Draft
                  if (widget.config.enableDrafts)
                    IconButton(
                      icon: Icon(
                        Icons.bookmark_border,
                        color:
                            _controller.isDirty
                                ? Colors.amberAccent
                                : theme.secondaryIconColor,
                      ),
                      tooltip: strings.saveDraft,
                      onPressed: _handleSaveDraft,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Export button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text(strings.export),
            onPressed: _handleExport,
          ),
        ],
      ),
    );
  }

  void _openTextEditor(BuildContext context, [StoryElement? editingElement]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => RichTextEditorSheet(
            controller: _controller,
            editingElement: editingElement,
          ),
    );
  }

  void _openShapePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShapePickerSheet(controller: _controller),
    );
  }

  void _openStickerPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => StickerPickerSheet(
            controller: _controller,
            assetProvider: widget.config.assetProvider,
          ),
    );
  }

  void _openTemplatePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TemplatePickerSheet(controller: _controller),
    );
  }

  void _openLayerManager(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LayerManagerSheet(controller: _controller),
    );
  }

  void _openAnimationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnimationPickerSheet(controller: _controller),
    );
  }

  void _openAudioSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AudioSettingsSheet(controller: _controller),
    );
  }

  void _openCoverSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CoverPickerSheet(controller: _controller),
    );
  }

  void _handleAdjustPress(BuildContext context) {
    final targetId = _targetImageElementId;
    if (targetId != null) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => ImageAdjustmentSheet(
              controller: _controller,
              elementId: targetId,
            ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select or add an image to adjust filters.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showBackgroundPickerSheet(BuildContext context) {
    final theme = widget.config.theme;
    final strings = widget.config.strings;
    const presetNames = [
      'Sunset',
      'Ocean',
      'Neon',
      'Midnight',
      'Berry',
      'Forest',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.sheetBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  indicatorColor: theme.accentColor,
                  labelColor: theme.primaryIconColor,
                  unselectedLabelColor: theme.secondaryIconColor,
                  tabs: [
                    Tab(text: strings.gradients),
                    Tab(text: strings.solidColors),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Gradient Presets
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: StoryGradientBackground.presets.length,
                        itemBuilder: (context, index) {
                          final preset = StoryGradientBackground.presets[index];
                          final name =
                              index < presetNames.length
                                  ? presetNames[index]
                                  : 'Gradient ${index + 1}';
                          final isSelected =
                              _controller.activePage.backgroundGradient ==
                              preset;

                          return GestureDetector(
                            onTap: () {
                              _controller.setPageGradient(preset);
                              Navigator.of(ctx).pop();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: preset.toGradient(),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: theme.accentColor,
                                          width: 3,
                                        )
                                        : Border.all(
                                          color: Colors.white24,
                                          width: 1,
                                        ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Solid Colors
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            widget.config.availableColors.map((color) {
                              return GestureDetector(
                                onTap: () {
                                  _controller.setPageGradient(null);
                                  _controller.setPageBackground(color: color);
                                  Navigator.of(ctx).pop();
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white38,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSaveDraft() async {
    await _draftRepo.saveDraft(_controller.project);
    _controller.markSaved();
    widget.onSaveDraft?.call(_controller.project);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.config.strings.draftSaved),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      const exporter = StoryStillImageExporter();
      final results = await exporter.exportProject(_controller.project);
      widget.onExport?.call(results);
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
