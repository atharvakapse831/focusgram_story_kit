import 'package:flutter/material.dart';
import '../../models/element_payloads.dart';
import '../../models/story_element.dart';
import '../../models/story_transform.dart';
import '../editor_controller.dart';

/// Modal bottom sheet for composing and editing rich typography story elements.
class RichTextEditorSheet extends StatefulWidget {
  const RichTextEditorSheet({
    super.key,
    required this.controller,
    this.editingElement,
  });

  final EditorController controller;
  final StoryElement? editingElement;

  @override
  State<RichTextEditorSheet> createState() => _RichTextEditorSheetState();
}

class _RichTextEditorSheetState extends State<RichTextEditorSheet> {
  late final TextEditingController _textController;

  double _fontSize = 26.0;
  Color _textColor = Colors.white;
  Color? _backgroundColor;
  TextAlign _textAlign = TextAlign.center;
  bool _isBold = false;
  bool _isItalic = false;
  String? _fontFamily;

  Color? _outlineColor;
  double _outlineWidth = 0.0;
  Color? _shadowColor;
  double _shadowBlur = 0.0;

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

  static const List<String?> _fontFamilies = [
    null, // System default
    'Roboto',
    'Serif',
    'Monospace',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editingElement != null &&
        widget.editingElement!.payload is TextElementPayload) {
      final p = widget.editingElement!.payload as TextElementPayload;
      _textController = TextEditingController(text: p.text);
      _fontSize = p.fontSize;
      _textColor = p.textColor;
      _backgroundColor = p.backgroundColor;
      _textAlign = p.textAlign;
      _isBold = p.isBold;
      _isItalic = p.isItalic;
      _fontFamily = p.fontFamily;
      _outlineColor = p.outlineColor;
      _outlineWidth = p.outlineWidth;
      _shadowColor = p.shadowColor;
      _shadowBlur = p.shadowBlurRadius;
    } else {
      _textController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF222222),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action row
            Row(
              children: [
                const Text(
                  'Typography',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _handleSave,
                  child: Text(widget.editingElement != null ? 'Update' : 'Add'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Live Text Input Field
            TextField(
              controller: _textController,
              autofocus: true,
              maxLines: null,
              textAlign: _textAlign,
              style: TextStyle(
                fontSize: _fontSize,
                color: _textColor,
                fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                fontFamily: _fontFamily,
                backgroundColor: _backgroundColor,
              ),
              decoration: const InputDecoration(
                hintText: 'Type something...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),

            const Divider(color: Colors.white24),

            // Styling Toggles: Align, Bold, Italic, Pill, Outline, Shadow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Alignment cycle
                IconButton(
                  icon: Icon(
                    _textAlign == TextAlign.left
                        ? Icons.format_align_left
                        : _textAlign == TextAlign.center
                        ? Icons.format_align_center
                        : Icons.format_align_right,
                    color: Colors.white,
                  ),
                  tooltip: 'Text Alignment',
                  onPressed: () {
                    setState(() {
                      if (_textAlign == TextAlign.left) {
                        _textAlign = TextAlign.center;
                      } else if (_textAlign == TextAlign.center) {
                        _textAlign = TextAlign.right;
                      } else {
                        _textAlign = TextAlign.left;
                      }
                    });
                  },
                ),
                // Bold toggle
                IconButton(
                  icon: Icon(
                    Icons.format_bold,
                    color: _isBold ? Colors.blueAccent : Colors.white60,
                  ),
                  tooltip: 'Bold',
                  onPressed: () => setState(() => _isBold = !_isBold),
                ),
                // Italic toggle
                IconButton(
                  icon: Icon(
                    Icons.format_italic,
                    color: _isItalic ? Colors.blueAccent : Colors.white60,
                  ),
                  tooltip: 'Italic',
                  onPressed: () => setState(() => _isItalic = !_isItalic),
                ),
                // Background highlight pill toggle
                IconButton(
                  icon: Icon(
                    Icons.font_download,
                    color:
                        _backgroundColor != null
                            ? Colors.blueAccent
                            : Colors.white60,
                  ),
                  tooltip: 'Background Pill',
                  onPressed: () {
                    setState(() {
                      _backgroundColor =
                          _backgroundColor == null ? Colors.black87 : null;
                    });
                  },
                ),
                // Outline toggle
                IconButton(
                  icon: Icon(
                    Icons.border_color,
                    color:
                        _outlineWidth > 0 ? Colors.blueAccent : Colors.white60,
                  ),
                  tooltip: 'Outline',
                  onPressed: () {
                    setState(() {
                      if (_outlineWidth > 0) {
                        _outlineWidth = 0.0;
                        _outlineColor = null;
                      } else {
                        _outlineWidth = 2.0;
                        _outlineColor = Colors.black;
                      }
                    });
                  },
                ),
                // Shadow toggle
                IconButton(
                  icon: Icon(
                    Icons.wb_shade,
                    color: _shadowBlur > 0 ? Colors.blueAccent : Colors.white60,
                  ),
                  tooltip: 'Drop Shadow',
                  onPressed: () {
                    setState(() {
                      if (_shadowBlur > 0) {
                        _shadowBlur = 0.0;
                        _shadowColor = null;
                      } else {
                        _shadowBlur = 6.0;
                        _shadowColor = Colors.black87;
                      }
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Font Family Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _fontFamilies.map((font) {
                      final isSelected = _fontFamily == font;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(font ?? 'Default'),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _fontFamily = font),
                        ),
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Color Palette
            Row(
              children:
                  _palette.map((color) {
                    final isSelected =
                        _textColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () => setState(() => _textColor = color),
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
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final newPayload = TextElementPayload(
      text: text,
      fontSize: _fontSize,
      textColor: _textColor,
      backgroundColor: _backgroundColor,
      textAlign: _textAlign,
      isBold: _isBold,
      isItalic: _isItalic,
      fontFamily: _fontFamily,
      outlineColor: _outlineColor,
      outlineWidth: _outlineWidth,
      shadowColor: _shadowColor,
      shadowBlurRadius: _shadowBlur,
      shadowOffsetX: _shadowBlur > 0 ? 2.0 : 0.0,
      shadowOffsetY: _shadowBlur > 0 ? 3.0 : 0.0,
    );

    if (widget.editingElement != null) {
      widget.controller.updateElementPayload(
        widget.editingElement!.id,
        newPayload,
      );
    } else {
      final element = StoryElement(
        id: 'text_${DateTime.now().millisecondsSinceEpoch}',
        type: StoryElementType.text,
        transform: const StoryTransform(
          x: 0.5,
          y: 0.5,
          width: 0.75,
          height: 0.16,
        ),
        payload: newPayload,
      );
      widget.controller.addElement(element);
    }

    Navigator.of(context).pop();
  }
}
