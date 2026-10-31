import 'package:flutter/material.dart';
import '../editor_controller.dart';

/// Modal bottom sheet for choosing the still-image cover frame timestamp from video.
class CoverPickerSheet extends StatefulWidget {
  const CoverPickerSheet({super.key, required this.controller});

  final EditorController controller;

  static Future<void> show(BuildContext context, EditorController controller) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CoverPickerSheet(controller: controller),
    );
  }

  @override
  State<CoverPickerSheet> createState() => _CoverPickerSheetState();
}

class _CoverPickerSheetState extends State<CoverPickerSheet> {
  late Duration _selectedTimestamp;

  @override
  void initState() {
    super.initState();
    final page = widget.controller.activePage;
    _selectedTimestamp =
        page.coverTimestamp ?? page.videoTrimRange?.start ?? Duration.zero;
  }

  String _formatTimestamp(Duration d) {
    final s = d.inSeconds.remainder(60);
    final ms = (d.inMilliseconds.remainder(1000) ~/ 100);
    return '$s.${ms}s';
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.controller.activePage;
    final totalMs = page.duration.inMilliseconds;
    const slices = 7;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                'Select Story Cover Frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.controller.setCoverTimestamp(_selectedTimestamp);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cover Timestamp: ${_formatTimestamp(_selectedTimestamp)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Thumbnail frames strip
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: slices,
              itemBuilder: (context, i) {
                final sliceMs =
                    totalMs > 0 ? (totalMs * (i / (slices - 1))).toInt() : 0;
                final sliceDuration = Duration(milliseconds: sliceMs);
                final isSelected =
                    (_selectedTimestamp.inMilliseconds - sliceMs).abs() < 500;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedTimestamp = sliceDuration);
                    widget.controller.timelineController.seekTo(
                      sliceDuration,
                      exact: true,
                    );
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.white24,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          color: isSelected ? Colors.amber : Colors.white54,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(sliceDuration),
                          style: TextStyle(
                            color: isSelected ? Colors.amber : Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
