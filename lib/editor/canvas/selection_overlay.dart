import 'package:flutter/material.dart';

/// Renders bounding chrome, resize handles, and action buttons for the selected element.
class StorySelectionOverlay extends StatelessWidget {
  const StorySelectionOverlay({
    super.key,
    required this.size,
    required this.onDelete,
    this.onBringForward,
    this.onSendBackward,
  });

  final Size size;
  final VoidCallback onDelete;
  final VoidCallback? onBringForward;
  final VoidCallback? onSendBackward;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bounding outline
        Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        // Corner handles
        _buildCornerHandle(top: -4, left: -4),
        _buildCornerHandle(top: -4, right: -4),
        _buildCornerHandle(bottom: -4, left: -4),
        _buildCornerHandle(bottom: -4, right: -4),

        // Action toolbar above element
        Positioned(
          top: -42,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onBringForward != null)
                    _buildActionButton(
                      icon: Icons.flip_to_front,
                      tooltip: 'Bring Forward',
                      onPressed: onBringForward!,
                    ),
                  if (onSendBackward != null)
                    _buildActionButton(
                      icon: Icons.flip_to_back,
                      tooltip: 'Send Backward',
                      onPressed: onSendBackward!,
                    ),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete',
                    color: Colors.redAccent,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerHandle({
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return IconButton(
      icon: Icon(icon, size: 16, color: color),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      onPressed: onPressed,
    );
  }
}
