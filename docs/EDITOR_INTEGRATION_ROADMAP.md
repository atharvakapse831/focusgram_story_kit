# FocusGram Story Kit — Editor Integration Roadmap & Execution Plan

**Status:** Proposed Roadmap & Phase Gate Specification  
**Repository:** `atharvakapse831/focusgram_story_kit`  
**Branch:** `main`  
**Date:** 2026-11-01  
**Target Milestone:** Phased delivery of unified Image and Video StoryEditor  

---

## 1. Executive Summary

This roadmap defines the engineering milestones, dependency governance, testing gates, and verification criteria required to implement the **Unified StoryEditor Architecture** in `focusgram_story_kit`.

The integration sequence is organized into 8 sequential milestones designed to guarantee:
1. Strict isolation of third-party dependencies (`pro_image_editor`, `easy_video_editor`).
2. Preservation of the interactive metadata overlay contract (`StoryOverlay`).
3. Lifecycle and cancellation safety across Android and iOS platforms.
4. Deterministic multi-page mixed-media story export.

---

## 2. Dependency Decisions Summary

| Candidate Package | Decision | Operational Scope | Maintenance & Risk Rationale |
|---|---|---|---|
| **`pro_image_editor: ^14.23.0`** | **DEFERRED / REJECTED AS CORE ENGINE** | May only be invoked as an optional modal pre-processor for image cropping and color tuning. | Flattens interactive overlays into pixels on export. Incompatible with FocusGram's interactive sticker metadata model. Requires custom overlay engine. |
| **`easy_video_editor: ^0.1.7`** | **DEFERRED / REJECTED AS COMPLETE VIDEO ENGINE** | Headless video trimming and scaling utility only. | Completely lacks overlay compositing and cancellation APIs. Cannot burn text/stickers into video or stop runaway 4K exports. |
| **`video_player: ^2.9.2`** | **ADOPTED / RETAINED** | In-editor video preview playback and timeline scrubbing. | Established first-party Flutter plugin with reliable texture rendering. |
| **In-House Native Compositor** | **MANDATORY** | Media3 (Android) and AVFoundation (iOS) timestamp-synchronized overlay compositing. | Only viable architecture that delivers video export with burned-in animated text, stickers, drawings, and shapes without losing interactive data in the viewer. |

---

## 3. Phased Execution Milestones

```
Milestone 1: Foundation & Abstraction Contracts
       │
       ▼
Milestone 2: Media Import & Session Lifecycle
       │
       ▼
Milestone 3: Unified Canvas & Overlay Interaction
       │
       ▼
Milestone 4: Image Engine Adapter & Still Export
       │
       ▼
Milestone 5: Video Engine Adapter & Timeline Scrubber
       │
       ▼
Milestone 6: Native Video Overlay Compositor (Media3 / AVFoundation)
       │
       ▼
Milestone 7: Mixed-Media Multi-Page Story Orchestration
       │
       ▼
Milestone 8: Hardening, Verification & Host Integration
```

---

### Milestone 1: Foundation, Data Contracts & Public API Abstraction
**Objective:** Define the core domain models, public API interfaces, and adapter contracts without adding third-party dependencies.

- **Tasks**:
  1. Define `StoryCompositionModel`, `StoryPageModel`, and `StoryElementModel` representing the engine-independent document graph.
  2. Implement resolution-independent normalized coordinate geometry `(x, y, width, height, rotation, scale, opacity, zIndex)`.
  3. Define abstract adapter interfaces:
     - `ImageEditorAdapter`
     - `VideoEditorAdapter`
     - `StoryVideoExportAdapter`
  4. Define public contracts: `StoryEditor`, `StoryEditorConfig`, `StoryInputMedia`, `StoryEditorResult`, `StoryCancellationToken`, and `StoryExportProgress`.
  5. Implement typed exception hierarchy (`StoryEditorException`).
- **Exit Criteria**:
  - All contracts compile with 0 analyzer warnings.
  - Serialization unit tests pass for `StoryCompositionModel` (JSON round-trip with full backward/forward compatibility).
  - No third-party packages imported in public barrel exports.

---

### Milestone 2: Media Import, Probing & Temporary Workspace Management
**Objective:** Build safe media intake, metadata inspection, and deterministic temporary file lifecycle management.

- **Tasks**:
  1. Implement `MediaImportService`:
     - Probes image dimensions, EXIF rotation, and MIME types.
     - Probes video duration, bitrate, resolution, framerate, and audio track presence.
     - Enforces constraints (e.g. maximum video duration 60s, maximum photo file size).
  2. Implement `TemporaryStorageManager`:
     - Creates isolated session directories: `${tempDir}/story_kit/session_${uuid}/`.
     - Provides atomic file creation, temporary file renaming, and safe deletion.
     - Implements orphan directory cleanup on application startup.
  3. Implement `StoryCancellationToken` propagation across asynchronous import operations.
