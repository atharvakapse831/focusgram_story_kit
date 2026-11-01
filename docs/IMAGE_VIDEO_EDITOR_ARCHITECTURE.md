# FocusGram Story Kit — Unified Image & Video Editing Engine Architecture

**Status:** Proposed Architecture Specification  
**Repository:** `atharvakapse831/focusgram_story_kit`  
**Branch:** `main`  
**Date:** 2026-11-01  
**Architecture Version:** 1.0.0-draft  

---

## 1. Executive Summary & Design Vision

FocusGram requires a unified, creator-grade **StoryEditor** that handles both still photo stories and high-definition video stories within a single, cohesive user experience. 

The editor must support:
- Single-page and multi-page mixed-media stories (e.g., Page 1: Photo, Page 2: 15s Video, Page 3: Photo with drawings, Page 4: Video with music).
- Photo editing: crop, rotate, flip, color tuning (brightness, contrast, saturation), and aesthetic filters.
- Video editing: timeline scrubbing, millisecond-accurate trimming, clip splitting, playback speed, and audio/music mixing.
- Unified composition: rich typography, stickers, emojis, freehand drawings, vector shapes, layer z-ordering, and animated transforms.
- **Interactive metadata overlays**: polls, quizzes, sliders, questions, countdowns, links, mentions, and FocusGram post/note share cards that remain interactive for viewers.
- High-fidelity export: crisp still-image rendering for photos and hardware-accelerated Media3/AVFoundation video encoding with timestamp-synchronized animated overlay compositing.

### Core Architectural Mandate: Zero Third-Party Leakage
Neither `pro_image_editor`, `easy_video_editor`, nor any platform-specific SDK shall ever be exposed in the public Story Kit API. All third-party packages must live strictly behind pluggable internal adapter interfaces. If an underlying package is replaced, deprecated, or swapped for an in-house engine in a future phase, consumer applications (like FocusGram Mobile) require **zero code changes**.

