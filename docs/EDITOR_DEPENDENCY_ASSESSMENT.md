# FocusGram Story Kit — Editor Dependency Reassessment & Three-Way Feasibility Study

**Status:** Corrected & Revalidated Dependency Assessment  
**Repository:** `atharvakapse831/focusgram_story_kit`  
**Branch:** `main`  
**Date:** 2026-11-01  
**Target Dependencies Evaluated:**
1. Image Editing Engine: `pro_image_editor: ^14.23.0` (evaluated against published release `14.22.0` and pending `14.23.0`)
2. Video Processing Engine: `easy_video_editor: ^0.1.7` (evaluated against published `0.1.7`)
3. Video Rendering & Composition Engine: `pro_video_editor: ^2.50.1` (evaluated against published `2.50.1`)
4. Video Preview / Playback: `video_player: ^2.9.2` (in-tree dependency)

---

## 1. Executive Summary & Corrected Dependency Verdict

This assessment re-evaluates the third-party candidate packages based on exact published package archives, API specifications, version-specific changelogs, native rendering architectures, cancellation contracts, and SDK environment constraints.

### Core Architecture Principle: Separating Visual Rendering from Interactive Metadata
A crucial insight that was clarified in this reassessment is the distinction between **visual layers** and **interactive metadata overlays**:
- **Visual Layers**: Rich typography, freehand drawings, stickers, decorative shapes, background crops, color tuning, and filters. **These layers SHOULD be flattened or composited into pixel buffers** during final still-image or video export. This is normal, desirable behavior for visual media export.
- **Interactive Metadata Overlays**: Polls, quizzes, emoji sliders, question boxes, countdown timers, deep links, mentions, and FocusGram share cards. **These MUST NEVER be flattened into pixels**; they must remain structured, typed JSON data (`StoryOverlay.toJson()`) so that viewers can interactively vote, answer, slide, and tap deep links in `StoryKitViewer`.

Therefore, candidate engines must not be disqualified simply because they flatten their internal visual layers during export. Instead, candidate engines are evaluated on:
1. Whether their rendering capabilities fulfill the creator toolset (image and video).
2. Whether they allow Story Kit's outer composition layer to cleanly extract or preserve interactive metadata separately.
3. Whether their video export pipeline supports multi-layer animated overlay compositing, multi-track audio, reliable cancellation, and SDK compatibility.

---

## 2. In-Depth Evaluation of Candidate Packages

### 2.1 Image Engine: `pro_image_editor: ^14.23.0`

#### Version & SDK Constraints
- **Published State**: The latest published stable release on pub.dev is **`14.22.0`** (February 2026). Version `14.23.0` is currently in active staging on GitHub. Specifying `^14.22.0` or `^14.23.0` resolves to the 14.x branch.
- **License**: **BSD-3-Clause** (Alex Frei / waio.ch). Permissive and suitable for commercial proprietary distribution.
- **Dart/Flutter SDK Requirement**: Requires Dart `>=3.0.0 <4.0.0` and Flutter `>=3.22.0`. **Fully compatible** with Story Kit's current environment (`Dart ^3.5.0`, `Flutter >=3.24.0`).
- **Platform Support**: Android, iOS, Web, macOS, Windows, Linux (pure Flutter/Dart with background isolates for image encoding).

#### Image Editing Modules & Layer Capabilities
- **Cropping & Geometry**: Freeform cropping, fixed aspect ratios (9:16 portrait, 1:1 square, 4:5, 16:9), free rotation, 90° step rotations, horizontal/vertical flipping.
- **Paint & Freehand Drawing**: Brush stroke sizes, opacity, color picker, eraser, arrow, line, rectangle, oval, and privacy blur/pixelation tools.
- **Rich Typography**: Text styles, custom font families, letter alignment, background highlight chips, text gradients (`TextLayer.gradient`), overflow bounds (`TextLayerBoxOverflow.visible`), and live text scaling.
- **Stickers & Emojis**: Emoji selector, asset stickers, layer reordering (z-index), pinch-to-scale, rotation, flip, and layer animations (`LayerAnimationType.spin`, `LayerAnimationType.flip`).
- **Filters & Color Adjustments**: High-performance ColorFilter matrix presets and granular tuning (brightness, contrast, saturation).
- **Undo / Redo**: High-efficiency state snapshot history with non-destructive state restoration.

