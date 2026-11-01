# FocusGram Story Kit — Editor Dependency Feasibility Assessment

**Status:** Technical Architecture & Feasibility Assessment  
**Repository:** `atharvakapse831/focusgram_story_kit`  
**Branch:** `main`  
**Date:** 2026-11-01  
**Target Dependencies Evaluated:**
- Image Editing Engine: `pro_image_editor: ^14.23.0` (evaluated against latest pub release `14.22.0` / upcoming `14.23.0`)
- Video Processing Engine: `easy_video_editor: ^0.1.7` (evaluated against published `0.1.7`)
- Video Preview / Playback: `video_player: ^2.9.2` (current in-tree dependency)

---

## 1. Executive Summary & Assessment Verdict

FocusGram Story Kit requires an Instagram-class Story creation and viewing system. Stories consist of photo and video slides decorated with text, freehand drawings, stickers, vector shapes, background adjustments, and—critically—**interactive, structured metadata overlays** (polls, quizzes, sliders, questions, countdowns, links, mentions, and FocusGram post/note share cards).

This assessment was conducted under the **Phase 1 Baseline Audit Gate**. In accordance with repository governance rules, no production dependencies have been modified, and no unauthorized implementation code has been introduced during this assessment.

### Evaluation Summary Table

| Engine Candidate | Target Version | Published Version | License | Primary Strength | Critical Architectural Defect / Gap | Final Recommendation |
|---|---|---|---|---|---|---|
| **`pro_image_editor`** | `^14.23.0` | `14.22.0` | BSD-3-Clause | Rich Flutter-native photo editing (crop, rotate, tune, filter, paint, text, sticker layers, undo/redo, isolate rendering) | **Flattens overlays to static pixels on export.** Incompatible with Story Kit's structured overlay contract (`StoryOverlay.toJson()`). Destroys viewer interactivity for polls, quizzes, sliders, countdowns, and deep links. Does not handle video. | **DEFER / REJECT as core composition engine.** May only be used as an internal background photo pre-processor (crop/tuning) behind a strict adapter. |
| **`easy_video_editor`** | `^0.1.7` | `0.1.7` | MIT | Lightweight native Media3 (Android) and AVFoundation (iOS) video trimming, scaling, speed control, and compression without FFmpeg | **Zero overlay compositing support.** Cannot burn animated text, stickers, drawings, or shapes into exported videos. **No cancellation API** in 0.1.7. **No multi-track audio mixing** (only mute/extract). Headless only (no timeline UI). | **REJECT / DEFER as full video editor.** Cannot fulfill Story video export requirements without an external native compositing pipeline. Only suitable for low-level media trimming if native plugins are allowed. |
| **`video_player`** | `^2.9.2` | `2.9.2` | BSD-3-Clause | Established Flutter First-Party Plugin for video decoding and surface texture rendering | Playback and timeline scrubbing only; does not perform video editing or export transcoding. | **RETAIN for preview and playback.** |

---

## 2. Current Story Kit Baseline & Phase 1 Context

### 2.1 Repository State on `main`
An audit of `main` at commit `84575c0` reveals the following structure:
- **`pubspec.yaml`**: Declares `sdk: ^3.5.0`, `flutter: ">=3.24.0"`, dependencies `cached_network_image: ^3.4.1`, `video_player: ^2.9.2`, and dev_dependencies `flutter_test`, `flutter_lints: ^5.0.0`.
- **Public API (`lib/focusgram_story_kit.dart`)**: Exports `StoryItemModel`, `StoryGroupModel`, `StoryOverlay`, `OverlayCodec`, `StoryKitViewer`, and `StoryOverlayRenderer`.
- **Viewer Engine (`lib/viewer/`)**: Implements `StoryKitViewer` (PageView, progress timer, video controller, tap zones) and `StoryOverlayRenderer` (overlay widget layout).
- **Overlay Subsystem (`lib/overlays/`)**: Implements 7 typed overlays: `PollOverlay`, `QuizOverlay`, `SliderOverlay`, `QuestionOverlay`, `CountdownOverlay`, `LinkOverlay`, `MentionOverlay`.
- **Absence of Editor**: There is **no editor widget, canvas, command history, draft storage, or export engine on `main`**.

