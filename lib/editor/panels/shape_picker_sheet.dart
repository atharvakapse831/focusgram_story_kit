import 'package:flutter/material.dart';
import '../../models/element_payloads.dart';
import '../../models/shape_payload.dart';
import '../../models/story_element.dart';
import '../../models/story_transform.dart';
import '../editor_controller.dart';

/// Modal bottom sheet for choosing and customizing geometric vector shapes.
class ShapePickerSheet extends StatefulWidget {
  const ShapePickerSheet({super.key, required this.controller});

  final EditorController controller;

  @override
  State<ShapePickerSheet> createState() => _ShapePickerSheetState();
}

class _ShapePickerSheetState extends State<ShapePickerSheet> {
  ShapeType _selectedType = ShapeType.rectangle;
  Color _strokeColor = Colors.white;
  Color? _fillColor;
  final double _strokeWidth = 3.0;

  static const List<Color> _palette = [
    Colors.white,
    Colors.yellow,
    Colors.orange,
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.cyanAccent,
    Colors.greenAccent,
    Colors.black,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF222222),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Shapes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Shape'),
                onPressed: _handleAddShape,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Shape Type Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShapeTypeButton(
                ShapeType.rectangle,
                Icons.crop_square,
                'Rect',
              ),
              _buildShapeTypeButton(
                ShapeType.circle,
                Icons.circle_outlined,
                'Circle',
              ),
              _buildShapeTypeButton(ShapeType.star, Icons.star_border, 'Star'),
              _buildShapeTypeButton(
                ShapeType.heart,
                Icons.favorite_border,
                'Heart',
              ),
              _buildShapeTypeButton(
                ShapeType.line,
                Icons.horizontal_rule,
                'Line',
              ),
              _buildShapeTypeButton(
                ShapeType.arrow,
                Icons.arrow_right_alt,
                'Arrow',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stroke Color Palette
          const Text(
            'Stroke Color',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children:
                _palette.map((color) {
                  final isSelected =
                      _strokeColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _strokeColor = color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 28,
                      height: 28,
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

          const SizedBox(height: 16),

          // Fill Color Options
          Row(
            children: [
              const Text(
                'Fill Color:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('None'),
                selected: _fillColor == null,
                onSelected: (_) => setState(() => _fillColor = null),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Fill'),
                selected: _fillColor != null,
                onSelected:
                    (_) => setState(
                      () => _fillColor = _strokeColor.withAlpha(120),
                    ),
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildShapeTypeButton(ShapeType type, IconData icon, String label) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddShape() {
    final element = StoryElement(
      id: 'shape_${DateTime.now().millisecondsSinceEpoch}',
      type: StoryElementType.shape,
      transform: const StoryTransform(x: 0.5, y: 0.5, width: 0.35, height: 0.2),
      payload: ShapeElementPayload(
        shapeType: _selectedType,
        strokeColor: _strokeColor,
        strokeWidth: _strokeWidth,
        fillColor: _fillColor,
        cornerRadius: 12.0,
      ),
    );

    widget.controller.addElement(element);
    Navigator.of(context).pop();
  }
}