```
                        ┌──────────────────────────────────────────────┐
                        │              FocusGram Host App              │
                        │           (e.g., Mobile / Web / Desktop)     │
                        └──────────────────────┬───────────────────────┘
                                               │
                                               │ Calls Public API
                                               ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                          FocusGram Story Kit (Public Contract)                              │
│                                                                                             │
│  • StoryEditor Widget          • StoryEditorConfig        • StoryInputMedia                 │
│  • StoryEditingSession         • StoryEditorResult        • StoryCancellationToken          │
│  • StoryCompositionModel       • StoryExportProgress      • StoryEditorException            │
└──────────────────────────────────────────────┬──────────────────────────────────────────────┘
                                               │
                                               │ Internally Orchestrates
                                               ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                       Internal Story Engine Architecture Layer                              │
│                                                                                             │
│   ┌──────────────────────────┐    ┌──────────────────────────┐    ┌─────────────────────┐   │
│   │    MediaImportService    │    │ StoryCompositionCtrl     │    │ StoryExportService  │   │
│   └────────────┬─────────────┘    └────────────┬─────────────┘    └──────────┬──────────┘   │
│                │                               │                             │              │
│                ▼                               ▼                             ▼              │
│   ┌──────────────────────────┐    ┌──────────────────────────┐    ┌─────────────────────┐   │
│   │    ImageEditorAdapter    │    │ Unified Interactive      │    │ VideoEditorAdapter  │   │
│   │       (Pluggable)        │    │ Canvas & Overlay Engine  │    │     (Pluggable)     │   │
│   │  [pro_image_editor sub]  │    │ (Vector + Interactive)   │    │ [easy_video_editor] │   │
│   └──────────────────────────┘    └──────────────────────────┘    └──────────┬──────────┘   │
│                                                                              │              │
│                                                                              ▼              │
│                                                                   ┌─────────────────────┐   │
│                                                                   │ Native Timestamp    │   │
│                                                                   │ Overlay Compositor  │   │
│                                                                   │ (Media3 / AVFound.) │   │
│                                                                   └─────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Non-Negotiable Architectural Rules

The following 9 rules govern the entire StoryEditor design:

1. **Zero Third-Party Exposure**: Never import or return types from `pro_image_editor`, `easy_video_editor`, or `video_player` in the public API.
2. **Pluggable & Replaceable Engine Adapters**: Image and video processing pipelines are accessed strictly through abstract interfaces (`ImageEditorAdapter`, `VideoEditorAdapter`, `StoryVideoExportAdapter`).
3. **Engine-Independent Composition Model**: The document model (`StoryCompositionModel` / `StoryProject`) owns all page, layer, coordinate, and metadata definitions. No engine-specific data models are persisted.
4. **Preview vs Export Separation**: Real-time canvas preview and video playback use high-performance Flutter UI widgets (`video_player` texture and Flutter `CustomPainter`), completely decoupled from headless export transcoders.
5. **Non-Destructive Media Preservation**: Original user media files are treated as read-only. Edits produce transformed copies or metadata instructions; source media is never overwritten.
6. **Deterministic Temporary File Lifecycle**: All intermediate and exported files reside in a dedicated, isolated temporary workspace (`Directory('${tempDir.path}/focusgram_story_${sessionId}')`). The session explicitly owns and cleans up these files upon completion, cancellation, or error.
7. **Explicit Asynchronous Cancellation & Progress**: All heavy operations (import, transcode, compositing, export) accept a `StoryCancellationToken` and emit structured `StoryExportProgress` with phase and fractional percentage.
8. **Concurrency Safety & Mutex Guarding**: Parallel export calls on the same session are rejected. Mutex locks prevent concurrent writes to identical output paths.
9. **Forward Extensibility**: The architecture supports adding future engines (e.g. custom WebGL effects, AI background matting, or cloud renderers) without breaking existing consumers.

---

## 3. High-Level Component Architecture

### 3.1 MediaImportService
Responsible for ingesting media assets from device storage, camera, or remote URLs.
- **Probing**: Inspects MIME types, dimensions, aspect ratios, rotation metadata, container duration, and audio presence.
- **Validation**: Enforces maximum video duration (e.g., 60s), minimum dimensions, and supported codecs (H.264, H.265, AAC).
- **Initialization**: Automatically generates an initial `StoryCompositionModel` containing one or more pages with default durations (5s for images, actual video duration capped at 15s/30s for videos).

### 3.2 StoryCompositionController
The state container and command orchestrator for the active editing session.
- **Document Graph**: Manages pages, active page index, layer elements, and background media.
- **Command & History**: Executes mutations via an `UndoRedoManager` supporting infinite or bounded history snapshots.
- **Coordinate Normalization**: Translates raw gesture coordinates (pixels) into resolution-independent normalized units (`0.0` to `1.0`) relative to a virtual 9:16 canvas.
- **Selection & Transform**: Tracks the currently selected element, drag offsets, pinch scale, rotation angle, and snapping guidelines.

### 3.3 ImageEditorAdapter (Internal Engine Contract)
Abstracts image manipulation tasks:
- **`cropAndAdjustImage()`**: Opens or executes image cropping, free rotation, aspect ratio constraints, and color matrix adjustments.
- **`renderStillPage()`**: Offscreen rasterization of a still photo with vector drawings, shapes, and visual stickers to a high-resolution PNG/JPEG.
- **Implementation Strategy**: Can delegate background cropping and color tuning to `pro_image_editor` sub-components in an isolated modal session, returning a clean cropped bitmap back to the Story Kit canvas.

### 3.4 VideoEditorAdapter (Internal Engine Contract)
Abstracts video manipulation tasks:
- **`trimVideo()`**: Trims video to millisecond boundaries.
- **`splitVideoClip()`**: Splits a long video clip into two adjacent clips across multiple story pages.
- **`adjustSpeed()`**: Modifies playback rate (0.5x to 2.0x).
- **`extractThumbnail()`**: Generates timeline scrubber thumbnails at specified timestamps.
- **`extractAudio()` / `removeAudio()`**: Strips or extracts raw audio.
- **Implementation Strategy**: Delegates headless trimming and scaling to `easy_video_editor: 0.1.7` (or in-house Media3/AVFoundation plugin).

### 3.5 StoryExportService & Native Overlay Compositor
The master export coordinator:
- Inspects every page in the `StoryCompositionModel`.
- Routes still photo pages to the offscreen image renderer.
- Routes video pages to the native video compositor:
  - Phase 1: Video transcoding (trim, scale, speed via `VideoEditorAdapter`).
  - Phase 2: Timestamp-aware overlay compositing (burns rich text, drawings, stickers, and animations into video frames).
  - Phase 3: Audio multiplexing (mixes background music track and original video audio with volume balance).
- Emits aggregated progress events across all pages to the host application.

---

## 4. Unified Editing Experience & Tool Specialization

The user interface follows a single, intuitive layout with contextual specialization:

```
┌────────────────────────────────────────────────────────┐
│ [X] Close        [↶] Undo  [↷] Redo         [Next >]    │ ◄── Top Navigation Bar
├────────────────────────────────────────────────────────┤
│                                                        │
│                     STORY CANVAS                       │
│                     (9:16 Aspect)                      │
│                                                        │
│             ┌────────────────────────────┐             │
│             │                            │             │
│             │    Background Photo or     │             │
│             │    Video (video_player)    │             │
│             │                            │             │
│             │    + Rich Text Layer       │             │
│             │    + Interactive Poll      │             │
│             │    + Freehand Drawing      │             │
│             │    + Stickers / Shapes     │             │
│             │                            │             │
│             └────────────────────────────┘             │
│                                                        │
├────────────────────────────────────────────────────────┤
│ [ Page 1 (Photo) ]  [ Page 2 (Video) ]  [ + Add Media ] │ ◄── Multi-Page Story Strip
├────────────────────────────────────────────────────────┤
│ Contextual Tool Dock (Switches based on active page):  │
│                                                        │
│ PHOTO MODE:  [Crop]  [Filters]  [Text]  [Draw]  [Sticker] [Widgets] [Background]
│ VIDEO MODE:  [Trim]  [Split]    [Audio] [Text]  [Draw]   [Sticker] [Widgets]
└────────────────────────────────────────────────────────┘
```

### 4.1 Consistent Navigation Chrome
- **Top Bar**: Always provides "Close" (with discard confirmation), "Undo", "Redo", and "Next / Export".
- **Story Page Strip**: Shows all pages in the current story project. Users can tap to select, drag to reorder, duplicate, or delete pages.
- **Add Media**: Accessible at any time to append additional photos or videos to the multi-page story.

### 4.2 Contextual Tool Dock
The bottom toolbar intelligently adapts to the active page type:
- **When Image Page is Active**:
  - **Crop & Adjust**: Opens the image cropping/aspect ratio tool.
  - **Filters & Tuning**: Sliders for brightness, contrast, saturation, and aesthetic color presets.
  - **Text, Drawing, Stickers, Shapes**: Unified vector/text tools.
  - **Interactive Overlays**: Polls, quizzes, emoji sliders, question boxes, countdowns, links, mentions.
  - **Background**: Solid color, gradient presets, or blurred backdrop.
- **When Video Page is Active**:
  - **Timeline & Trim**: Interactive scrubber bar with draggable start/end trim handles (1s to 15s/30s).
  - **Split Clip**: Cuts the video at current playhead and spawns a new adjacent page with the remainder.
  - **Audio & Music**: Volume sliders (original audio vs added music track), mute toggle, and audio asset picker.
  - **Text, Drawing, Stickers, Shapes**: Animated overlays with entrance/exit timing.
  - **Interactive Overlays**: Positioned over the video with persistence in the viewer.

---

## 5. Overlay and Composition Strategy

A central challenge in story systems is resolving the dichotomy between **visual pixels** (what must be burned into exported videos/photos for third-party sharing) and **structured data** (what must remain interactive in the FocusGram viewer).

### 5.1 The Dual-Layer Architecture

To solve this, Story Kit establishes a **Dual-Layer Composition Model**:

```
┌─────────────────────────────────────────────────────────────────┐
│                    StoryCompositionModel                        │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ Layer 0: Background Media Layer                           │  │
│  │ • Image: File URI, Crop Rect, Color Matrix, Blur          │  │
│  │ • Video: File URI, Trim Range, Speed, Volume, Crop Rect   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ Layer 1: Visual Overlay Elements (Burned into Export)     │  │
│  │ • Rich Text (Typography, colors, alignments, gradients)   │  │
│  │ • Freehand Drawings (Vector strokes, smooth bezier paths) │  │
│  │ • Stickers & Emojis (PNG/SVG assets, transforms)          │  │
│  │ • Vector Shapes (Rectangles, circles, arrows, stars)      │  │
│  │ • FocusGram Share Card (Post / note / video deep link)    │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ Layer 2: Interactive Metadata Overlays (Preserved as Data)│  │
│  │ • PollOverlay (Question, options, multiple choice flag)   │  │
│  │ • QuizOverlay (Question, options, correct answer index)   │  │
│  │ • SliderOverlay (Emoji, question, min/max values)         │  │
│  │ • QuestionOverlay (Prompt)                                │  │
│  │ • CountdownOverlay (Target UTC timestamp)                 │  │
│  │ • LinkOverlay (Verified HTTP/HTTPS URL, display domain)   │  │
│  │ • MentionOverlay (User ID, username)                      │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Export Handling by Output Channel