### 2.2 Phase 1 Status & Stop Rule
As documented in `docs/PHASE_1_AUDIT_REPORT.md` and `docs/PHASE_1_EXIT_CRITERIA.md`:
- Phase 1 audit established a `NO-GO` gate for Phase 2 until baseline compilation issues and toolchain verification are resolved.
- Specifically, `story_overlay_renderer.dart` contains unhandled switch cases and scoping errors (`widget.countdown`), and `test/story_overlay_renderer_test.dart` uses undefined finders (`textStartingWith`), causing test compilation failures under Flutter 3.24+.
- **Mandate**: This document is an **architecture and dependency feasibility assessment ONLY**. It does not mutate production code or skip phase gates.

---

## 3. Deep-Dive Evaluation: `pro_image_editor`

### 3.1 Version Verification & Licensing
- **Requested Version**: `^14.23.0`.
- **Actual Published Version**: The latest stable release published on pub.dev is **`14.22.0`** (February 2026). Version `14.23.0` has not yet been published to pub.dev. The dependency constraint `^14.22.0` or `^14.23.0` resolves within the 14.x semver range.
- **License**: **BSD 3-Clause License** (Copyright 2025 Alex Frei). Fully compatible with commercial use, distribution, and modification.
- **Platform Support**: Android, iOS, Web, macOS, Windows, Linux (pure Flutter/Dart with background isolates).

### 3.2 Feature Matrix vs Story Kit Requirements

| Feature Category | `pro_image_editor: 14.22.0` Capability | FocusGram Story Kit Requirement | Alignment Assessment |
|---|---|---|---|
| **Image Import** | Memory (`Uint8List`), File, Asset, Network | Local file path from camera/gallery, remote URL | **Compliant.** Supports fast memory and file loading. |
| **Cropping & Aspect Ratio** | Free crop, fixed aspect ratios (9:16, 1:1, 4:5, 16:9), rotation (90° steps and fine angle), horizontal/vertical flip | 9:16 default canvas, user image cropping | **Fully Compliant.** Production-grade cropping module. |
| **Drawing & Brush Tools** | Freehand paint, brush sizes, color picker, opacity, shapes (line, arrow, rect, oval), blur/pixelation modes | Freehand drawing and shapes on story canvas | **Compliant.** High-performance vector path rendering with isolate generation. |
| **Text Styling** | Rich text editor, font selection, alignments, background chips, text gradient (`TextLayer.gradient`), box overflow controls | Story text with colors, alignments, background pill | **Compliant.** Excellent typography tools. |
| **Stickers & Emojis** | Emoji picker, custom sticker builder, layer rotation, pinch-to-scale, flip, spin layer animations | Static stickers, animated stickers, custom FocusGram assets | **Compliant for static stickers.** |
| **Filters & Adjustments** | ColorFilter presets, image tuning (brightness, contrast, saturation) | Aesthetic photo filters and tuning | **Compliant.** Uses optimized shader-based color matrix filters. |
| **Layer Management** | Layer stack, drag, rotate, scale, z-index reordering, active layer selection chrome | Multi-layer canvas with direct manipulation | **Compliant for internal image layers.** |
| **Undo / Redo** | Full history stack with non-destructive state snapshots | Granular undo/redo for creator workflows | **Compliant.** Efficient snapshot history mechanism. |
| **Interactive Overlays** | None. Only supports custom widget layers that get **flattened to pixels** upon export. | **Interactive structured metadata** (`StoryOverlay`): polls, quizzes, sliders, questions, countdowns, links, mentions. | **FATAL GAP.** Flattens all layers into raster pixels on export. Viewers cannot tap or interact with flattened pixels. |
| **Export Formats & Quality** | `Uint8List` image bytes (PNG, JPEG, WebP), quality factor 0.0-1.0, isolated offscreen rasterization | Offscreen still-image export to temporary file | **Compliant for raster images.** |
| **Memory Management** | Uses Flutter background isolates for PNG/JPEG encoding to prevent UI thread frame drops | High-res camera image handling (12MP–48MP) | **Moderate Risk.** Decoding full 48MP camera images into uncompressed RGBA bitmaps requires 150MB–250MB RAM. Requires explicit downsampling before passing to editor. |
| **Video Editing** | **None.** Pure still-image editor. | Video timeline, video trimming, video export | **Not Supported.** |

### 3.3 The Fatal Incompatibility: Pixels vs Metadata
In `lib/overlays/story_overlay.dart`, lines 12–14 state:
> *"Overlays are data, not pixels: the editor serializes them with [toJson], the viewer rebuilds them as widgets. This is the deliberate inversion of flutter_story_editor's flatten-to-pixels export."*

