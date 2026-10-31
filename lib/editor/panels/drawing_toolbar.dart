import 'package:flutter/material.dart';
import '../../models/drawing_stroke.dart';
import '../editor_controller.dart';
import '../editor_state.dart';

/// Floating toolbar displayed during active freehand drawing mode.
class DrawingToolbar extends StatelessWidget {
  const DrawingToolbar({
    super.key,
    required this.controller,
    required this.onDone,
  });

  final EditorController controller;
  final VoidCallback onDone;

  static const List<Color> _palette = [
    Colors.white,
    Color(0xFFFFEB3B),
    Color(0xFFFF5722),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00E5FF),
    Color(0xFF00E676),
    Colors.black,
  ];

  @override
  Widget build(BuildContext context) {
    final state = controller.state;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xEE1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Brush types + Actions row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBrushChip(
                icon: Icons.edit,
                tooltip: 'Pen',
                type: DrawingBrushType.pen,
                activeType: state.activeBrushType,
              ),
              const SizedBox(width: 8),
              _buildBrushChip(
                icon: Icons.brush,
                tooltip: 'Marker',
                type: DrawingBrushType.marker,
                activeType: state.activeBrushType,
              ),
              const SizedBox(width: 8),
              _buildBrushChip(
                icon: Icons.auto_awesome,
                tooltip: 'Neon',
                type: DrawingBrushType.neon,
                activeType: state.activeBrushType,
              ),
              const SizedBox(width: 8),
              _buildBrushChip(
                icon: Icons.cleaning_services,
                tooltip: 'Eraser',
                type: DrawingBrushType.eraser,
                activeType: state.activeBrushType,
              ),
              const SizedBox(width: 16),
              // Undo
              IconButton(
                icon: Icon(
                  Icons.undo,
                  color: controller.canUndo ? Colors.white : Colors.white24,
                  size: 20,
                ),
                tooltip: 'Undo Stroke',
                onPressed: controller.canUndo ? controller.undo : null,
              ),
              // Clear drawing
              IconButton(
                icon: const Icon(
                  Icons.delete_sweep,
                  color: Colors.redAccent,
                  size: 20,
                ),
                tooltip: 'Clear Drawing',
                onPressed: () {
                  final targetId = 'drawing_${controller.activePage.id}';
                  controller.clearDrawing(targetId);
                },
              ),
              const SizedBox(width: 8),
              // Done button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  controller.setTool(EditorTool.select);
                  onDone();
                },
                child: const Text('Done'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 2. Color palette row
          if (state.activeBrushType != DrawingBrushType.eraser)
            Row(
              mainAxisSize: MainAxisSize.min,
              children:
                  _palette.map((color) {
                    final isSelected =
                        state.activeBrushColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap:
                          () => controller.setBrushSettings(brushColor: color),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? Colors.blueAccent : Colors.white38,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBrushChip({
    required IconData icon,
    required String tooltip,
    required DrawingBrushType type,
    required DrawingBrushType activeType,
  }) {
    final isSelected = type == activeType;
    return InkWell(
      onTap: () => controller.setBrushSettings(brushType: type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.blueAccent.withAlpha(180)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