#### Scenario A: In-App FocusGram Story Publishing
When publishing to FocusGram:
1. **Background Media**: The background photo or trimmed video is exported with visual adjustments.
2. **Visual Overlays (Layer 1)**: Text, drawings, and decorative stickers can be rendered into the media or sent alongside.
3. **Interactive Overlays (Layer 2)**: **NEVER FLATTENED**. They are serialized directly into `StoryItemModel.overlays` using `toJson()`:
   ```json
   {
     "id": "poll_123",
     "type": "poll",
     "dx": 0.5,
     "dy": 0.4,
     "question": "Should we launch today?",
     "options": ["Yes!", "Wait a bit"]
   }
   ```
4. In the viewer, `StoryOverlayRenderer` rebuilds live Flutter widgets over the media, enabling real-time voting and interaction.

#### Scenario B: Standalone / External Export (Save to Camera Roll / Share Sheet)
When saving a story to the device gallery or sharing to third-party apps (WhatsApp, Instagram, etc.):
- External viewers cannot execute Flutter code.
- In this mode, `StoryExportService` switches to **Visual Burn-In**:
  - Interactive overlays are converted into visual representations (e.g. the poll card is rendered with options visible).
  - The entire stack (Media + Visual Overlays + Rendered Interactive Cards) is composited into a single standalone MP4 or PNG.