If `pro_image_editor` is used as the root Story editor:
1. When a user adds a Poll or Quiz sticker, `pro_image_editor` treats it as a `WidgetLayer`.
2. When the user taps "Export", `pro_image_editor` renders the entire canvas to a static PNG/JPEG.
3. The resulting image contains the visual representation of the poll, but **the underlying data is lost**.
4. In the viewer, other users cannot click poll options, slide the emoji slider, answer questions, or tap links.
5. The FocusGram backend cannot track poll votes or quiz metrics.

**Verdict on `pro_image_editor`:**
It **cannot serve as the top-level StoryEditor or unified composition engine**. However, its modular sub-editors (specifically image cropping, color tuning, and filters) can be wrapped behind an `ImageEditorAdapter` to perform pre-composition image adjustments.

---

## 4. Deep-Dive Evaluation: `easy_video_editor`

### 4.1 Version Verification & Licensing
- **Target Version**: `^0.1.7`.
- **Actual Published Version**: **`0.1.7`** is published on pub.dev.
- **License**: **MIT License**. Fully permissive for commercial application.
- **Platform Support**: **Android** (via Media3 Transformer) and **iOS** (via AVFoundation, iOS 13.0+). No Web, Windows, macOS, or Linux support.

### 4.2 Feature Matrix vs Story Kit Requirements

| Feature Category | `easy_video_editor: 0.1.7` Capability | FocusGram Story Kit Requirement | Alignment Assessment |
|---|---|---|---|
| **Video Trimming** | `trim(startTimeMs: int, endTimeMs: int)` | Timeline trimming to 15s/30s story duration | **Compliant.** Direct millisecond boundary trimming. |
| **Video Merging** | Merges multiple video files sequentially | Concatenating multi-clip video stories | **Compliant.** Basic video clip merging. |
| **Speed Adjustment** | `speed(speed: double)` (e.g. 0.5x, 1.5x, 2.0x) | Video playback speed control | **Compliant.** Native playback rate adjustment. |
| **Transformations** | Scale dimensions, rotate (90°, 180°, 270°), crop to aspect ratio, flip horizontal/vertical | 9:16 portrait orientation, video rotation | **Compliant.** Uses native transformation matrices. |
| **Compression & Quality** | Preset output resolutions: 360p, 480p, 720p, 1080p, 4K | 1080x1920 (1080p) story video export | **Compliant.** Hardware-accelerated H.264 encoding. |
| **Frame & Thumbnail** | Extracts thumbnails at timestamp; reads raw RGBA8888 frame pixels | Timeline scrubber thumbnail filmstrip | **Compliant.** Fast native thumbnail generation. |
| **Metadata Retrieval** | Width, height, duration, bitrate, rotation, audio channels | Video probing during media import | **Compliant.** Efficient metadata inspection. |
| **Export Progress** | `onProgress: (double fraction)` callback (0.0 to 1.0) | User-facing export progress bar | **Compliant.** Reports transcode progress. |
| **Export Cancellation** | **None.** The `VideoEditorBuilder.export()` method has **no cancellation token or cancel API**. Once started, native transcode cannot be stopped. | Cancellation safety: user cancels export, background task terminates immediately, temp files deleted. | **FATAL DEFECT.** Violates P0 cancellation requirements. An un-cancellable 60-second 4K transcode continues in the background, consuming CPU, battery, and storage. |
| **Animated Overlays** | **None.** Cannot composite or burn text, stickers, drawings, or shapes into the exported video. | Video overlays: animated text, stickers, shapes, drawings synchronized to video timeline. | **FATAL GAP.** Leaves videos completely un-decorated on export. |
| **Audio Mixing** | `removeAudio()`, `extractAudio()`. **Cannot mix external music tracks, voiceover, or adjust volume balance.** | Add music/audio track, volume balance, audio ducking against video audio. | **FATAL GAP.** Cannot mix background music with camera audio. |
| **UI Components** | **None.** Headless processing library only. No timeline scrubber widget, no trimmer bar, no preview player. | Cohesive Story video editor UI. | **Requires Full In-House UI.** |

### 4.3 Detailed Technical Gaps in `easy_video_editor`
1. **Lack of Video Overlay Compositing**:
   FocusGram Story Kit requires video export with burned-in overlays (rich typography, drawings, stickers, and timestamps). `easy_video_editor` only invokes basic native transcoding pipelines (`Transformer` on Android, `AVAssetExportSession` on iOS). It does NOT implement timestamp-aware `BitmapOverlay` or `AVVideoCompositionCoreAnimationTool`. If used alone, any text, drawings, or stickers created on a video slide will be **completely missing from the exported MP4**.
