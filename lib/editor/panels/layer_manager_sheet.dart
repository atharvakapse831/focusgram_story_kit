import 'package:flutter/material.dart';
import '../../models/element_payloads.dart';
import '../../models/story_element.dart';
import '../editor_controller.dart';

/// Modal bottom sheet for inspecting, reordering, locking, and hiding story layers.
class LayerManagerSheet extends StatelessWidget {
  const LayerManagerSheet({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.activePage;
        final elements = page.sortedElements.reversed.toList();
        final selectedId = controller.state.selectedElementId;

        return Material(
          color: const Color(0xFF222222),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.55,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Layers & Order',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${elements.length} layers',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const Divider(color: Colors.white24),

                Expanded(
                  child:
                      elements.isEmpty
                          ? const Center(
                            child: Text(
                              'No layers on this page',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                          : ListView.separated(
                            itemCount: elements.length,
                            separatorBuilder:
                                (_, __) => const Divider(
                                  color: Colors.white12,
                                  height: 1,
                                ),
                            itemBuilder: (context, index) {
                              final el = elements[index];
                              final isSelected = el.id == selectedId;

                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: Colors.blueAccent.withAlpha(
                                  60,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                onTap: () {
                                  controller.selectElement(el.id);
                                },
                                leading: Icon(
                                  _getElementIcon(el),
                                  color:
                                      el.isVisible
                                          ? Colors.white
                                          : Colors.white38,
                                ),
                                title: Text(
                                  _getElementTitle(el),
                                  style: TextStyle(
                                    color:
                                        el.isVisible
                                            ? Colors.white
                                            : Colors.white38,
                                    fontSize: 14,
                                    decoration:
                                        el.isVisible
                                            ? null
                                            : TextDecoration.lineThrough,
                                  ),
                                ),
                                subtitle: Text(
                                  'z: ${el.zIndex}',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Lock toggle
                                    IconButton(
                                      icon: Icon(
                                        el.isLocked
                                            ? Icons.lock
                                            : Icons.lock_open,
                                        color:
                                            el.isLocked
                                                ? Colors.amberAccent
                                                : Colors.white38,
                                        size: 18,
                                      ),
                                      tooltip:
                                          el.isLocked
                                              ? 'Unlock Layer'
                                              : 'Lock Layer',
                                      onPressed:
                                          () => controller.toggleElementLock(
                                            el.id,
                                          ),
                                    ),
                                    // Visibility toggle
                                    IconButton(
                                      icon: Icon(
                                        el.isVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color:
                                            el.isVisible
                                                ? Colors.white70
                                                : Colors.white24,
                                        size: 18,
                                      ),
                                      tooltip:
                                          el.isVisible
                                              ? 'Hide Layer'
                                              : 'Show Layer',
                                      onPressed:
                                          () => controller
                                              .toggleElementVisibility(el.id),
                                    ),
                                    // Bring forward
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_upward,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                      tooltip: 'Bring Forward',
                                      onPressed:
                                          () => controller.bringForward(el.id),
                                    ),
                                    // Send backward
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_downward,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                      tooltip: 'Send Backward',
                                      onPressed:
                                          () => controller.sendBackward(el.id),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getElementIcon(StoryElement el) {
    switch (el.type) {
      case StoryElementType.text:
        return Icons.title;
      case StoryElementType.image:
        return Icons.image;
      case StoryElementType.sticker:
        return Icons.sentiment_satisfied_alt;
      case StoryElementType.card:
        return Icons.web_stories;
      case StoryElementType.drawing:
        return Icons.gesture;
      case StoryElementType.shape:
        return Icons.category;
      case StoryElementType.video:
        return Icons.videocam;
      case StoryElementType.unknown:
        return Icons.help_outline;
    }
  }

  String _getElementTitle(StoryElement el) {
    final payload = el.payload;
    if (payload is TextElementPayload) {
      final t = payload.text;
      return t.length > 20 ? '${t.substring(0, 18)}...' : t;
    } else if (payload is StickerElementPayload) {
      return payload.label ?? 'Sticker';
    } else if (payload is ShapeElementPayload) {
      return 'Shape: ${payload.shapeType.name}';
    } else if (payload is CardElementPayload) {
      return 'Card: ${payload.sharedContent.title}';
    } else if (payload is DrawingElementPayload) {
      return 'Drawing (${payload.strokes.length} strokes)';
    } else if (payload is VideoElementPayload) {
      return 'Video Layer';
    } else if (payload is ImageElementPayload) {
      return 'Image Layer';
    }
    return el.type.name;
  }
}
