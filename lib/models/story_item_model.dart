import '../overlays/story_overlay.dart';

/// Media type of a single story item.
enum StoryItemType { image, video }

/// One item (photo/video) inside a story group. The viewer plays items in
/// order; [duration] overrides the default display time for images.
///
/// Ported from flutter_story_view's StoryItem (duration + viewers concept),
/// extended for FocusGram: overlays ride as structured data, not pixels.
class StoryItemModel {
  final String id;
  final String mediaUrl;
  final StoryItemType type;

  /// Display duration for image items. Videos use their own length, capped at
  /// [StoryKitViewer.maxVideoDuration] (default 30s, Instagram rule).
  final Duration duration;

  /// Optional caption rendered below the header.
  final String? caption;

  /// Interactive overlays positioned on top of the media.
  final List<StoryOverlay> overlays;

  /// When the item was created (viewer header time-ago).
  final DateTime? createdAt;

  /// Shared-content card (FocusGram share-to-story: post/note/video deep link).
  final Map<String, dynamic>? sharedContent;

  const StoryItemModel({
    required this.id,
    required this.mediaUrl,
    required this.type,
    this.duration = const Duration(seconds: 5),
    this.caption,
    this.overlays = const [],
    this.createdAt,
    this.sharedContent,
  });
}
