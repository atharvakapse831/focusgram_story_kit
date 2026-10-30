import 'package:flutter/material.dart';
import '../draft/draft_repository.dart';
import '../draft/in_memory_draft_repository.dart';
import '../export/export_result.dart';
import '../export/still_image_exporter.dart';
import '../models/element_payloads.dart';
import '../models/story_element.dart';
import '../models/story_project.dart';
import '../models/story_transform.dart';
import 'canvas/story_editor_canvas.dart';
import 'canvas/story_page_strip.dart';
import 'editor_controller.dart';

/// Configuration options for the [StoryKitEditor] UI.
@immutable
class StoryKitEditorConfig {
  const StoryKitEditorConfig({
    this.enablePageStrip = true,
    this.enableUndoRedo = true,
    this.enableDrafts = true,
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
  final List<Color> availableColors;
}

/// The top-level FocusGram story editor screen widget.
///
/// Coordinates document state, history, canvas manipulation, page management,
/// draft persistence, and deterministic raster export.
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

  /// Feature toggles and color palettes.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                // 1. Main Column: Top bar + Canvas + Page Strip
                Column(
                  children: [
                    _buildTopBar(context),
                    Expanded(child: StoryEditorCanvas(controller: _controller)),
                    if (widget.config.enablePageStrip &&
                        _controller.state.showPageStrip)
                      StoryPageStrip(controller: _controller),
                  ],
                ),

                // 2. Exporting progress modal overlay
                if (_isExporting)
                  Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Exporting story...',
                          style: TextStyle(color: Colors.white, fontSize: 14),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.black87,
      child: Row(
        children: [
          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close Editor',
            onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
          ),

          const Spacer(),

          // Undo / Redo
          if (widget.config.enableUndoRedo) ...[
            IconButton(
              icon: Icon(
                Icons.undo,
                color: _controller.canUndo ? Colors.white : Colors.white24,
              ),
              tooltip: 'Undo',
              onPressed: _controller.canUndo ? _controller.undo : null,
            ),
            IconButton(
              icon: Icon(
                Icons.redo,
                color: _controller.canRedo ? Colors.white : Colors.white24,
              ),
              tooltip: 'Redo',
              onPressed: _controller.canRedo ? _controller.redo : null,
            ),
          ],

          // Add Text
          IconButton(
            icon: const Icon(Icons.title, color: Colors.white),
            tooltip: 'Add Text',
            onPressed: () => _showAddTextDialog(context),
          ),

          // Add Sticker
          IconButton(
            icon: const Icon(
              Icons.sentiment_satisfied_alt,
              color: Colors.white,
            ),
            tooltip: 'Add Sticker',
            onPressed: () => _addSampleSticker(),
          ),

          // Change Background
          IconButton(
            icon: const Icon(Icons.palette_outlined, color: Colors.white),
            tooltip: 'Change Background',
            onPressed: () => _showBackgroundColorSheet(context),
          ),

          // Toggle Page Strip
          if (widget.config.enablePageStrip)
            IconButton(
              icon: Icon(
                Icons.view_carousel_outlined,
                color:
                    _controller.state.showPageStrip
                        ? Colors.blueAccent
                        : Colors.white60,
              ),
              tooltip: 'Toggle Page Strip',
              onPressed: _controller.togglePageStrip,
            ),

          // Save Draft
          if (widget.config.enableDrafts)
            IconButton(
              icon: Icon(
                Icons.bookmark_border,
                color:
                    _controller.isDirty ? Colors.amberAccent : Colors.white60,
              ),
              tooltip: 'Save Draft',
              onPressed: _handleSaveDraft,
            ),

          const SizedBox(width: 4),

          // Export Done button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Export'),
            onPressed: _handleExport,
          ),
        ],
      ),
    );
  }

  void _showAddTextDialog(BuildContext context) {
    final textController = TextEditingController();
    Color selectedColor = Colors.white;
    Color? backgroundColor;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF222222),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    autofocus: true,
                    style: TextStyle(
                      color: selectedColor,
                      backgroundColor: backgroundColor,
                      fontSize: 20,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Type your story text...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Toggle background pill
                      IconButton(
                        icon: Icon(
                          Icons.font_download,
                          color:
                              backgroundColor != null
                                  ? Colors.blueAccent
                                  : Colors.white60,
                        ),
                        onPressed: () {
                          setSheetState(() {
                            backgroundColor =
                                backgroundColor == null ? Colors.black87 : null;
                          });
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          final text = textController.text.trim();
                          if (text.isNotEmpty) {
                            final element = StoryElement(
                              id: 'el_${DateTime.now().millisecondsSinceEpoch}',
                              type: StoryElementType.text,
                              transform: const StoryTransform(
                                x: 0.5,
                                y: 0.5,
                                width: 0.7,
                                height: 0.15,
                              ),
                              payload: TextElementPayload(
                                text: text,
                                textColor: selectedColor,
                                backgroundColor: backgroundColor,
                              ),
                            );
                            _controller.addElement(element);
                          }
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addSampleSticker() {
    final element = StoryElement(
      id: 'el_${DateTime.now().millisecondsSinceEpoch}',
      type: StoryElementType.sticker,
      transform: const StoryTransform(x: 0.5, y: 0.4, width: 0.3, height: 0.15),
      payload: const StickerElementPayload(
        stickerId: 'star_1',
        assetUri: '',
        label: 'Star',
      ),
    );
    _controller.addElement(element);
  }

  void _showBackgroundColorSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF222222),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Canvas Background Color',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    widget.config.availableColors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          _controller.setPageBackground(color: color);
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white38, width: 2),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
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
        const SnackBar(
          content: Text('Draft saved successfully'),
          duration: Duration(seconds: 2),
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
