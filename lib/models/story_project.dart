import 'package:flutter/foundation.dart';
import 'element_payloads.dart';
import 'story_canvas_spec.dart';
import 'story_group_model.dart';
import 'story_item_model.dart';
import 'story_page.dart';

/// Top-level canonical document model for a multi-page FocusGram story project.
@immutable
class StoryProject {
  const StoryProject({
    required this.id,
    this.schemaVersion = currentSchemaVersion,
    this.revision = 0,
    this.canvasSpec = const StoryCanvasSpec(),
    this.pages = const [],
    this.metadata,
  });

  /// Canonical schema version.
  static const int currentSchemaVersion = 1;

  /// Unique identifier for this project / draft.
  final String id;

  /// Schema version number for forward-compatible migrations.
  final int schemaVersion;

  /// Monotonically increasing revision counter tracking modifications.
  final int revision;

  /// Canonical aspect ratio and canvas settings.
  final StoryCanvasSpec canvasSpec;

  /// Ordered list of story slides / pages.
  final List<StoryPage> pages;

  /// Optional host-supplied metadata (e.g., authorId, tags, draft timestamps).
  final Map<String, dynamic>? metadata;

  /// Retrieves a page by its [pageId].
  StoryPage? getPage(String pageId) {
    for (final page in pages) {
      if (page.id == pageId) return page;
    }
    return null;
  }

  /// Creates a clean initial project with one empty page.
  factory StoryProject.create({
    required String id,
    StoryCanvasSpec canvasSpec = const StoryCanvasSpec(),
    Map<String, dynamic>? metadata,
  }) {
    final initialPage = StoryPage(
      id: 'page_${DateTime.now().millisecondsSinceEpoch}_1',
    );
    return StoryProject(
      id: id,
      canvasSpec: canvasSpec,
      pages: [initialPage],
      metadata: metadata,
    );
  }

  StoryProject copyWith({
    String? id,
    int? schemaVersion,
    int? revision,
    StoryCanvasSpec? canvasSpec,
    List<StoryPage>? pages,
    Map<String, dynamic>? metadata,
  }) {
    return StoryProject(
      id: id ?? this.id,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      revision: revision ?? this.revision,
      canvasSpec: canvasSpec ?? this.canvasSpec,
      pages: pages ?? this.pages,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts this project into a viewer-compatible [StoryGroupModel].
  StoryGroupModel toStoryGroupModel({
    String? userId,
    String? username,
    String? avatarUrl,
  }) {
    final items =
        pages.map((page) {
          // Find if any element contains shared content
          CardElementPayload? cardPayload;
          for (final el in page.elements) {
            if (el.payload is CardElementPayload) {
              cardPayload = el.payload as CardElementPayload;
              break;
            }
          }

          final mediaUri = page.backgroundAsset?.uri ?? '';
          final isVideo =
              page.backgroundAsset?.mimeType?.contains('video') ?? false;

          return StoryItemModel(
            id: page.id,
            mediaUrl: mediaUri,
            type: isVideo ? StoryItemType.video : StoryItemType.image,
            duration: page.duration,
            sharedContent: cardPayload?.sharedContent,
          );
        }).toList();

    return StoryGroupModel(
      userId: userId ?? id,
      username: username ?? 'You',
      avatarUrl: avatarUrl,
      items: items,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'schemaVersion': schemaVersion,
    'revision': revision,
    'canvasSpec': canvasSpec.toJson(),
    'pages': pages.map((p) => p.toJson()).toList(),
    if (metadata != null) 'metadata': metadata,
  };

  factory StoryProject.fromJson(Map<String, dynamic> rawJson) {
    // Schema migration entry point
    var json = Map<String, dynamic>.from(rawJson);
    final version = json['schemaVersion'] as int? ?? 1;

    if (version < currentSchemaVersion) {
      json = _migrateSchema(json, version, currentSchemaVersion);
    }

    return StoryProject(
      id: json['id'] as String? ?? '',
      schemaVersion: version,
      revision: json['revision'] as int? ?? 0,
      canvasSpec:
          json['canvasSpec'] != null
              ? StoryCanvasSpec.fromJson(
                Map<String, dynamic>.from(json['canvasSpec'] as Map),
              )
              : const StoryCanvasSpec(),
      pages:
          (json['pages'] as List<dynamic>? ?? [])
              .map(
                (p) => StoryPage.fromJson(Map<String, dynamic>.from(p as Map)),
              )
              .toList(),
      metadata:
          json['metadata'] != null
              ? Map<String, dynamic>.from(json['metadata'] as Map)
              : null,
    );
  }

  static Map<String, dynamic> _migrateSchema(
    Map<String, dynamic> oldJson,
    int fromVersion,
    int toVersion,
  ) {
    // Migration pipeline for future schema versions
    var migrated = Map<String, dynamic>.from(oldJson);
    for (var v = fromVersion; v < toVersion; v++) {
      // Version-specific incremental migrations
    }
    migrated['schemaVersion'] = toVersion;
    return migrated;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryProject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          schemaVersion == other.schemaVersion &&
          revision == other.revision &&
          canvasSpec == other.canvasSpec &&
          listEquals(pages, other.pages);

  @override
  int get hashCode => Object.hash(
    id,
    schemaVersion,
    revision,
    canvasSpec,
    Object.hashAll(pages),
  );
}
