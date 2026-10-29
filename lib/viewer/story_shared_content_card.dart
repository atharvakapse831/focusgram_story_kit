import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/story_shared_content.dart';

/// A card widget rendering shared content inside the story viewer.
///
/// Designed to visually present shared image/video posts, shorts, long videos,
/// articles, and notes with author attribution, thumbnail preview, badge,
/// and tap-to-open action.
class StorySharedContentCard extends StatelessWidget {
  final StorySharedContent content;
  final VoidCallback? onTap;

  const StorySharedContentCard({super.key, required this.content, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xEE1E1E24), // High-opacity dark card background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top author bar + Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  ClipOval(
                    child:
                        content.authorAvatarUrl.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: content.authorAvatarUrl,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => _fallbackAvatar(),
                            )
                            : _fallbackAvatar(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      content.authorUsername.isNotEmpty
                          ? '@${content.authorUsername.replaceAll('@', '')}'
                          : (content.authorName.isNotEmpty
                              ? content.authorName
                              : 'Shared Content'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildTypeBadge(),
                ],
              ),
            ),

            // Thumbnail preview (if available)
            if (content.thumbnailUrl.isNotEmpty)
              Container(
                height: 140,
                width: double.infinity,
                color: const Color(0xFF121216),
                child: CachedNetworkImage(
                  imageUrl: content.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder:
                      (_, _) => const ColoredBox(color: Color(0xFF2A2A32)),
                  errorWidget:
                      (_, _, _) => Container(
                        color: const Color(0xFF24242C),
                        alignment: Alignment.center,
                        child: _fallbackThumbnailIcon(),
                      ),
                ),
              ),

            // Title & Description
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (content.title.isNotEmpty)
                    Text(
                      content.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.25,
                      ),
                    ),
                  if (content.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      content.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.35,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action bar at bottom ("Tap to open →")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap to open',
                    style: TextStyle(
                      color: Color(0xFF3897F0), // Standard focus/action blue
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFF3897F0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    final badgeColor = _resolveBadgeColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        content.badgeText.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _resolveBadgeColor() {
    switch (content.type) {
      case StoryKitContentType.shortVideo:
      case StoryKitContentType.longVideo:
      case StoryKitContentType.videoPost:
        return const Color(0xFFFF007F); // Vibrant pink/magenta
      case StoryKitContentType.note:
        return const Color(0xFF00E676); // Emerald accent
      case StoryKitContentType.article:
        return const Color(0xFFFFB300); // Amber/gold
      case StoryKitContentType.imagePost:
        return const Color(0xFF3897F0); // Focus blue
      case StoryKitContentType.unknown:
        return const Color(0xFF9E9E9E); // Muted grey
    }
  }

  Widget _fallbackAvatar() {
    return Container(
      width: 24,
      height: 24,
      color: const Color(0xFF2C2C36),
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 14, color: Colors.white70),
    );
  }

  Widget _fallbackThumbnailIcon() {
    IconData icon;
    switch (content.type) {
      case StoryKitContentType.note:
        icon = Icons.code_rounded;
      case StoryKitContentType.article:
        icon = Icons.article_rounded;
      case StoryKitContentType.shortVideo:
      case StoryKitContentType.longVideo:
      case StoryKitContentType.videoPost:
        icon = Icons.play_arrow_rounded;
      case StoryKitContentType.imagePost:
      case StoryKitContentType.unknown:
        icon = Icons.image_rounded;
    }
    return Icon(icon, color: Colors.white38, size: 36);
  }
}