- **Exit Criteria**:
  - Unit tests verify corrupted, empty, or unsupported media files throw typed `MediaImportException`.
  - Integration tests verify session directory is completely wiped on cancellation or error.
  - No temporary file leaks occur across 100 consecutive simulated sessions.

---

### Milestone 3: Unified Interactive Canvas & Direct Manipulation
**Objective:** Create the central 9:16 story canvas supporting direct manipulation of text, stickers, drawings, and interactive widgets.

- **Tasks**:
  1. Implement `StoryEditorCanvas`:
     - Renders background media (image or video texture).
     - Renders visual overlays (text, stickers, shapes, drawings).
     - Renders interactive widget overlays (polls, quizzes, sliders, countdowns, links, mentions).
  2. Implement `CanvasGestureDetector`:
     - Single-finger drag for translation.
     - Two-finger pinch-to-scale and rotation.
     - Active element bounding box chrome and corner transform handles.
     - Dynamic boundary snapping (center x/y guidelines, edge margins) with haptic feedback.
  3. Implement `UndoRedoManager`:
     - Maintains immutable snapshot stack of `StoryCompositionModel`.
     - Supports granular undo/redo for add, delete, transform, and layer reorder operations.
- **Exit Criteria**:
  - Widget tests verify gesture precision, element selection, and boundary clamping.
  - Undo/redo unit tests verify exact state restoration across 20 sequential operations.
  - Interactive overlays maintain tap detection while in preview mode and transform handles while in edit mode.

---

### Milestone 4: Image Engine Integration & Still-Image Export
**Objective:** Integrate image cropping/tuning tools and build offscreen still-image rasterization.

- **Tasks**:
  1. Implement `ProImageEditorAdapter` (wrapping `pro_image_editor` sub-modules):
     - Provides modal cropping sheet with 9:16, 1:1, 4:5, and custom aspect ratios.
     - Provides color tuning (brightness, contrast, saturation) and filter matrix presets.
     - Returns cropped/adjusted image bytes to the temporary workspace without altering original source file.
  2. Implement `StoryStillImageExporter`:
     - Uses Flutter's `PictureRecorder` and `Canvas` to render background image + Layer 1 visual overlays at high resolution (1080x1920).
     - Encodes to PNG/JPEG inside a background Dart isolate (`compute`).
  3. For FocusGram story publishing, preserve Layer 2 interactive overlays as metadata; for standalone gallery export, composite visual representations.
- **Exit Criteria**:
  - Exported PNG files match canvas dimensions (1080x1920) with crisp typography and anti-aliased drawings.
  - Original camera photos remain unmodified in device gallery.
  - Memory consumption during high-res image export remains under 80 MB.

---

### Milestone 5: Video Engine Integration & Timeline Trimming
**Objective:** Implement video timeline playback, timeline scrubbing, trimming, and headless video transformation.

- **Tasks**:
  1. Integrate `video_player` for editor canvas background:
     - Implements playback control (play, pause, seek, loop).
     - Handles texture sizing, aspect ratio fitting (cover vs contain), and widget disposal.
  2. Implement `StoryTimelineScrubber`:
     - Displays filmstrip thumbnails generated at 1-second intervals.
     - Draggable trim start and trim end handles with millisecond precision.
     - Real-time playhead scrubber synchronized to `video_player`.
  3. Implement `EasyVideoEditorAdapter` (wrapping `easy_video_editor: 0.1.7`):
     - Executes native trimming (`trim(startTimeMs, endTimeMs)`).
     - Executes video scaling and aspect ratio cropping.
     - Wraps native export with timeout and error mapping.
- **Exit Criteria**:
  - Widget tests verify timeline trimming updates video playback bounds accurately.
  - Rapid play/pause/seek operations cause zero controller leaks or crashes.
  - Video trims execute within 3 seconds for 15-second 1080p clips.

---

### Milestone 6: Native Video Overlay Compositor & Cancellation State Machine
**Objective:** Implement timestamp-synchronized overlay compositing and cancellation safety on Android and iOS.

- **Tasks**:
  1. Android Implementation:
     - Media3 `Transformer` integration with `BitmapOverlay` / `GlEffect`.
     - Queries timestamp-driven overlay frames (`getBitmap(presentationTimeUs)`).
     - Synchronizes animated text, entrance/exit sticker animations, and vector shapes to video PTS.
     - Implement explicit cancellation state machine: request cancel -> wait for native termination -> release Media3 pipeline -> delete temp files -> complete future.
  2. iOS Implementation:
     - AVFoundation `AVVideoCompositionCoreAnimationTool` integration.
     - Synchronizes Core Animation layer tree with AVAssetTrack timeline.
     - Cancellation protocol with `AVAssetExportSession.cancelExport()` and atomic cleanup.
  3. Audio Mixing:
     - Multiplexes original video audio track with external background music track.
     - Applies configurable volume levels and audio fade-out at trim boundary.
