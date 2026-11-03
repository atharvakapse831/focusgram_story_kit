import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/story_media_asset.dart';
import '../../models/story_page.dart';
import '../editor_controller.dart';

/// Bottom thumbnail navigation bar showing all pages, add page, duplicate, and delete.
class StoryPageStrip extends StatelessWidget {
  const StoryPageStrip({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pages = controller.project.pages;
        final activePageId = controller.state.activePageId;
        final activeIndex = pages.indexWhere((p) => p.id == activePageId);

        return Container(
          height: 100,
          color: Colors.black.withAlpha(220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Reorderable thumbnails
              Expanded(
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  itemCount: pages.length,
                  // ignore: deprecated_member_use
                  onReorder: (oldIndex, newIndex) {
                    final target =
                        newIndex > oldIndex ? newIndex - 1 : newIndex;
                    controller.reorderPage(oldIndex, target);
                  },
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    final isSelected = page.id == activePageId;

                    return ReorderableDragStartListener(
                      key: ValueKey(page.id),
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildPageThumbnail(
                          context,
                          page: page,
                          index: index,
                          isSelected: isSelected,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),
              const VerticalDivider(color: Colors.white24, width: 1),
              const SizedBox(width: 8),

              // Page controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Move left button
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: activeIndex > 0 ? Colors.white : Colors.white24,
                    ),
                    tooltip: 'Move Left',
                    onPressed:
                        activeIndex > 0
                            ? () => controller.reorderPage(
                              activeIndex,
                              activeIndex - 1,
                            )
                            : null,
                  ),

                  // Move right button
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color:
                          activeIndex >= 0 && activeIndex < pages.length - 1
                              ? Colors.white
                              : Colors.white24,
                    ),
                    tooltip: 'Move Right',
                    onPressed:
                        activeIndex >= 0 && activeIndex < pages.length - 1
                            ? () => controller.reorderPage(
                              activeIndex,
                              activeIndex + 1,
                            )
                            : null,
                  ),

                  // Add Page button
                  IconButton(
                    icon: const Icon(Icons.add_to_photos, color: Colors.white),
                    tooltip: 'Add Page',
                    onPressed: controller.addPage,
                  ),

                  // Duplicate Page button
                  IconButton(
                    icon: const Icon(Icons.content_copy, color: Colors.white),
                    tooltip: 'Duplicate Active Page',
                    onPressed: controller.duplicateActivePage,
                  ),

                  // Delete Page button (disabled if only 1 page)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color:
                          pages.length > 1 ? Colors.redAccent : Colors.white24,
                    ),
                    tooltip: 'Delete Active Page',
                    onPressed:
                        pages.length > 1 ? controller.deleteActivePage : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageThumbnail(
    BuildContext context, {
    required StoryPage page,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => controller.selectPage(page.id),
      child: Container(
        width: 50,
        decoration: BoxDecoration(
          color: page.backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.white30,
            width: isSelected ? 2.5 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background preview
            if (page.backgroundAsset != null)
              _buildBackgroundThumbnail(page.backgroundAsset!),

            // Element count indicator
            if (page.elements.isNotEmpty)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${page.elements.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
              ),

            // Page index badge
            Positioned(
              bottom: 2,
              left: 4,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundThumbnail(StoryMediaAsset asset) {
    switch (asset.sourceType) {
      case StoryMediaSourceType.file:
        return Image.file(File(asset.uri), fit: BoxFit.cover);
      case StoryMediaSourceType.asset:
        return Image.asset(asset.uri, fit: BoxFit.cover);
      case StoryMediaSourceType.network:
      case StoryMediaSourceType.memory:
        if (asset.uri.isEmpty) return const SizedBox.shrink();
        return CachedNetworkImage(
          imageUrl: asset.uri,
          fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox.shrink(),
          errorWidget: (_, __, ___) => const SizedBox.shrink(),
        );
    }
  }
}