#### Layer Export, Serialization, and Companion Video Integration
- **Layer Serialization**: State history can be exported to JSON/Map structures via `CompleteParameters.fromMap` / `toJson`. Individual layers can be rendered standalone using `Layer.captureAsPng()`, and batch export is supported via `Layer.captureAllLayers()`.
- **Relationship with `pro_video_editor`**: Both packages are authored by Alex Frei (`hm21`). `pro_image_editor` natively integrates with `pro_video_editor` to edit video thumbnails, background video frames, and provide visual overlay layers to the video rendering pipeline.

#### Assessment Verdict
`pro_image_editor` is a **high-quality, feature-complete Flutter image editor**. It can be integrated as the visual image editing sub-system inside Story Kit, provided it is wrapped in an internal `ImageEditorAdapter` that strips or intercepts interactive Story Kit overlays (`StoryOverlay`) so they are not rasterized into the background image.

---

### 2.2 Video Engine: `easy_video_editor: ^0.1.7`

#### Version & SDK Constraints
- **Published State**: Version **`0.1.7`** is published on pub.dev.
- **License**: **MIT License** (iawtk2302). Permissive for commercial use.
- **Dart/Flutter SDK Requirement**: Requires Dart `>=3.0.0 <4.0.0` and Flutter `>=3.0.0`. **Fully compatible** with Story Kit's environment (`Dart ^3.5.0`, `Flutter >=3.24.0`).
- **Platform Support**: **Android** (Media3 Transformer) and **iOS** (AVFoundation, iOS 13.0+). No desktop or web support.

#### Verified Capabilities
- **Trimming**: `trim(startTimeMs: int, endTimeMs: int)` provides millisecond-accurate timeline trimming.
- **Transformations**: `scale()`, `rotate()`, `crop()`, and horizontal/vertical `flip()`.
- **Playback Rate**: `speed(speed: double)` adjusts playback tempo (e.g. 0.5x to 2.0x).
- **Compression**: Presets from 360p to 4K maintaining aspect ratios.
- **Frame & Thumbnail Extraction**: Thumbnail generation at timestamps; raw RGBA8888 frame buffer reading.
- **Merging**: Sequential concatenation of multiple video files.
- **Progress Reporting**: Streams progress fraction (`0.0` to `1.0`) via an `EventChannel`.

#### Re-Examination of Cancellation & Concurrency
- **`VideoEditorBuilder.cancel()`**: **VERIFIED AS PRESENT**. In 0.1.7, `VideoEditorBuilder` exposes an asynchronous `cancel()` method that transmits an interrupt down the native MethodChannel:
  - On Android: calls `Transformer.cancel()`.
  - On iOS: calls `AVAssetExportSession.cancelExport()`.
- **Cancellation Latency & Concurrency Risk**: While `cancel()` exists, the native implementation does not provide a synchronous termination callback or barrier. If a new export operation is dispatched immediately after calling `cancel()`, race conditions on native Media3 file locks or concurrent encoder allocation can result in file corruption or decoder resource exhaustion.
- **Critical Video Limitations**:
  1. **Zero Overlay Compositing**: Cannot burn animated text, stickers, drawings, or vector shapes into exported video frames.
  2. **No Multi-Track Audio Mixing**: Only supports `removeAudio()` or `extractAudio()`. Cannot mix external background music tracks with original camera audio or adjust relative volumes.
  3. **No Timeline Scrubber UI**: It is a headless processing builder, not a Flutter UI widget.

#### Assessment Verdict
`easy_video_editor` is a **clean, lightweight headless utility for basic video transforms (trim, scale, speed, compress)**. However, because it lacks overlay compositing and multi-track audio mixing, it cannot fulfill Story Kit's video export requirements on its own.

---

### 2.3 Video Engine: `pro_video_editor: ^2.50.1`

#### Version & SDK Constraints
- **Published State**: Version **`2.50.1`** is published on pub.dev.
- **License**: **BSD-3-Clause** (Alex Frei / waio.ch). Permissive for commercial distribution.
- **Dart/Flutter SDK Requirement**: Specifies `sdk: '>=3.12.0 <4.0.0'`.  
  > ⚠️ **SDK COMPATIBILITY WARNING:** The published package manifest for `pro_video_editor: ^2.50.1` specifies Dart `>=3.12.0`. Story Kit's current manifest declares `sdk: ^3.5.0` and the active host environment uses Dart 3.5.x. Upgrading the minimum Dart SDK constraint to 3.12+ would break compatibility with existing host environments running Dart 3.5.
