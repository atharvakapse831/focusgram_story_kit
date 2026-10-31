import 'package:flutter/material.dart';
import '../../models/story_template.dart';
import '../editor_controller.dart';

/// Modal bottom sheet for choosing and applying pre-designed story templates.
class TemplatePickerSheet extends StatelessWidget {
  const TemplatePickerSheet({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final templates = StoryTemplate.presets;

    return Material(
      color: const Color(0xFF222222),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Story Templates',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              itemCount: templates.length,
              separatorBuilder:
                  (_, __) => const Divider(color: Colors.white12, height: 16),
              itemBuilder: (context, index) {
                final tpl = templates[index];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.white.withAlpha(10),
                  title: Text(
                    tpl.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    tpl.description,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  trailing: Chip(
                    label: Text(
                      tpl.category,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: Colors.blueAccent.withAlpha(120),
                  ),
                  onTap: () {
                    controller.applyTemplate(tpl);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
