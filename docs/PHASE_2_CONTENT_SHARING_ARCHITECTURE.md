# Phase 2 — FocusGram Content Sharing Integration Architecture

**Document Version:** 1.0.0  
**Status:** APPROVED / IN PROGRESS  
**Author:** FocusGram Engineering  
**Scope:** `focusgram_story_kit` package and `Mobile` host application  

---

## 1. Overview & Objectives

Phase 2 integrates FocusGram's content ecosystem into `focusgram_story_kit` so users can share app content into their stories, and viewers can render rich, interactive shared-content cards with deep-link navigation.

### The 6 FocusGram Content Types
1. **Image Posts:** Feed photo/carousel posts with captions and previews.
2. **Video Posts:** Standard feed video content with media thumbnail.
3. **Short Videos (Shorts/Reels):** Vertical full-screen short-form videos.
4. **Long Videos:** Landscape/long-form videos with durations and views.
5. **Articles:** Rich-text publishing articles with author and read preview.
6. **Notes:** Code snippets and technical note documents.

---

## 2. Core Architectural Principles

1. **Domain Independence (Dumb Package, Smart Host):**
   `focusgram_story_kit` must remain a 100% standalone Flutter package. It has no knowledge of FocusGram-specific classes (`ExploreVideoModel`, `SharedContentModel`, `AppRoute`, `DioClient`, etc.).
2. **Generic, Pluggable Model (`StorySharedContent`):**
   Story Kit defines a generic, immutable data contract (`StorySharedContent`) representing shared content payloads.
3. **Pluggable & Default UI Rendering:**
   Story Kit provides a default, high-quality, theme-adaptable `StorySharedContentCard` with loading/error states. It also exposes `sharedContentCardBuilder` for host applications desiring custom UI.
4. **Decoupled Navigation via Typed Callbacks:**
   `StoryKitViewer` exposes `onSharedContentTap: void Function(StorySharedContent content)?`. When tapped, playback pauses, and the host receives the callback to execute navigation.
5. **Zero Circular Dependencies:**
   `focusgram_story_kit` does not depend on `Mobile`. `Mobile` depends on `focusgram_story_kit` and provides bidirectional adapters (`StoryContentAdapter`).

---

## 3. Data Contracts

### 3.1 `StoryKitContentType` (Enum with fallback)

```dart
enum StoryKitContentType {
  imagePost,
  videoPost,
  shortVideo,
  longVideo,
  article,
  note,
  unknown;

  static StoryKitContentType fromString(String? raw) {
    if (raw == null) return StoryKitContentType.unknown;
    switch (raw.toLowerCase().trim()) {
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
```

### 3.2 `StorySharedContent` Model

```dart
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

  factory StorySharedContent.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

---

## 4. UI & Card Interaction Design

### Visual Layout
The default card renders in a centered, floating card layout:
```
+-------------------------------------------------------+
|  [Avatar] @authorUsername                [BADGE: TYPE] |
|-------------------------------------------------------|
|                                                       |
|              [ Thumbnail Preview Image ]              |
|                                                       |
|-------------------------------------------------------|
|  Title of Shared Content (Max 2 lines, bold)          |
|  Snippet / description text (Max 2 lines, secondary)  |
|-------------------------------------------------------|
|  Tap to open                                      ->  |
+-------------------------------------------------------+
```

### Type Badge Palette
- **Short Video / Long Video:** Magenta (`#FF007F`)
- **Note / Code:** Emerald Green (`#00E676`)
- **Article:** Amber (`#FFB300`)
- **Image Post / Carousel:** Indigo / Sky Blue (`#00A3FF`)
- **Unknown:** Muted Grey (`#9E9E9E`)

### Gestures & Hit Testing
- Card is wrapped with `GestureDetector(behavior: HitTestBehavior.opaque, onTap: ...)`.
- Card hit testing is placed above the viewer's page navigation tap detection, ensuring card taps open content rather than paging forward/backward.

---

## 5. Mobile Host Adapter Architecture

In `Mobile/lib/feature/stories`:

### `StoryContentAdapter`
```dart
class StoryContentAdapter {
  static StorySharedContent toStoryKit(SharedContentModel mobileModel);
  static SharedContentModel toMobile(StorySharedContent kitModel);
  static StoryItemModel toStoryKitItem(mobile.StoryItemModel mobileItem);
  static StoryGroupModel toStoryKitGroup(mobile.StoryGroupModel mobileGroup);
}
```

### Navigation Mapping in `StoryViewerScreen`
```dart
void handleSharedContentNavigation(BuildContext context, StorySharedContent content) {
  switch (content.type) {
    case StoryKitContentType.longVideo:
      // Navigate to VideoDetailScreen
      break;
    case StoryKitContentType.shortVideo:
      // Navigate to ShortsFeedScreen
      break;
    case StoryKitContentType.article:
      // Navigate to ArticleDetailScreen
      break;
    case StoryKitContentType.note:
      // Navigate to NoteDetailScreen
      break;
    case StoryKitContentType.imagePost:
    case StoryKitContentType.videoPost:
    case StoryKitContentType.unknown:
      // Navigate to Profile or Post
      break;
  }
}
```

---

## 6. Implementation Plan & Work Breakdown

1. **Step 1 (Story Kit):** Create `lib/models/story_shared_content.dart` with `StoryKitContentType` and `StorySharedContent`.
2. **Step 2 (Story Kit):** Update `StoryItemModel` to include typed `StorySharedContent? sharedContent` while supporting legacy JSON payloads.
3. **Step 3 (Story Kit):** Implement `StorySharedContentCard` in `lib/viewer/story_shared_content_card.dart`.
4. **Step 4 (Story Kit):** Integrate `StorySharedContentCard` into `StoryKitViewer` with `onSharedContentTap` and optional `sharedContentCardBuilder`.
5. **Step 5 (Story Kit):** Add unit tests (`test/story_shared_content_test.dart`) and widget tests (`test/story_shared_content_card_test.dart`).
6. **Step 6 (Story Kit):** Verify formatting, static analysis (`flutter analyze`), and test suite (`flutter test`).
7. **Step 7 (Mobile):** Implement `StoryContentAdapter` and update `StoryViewerScreen` to use `StoryKitViewer`.
8. **Step 8 (Mobile):** Verify Mobile compilation and test suite.
9. **Step 9 (Publish & Review):** Commit, push to `phase-2/content-sharing`, open PR, and prepare Phase 2 exit review.