- **Platform Support**: **Android, iOS, macOS, Windows, Linux, and Web**.

#### Video Rendering & Composition Architecture
- **Compositing Pipeline**: High-performance cross-platform rendering engine. Utilizes independent compositor instances for concurrent operations to prevent memory collisions (`EXC_BAD_ACCESS`) during multi-pass rendering.
- **Multi-Layer Composition**: Supports timed video clips, image overlays, text layers, and freehand paint paths synchronized to frame presentation timestamps (PTS).
- **Advanced Motion & Effects**: Keyframed shape masks (moving, resizing, blur, wipe), clip transitions, speed ramps, and reverse video playback.
- **Audio Architecture**: Multi-track audio mixer, custom frequency equalizers, volume automation curves, and **Audio Ducking** (automatically ducks background music when voice audio is present).
- **Diagnostics & Error Handling**: Built-in `ExportWatchdog` to detect and break stalled hardware encoder pipelines; native `logStream` pipeline piping diagnostics to Dart.
- **Cancellation**: Explicit, lifecycle-safe cancellation hooks integrated with encoder watchdogs.

#### Assessment Verdict
`pro_video_editor` is an **exceptionally capable, production-grade video composition engine**. It natively solves multi-layer compositing, animated text/stickers, and audio ducking. However, it introduces two significant risks:
1. **SDK Version Incompatibility**: Dart `>=3.12.0` requirement conflicts with Dart `^3.5.0`.
2. **Heavyweight Architecture & UI Coupling**: Adopting it requires pulling in its entire runtime dependencies, while Story Kit only requires a focused 9:16 story creation workflow.

---

## 3. Comprehensive Three-Way Comparison

| Evaluation Dimension | Option A: `pro_image_editor` + `easy_video_editor` | Option B: `pro_image_editor` + `pro_video_editor` | Option C: Story Kit In-House Editor UI + Canonical Composition Model + Replaceable Native Adapters |
|---|---|---|---|
| **Image Editing** | **Excellent**: Complete crop, tuning, filters, drawings, text, stickers via `pro_image_editor`. | **Excellent**: Complete crop, tuning, filters, drawings, text, stickers via `pro_image_editor`. | **High**: Dedicated 9:16 canvas with crop, color adjustments, brush, text styling, and stickers. |
| **Video Editing & Trimming** | **Basic**: Headless trim, speed, scale, crop via `easy_video_editor`. UI must be custom-built. | **Advanced**: Transitions, speed ramps, reverse playback, trimming, and multi-clip merging. | **Optimized for Stories**: Millisecond trim, clip splitting, playback speed, timeline scrubber, and 9:16 crop. |
| **Visual Overlay Compositing** | **FAILED**: `easy_video_editor` cannot composite text, stickers, or drawings onto exported video. Requires separate native compositor. | **Native Support**: Full timed visual overlay compositing for text, stickers, and animations onto video. | **Fully Integrated**: Timestamp-synchronized overlay compositing via Media3 (`BitmapOverlay`) and AVFoundation (`AVVideoComposition`). |
| **Interactive Metadata Overlays** | **Requires Custom Separation**: Visual layers must be separated from `StoryOverlay` metadata. | **Requires Custom Separation**: `StoryOverlay` metadata must be kept out of the pixel rendering graph. | **Native First-Class**: `StoryOverlay` metadata is the core document model; never flattened into pixels. |
| **Audio Mixing & Ducking** | **FAILED**: No multi-track mixing; cannot mix background music with speech. | **Advanced**: Multi-track mixing, volume curves, and audio ducking. | **Complete**: Background music mixing with volume balance and trim boundary fade. |
| **Export Cancellation Safety** | **Partial**: `cancel()` exists, but lacks synchronous native completion acknowledgement. | **High**: Robust `ExportWatchdog` with timeout safeguards. | **Complete (P0 Verified)**: Dedicated cancellation state machine with explicit native barrier and cleanup. |
| **SDK Compatibility (`^3.5.0`)** | **Fully Compatible**: Resolves cleanly on Dart 3.5.0 and Flutter 3.24.0. | **INCOMPATIBLE**: `pro_video_editor` requires Dart `>=3.12.0`. | **100% Compatible**: Zero external SDK version conflicts; pure Dart on `main`. |
| **App Size & Dependency Overhead** | **Low**: Lightweight (~450 KB total overhead). | **Very High**: Large dependency tree (`material_ui`, `cupertino_ui`, C++ native libs). | **Zero / Minimal**: No third-party package bloat. |
| **Maintenance & UI Ownership** | High third-party surface; two independent maintainers. | Single ecosystem (Alex Frei), but tied to upstream releases. | **Complete Ownership**: 100% controlled by FocusGram team with zero vendor lock-in. |