### 5.3 Video Overlay Compositing Pipeline

Because `easy_video_editor: 0.1.7` does not support overlay compositing, the architecture specifies a dedicated **Timestamp-Synchronized Native Compositor**:

```
                       ┌────────────────────────────┐
                       │   Trimmed Source Video     │
                       └─────────────┬──────────────┘
                                     │
                                     ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                     Native Compositing Engine                             │
│                                                                           │
│  Android: Media3 Transformer + TimestampOverlayRenderer                   │
│           • Queries Flutter Canvas or cached bitmap for timestamp (t_us)  │
│           • Applies OpenGL GlEffect matrix transformations                │
│                                                                           │
│  iOS:     AVFoundation + AVVideoCompositionCoreAnimationTool              │
│           • Synchronizes Core Animation layer tree with video timeline    │
│           • Evaluates entrance/exit animations at frame PTS               │
└────────────────────────────────────┬──────────────────────────────────────┘
                                     │
                                     ▼
                       ┌────────────────────────────┐
                       │ Composed Output MP4 Video  │
                       │ (Video + Overlays + Audio) │
                       └────────────────────────────┘
```

---

## 6. Public API Design

The public API is designed to be concise, strictly typed, and completely isolated from internal implementation packages.

### 6.1 Entry Widget & Configuration

