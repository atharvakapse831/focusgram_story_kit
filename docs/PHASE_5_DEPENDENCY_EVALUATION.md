# FocusGram Story Kit — Phase 5 Dependency Evaluation

**Document Version:** 1.1.0  
**Status:** Evaluation Refined & Architecture Approved  
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
| **`video_thumbnail`** | MIT | ~1.2 MB | Yes (Native platform channels) | None | Medium (Third-party wrapper) | **DEFERRED** (Use native adapter) |
| **Flutter Built-in Motion** (`dart:ui` & `AnimationController`) | BSD-3-Clause | 0 MB | **Yes** (Impeller / Skia GPU) | None | Maximum (Flutter Core) | **YES** (Recommended Animation Engine) |

---

## 3. Deep-Dive Domain Analysis

### 3.1 Video Playback & Timeline Scrubbing: `video_player` (^2.9.2) Evaluation Against Flutter 3.29.0+ & Dart 3.7.0+

#### Package Status & SDK Compatibility
- **Status in Repo:** Declared in `pubspec.yaml` (line 24: `video_player: ^2.9.2`).
- **Flutter SDK Target:** `>=3.29.0`
- **Dart SDK Target:** `^3.7.0`

#### Architectural Fit with Flutter 3.29.0+ & Impeller
1. **Texture Registry Lifecycle:**
   - `video_player` registers a platform texture ID via Flutter's `TextureRegistry` (`SurfaceTexture` / `SurfaceProducer` on Android, `FlutterTexture` backed by `CVPixelBufferRef` on iOS).
   - In Flutter 3.29.0+, the Impeller rendering backend is the default rendering engine on iOS and standard on modern Android. Impeller composites native textures directly into the GPU scene graph without CPU readback.
   - *Requirement:* To prevent memory leaks or blank/black frames on surface recreation (e.g. app backgrounding/foregrounding), `VideoPlayerController` disposal and pause/resume lifecycle hooks must be strictly coordinated via `AppLifecycleListener`.
2. **Precision Scrubbing Contract:**
   - `video_player` provides `seekTo(Duration)`. On Android (`ExoPlayer`), `seekTo` defaults to keyframe synchronization; for exact frame positioning during timeline scrubbing, the native implementation supports exact seeking when the gesture finishes.
   - During continuous timeline scrubber drags, `StoryTimelineController` uses throttled approximate seeks to prevent texture decode starvation, and commits an exact seek on drag release (`onHorizontalDragEnd`).
3. **Role Boundary:**
   - `video_player` is used **exclusively for in-canvas interactive preview and timeline scrubbing**. It is **not** used for offline video export or audio multiplexing.

---

### 3.2 Clarification: Zero `pub.dev` Dependencies vs. Native Android/iOS Dependencies

A critical architectural distinction exists between Dart package dependencies and platform-level build dependencies:

```mermaid
flowchart TD
    subgraph DartSpace["Pure Flutter / Dart Space (pubspec.yaml)"]
        SK["focusgram_story_kit"]
        VP["video_player: ^2.9.2 (Existing)"]
        CNI["cached_network_image (Existing)"]
        EXP["StoryVideoExportAdapter (Abstract Interface)"]
        SK --> VP
        SK --> CNI
        SK --> EXP
    end

    subgraph NativeSpace["Platform Hardware Acceleration Layer"]
        EXP -.->|Host App Implementation / Native Plugin| NativeImpl["Native Video Export Implementation"]
        NativeImpl -->|Android (build.gradle)| Media3["androidx.media3:media3-transformer<br/>androidx.media3:media3-effect"]
        NativeImpl -->|iOS (System Frameworks)| AVF["AVFoundation + VideoToolbox<br/>CoreMedia + CoreAnimation (0 CocoaPods)"]
    end
```

1. **Pure Dart Layer (`pubspec.yaml`):**
   - **Zero new `pub.dev` dependencies are added to `pubspec.yaml`.**
   - The story kit remains a modular, lean Dart package with no dependency bloat, no third-party NLE wrappers, and no licensing entanglements.
