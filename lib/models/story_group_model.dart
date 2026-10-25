import 'story_item_model.dart';

/// One user's story group: avatar/header info plus that user's items.
class StoryGroupModel {
  final String userId;
  final String username;
  final String? avatarUrl;
  final List<StoryItemModel> items;

  const StoryGroupModel({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.items = const [],
  });
}