```dart
// lib/focusgram_story_kit.dart

/// Primary entry point for the unified Story Creation Studio.
class StoryEditor extends StatefulWidget {
  final StoryInputMedia? initialMedia;
  final StoryCompositionModel? initialProject;
  final StoryEditorConfig config;
  final ValueChanged<StoryEditorResult> onExportComplete;
  final ValueChanged<StoryCompositionModel>? onSaveDraft;
  final VoidCallback? onClose;

  const StoryEditor({
    super.key,
    this.initialMedia,
    this.initialProject,
    this.config = const StoryEditorConfig(),
    required this.onExportComplete,
    this.onSaveDraft,
    this.onClose,
  });

  @override
  State<StoryEditor> createState() => _StoryEditorState();
}

/// Feature flags, limits, and styling for the StoryEditor.
class StoryEditorConfig {
  final bool enableMultiPage;
  final int maxPages;
  final Duration defaultImageDuration;
  final Duration maxVideoDuration;
  final bool enableDrawing;
  final bool enableText;
  final bool enableStickers;
  final bool enableInteractiveOverlays;
  final bool enableAudioMixing;
  final StoryEditorTheme theme;

  const StoryEditorConfig({
    this.enableMultiPage = true,
    this.maxPages = 10,
    this.defaultImageDuration = const Duration(seconds: 5),
    this.maxVideoDuration = const Duration(seconds: 30),
    this.enableDrawing = true,
    this.enableText = true,
    this.enableStickers = true,
    this.enableInteractiveOverlays = true,
    this.enableAudioMixing = true,
    this.theme = StoryEditorTheme.dark,
  });
}

enum StoryEditorTheme { dark, light, system }
```

### 6.2 Input Media Models

```dart
/// Represents media passed into the StoryEditor at launch.
sealed class StoryInputMedia {
  const StoryInputMedia();

  /// Launch with a single image file.
  factory StoryInputMedia.image({required String filePath}) = ImageInputMedia;

  /// Launch with a single video file.
  factory StoryInputMedia.video({required String filePath}) = VideoInputMedia;

  /// Launch with multiple media files (creates multi-page project).
  factory StoryInputMedia.multi({required List<String> filePaths}) = MultiInputMedia;

  /// Launch with a blank canvas (solid/gradient color).
  factory StoryInputMedia.blank({Color? backgroundColor}) = BlankInputMedia;
}

class ImageInputMedia extends StoryInputMedia {
  final String filePath;
  const ImageInputMedia({required this.filePath});
}

class VideoInputMedia extends StoryInputMedia {
  final String filePath;
  const VideoInputMedia({required this.filePath});
}

class MultiInputMedia extends StoryInputMedia {
  final List<String> filePaths;
  const MultiInputMedia({required this.filePaths});
}

class BlankInputMedia extends StoryInputMedia {
  final Color? backgroundColor;
  const BlankInputMedia({this.backgroundColor});
}
```

### 6.3 Export Result & Output Models

```dart
/// The final result delivered when export completes.
class StoryEditorResult {
  final String projectId;
  final List<StoryPageResult> pages;
  final StoryCompositionModel composition;
  final Duration totalDuration;

  const StoryEditorResult({
    required this.projectId,
    required this.pages,
    required this.composition,
    required this.totalDuration,
  });
}

/// Output for an individual story page.
class StoryPageResult {
  final String pageId;
  final int pageIndex;
  final String outputFilePath;
  final StoryItemType mediaType; // image or video
  final Duration duration;
  final List<StoryOverlay> interactiveOverlays; // Structured data for viewer

  const StoryPageResult({
    required this.pageId,
    required this.pageIndex,
    required this.outputFilePath,
    required this.mediaType,
    required this.duration,
    required this.interactiveOverlays,
  });

  bool get isVideo => mediaType == StoryItemType.video;
}
```

### 6.4 Cancellation Token & Progress Reporting

