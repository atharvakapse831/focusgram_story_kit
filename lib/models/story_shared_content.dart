import 'package:flutter/foundation.dart';

/// Supported types of content that can be shared into a story.
enum StoryKitContentType {
  imagePost,
  videoPost,
  shortVideo,
  longVideo,
  article,
  note,
  unknown;

  /// Parses a raw string discriminator into a [StoryKitContentType],
  /// supporting common aliases across FocusGram feeds and services.
  static StoryKitContentType fromString(String? raw) {
    if (raw == null) return StoryKitContentType.unknown;
    final normalized = raw.toLowerCase().trim();
    switch (normalized) {
      case 'image':
      case 'image_post':
      case 'post':
      case 'carousel':
        return StoryKitContentType.imagePost;
      case 'video_post':
      case 'feed_video':
        return StoryKitContentType.videoPost;
      case 'short':
      case 'short_video':
      case 'reel':
      case 'shorts':
        return StoryKitContentType.shortVideo;
      case 'long':
      case 'long_video':
      case 'video':
        return StoryKitContentType.longVideo;
      case 'article':
      case 'article_post':
        return StoryKitContentType.article;
      case 'note':
      case 'code':
      case 'code_note':
        return StoryKitContentType.note;
      default:
        return StoryKitContentType.unknown;
    }
  }

  /// Serializes the content type into a standard canonical discriminator.
  String toSerializedString() {
    switch (this) {
      case StoryKitContentType.imagePost:
        return 'post';
      case StoryKitContentType.videoPost:
        return 'video_post';
      case StoryKitContentType.shortVideo:
        return 'short';
      case StoryKitContentType.longVideo:
        return 'long';
      case StoryKitContentType.article:
        return 'article';
      case StoryKitContentType.note:
        return 'note';
      case StoryKitContentType.unknown:
        return 'unknown';
    }
  }
}

/// A domain-independent model for shared content rendered inside a story card.
///
/// Designed to hold rich metadata for shared feed posts, videos, shorts,
/// articles, and notes without tying Story Kit to any host-app schema.
@immutable
class StorySharedContent {
  final String id;
  final StoryKitContentType type;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String authorName;
  final String authorUsername;
  final String authorAvatarUrl;
  final String badgeText;
  final String? deepLinkUrl;
  final Duration? duration;
  final Map<String, dynamic> extra;

  const StorySharedContent({
    required this.id,
    required this.type,
    required this.title,
    this.description = '',
    this.thumbnailUrl = '',
    this.authorName = '',
    this.authorUsername = '',
    this.authorAvatarUrl = '',
    this.badgeText = 'POST',
    this.deepLinkUrl,
    this.duration,
    this.extra = const {},
  });

  /// Safely parses a [StorySharedContent] from a JSON map.
  factory StorySharedContent.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'] as Map<String, dynamic>?;
    final rawType = json['type'] as String? ?? json['contentType'] as String?;
    final rawDuration = json['duration'];
    Duration? parsedDuration;
    if (rawDuration is int) {
      parsedDuration = Duration(milliseconds: rawDuration);
    } else if (rawDuration is String) {
      final parsedMs = int.tryParse(rawDuration);
      if (parsedMs != null) {
        parsedDuration = Duration(milliseconds: parsedMs);
      }
    }

    return StorySharedContent(
      id: json['id'] as String? ?? '',
      type: StoryKitContentType.fromString(rawType),
      title: json['title'] as String? ?? '',
      description:
          json['description'] as String? ?? json['caption'] as String? ?? '',
      thumbnailUrl:
          json['thumbnailUrl'] as String? ??
          json['thumbnail_url'] as String? ??
          json['mediaUrl'] as String? ??
          '',
      authorName:
          json['authorName'] as String? ??
          json['author_name'] as String? ??
          creator?['displayName'] as String? ??
          creator?['name'] as String? ??
          '',
      authorUsername:
          json['authorUsername'] as String? ??
          json['author_username'] as String? ??
          creator?['username'] as String? ??
          '',
      authorAvatarUrl:
          json['authorAvatarUrl'] as String? ??
          json['author_avatar_url'] as String? ??
          creator?['avatarUrl'] as String? ??
          creator?['profilePicture'] as String? ??
          '',
      badgeText:
          json['badgeText'] as String? ??
          json['badge_text'] as String? ??
          (rawType != null ? rawType.toUpperCase() : 'POST'),
      deepLinkUrl:
          json['deepLinkUrl'] as String? ?? json['deep_link_url'] as String?,
      duration: parsedDuration,
      extra:
          json['extra'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(json['extra'] as Map)
              : const {},
    );
  }

  /// Serializes the model into a standard JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toSerializedString(),
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'authorName': authorName,
      'authorUsername': authorUsername,
      'authorAvatarUrl': authorAvatarUrl,
      'badgeText': badgeText,
      if (deepLinkUrl != null) 'deepLinkUrl': deepLinkUrl,
      if (duration != null) 'duration': duration!.inMilliseconds,
      if (extra.isNotEmpty) 'extra': extra,
    };
  }

  /// Creates a copy of this model with the given fields replaced.
  StorySharedContent copyWith({
    String? id,
    StoryKitContentType? type,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? authorName,
    String? authorUsername,
    String? authorAvatarUrl,
    String? badgeText,
    String? deepLinkUrl,
    Duration? duration,
    Map<String, dynamic>? extra,
  }) {
    return StorySharedContent(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      badgeText: badgeText ?? this.badgeText,
      deepLinkUrl: deepLinkUrl ?? this.deepLinkUrl,
      duration: duration ?? this.duration,
      extra: extra ?? this.extra,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StorySharedContent &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.description == description &&
        other.thumbnailUrl == thumbnailUrl &&
        other.authorName == authorName &&
        other.authorUsername == authorUsername &&
        other.authorAvatarUrl == authorAvatarUrl &&
        other.badgeText == badgeText &&
        other.deepLinkUrl == deepLinkUrl &&
        other.duration == duration &&
        mapEquals(other.extra, extra);
  }

  static int _hashExtra(Map<String, dynamic> map) {
    if (map.isEmpty) return 0;
    final sortedKeys = map.keys.toList()..sort();
    return Object.hashAll(sortedKeys.map((key) => Object.hash(key, map[key])));
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    description,
    thumbnailUrl,
    authorName,
    authorUsername,
    authorAvatarUrl,
    badgeText,
    deepLinkUrl,
    duration,
    _hashExtra(extra),
  );
}
