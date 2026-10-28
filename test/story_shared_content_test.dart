import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/models/story_item_model.dart';

void main() {
  group('StoryKitContentType', () {
    test('parses all canonical and alias strings correctly', () {
      expect(
        StoryKitContentType.fromString('post'),
        StoryKitContentType.imagePost,
      );
      expect(
        StoryKitContentType.fromString('image'),
        StoryKitContentType.imagePost,
      );
      expect(
        StoryKitContentType.fromString('carousel'),
        StoryKitContentType.imagePost,
      );

      expect(
        StoryKitContentType.fromString('video_post'),
        StoryKitContentType.videoPost,
      );
      expect(
        StoryKitContentType.fromString('feed_video'),
        StoryKitContentType.videoPost,
      );

      expect(
        StoryKitContentType.fromString('short'),
        StoryKitContentType.shortVideo,
      );
      expect(
        StoryKitContentType.fromString('reel'),
        StoryKitContentType.shortVideo,
      );
      expect(
        StoryKitContentType.fromString('shorts'),
        StoryKitContentType.shortVideo,
      );

      expect(
        StoryKitContentType.fromString('long'),
        StoryKitContentType.longVideo,
      );
      expect(
        StoryKitContentType.fromString('video'),
        StoryKitContentType.longVideo,
      );
      expect(
        StoryKitContentType.fromString('long_video'),
        StoryKitContentType.longVideo,
      );

      expect(
        StoryKitContentType.fromString('article'),
        StoryKitContentType.article,
      );
      expect(
        StoryKitContentType.fromString('article_post'),
        StoryKitContentType.article,
      );

      expect(StoryKitContentType.fromString('note'), StoryKitContentType.note);
      expect(StoryKitContentType.fromString('code'), StoryKitContentType.note);
      expect(
        StoryKitContentType.fromString('code_note'),
        StoryKitContentType.note,
      );

      expect(
        StoryKitContentType.fromString('unknown_type'),
        StoryKitContentType.unknown,
      );
      expect(StoryKitContentType.fromString(null), StoryKitContentType.unknown);
    });

    test('serializes to canonical string', () {
      expect(StoryKitContentType.imagePost.toSerializedString(), 'post');
      expect(StoryKitContentType.videoPost.toSerializedString(), 'video_post');
      expect(StoryKitContentType.shortVideo.toSerializedString(), 'short');
      expect(StoryKitContentType.longVideo.toSerializedString(), 'long');
      expect(StoryKitContentType.article.toSerializedString(), 'article');
      expect(StoryKitContentType.note.toSerializedString(), 'note');
      expect(StoryKitContentType.unknown.toSerializedString(), 'unknown');
    });
  });

  group('StorySharedContent', () {
    test('round-trips through json serialization cleanly', () {
      const original = StorySharedContent(
        id: 'content_123',
        type: StoryKitContentType.article,
        title: 'Deep Dive into Flutter Architecture',
        description:
            'Exploring layered architecture in high scale applications.',
        thumbnailUrl: 'https://images.example.com/flutter.png',
        authorName: 'Alex Rivers',
        authorUsername: 'alex_rivers',
        authorAvatarUrl: 'https://images.example.com/alex.jpg',
        badgeText: 'ARTICLE',
        deepLinkUrl: 'focusgram://article/content_123',
        duration: Duration(seconds: 45),
        extra: {'claps': 250, 'featured': true},
      );

      final json = original.toJson();
      final deserialized = StorySharedContent.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.type, original.type);
      expect(deserialized.title, original.title);
      expect(deserialized.description, original.description);
      expect(deserialized.thumbnailUrl, original.thumbnailUrl);
      expect(deserialized.authorName, original.authorName);
      expect(deserialized.authorUsername, original.authorUsername);
      expect(deserialized.authorAvatarUrl, original.authorAvatarUrl);
      expect(deserialized.badgeText, original.badgeText);
      expect(deserialized.deepLinkUrl, original.deepLinkUrl);
      expect(deserialized.duration, original.duration);
      expect(deserialized.extra['claps'], 250);
      expect(deserialized.extra['featured'], isTrue);
      expect(deserialized, equals(original));
    });

    test(
      'parses Mobile-style creator object and alternative keys gracefully',
      () {
        final json = {
          'id': 'note_99',
          'type': 'code',
          'title': 'Binary Search Tree Dart Implementation',
          'description': 'Clean recursive implementation.',
          'thumbnail_url': 'https://images.example.com/thumb.png',
          'badge_text': 'CODE',
          'creator': {
            'id': 'user_88',
            'displayName': 'Taylor Swift',
            'username': 'taylor',
            'avatarUrl': 'https://images.example.com/taylor.png',
          },
          'duration': 5000,
        };

        final parsed = StorySharedContent.fromJson(json);
        expect(parsed.id, 'note_99');
        expect(parsed.type, StoryKitContentType.note);
        expect(parsed.title, 'Binary Search Tree Dart Implementation');
        expect(parsed.description, 'Clean recursive implementation.');
        expect(parsed.thumbnailUrl, 'https://images.example.com/thumb.png');
        expect(parsed.authorName, 'Taylor Swift');
        expect(parsed.authorUsername, 'taylor');
        expect(parsed.authorAvatarUrl, 'https://images.example.com/taylor.png');
        expect(parsed.badgeText, 'CODE');
        expect(parsed.duration, const Duration(seconds: 5));
      },
    );

    test('handles missing or malformed fields safely without crashing', () {
      final parsed = StorySharedContent.fromJson({});
      expect(parsed.id, isEmpty);
      expect(parsed.type, StoryKitContentType.unknown);
      expect(parsed.title, isEmpty);
      expect(parsed.description, isEmpty);
      expect(parsed.thumbnailUrl, isEmpty);
      expect(parsed.badgeText, 'POST');
      expect(parsed.extra, isEmpty);
    });

    test('copyWith updates specified fields only', () {
      const original = StorySharedContent(
        id: '1',
        type: StoryKitContentType.imagePost,
        title: 'Original Title',
      );
      final updated = original.copyWith(
        title: 'Updated Title',
        badgeText: 'FEATURED',
      );

      expect(updated.id, '1');
      expect(updated.title, 'Updated Title');
      expect(updated.badgeText, 'FEATURED');
      expect(updated.type, StoryKitContentType.imagePost);
    });
  });

  group('StoryItemModel with StorySharedContent', () {
    test('serializes and deserializes sharedContent within item', () {
      const item = StoryItemModel(
        id: 'item_1',
        mediaUrl: 'https://media.example.com/story.jpg',
        type: StoryItemType.image,
        duration: Duration(seconds: 7),
        sharedContent: StorySharedContent(
          id: 'v1',
          type: StoryKitContentType.shortVideo,
          title: 'Morning Routine',
          badgeText: 'SHORT',
        ),
      );

      final json = item.toJson();
      final restored = StoryItemModel.fromJson(json);

      expect(restored.id, 'item_1');
      expect(restored.type, StoryItemType.image);
      expect(restored.duration, const Duration(seconds: 7));
      expect(restored.sharedContent, isNotNull);
      expect(restored.sharedContent!.id, 'v1');
      expect(restored.sharedContent!.type, StoryKitContentType.shortVideo);
      expect(restored.sharedContent!.title, 'Morning Routine');
      expect(restored.sharedContent!.badgeText, 'SHORT');
    });
  });
}
