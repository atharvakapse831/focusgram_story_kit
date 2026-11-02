import 'package:flutter/foundation.dart';
import '../models/story_project.dart';

/// Lightweight metadata summary for a saved story draft.
@immutable
class StoryDraftMetadata {
  const StoryDraftMetadata({
    required this.id,
    required this.updatedAt,
    required this.pageCount,
    this.title,
    this.coverUri,
  });

  final String id;
  final DateTime updatedAt;
  final int pageCount;
  final String? title;
  final String? coverUri;

  Map<String, dynamic> toJson() => {
    'id': id,
    'updatedAt': updatedAt.toIso8601String(),
    'pageCount': pageCount,
    if (title != null) 'title': title,
    if (coverUri != null) 'coverUri': coverUri,
  };

  factory StoryDraftMetadata.fromJson(Map<String, dynamic> json) {
    return StoryDraftMetadata(
      id: json['id'] as String? ?? '',
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
              : DateTime.now(),
      pageCount: json['pageCount'] as int? ?? 1,
      title: json['title'] as String?,
      coverUri: json['coverUri'] as String?,
    );
  }
}

/// Abstract storage interface for persisting and restoring editable story drafts.
abstract class StoryDraftRepository {
  /// Persists the complete [project] document.
  Future<void> saveDraft(StoryProject project);

  /// Restores a previously saved project by [projectId].
  Future<StoryProject?> loadDraft(String projectId);

  /// Lists metadata for all available drafts.
  Future<List<StoryDraftMetadata>> listDrafts();

  /// Deletes a draft by [projectId].
  Future<void> deleteDraft(String projectId);
}
