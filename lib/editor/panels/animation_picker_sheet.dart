import 'package:flutter/material.dart';
import '../../models/overlay_animation.dart';
import '../editor_controller.dart';

/// Modal bottom sheet for configuring layer time ranges and entrance/exit motion animations.
class AnimationPickerSheet extends StatefulWidget {
  const AnimationPickerSheet({super.key, required this.controller});

  final EditorController controller;

  static Future<void> show(BuildContext context, EditorController controller) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AnimationPickerSheet(controller: controller),
    );
  }

  @override
  State<AnimationPickerSheet> createState() => _AnimationPickerSheetState();
}

class _AnimationPickerSheetState extends State<AnimationPickerSheet> {
  late OverlayAnimationType _entrance;
  late int _entranceMs;
  late OverlayAnimationType _exit;
  late int _exitMs;
  late String _curve;
  late double _startSec;
  late double _endSec;

  @override
  void initState() {
    super.initState();
    final element = widget.controller.selectedElement;
    final anim = element?.animation ?? const OverlayAnimationConfig();
    final pageDurationSec =
        widget.controller.activePage.duration.inMilliseconds / 1000.0;
    final range = element?.visibleTimeRange;

    _entrance = anim.entranceType;
    _entranceMs = anim.entranceDuration.inMilliseconds;
    _exit = anim.exitType;
    _exitMs = anim.exitDuration.inMilliseconds;
    _curve = anim.curveName;
    _startSec = (range?.start.inMilliseconds ?? 0) / 1000.0;
    _endSec =
        (range?.end.inMilliseconds ??
            widget.controller.activePage.duration.inMilliseconds) /
        1000.0;
    if (_endSec > pageDurationSec) _endSec = pageDurationSec;
  }

  void _applyChanges() {
    final el = widget.controller.selectedElement;
    if (el == null) return;

    final anim = OverlayAnimationConfig(
      entranceType: _entrance,
      entranceDuration: Duration(milliseconds: _entranceMs),
      exitType: _exit,
      exitDuration: Duration(milliseconds: _exitMs),
      curveName: _curve,
    );

    final range = LayerTimeRange(
      start: Duration(milliseconds: (_startSec * 1000).toInt()),
      end: Duration(milliseconds: (_endSec * 1000).toInt()),
    );

    widget.controller.setElementAnimation(el.id, anim);
    widget.controller.setElementTimeRange(el.id, range);
  }

  @override
  Widget build(BuildContext context) {
    final el = widget.controller.selectedElement;
    final maxSec =
        widget.controller.activePage.duration.inMilliseconds / 1000.0;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child:
          el == null
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Select an element to configure animations and timing',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Layer Timing & Animation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _applyChanges();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 1. Visible time range sliders
                    Text(
                      'Visible Range: ${_startSec.toStringAsFixed(1)}s - ${_endSec.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    RangeSlider(
                      values: RangeValues(
                        _startSec.clamp(0.0, maxSec),
                        _endSec.clamp(0.0, maxSec),
                      ),
                      min: 0.0,
                      max: maxSec > 0 ? maxSec : 1.0,
                      activeColor: Colors.amber,
                      inactiveColor: Colors.white24,
                      onChanged: (vals) {
                        setState(() {
                          _startSec = vals.start;
                          _endSec = vals.end;
                        });
                      },
                    ),

                    const Divider(color: Colors.white24, height: 24),

                    // 2. Entrance Animation
                    const Text(
                      'Entrance Transition',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Wrap(
                      spacing: 8,
                      children:
                          OverlayAnimationType.values.map((type) {
                            final isSelected = _entrance == type;
                            return ChoiceChip(
                              label: Text(type.name),
                              selected: isSelected,
                              onSelected:
                                  (_) => setState(() => _entrance = type),
                              selectedColor: Colors.amber,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                    ),
                    Row(
                      children: [
                        Text(
                          'Duration: ${_entranceMs}ms',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _entranceMs.toDouble(),
                            min: 100,
                            max: 1500,
                            divisions: 14,
                            activeColor: Colors.amber,
                            onChanged:
                                (val) =>
                                    setState(() => _entranceMs = val.toInt()),
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Colors.white24, height: 24),

                    // 3. Exit Animation
                    const Text(
                      'Exit Transition',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Wrap(
                      spacing: 8,
                      children:
                          OverlayAnimationType.values.map((type) {
                            final isSelected = _exit == type;
                            return ChoiceChip(
                              label: Text(type.name),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _exit = type),
                              selectedColor: Colors.amber,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                    ),
                    Row(
                      children: [
                        Text(
                          'Duration: ${_exitMs}ms',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _exitMs.toDouble(),
                            min: 100,
                            max: 1500,
                            divisions: 14,
                            activeColor: Colors.amber,
                            onChanged:
                                (val) => setState(() => _exitMs = val.toInt()),
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Colors.white24, height: 24),

                    // 4. Easing Curve
                    const Text(
                      'Motion Easing Curve',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Wrap(
                      spacing: 8,
                      children:
                          [
                            'easeInOut',
                            'easeIn',
                            'easeOut',
                            'bounceOut',
                            'elasticOut',
                            'linear',
                          ].map((curve) {
                            final isSelected = _curve == curve;
                            return ChoiceChip(
                              label: Text(curve),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _curve = curve),
                              selectedColor: Colors.amber,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
    );
  }
}
