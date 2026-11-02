import 'package:flutter/material.dart';
import '../../models/element_payloads.dart';
import '../editor_controller.dart';

/// Modal sheet for tweaking non-destructive image adjustments and filters.
class ImageAdjustmentSheet extends StatefulWidget {
  const ImageAdjustmentSheet({
    super.key,
    required this.controller,
    required this.elementId,
  });

  final EditorController controller;
  final String elementId;

  @override
  State<ImageAdjustmentSheet> createState() => _ImageAdjustmentSheetState();
}

class _ImageAdjustmentSheetState extends State<ImageAdjustmentSheet> {
  late ImageAdjustments _current;

  @override
  void initState() {
    super.initState();
    final el = widget.controller.activePage.getElement(widget.elementId);
    if (el != null && el.payload is ImageElementPayload) {
      _current = (el.payload as ImageElementPayload).adjustments;
    } else {
      _current = ImageAdjustments.identity;
    }
  }

  void _apply(ImageAdjustments newAdjustments) {
    setState(() => _current = newAdjustments);
    widget.controller.updateImageAdjustments(widget.elementId, newAdjustments);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF222222),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Image Adjustments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _apply(ImageAdjustments.identity),
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Flip Actions
            Row(
              children: [
                const Text(
                  'Orientation:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    Icons.flip,
                    color:
                        _current.isFlippedHorizontally
                            ? Colors.blueAccent
                            : Colors.white60,
                  ),
                  tooltip: 'Flip Horizontal',
                  onPressed: () {
                    _apply(
                      _current.copyWith(
                        isFlippedHorizontally: !_current.isFlippedHorizontally,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.flip,
                    color:
                        _current.isFlippedVertically
                            ? Colors.blueAccent
                            : Colors.white60,
                  ),
                  tooltip: 'Flip Vertical',
                  onPressed: () {
                    _apply(
                      _current.copyWith(
                        isFlippedVertically: !_current.isFlippedVertically,
                      ),
                    );
                  },
                ),
              ],
            ),

            const Divider(color: Colors.white24),

            // Filter Preset Chips
            const Text('Filters', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    ImageFilterPreset.values.map((preset) {
                      final isSelected = _current.filterPreset == preset;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(preset.name.toUpperCase()),
                          selected: isSelected,
                          onSelected: (_) {
                            _apply(_current.copyWith(filterPreset: preset));
                          },
                        ),
                      );
                    }).toList(),
              ),
            ),

            const Divider(color: Colors.white24),

            // Brightness Slider
            _buildSliderRow(
              label: 'Brightness',
              value: _current.brightness,
              min: -1.0,
              max: 1.0,
              onChanged: (v) => _apply(_current.copyWith(brightness: v)),
            ),

            // Contrast Slider
            _buildSliderRow(
              label: 'Contrast',
              value: _current.contrast,
              min: 0.0,
              max: 2.0,
              onChanged: (v) => _apply(_current.copyWith(contrast: v)),
            ),

            // Saturation Slider
            _buildSliderRow(
              label: 'Saturation',
              value: _current.saturation,
              min: 0.0,
              max: 2.0,
              onChanged: (v) => _apply(_current.copyWith(saturation: v)),
            ),

            // Warmth Slider
            _buildSliderRow(
              label: 'Warmth',
              value: _current.warmth,
              min: -1.0,
              max: 1.0,
              onChanged: (v) => _apply(_current.copyWith(warmth: v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              activeColor: Colors.blueAccent,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