2. **Native Platform Layer:**
   - Video hardware encoding, multi-track audio multiplexing, and final MP4 packaging require OS-level hardware encoder access (`MediaCodec` on Android, `VideoToolbox` on iOS).
   - On **Android**, native export leverages Google's official AndroidX Media3 libraries:
     - `androidx.media3:media3-transformer`
     - `androidx.media3:media3-effect`
     - `androidx.media3:media3-common`
     These are modern, Google-maintained AndroidX dependencies included in the host Android build or platform plugin, adding minimal DEX footprint and utilizing device hardware encoders.
   - On **iOS**, native export uses system frameworks built directly into iOS firmware:
     - `AVFoundation` (`AVAssetExportSession`, `AVMutableVideoComposition`, `AVVideoCompositionCoreAnimationTool`)
     - `VideoToolbox` (hardware H.264/HEVC encoding)
     - `CoreMedia` & `CoreAudio`
     These require **zero CocoaPods or SPM third-party packages**.

---

### 3.3 Platform Video Composition & Crossfade Mechanics: Android Media3 vs. iOS AVFoundation

When combining background video with animated overlays or video transitions, platform composition architectures exhibit distinct capabilities and constraints:

#### Android Media3 Transformer: Capabilities & Crossfade Constraints
- **Architecture:** AndroidX `Media3 Transformer` processes video via a pipeline of `MediaCodec` decoders $\to$ OpenGL ES shader effects (`GlEffect` / `GlShaderProgram`) $\to$ `MediaCodec` hardware encoder $\to$ `Muxer`.
- **Overlay Composition:** Static and animated overlays are blended into the video stream via an OpenGL overlay shader by passing RGBA bitmaps or dynamic overlay surfaces.
- **Crossfade Limitations:**
  - True video-to-video crossfades (fading between two concurrent video clips) require decoding two video streams simultaneously.
  - On many mid-to-low-tier Android devices (e.g. MediaTek, older Qualcomm chipsets), hardware decoders have strict concurrent instance limits (often capped at 2 to 4 simultaneous `MediaCodec` instances across the entire OS).
  - If the host app or system is playing audio/video while Transformer attempts dual decoding, decoder resource starvation (`MediaCodec.CodecException: ERROR_INSUFFICIENT_RESOURCE`) occurs.
- **Phase 5 Strategy for Android:**
  - Standard story pages contain a single primary video asset with overlay layers (text, stickers, shapes, drawings). Media3 handles single-video decode + GL overlay blend with 100% hardware stability.
  - Video cut transitions (concatenation) are handled sequentially via `EditedMediaItemSequence`.
  - For crossfades between pages, the kit provides an RGBA frame-blended texture transition, avoiding dual-hardware-decoder starvation.

#### iOS AVFoundation: Custom Compositor Strategy
- **Architecture:** iOS uses `AVMutableVideoComposition` and `AVAssetExportSession`.
- **Custom Compositor Contract:**
  - For advanced transition parity and pixel-accurate blending, AVFoundation supports custom compositors conforming to the `AVVideoCompositing` protocol.
  - In `startRequest:`, the custom compositor receives pixel buffers (`CVPixelBufferRef`) from multiple source tracks and renders into the target pixel buffer using Metal (`MTLRenderCommandEncoder`) or Core Image (`CIContext`).
  - Unlike Android, iOS hardware decoders cleanly handle concurrent 1080p video streams on all devices running iOS 14+.
- **CoreAnimation Alternative:**
  - For standard story exports (background video + animated Flutter overlays), `AVVideoCompositionCoreAnimationTool` synchronizes an exported `CALayer` hierarchy containing Flutter's animated vector and text assets with the video track at zero export overhead.

---

### 3.4 Animation & Motion System
- Built-in Flutter `dart:ui`, `AnimationController`, and `Curve` library are mathematically pure, thoroughly optimized, and natively supported by the Impeller GPU engine.
- Build `OverlayAnimation` on top of pure Flutter `Curve` primitives (`Curves.easeIn`, `Curves.easeOut`, `Curves.elasticOut`, `Curves.bounceOut`). This ensures zero dependency bloat and pure mathematical determinism during both preview and frame-by-frame export.

---

## 4. Final Architecture & Dependency Plan

To preserve the Hippocratic Oath (Rule 1) and Minimal Diff Principle (Rule 3):
1. **No new third-party dependencies are required in `pubspec.yaml` for Phase 5.**
2. Existing dependencies (`video_player: ^2.9.2`, `cached_network_image`, `flutter_lints: ^5.0.0`) are sufficient to build the complete document models, timeline engine, animated canvas layers, timeline scrubber UI, cover selector, and export contracts.
3. The video export subsystem will use a clean, modular adapter pattern (`StoryVideoExportAdapter`), allowing native platform hardware pipelines to be plugged in seamlessly without polluting the Dart package core.
