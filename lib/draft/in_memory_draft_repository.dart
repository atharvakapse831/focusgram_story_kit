import 'dart:convert';
import '../models/story_project.dart';
import 'draft_repository.dart';

/// In-memory implementation of [StoryDraftRepository] for testing, headless runners,
/// and reference integration.
class InMemoryStoryDraftRepository implements StoryDraftRepository {
  final Map<String, String> _storage = {};
  final Map<String, StoryDraftMetadata> _metadata = {};

  @override
  Future<void> saveDraft(StoryProject project) async {
    final serialized = jsonEncode(project.toJson());
    _storage[project.id] = serialized;

    final coverUri =
        project.pages.isNotEmpty
            ? project.pages.first.backgroundAsset?.uri
            : null;

    _metadata[project.id] = StoryDraftMetadata(
      id: project.id,
      updatedAt: DateTime.now(),
      pageCount: project.pages.length,
      coverUri: coverUri,
    );
  }

  @override
  Future<StoryProject?> loadDraft(String projectId) async {
    final raw = _storage[projectId];
    if (raw == null) return null;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return StoryProject.fromJson(decoded);
  }

  @override
  Future<List<StoryDraftMetadata>> listDrafts() async {
    final list = _metadata.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<void> deleteDraft(String projectId) async {
    _storage.remove(projectId);
    _metadata.remove(projectId);
  }

  /// Clears all stored drafts in memory.
  void clear() {
    _storage.clear();
    _metadata.clear();
  }
}