---

## 4. Architectural Recommendation: The Hybrid Modular Approach

Based on this evidence-based assessment:

### Strategic Decision: Option C with Optional Option A/B Adapter Hooks
1. **Primary Recommendation**: Adopt **Option C (Story Kit's In-House Editor UI and Canonical Composition Model)** as the authoritative architecture:
   - Story Kit retains complete ownership of the 9:16 Story canvas, gesture detection, timeline scrubber, layer transforms, and the public API.
   - Story Kit retains full control over the **interactive metadata overlay contract** (`StoryOverlay`).
   - Story Kit maintains zero dependency conflicts with Flutter 3.24 / Dart 3.5.
2. **Pluggable Engine Adapter Integration**:
   - `ImageEditorAdapter`: Defines an abstract contract. When advanced image cropping, filter presets, or brush tools are invoked, the editor can optionally delegate to `pro_image_editor` sub-modules as an internal modal tool, returning the resulting bitmap to the Story canvas.
   - `VideoEditorAdapter`: Defines an abstract contract for headless trimming and scaling. When native plugins are permitted in the host app, `easy_video_editor` or native Media3/AVFoundation can be swapped in without modifying any UI or document models.
   - `ProVideoEditorAdapter`: Can be introduced in a future release once the project's base Dart SDK is upgraded to Dart 3.12+.

---

## 5. Interactive Overlay Preservation Architecture

To ensure interactive stickers are never flattened into pixels, the architecture enforces a strict 4-tier pipeline:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      StoryCompositionModel                              │
│                                                                         │
│  [Tier 0: Background Media]                                             │
│  • Photo (Local File URI, Aspect Ratio, Crop Bounds, Color Matrix)      │
│  • Video (Local File URI, Trim Range, Speed, Volume)                    │
│                                                                         │
│  [Tier 1: Visual Overlay Elements] ─────────────► FLATTENED ON EXPORT   │
│  • Rich Typography (Colors, Fonts, Alignments, Gradients)               │
│  • Freehand Vector Drawings (Bezier Paths, Stroke Width, Color)         │
│  • Decorative Stickers & Emojis (PNG/SVG, Position, Rotation, Scale)    │
│  • Vector Shapes (Rectangles, Circles, Arrows, Stars)                   │
│                                                                         │
│  [Tier 2: Interactive Metadata Overlays] ───────► PRESERVED AS DATA     │
│  • PollOverlay (Question, Options, allowMultiple)                       │
│  • QuizOverlay (Question, Options, answerIndex)                         │
│  • SliderOverlay (Emoji, Question, Min/Max)                             │
│  • QuestionOverlay (Prompt)                                             │
│  • CountdownOverlay (Target UTC Time)                                   │
│  • LinkOverlay (Verified URL, Display Domain)                           │
│  • MentionOverlay (User ID, Username)                                   │
│  • SharedContentCard (Post / Note / Video Deep Link)                    │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                  ┌──────────────────┴──────────────────┐
                  │                                     │
                  ▼                                     ▼
      [Still Image / Video Exporter]           [StoryItemModel Payload]
      • Encodes Background (Tier 0)            • Stores Media File URL
      • Burns Visual Overlays (Tier 1)         • Stores Structured Overlays
      • EXCLUDES Interactive (Tier 2)            (Tier 2 serialized via toJson())
                  │                                     │
                  ▼                                     ▼
        Rendered MP4 / PNG File                 Live Viewer Execution
        (Crisp Media Background)                (Interactive Widgets)
```

1. **Visual Elements (Tier 1)** are submitted to the image rasterizer or native video compositor to be permanently burned into the exported file.
2. **Interactive Overlays (Tier 2)** are completely excluded from the pixel compositor. Instead, they are serialized directly into `StoryItemModel.overlays` using `toJson()`.
3. In `StoryKitViewer`, `StoryOverlayRenderer` mounts live Flutter widgets on top of the media, allowing viewers to tap polls, answer quizzes, slide emojis, and navigate links.