```dart
/// Thread-safe cancellation token for asynchronous editor and export operations.
class StoryCancellationToken {
  bool _isCancelled = false;
  final List<VoidCallback> _listeners = [];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in _listeners) {
      listener();
    }
  }

  void onCancel(VoidCallback callback) {
    if (_isCancelled) {
      callback();
    } else {
      _listeners.add(callback);
    }
  }
}

/// Real-time export progress information.
class StoryExportProgress {
  final int currentPageIndex;
  final int totalPages;
  final StoryExportPhase phase;
  final double progress; // 0.0 to 1.0

  const StoryExportProgress({
    required this.currentPageIndex,
    required this.totalPages,
    required this.phase,
    required this.progress,
  });
}

enum StoryExportPhase {
  preparing,
  processingMedia,
  compositingOverlays,
  mixingAudio,
  finalizing,
  completed,
  cancelled,
}
```

### 6.5 Typed Exception Hierarchy

```dart
/// Root exception for all StoryEditor operations.
sealed class StoryEditorException implements Exception {
  final String message;
  final dynamic cause;
  final StackTrace? stackTrace;

  const StoryEditorException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => '$runtimeType: $message${cause != null ? " (Cause: $cause)" : ""}';
}

class MediaImportException extends StoryEditorException {
  const MediaImportException(super.message, {super.cause, super.stackTrace});
}

class VideoExportException extends StoryEditorException {
  const VideoExportException(super.message, {super.cause, super.stackTrace});
}

class ImageExportException extends StoryEditorException {
  const ImageExportException(super.message, {super.cause, super.stackTrace});
}

class ExportCancelledException extends StoryEditorException {
  const ExportCancelledException() : super('Export operation was cancelled by user.');
}

class TemporaryStorageException extends StoryEditorException {
  const TemporaryStorageException(super.message, {super.cause, super.stackTrace});
}
```

---

## 7. Performance and Reliability

### 7.1 Large Image Handling & OOM Mitigation
Mobile devices capture photos at 12MP (4032x3024) to 48MP+. Decoding a full-resolution 48MP image into an uncompressed RGBA pixel buffer requires approximately **192 MB of RAM**. If multiple images are loaded in a multi-page story, a 32-bit or memory-constrained device will experience an immediate Out-Of-Memory (OOM) crash.
- **Mitigation Strategy**:
  1. Downsample background images on import to match the maximum target export canvas resolution (1080x1920 pixels).
  2. Perform image decoding and downsampling inside a background Dart isolate (`compute()`).
  3. Keep only compressed image file references in memory; load bitmaps into texture memory on demand when a page becomes visible in the editor.

### 7.2 1080p and 4K Video Processing
Video transcoding is computationally intensive and battery-draining.
- **Mitigation Strategy**:
  1. Utilize hardware-accelerated MediaCodec (Android) and VideoToolbox (iOS) through Media3 / AVFoundation.
  2. Enforce output video constraints: 1080x1920, 30fps, H.264 High Profile, with a target bitrate of 6–8 Mbps (optimal for mobile stories).
  3. Pre-scale 4K input videos during the initial transcode phase to avoid high-resolution frame buffer overhead in the overlay compositor.

### 7.3 Temporary File Lifecycle & Storage Safety
Editing sessions generate intermediate files (transcoded clips, rendered overlay bitmaps, mixed audio tracks).
- **Storage Lifecycle Rules**:
  1. Every editing session creates a uniquely namespaced sandbox directory:  
     `${tempDir}/story_kit/session_${uuid}/`
  2. Intermediate files are written using temporary extensions (`.tmp`) and atomically renamed upon success.
  3. When an export finishes successfully, output files are moved to their destination and the session directory is wiped.
  4. If export is cancelled or crashes, a deterministic cleanup handler recursively deletes the session directory.
  5. An automatic startup cleaner purges any orphan directories older than 24 hours.

### 7.4 Application Lifecycle & Interruption Handling
Users frequently exit to the home screen or receive incoming phone calls while editing.
- **Mitigation Strategy**:
  1. Implement `WidgetsBindingObserver` in `StoryEditor`.
  2. On `AppLifecycleState.paused`: immediately pause video playback and audio.
  3. Automatically persist an in-memory draft (`onSaveDraft`) so the creator does not lose progress if the OS kills the background process.
  4. On resume, restore video player controllers safely without duplicating state.