2. **Missing Cancellation Protocol**:
   The native implementation in `easy_video_editor` does not expose an interrupt handle or cancel callback. Once a user triggers export of a high-resolution video, if they hit "Cancel" or close the editor, the native thread continues burning CPU and battery until completion.
3. **No Audio Multiplexing**:
   Stories frequently include added background music. `easy_video_editor` can only strip audio or extract audio; it cannot mix two PCM audio streams together.

**Verdict on `easy_video_editor`:**
It **cannot serve as a complete video editing solution for Story Kit**. It is solely a headless video transform utility. If adopted, it would still require an entirely custom native overlay compositing engine, custom audio mixer, and custom cancellation mechanism.

---

## 5. Dependency Compatibility Matrix & Flutter/Dart Constraints

| Dimension | `focusgram_story_kit` Constraint | `pro_image_editor: 14.22.0` | `easy_video_editor: 0.1.7` | Compatibility Verdict |
|---|---|---|---|---|
| **Dart SDK** | `^3.5.0` | `>=3.0.0 <4.0.0` | `>=3.0.0 <4.0.0` | **Compatible** |
| **Flutter SDK** | `>=3.24.0` | `>=3.22.0` | `>=3.0.0` | **Compatible** |
| **Android SDK** | Min SDK 21+ | Min SDK 21 | Min SDK 21 (uses Media3 1.2+) | **Compatible** |
| **iOS Deployment** | iOS 13.0+ | iOS 12.0+ | iOS 13.0+ (AVFoundation) | **Compatible** |
| **Transitive Dependencies** | `cached_network_image`, `video_player` | `vibration`, `http`, `image` | `flutter`, `plugin_platform_interface` | **No version conflicts** |
| **Package Size Impact** | ~50 KB (pure Dart) | ~450 KB (Dart UI assets + icons) | ~120 KB (native Kotlin/Swift bridges) | **Acceptable** |
| **Native Toolchain Requirement** | Pure Dart package on `main` | Pure Dart package (no native code) | Requires Android Gradle + iOS CocoaPods/SPM | **Breaks "pure Dart" nature of Story Kit on `main`** |

> **Crucial Observation:** On `main`, `pubspec.yaml` line 33 explicitly specifies:  
> `# No native plugin platforms in this package — pure Dart/UI + widget tests.`  
> Adding `easy_video_editor` transforms `focusgram_story_kit` from a pure Flutter package into a platform-dependent native plugin package.

---

## 6. Strategic Recommendations & Architecture Decisions

### Decision 1: Do Not Couple Story Kit Public API to Either Third-Party Package
Neither `pro_image_editor` nor `easy_video_editor` should ever be imported or exposed in `lib/focusgram_story_kit.dart` or any public-facing model/interface. 

### Decision 2: Maintain an In-House Canonical Story Composition Model
The Story Kit must maintain its own unified `StoryCompositionModel` (or `StoryProject`) representing:
- Ordered story pages (photo or video).
- Normalized resolution-independent coordinates `(x, y, width, height, rotation, scale, opacity, zIndex)`.
- Interactive overlay metadata (`StoryOverlay`: polls, quizzes, sliders, questions, countdowns, links, mentions).
- Visual overlay elements (rich text, stickers, vector shapes, freehand drawings).
- Background media specification (source URI, aspect ratio, trim bounds, volume, filters).

### Decision 3: Engine Role Assignments
1. **Top-Level Editor UI**: Custom Story Kit canvas providing unified tools (text, stickers, drawing, shapes, interactive widgets, templates) identical across both photo and video modes.
2. **Photo Cropping & Tuning**: `pro_image_editor` can be utilized internally via an `ImageEditorAdapter` as a modal sub-sheet specifically for non-destructive photo cropping, rotation, and color matrix adjustments.
3. **Video Trimming & Scaling**: `easy_video_editor` can be utilized internally via a `VideoEditorAdapter` strictly for headless video trimming, rotation, and compression—provided native plugin integration is authorized.
4. **Video Overlay Compositing**: Must use a timestamp-synchronized overlay renderer (Media3 `BitmapOverlay`/`GlEffect` on Android, `AVVideoCompositionCoreAnimationTool` on iOS) to burn animated text, stickers, drawings, and shapes into exported video frames while preserving structured data for the viewer.
5. **Video Playback & Preview**: Retain `video_player` with custom timeline scrubbing and overlay preview sync.