- **Exit Criteria**:
  - Exported MP4 videos feature exact visual parity with Flutter canvas preview across 10 sample timestamps.
  - Cancellation stress test: cancelling export at 10%, 50%, and 90% terminates native transcode within 100ms and leaves zero temporary files.
  - Audio and video tracks remain perfectly lip-synced throughout playback.

---

### Milestone 7: Mixed-Media Multi-Page Story Orchestration
**Objective:** Enable multi-page stories containing arbitrary sequences of photos and videos.

- **Tasks**:
  1. Implement `StoryPageStrip`:
     - Visual thumbnail strip of all story pages.
     - Reordering via drag-and-drop.
     - Page duplication and deletion.
     - "Add Media" sheet supporting mixed photo/video selection.
  2. Implement `StoryProjectExporter`:
     - Iterates through all pages in the `StoryCompositionModel`.
     - Deterministically dispatches photo pages to `StoryStillImageExporter` and video pages to native video compositor.
     - Aggregates page export outputs into `StoryEditorResult`.
     - Emits cumulative progress across total project slides.
  3. Implement Draft Persistence:
     - Persists active project state to `StoryDraftRepository`.
     - Reopens editable drafts with complete layer, trim, and media state intact.
- **Exit Criteria**:
  - Integration test verifies a 4-page mixed project (Photo -> Video -> Photo -> Video) exports all 4 slides successfully.
  - Draft save and restore test verifies 100% fidelity across all layers and trim boundaries.

---

### Milestone 8: Hardening, Verification & Host Integration
**Objective:** Comprehensive quality audit, performance benchmarking, accessibility, and host application integration.

- **Tasks**:
  1. Memory & Performance Audit:
     - Leak testing with Dart DevTools memory profiler.
     - Stress test with 10 sequential 4K video imports and exports.
  2. Accessibility (a11y):
     - Semantics labels for all toolbar buttons, layer handles, and scrubber controls.
     - High-contrast visual focus indicators.
  3. CI & Verification Suite:
     - Unit tests for all adapters, models, and controllers.
     - Widget tests for canvas, timeline, toolbars, and modal sheets.
     - Native compilation checks for Android Gradle and iOS Xcode.
  4. Integration into FocusGram Mobile:
     - Connect `StoryEditor` to `StoryCubit` and `StoryRepository.uploadStory`.
- **Exit Criteria**:
  - 100% pass rate on all automated unit and widget test suites.
  - Zero memory leaks detected after 20 open-edit-export-close cycles.
  - CI workflow passes clean on Android and iOS runners.

---

## 4. Verification Test Matrix

| Test Suite | Scope | Target Pass Rate | Execution Tool |
|---|---|---|---|
| **Model & Codec Unit Tests** | Document serialization, geometry, undo/redo, coordinate math | 100% | `flutter test test/models/` |
| **Adapter Unit Tests** | Mock image/video adapters, error mapping, cancellation token | 100% | `flutter test test/adapters/` |
| **Canvas & Gesture Widget Tests** | Selection, transform, bounds snapping, tool switching | 100% | `flutter test test/widgets/` |
| **Lifecycle & Interruption Tests** | App backgrounding, controller disposal, draft autosave | 100% | `flutter test test/lifecycle/` |
| **Still Export Integration Tests** | High-res PNG generation, memory budget, isolated rendering | 100% | `flutter test test/export/` |
| **Native Video Compositor Tests** | Frame timestamp parity, audio sync, Media3 cancellation | 100% | Android Instrumentation / iOS XCTest |
| **Mixed-Media Multi-Page Tests** | End-to-end multi-page project creation and export | 100% | `flutter test test/integration/` |

---

## 5. Technical Risk Register & Fallback Plan

| Risk ID | Description | Severity | Likelihood | Mitigation Strategy | Fallback Plan |
|---|---|---|---|---|---|
| **TR-1** | `pro_image_editor` breaking API changes across minor versions | High | Medium | Strict adapter pattern (`ImageEditorAdapter`). Package is never exposed publicly. | Swap with lightweight custom Flutter canvas cropping/filter module. |
| **TR-2** | `easy_video_editor` lacks cancellation and overlay compositing | Critical | High | Do not rely on `easy_video_editor` for overlays. Use dedicated native compositor with Media3 / AVFoundation. | Implement full native plugin directly in Story Kit or host app. |
| **TR-3** | OOM crashes during high-resolution multi-page editing | High | High | Enforce 1080x1920 downsampling on import. Evict offscreen page textures from memory. | Restrict simultaneous active page previews; enforce maximum 10 pages per story. |
| **TR-4** | Audio desynchronization in trimmed videos | Medium | Medium | Force audio re-encoding with constant frame rate (CFR) and fixed 44.1kHz/48kHz sample rate. | Mute original audio or warn user if container has variable frame rate (VFR). |
| **TR-5** | Android Media3 hardware codec incompatibility on budget devices | High | Medium | Check `MediaCodecList` capabilities before configuring Transformer. Fall back to baseline H.264 profile. | Provide software encoding fallback or reduce export resolution to 720p. |
