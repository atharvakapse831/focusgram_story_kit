import '../overlays/overlay_codec.dart';
import '../overlays/story_overlay.dart';
import 'story_shared_content.dart';

export 'story_shared_content.dart';

/// Media type of a single story item.
enum StoryItemType {
  image,
  video;

  static StoryItemType fromString(String? raw) {
    if (raw == null) return StoryItemType.image;
    return raw.toLowerCase() == 'video'
        ? StoryItemType.video
        : StoryItemType.image;
  }
}

/// One item (photo/video) inside a story group. The viewer plays items in
/// order; [duration] overrides the default display time for images.
///
/// Ported from flutter_story_view's StoryItem (duration + viewers concept),
/// extended for FocusGram: overlays ride as structured data, not pixels.
class StoryItemModel {
  final String id;
  final String mediaUrl;
  final StoryItemType type;

  /// Display duration for image items. When specified, overrides the viewer's
  /// [StoryKitViewer.defaultImageDuration]. Videos use their own length, capped
  /// at [StoryKitViewer.maxVideoDuration] (default 30s, Instagram rule).
  final Duration? duration;

  /// Optional caption rendered below the header.
  final String? caption;

  /// Interactive overlays positioned on top of the media.
  final List<StoryOverlay> overlays;

  /// When the item was created (viewer header time-ago).
  final DateTime? createdAt;

  /// Shared-content card (FocusGram share-to-story: post/note/video deep link).
  final StorySharedContent? sharedContent;

  const StoryItemModel({
    required this.id,
    required this.mediaUrl,
    required this.type,
    this.duration,
    this.caption,
    this.overlays = const [],
    this.createdAt,
    this.sharedContent,
  });

  /// Safely deserializes a [StoryItemModel] from JSON.
  factory StoryItemModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    final rawDuration = json['duration'];
    Duration? duration;
    if (rawDuration is int) {
      duration = Duration(milliseconds: rawDuration);
    } else if (rawDuration is String) {
      final ms = int.tryParse(rawDuration);
      if (ms != null) duration = Duration(milliseconds: ms);
    }

    StorySharedContent? shared;
    final rawShared = json['sharedContent'] ?? json['shared_content'];
    if (rawShared is Map<String, dynamic>) {
      shared = StorySharedContent.fromJson(rawShared);
    }

    final rawOverlays = json['overlays'] ?? json['stickers'];
    List<StoryOverlay> overlays = [];
    if (rawOverlays is List) {
      overlays = decodeOverlayList(rawOverlays);
    }

    DateTime? createdAt;
    final rawCreated = json['createdAt'] ?? json['created_at'];
    if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated);
    }

    return StoryItemModel(
      id: json['id'] as String? ?? '',
      mediaUrl:
          json['mediaUrl'] as String? ??
          json['media_url'] as String? ??
          json['contentUrl'] as String? ??
          json['content_url'] as String? ??
          '',
      type: StoryItemType.fromString(rawType),
      duration: duration,
      caption: json['caption'] as String?,
      overlays: overlays,
      createdAt: createdAt,
      sharedContent: shared,
    );
  }

  /// Serializes the model into a standard JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mediaUrl': mediaUrl,
      'type': type.name,
      if (duration != null) 'duration': duration!.inMilliseconds,
      if (caption != null) 'caption': caption,
      if (overlays.isNotEmpty)
        'overlays': overlays.map((o) => o.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (sharedContent != null) 'sharedContent': sharedContent!.toJson(),
    };
  }
}
