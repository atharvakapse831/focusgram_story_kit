import 'package:flutter/foundation.dart';

/// Category descriptor for grouping story stickers and assets.
@immutable
class StoryAssetCategory {
  const StoryAssetCategory({
    required this.id,
    required this.name,
    this.iconEmoji,
  });

  final String id;
  final String name;
  final String? iconEmoji;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryAssetCategory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          iconEmoji == other.iconEmoji;

  @override
  int get hashCode => Object.hash(id, name, iconEmoji);
}

/// A sticker item descriptor representing an emoji, vector badge, or image sticker.
@immutable
class StoryStickerItem {
  const StoryStickerItem({
    required this.id,
    required this.name,
    required this.categoryId,
    this.assetUri = '',
    this.emojiText,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String categoryId;
  final String assetUri;
  final String? emojiText;
  final List<String> tags;

  bool get isEmoji => emojiText != null && emojiText!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryStickerItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          categoryId == other.categoryId &&
          assetUri == other.assetUri &&
          emojiText == other.emojiText;

  @override
  int get hashCode => Object.hash(id, name, categoryId, assetUri, emojiText);
}

/// Abstract provider interface for discovering local or remote story stickers and emojis.
abstract class StoryAssetProvider {
  const StoryAssetProvider();

  /// Retrieves available sticker categories.
  Future<List<StoryAssetCategory>> getCategories();

  /// Retrieves stickers filtered by category, or all stickers if null.
  Future<List<StoryStickerItem>> getStickers({String? categoryId});

  /// Searches stickers across names and tags.
  Future<List<StoryStickerItem>> searchStickers(String query);
}

/// Default built-in asset provider supplying standard categorized emojis and stickers.
class DefaultStoryAssetProvider extends StoryAssetProvider {
  const DefaultStoryAssetProvider({
    List<StoryStickerItem> customStickers = const [],
  }) : _customStickers = customStickers;

  final List<StoryStickerItem> _customStickers;

  static const categories = [
    StoryAssetCategory(id: 'popular', name: 'Popular', iconEmoji: '🔥'),
    StoryAssetCategory(id: 'reactions', name: 'Reactions', iconEmoji: '😍'),
    StoryAssetCategory(id: 'celebrate', name: 'Celebrate', iconEmoji: '🎉'),
    StoryAssetCategory(id: 'nature', name: 'Nature', iconEmoji: '🌸'),
    StoryAssetCategory(id: 'symbols', name: 'Symbols', iconEmoji: '✨'),
  ];

  static const builtInStickers = [
    // Popular
    StoryStickerItem(
      id: 'stk_fire',
      name: 'Fire',
      categoryId: 'popular',
      emojiText: '🔥',
      tags: ['fire', 'hot', 'lit'],
    ),
    StoryStickerItem(
      id: 'stk_heart_eyes',
      name: 'Heart Eyes',
      categoryId: 'popular',
      emojiText: '😍',
      tags: ['love', 'crush', 'heart'],
    ),
    StoryStickerItem(
      id: 'stk_100',
      name: 'Hundred',
      categoryId: 'popular',
      emojiText: '💯',
      tags: ['perfect', 'score', '100'],
    ),
    StoryStickerItem(
      id: 'stk_sparkles',
      name: 'Sparkles',
      categoryId: 'popular',
      emojiText: '✨',
      tags: ['magic', 'shine', 'star'],
    ),

    // Reactions
    StoryStickerItem(
      id: 'stk_laughing',
      name: 'Laughing',
      categoryId: 'reactions',
      emojiText: '😂',
      tags: ['funny', 'lol', 'laugh'],
    ),
    StoryStickerItem(
      id: 'stk_crying',
      name: 'Crying',
      categoryId: 'reactions',
      emojiText: '😭',
      tags: ['sad', 'tears', 'emotional'],
    ),
    StoryStickerItem(
      id: 'stk_cool',
      name: 'Cool Sunglasses',
      categoryId: 'reactions',
      emojiText: '😎',
      tags: ['cool', 'sunglasses'],
    ),
    StoryStickerItem(
      id: 'stk_mind_blown',
      name: 'Mind Blown',
      categoryId: 'reactions',
      emojiText: '🤯',
      tags: ['mindblown', 'wow', 'shock'],
    ),

    // Celebrate
    StoryStickerItem(
      id: 'stk_tada',
      name: 'Party Popper',
      categoryId: 'celebrate',
      emojiText: '🎉',
      tags: ['party', 'celebrate', 'congrats'],
    ),
    StoryStickerItem(
      id: 'stk_balloon',
      name: 'Balloon',
      categoryId: 'celebrate',
      emojiText: '🎈',
      tags: ['birthday', 'party', 'float'],
    ),
    StoryStickerItem(
      id: 'stk_cake',
      name: 'Birthday Cake',
      categoryId: 'celebrate',
      emojiText: '🎂',
      tags: ['birthday', 'cake', 'sweet'],
    ),
    StoryStickerItem(
      id: 'stk_trophy',
      name: 'Trophy',
      categoryId: 'celebrate',
      emojiText: '🏆',
      tags: ['win', 'first', 'champion'],
    ),

    // Nature
    StoryStickerItem(
      id: 'stk_flower',
      name: 'Cherry Blossom',
      categoryId: 'nature',
      emojiText: '🌸',
      tags: ['flower', 'spring', 'bloom'],
    ),
    StoryStickerItem(
      id: 'stk_sun',
      name: 'Sun',
      categoryId: 'nature',
      emojiText: '☀️',
      tags: ['sun', 'summer', 'day'],
    ),
    StoryStickerItem(
      id: 'stk_rainbow',
      name: 'Rainbow',
      categoryId: 'nature',
      emojiText: '🌈',
      tags: ['rainbow', 'color', 'sky'],
    ),

    // Symbols
    StoryStickerItem(
      id: 'stk_star',
      name: 'Star',
      categoryId: 'symbols',
      emojiText: '⭐',
      tags: ['star', 'favorite', 'rating'],
    ),
    StoryStickerItem(
      id: 'stk_red_heart',
      name: 'Red Heart',
      categoryId: 'symbols',
      emojiText: '❤️',
      tags: ['heart', 'love', 'red'],
    ),
    StoryStickerItem(
      id: 'stk_thumbs_up',
      name: 'Thumbs Up',
      categoryId: 'symbols',
      emojiText: '👍',
      tags: ['like', 'agree', 'yes'],
    ),
  ];

  @override
  Future<List<StoryAssetCategory>> getCategories() async {
    return categories;
  }

  @override
  Future<List<StoryStickerItem>> getStickers({String? categoryId}) async {
    final all = [...builtInStickers, ..._customStickers];
    if (categoryId == null || categoryId.isEmpty) {
      return all;
    }
    return all.where((s) => s.categoryId == categoryId).toList();
  }

  @override
  Future<List<StoryStickerItem>> searchStickers(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return getStickers();

    final all = [...builtInStickers, ..._customStickers];
    return all.where((s) {
      if (s.name.toLowerCase().contains(q)) return true;
      if (s.tags.any((t) => t.toLowerCase().contains(q))) return true;
      return false;
    }).toList();
  }
}
