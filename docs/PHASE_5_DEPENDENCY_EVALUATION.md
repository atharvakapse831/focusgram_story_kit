# FocusGram Story Kit — Phase 5 Dependency Evaluation

**Document Version:** 1.0.0  
**Status:** Evaluation Completed & Strategy Formulated  
**Target Branch:** `phase-1/implementation`  

---

## 1. Evaluation Scope & Core Objectives

Phase 5 introduces timeline scrubbing, animated overlays, video playback, and video export. To ensure FocusGram Story Kit remains lightweight, maintainable, compliant with open-source licenses, and suitable for commercial deployment on Google Play and Apple App Store, this document evaluates candidate libraries and native platform technologies across four critical domains:
1. Video Decoding & Timeline Playback.
2. Video Composition & Hardware Encoding/Export.
3. Thumbnail & Cover-Frame Generation.
4. Animation & Easing Engines.

---

## 2. Comparative Evaluation Matrix

| Candidate Solution | License | Binary Size Impact | HW Acceleration | iOS App Store Risk | Maintenance Viability | Recommended? |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`video_player` (^2.9.2)** (Current) | BSD-3-Clause | ~0 MB (Already integrated) | **Yes** (ExoPlayer / AVPlayer) | None (Official plugin) | Very High (Flutter Core Team) | **YES** (Retain for Canvas Playback) |
| **`ffmpeg_kit_flutter`** | LGPL-3.0 / GPL-3.0 | **+45 MB to +85 MB** | Partial (Software CPU heavy) | **High** (Patent & GPL review) | Low (Discontinued/Archived upstream) | **NO** (Banned) |
| **Native Platform Pipeline** (`Media3 Transformer` / `AVFoundation`) | Platform Built-in | **~0 MB** (Uses OS frameworks) | **Yes** (On-chip MediaCodec & VideoToolbox) | None (Standard Apple APIs) | Maximum (Android & iOS OS standard) | **YES** (Recommended Export Architecture) |
| **`video_thumbnail`** | MIT | ~1.2 MB | Yes (Native platform channels) | None | Medium (Third-party wrapper) | **CONDITIONAL** (Adapter-based) |
| **Flutter Built-in Motion** (`dart:ui` & `AnimationController`) | BSD-3-Clause | 0 MB | **Yes** (Impeller / Skia GPU) | None | Maximum (Flutter Core) | **YES** (Recommended Animation Engine) |

---

## 3. Deep-Dive Domain Analysis

### 3.1 Video Playback & Timeline Scrubbing

#### Candidate: `video_player` (version `^2.9.2`)
- **Status in Repo:** Already declared in `pubspec.yaml` (line 24).
- **Architecture:** Backed by Google's `ExoPlayer` / AndroidX Media3 on Android and Apple's `AVPlayer` on iOS.
- **Suitability for Scrubbing:**
  - `seekTo(position)` supports millisecond-accurate seeking.
  - Generates a Flutter texture ID (`Texture(textureId: id)`), allowing video frames to be composited directly inside Flutter's widget tree with 2D transformations (rotation, scaling, translation, clip rect, opacity).
- **Assessment:** **Retain and standardize.** `video_player` provides optimal playback performance with zero additional binary footprint.

---

### 3.2 Video Composition, Encoding & Export

#### Candidate 1: `ffmpeg_kit_flutter`
- **Pros:** Extremely versatile command-line syntax for video filters, overlay compositing, and audio multiplexing.
- **Cons & Critical Risks:**
  1. **Licensing:** FFmpeg uses LGPL 2.1/3.0 with optional GPL components (x264, x265). Dynamic linking requirements under LGPL create compliance burdens, while GPL components are legally incompatible with proprietary commercial applications.
  2. **Binary Bloat:** Adds between 45MB and 85MB to the final APK/IPA download size, unacceptable for a focused modular story library.
  3. **Upstream Abandonment:** Tanersener's `ffmpeg-kit` was officially archived in 2024. Maintained forks are fragmented and prone to NDK/Clang toolchain breakage on newer Xcode and Android API levels.
  4. **Performance:** CPU-based software encoding is slow, consumes excessive battery power, and generates device heat on mobile hardware.
- **Verdict:** **REJECTED.** Banned from inclusion in the core kit.

#### Candidate 2: Native OS Hardware Pipelines (Media3 Transformer & AVFoundation)
- **Architecture:**
  - **Android:** AndroidX `Media3 Transformer` uses `MediaCodec` hardware video encoder and OpenGL ES shaders for overlay blending.
  - **iOS:** Apple `AVFoundation` uses `AVAssetExportSession`, `AVMutableVideoComposition`, and `AVVideoCompositionCoreAnimationTool` with Apple Silicon hardware encoding engines.
- **Pros:**
  - **Speed:** 5x to 10x faster export compared to software encoding.
  - **Zero App Size Increase:** Utilizes system libraries already present in Android and iOS firmware.
  - **Reliable Battery & Thermals:** Zero CPU saturation; hardware decoders and encoders handle pixel pipelines.
- **Verdict:** **SELECTED.** Provide a decoupled `StoryVideoExportAdapter` contract in Story Kit, with native platform implementations utilizing Media3 and AVFoundation.

---

### 3.3 Thumbnail & Cover-Frame Generation

#### Evaluation:
- Displaying filmstrip thumbnails in the timeline scrubber requires low-latency decoding of frames at timestamps $t_1, t_2, \dots, t_n$.
- Native platform `MediaMetadataRetriever` (Android) and `AVAssetImageGenerator` (iOS) extract video frames efficiently at arbitrary time offsets.
- **Strategy:** Define `StoryThumbnailProvider` interface. Use `VideoPlayerController` for single-frame live covers, and expose an adapter hook for host-app optimized thumbnail cache generation.

---

### 3.4 Animation & Motion System

#### Evaluation:
- Third-party animation packages (e.g. `simple_animations`, `flutter_animate`) introduce unnecessary dependencies and opinionated APIs that can change or break across major Flutter releases.
- Flutter's built-in `dart:ui`, `AnimationController`, and `Curve` library are mathematically pure, thoroughly optimized, and natively supported by the Impeller GPU engine.
- **Strategy:** Build `OverlayAnimation` on top of pure Flutter `Curve` primitives (`Curves.easeIn`, `Curves.easeOut`, `Curves.elasticOut`, `Curves.bounceOut`). This ensures zero dependency bloat and pure mathematical determinism during both preview and frame-by-frame export.

---

## 4. Final Architecture & Dependency Plan

To preserve the Hippocratic Oath (Rule 1) and Minimal Diff Principle (Rule 3):
1. **No new third-party dependencies are required in `pubspec.yaml` for Phase 5.**
2. Existing dependencies (`video_player: ^2.9.2`, `cached_network_image`, `flutter_lints: ^5.0.0`) are sufficient to build the complete document models, timeline engine, animated canvas layers, timeline scrubber UI, cover selector, and export contracts.
3. The video export subsystem will use a clean, modular adapter pattern (`StoryVideoExportAdapter`), allowing native platform hardware pipelines to be plugged in seamlessly without polluting the Dart package core.
