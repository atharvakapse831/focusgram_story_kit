# FocusGram Story Kit — Phase 5 Architecture Decision Records (ADRs)

**Document Version:** 1.0.0  
**Status:** Approved for Implementation  
**Target Branch:** `phase-1/implementation`  

---

## Index of Architectural Decisions

- **ADR-001:** Video Layer Representation & Canvas Placement
- **ADR-002:** Unified Timeline Clock & Hardware Video Sync Coordinator
- **ADR-003:** Video Composition & Export Engine Architecture
- **ADR-004:** Time-Ranged Layer Interval & Animation Schema
- **ADR-005:** Audio Mixing, Muting & Drift Mitigation Policy
- **ADR-006:** Export Job Lifecycle, Cancellation & Storage Quota Management
- **ADR-007:** Long Video Ingestion & Truncation-Prevention Policy

---

## ADR-001: Video Layer Representation & Canvas Placement

### Context
Story creators frequently record or import full-screen background video, but also increasingly place video stickers, reaction clips, or picture-in-picture videos as composable layers alongside text, drawings, and shapes. We must establish how video media is represented within the `StoryProject` document tree.

### Decision
Support two distinct video integration patterns in `StoryProject`:
1. **Background Video:** Attached directly to `StoryPage.backgroundAsset` with `StoryMediaSourceType.file` or `network`. It scales to fill/fit the canonical 9:16 aspect ratio letterbox and provides the default page duration.
2. **In-Canvas Video Element:** Represented as a `StoryElement` with `type: StoryElementType.video` and `payload: VideoElementPayload`. It supports standard 2D spatial transformations (`x`, `y`, `width`, `height`, `rotation`), z-order stacking, opacity, and layer locking/visibility.

### Rationale
- Decouples full-screen background video from floating video stickers.
- Reuses the existing robust `StoryTransform` coordinate system (0.0 to 1.0 normalized bounds) for in-canvas video widgets.
- Backward compatible with Phase 1–4 schemas without schema version bumping.

### Consequences
- **Positive:** Full-screen background video remains lightweight and performant. In-canvas floating video layers enjoy complete parity with text, shape, and sticker manipulation.
- **Negative:** Multiple simultaneous in-canvas video players can exhaust hardware video decoders on lower-end mobile devices.
- **Mitigation:** Enforce a maximum limit of **1 active playing video layer** simultaneously during preview (inactive video layers render their cached cover frame).

---

## ADR-002: Unified Timeline Clock & Hardware Video Sync Coordinator

### Context
In Flutter, native video playback runs on an independent platform media thread (`ExoPlayer` / `AVPlayer`), while widget animations run on Flutter's vsync animation ticker. When scrubbing or previewing, drift between the native video frame and overlay motion animations creates visual artifacts.

### Decision
Implement a centralized `StoryTimelineController` that acts as the **single source of truth** for time:
- During **playback**, the active `VideoPlayerController.position` updates `StoryTimelineController.currentPosition` via a throttled callback (30–60Hz).
- During **scrubbing / pause**, `StoryTimelineController.seekTo(position)` commands the video player to seek with exact frame tolerance (`seekTo(position)`) while synchronously broadcasting the new timestamp to all animated overlay widgets.
- If no video asset is present on the page (e.g. animated static story), an internal `Ticker`-driven clock provides playback progression.

**Frame-Rate-Relative Synchronization Tolerance:**
Rather than enforcing an arbitrary fixed tolerance (such as 33ms), synchronization tolerance is dynamically computed based on the video source or export target frame rate:
$$\text{SyncTolerance}(\text{fps}) = \pm 1 \text{ frame duration} = \pm \left(\frac{1000}{\text{fps}}\right) \text{ms}$$
- At **60 fps**: $\pm 16.67\text{ms}$
- At **30 fps**: $\pm 33.33\text{ms}$
- At **24 fps**: $\pm 41.67\text{ms}$

```mermaid
sequenceDiagram
    participant User as User / Scrubber
    participant TC as StoryTimelineController
    participant VP as VideoPlayerController (Native)
    participant AW as AnimatedElementBox (Overlays)

    Note over User,AW: Scrubbing Scenario
    User->>TC: seekTo(timestamp)
    TC->>VP: seekTo(timestamp) [Exact Frame]
    TC->>AW: notifyListeners(timestamp)
    AW-->>AW: Interpolate transform & opacity at timestamp

    Note over User,AW: Playback Scenario
    VP->>TC: positionChanged(videoPosition)
    TC->>AW: notifyListeners(videoPosition)
    AW-->>AW: Render motion frame in sync within ±(1000/fps) ms
```

### Consequences
- **Positive:** Guarantees frame-level alignment between overlay entrance/exit animations and underlying video action across both standard (30fps) and high-frame-rate (60fps) assets.
- **Negative:** Exact-frame seeking on video with large keyframe distances (GOP) can cause slight seek latency on older devices.
- **Mitigation:** Use fast seeking during active drag scrubbing, followed by exact keyframe seek on scrub release (`onScaleEnd` / `onPanEnd`).

---

## ADR-003: Video Composition & Export Engine Architecture

### Context
Rendering an exported MP4 story file containing background video, animated text overlays, vector shapes, drawings, and mixed audio is computationally intensive. We must choose an architecture that balances rendering fidelity, export speed, bundle size, platform stability, and transition parity.

### Options Considered
1. **Full FFmpeg (`ffmpeg_kit_flutter`):** Bundle full FFmpeg binaries for Android and iOS.
2. **Pure Flutter Canvas Image-Sequence Dump + Native Muxer:** Render canvas frames to PNG/RGBA byte buffers in Flutter, then pipe to platform hardware encoder (`MediaCodec` on Android, `AVAssetWriter` on iOS).
3. **Platform-Native Composition Pipeline:** Use Android `Media3 / Transformer` and iOS `AVFoundation / AVVideoComposition`.
4. **Abstract Video Export Adapter (`StoryVideoExportAdapter`):** Define a clean interface in the kit with a lightweight native hardware implementation, decoupled from proprietary or GPL-encumbered libraries.

### Decision
Adopt **Option 4 (Abstract Video Export Adapter with Native Hardware Pipeline)**:
- Define `StoryVideoExportAdapter` in `focusgram_story_kit`.
- Implement a two-pass compositing pipeline:
  1. **Visual Overlay Track:** Story Kit renders overlay layers (text, animations, drawings, shapes) at target timestamps into a transparent RGBA image stream or high-efficiency video overlay track.
  2. **Native Hardware Composition:** The platform layer utilizes native OS hardware encoders (`AVVideoCompositionCoreAnimationTool` or `AVVideoCompositing` on iOS, `Media3 Transformer / OpenGL Surface` on Android) to hardware-accelerate video scaling, trimming, overlay blending, and AAC audio muxing.
- Provide a fallback software exporter contract for environments where native hardware pipeline is mocked or disabled.

### Platform Composition Deep Dive & Transition Parity Strategy

#### 1. Android Media3 Transformer & Crossfade Limitations
- `androidx.media3:media3-transformer` processes video streams through an OpenGL ES shader effect pipeline (`GlEffect`).
- **Concurrent Decoding Limitation:** True video-to-video crossfades require decoding two concurrent video streams into an OpenGL shader. On mid-to-low-tier Android devices (e.g. MediaTek or entry-level Qualcomm SoCs), hardware decoders have strict concurrent instance limits (often capped at 2–4 instances total). Attempting dual 1080p hardware decodes during export can trigger `MediaCodec.CodecException: ERROR_INSUFFICIENT_RESOURCE`.
- **Media3 Strategy:**
  - Standard story pages contain a single primary video track; overlays (text, drawings, shapes, stickers) are rendered as an OpenGL texture overlay atop the single hardware-decoded video stream.
  - Video transitions between consecutive story pages utilize sequential `EditedMediaItemSequence` for cut transitions.
  - For cross-dissolve transitions, the kit composites incoming/outgoing frames into an RGBA blended texture stream in Flutter or via a single-pass GL shader, avoiding concurrent dual-hardware-decoder starvation.

#### 2. iOS AVFoundation Custom Compositor Strategy
- On iOS, `AVMutableVideoComposition` supports attaching a custom compositor conforming to the `AVVideoCompositing` protocol.
- **Metal / Core Image Pipeline:** In `startRequest:`, the custom compositor receives pixel buffers (`CVPixelBufferRef`) for both source video and overlay tracks, rendering with sub-millisecond precision via Metal (`MTLRenderCommandEncoder`) or Core Image (`CIContext`).
- **CoreAnimation Tool:** For standard story rendering, `AVVideoCompositionCoreAnimationTool` composites an exported `CALayer` hierarchy containing Flutter's vector elements directly during `AVAssetExportSession`, yielding maximum hardware encoding speed on Apple Silicon.

---

### Technical Prototype: Cross-Platform Video Compositing & Transition Parity

The following prototype illustrates how Flutter timeline math guarantees 100% visual parity between interactive canvas preview and exported native MP4 frames:

```dart
/// 1. PURE DETERMINISTIC TRANSITION MATH (Shared between Preview & Export)
class StoryTransitionMath {
  /// Evaluates normalized transition progress [0.0, 1.0] at timestamp [t].
  static double evaluateProgress({
    required Duration t,
    required Duration start,
    required Duration duration,
    Curve curve = Curves.easeInOut,
  }) {
    if (t < start) return 0.0;
    if (t >= start + duration) return 1.0;
    final elapsedMs = (t - start).inMicroseconds;
    final totalMs = duration.inMicroseconds;
    final linear = (elapsedMs / totalMs).clamp(0.0, 1.0);
    return curve.transform(linear);
  }

  /// Computes the exact 2D transformation matrix and opacity at time [t].
  static ElementVisualState computeState({
    required StoryElement element,
    required Duration t,
    required Size canvasSize,
  }) {
    final range = element.visibleTimeRange;
    if (range != null && !range.isVisibleAt(t)) {
      return ElementVisualState.hidden;
    }

    final anim = element.animation;
    if (anim == null) {
      return ElementVisualState.identity(element.transform, opacity: 1.0);
    }

    // Evaluate entrance transition
    if (t < (range?.start ?? Duration.zero) + anim.entranceDuration) {
      final p = evaluateProgress(
        t: t,
        start: range?.start ?? Duration.zero,
        duration: anim.entranceDuration,
      );
      return _interpolateEntrance(element, p, anim.entranceType);
    }

    // Evaluate exit transition
    final exitStart = (range?.end ?? const Duration(seconds: 15)) - anim.exitDuration;
    if (t >= exitStart) {
      final p = evaluateProgress(
        t: t,
        start: exitStart,
        duration: anim.exitDuration,
      );
      return _interpolateExit(element, p, anim.exitType);
    }

    return ElementVisualState.identity(element.transform, opacity: 1.0);
  }
}

/// 2. FLUTTER RENDER PIPELINE: Frame-by-Frame Canvas Rasterization
class OverlayFrameRasterizer {
  final PictureRecorder _recorder = PictureRecorder();

  Future<Uint8List> renderOverlayFrameRgba({
    required StoryPage page,
    required Duration timestamp,
    required Size targetResolution, // e.g. 1080 x 1920
  }) async {
    final canvas = Canvas(_recorder);
    final painter = StoryOverlayCanvasPainter(
      page: page,
      timestamp: timestamp,
      renderScale: targetResolution.width / 1080.0,
    );
    painter.paint(canvas, targetResolution);
    final picture = _recorder.endRecording();
    final image = await picture.toImage(
      targetResolution.width.toInt(),
      targetResolution.height.toInt(),
    );
    final byteData = await image.toByteData(format: ImageByteFormat.rawRgba);
    image.dispose();
    picture.dispose();
    return byteData!.buffer.asUint8List();
  }
}

/// 3. ABSTRACT EXPORT ADAPTER (Native Hook)
abstract class StoryVideoExportAdapter {
  Future<VideoExportResult> exportVideo({
    required StoryProject project,
    required StoryVideoExportConfig config,
    required Stream<OverlayFrameChunk> overlayStream,
    required void Function(double progress) onProgress,
    required CancellationToken cancelToken,
  });
}
```

```kotlin
// 4. ANDROID NATIVE GL SHADER EFFECT (Media3 Transformer)
// Blends the RGBA overlay texture received from Flutter over the video frame in OpenGL ES.
class StoryOverlayGlShaderProgram(
    private val overlayTextureId: Int
) : GlShaderProgram {
    private val vertexShader = """
        attribute vec4 aFramePosition;
        attribute vec4 aTexCoords;
        varying vec2 vTexCoords;
        void main() {
            gl_Position = aFramePosition;
            vTexCoords = aTexCoords.xy;
        }
    """.trimIndent()

    private val fragmentShader = """
        precision mediump float;
        uniform sampler2D uVideoSampler;
        uniform sampler2D uOverlaySampler;
        varying vec2 vTexCoords;
        void main() {
            vec4 videoColor = texture2D(uVideoSampler, vTexCoords);
            vec4 overlayColor = texture2D(uOverlaySampler, vTexCoords);
            // Alpha compositing: Over operator
            gl_FragColor = overlayColor + videoColor * (1.0 - overlayColor.a);
        }
    """.trimIndent()
}
```

```swift
// 5. iOS AVFOUNDATION CUSTOM COMPOSITOR (AVVideoCompositing)
// Blends pixel buffers with sub-millisecond transition parity via Metal or CoreImage.
final class StoryVideoCompositor: NSObject, AVVideoCompositing {
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        guard let sourcePixelBuffer = asyncVideoCompositionRequest.sourceFrame(byTrackID: videoTrackID),
              let overlayPixelBuffer = asyncVideoCompositionRequest.sourceFrame(byTrackID: overlayTrackID),
              let destinationPixelBuffer = asyncVideoCompositionRequest.renderContext.newPixelBuffer() else {
            asyncVideoCompositionRequest.finish(with: CompositionError.frameFetchFailed)
            return
        }

        let time = asyncVideoCompositionRequest.compositionTime
        // Blend sourcePixelBuffer and overlayPixelBuffer into destinationPixelBuffer using Metal/CIContext
        blendFrames(source: sourcePixelBuffer, overlay: overlayPixelBuffer, destination: destinationPixelBuffer, at: time)
        asyncVideoCompositionRequest.finish(withComposedVideoFrame: destinationPixelBuffer)
    }
}
```

---

## ADR-004: Time-Ranged Layer Interval & Animation Schema

### Context
Elements on a story canvas should not all be static. Users need stickers or text callouts to appear at specific timestamps (e.g., from 00:02 to 00:05 of a 15-second video), and enter/exit with engaging motion transitions (Fade, Scale, Slide, Bounce).

### Decision
Extend `StoryElement` with two optional schema fields:
1. `visibleTimeRange`:
   ```dart
   class LayerTimeRange {
     final Duration start;
     final Duration end;
     bool isVisibleAt(Duration timestamp);
   }
   ```
2. `animation`:
   ```dart
   class OverlayAnimationConfig {
     final OverlayAnimationType entranceType;
     final Duration entranceDuration;
     final OverlayAnimationType exitType;
     final Duration exitDuration;
     final String easingCurve; // 'linear', 'easeIn', 'easeOut', 'easeInOut', 'bounce'
   }
   ```
During canvas rendering and export, the visual state of an element at timestamp $t$ is computed via a pure mathematical function:
$$\text{State}(t) = f(\text{payload}, \text{visibleTimeRange}, \text{animation}, t)$$

### Consequences
- **Positive:** Pure functional evaluation guarantees **100% parity** between live canvas preview and exported video frames.
- **Negative:** Elements popping in and out may cause unexpected layer hit-testing clicks if the playhead moves.
- **Mitigation:** If an element is invisible at current playhead position, it is excluded from canvas hit-testing and selection.

---

## ADR-005: Audio Mixing, Muting & Drift Mitigation Policy

### Context
Stories can include original video audio, background music tracks, and voiceovers. Audio drift (loss of sync between video picture and sound) is a fatal defect in social video apps.

### Decision
Establish an explicit, configurable `VideoAudioPolicy` model:
- `muteOriginal`: Boolean flag to completely disable the source video audio track.
- `originalVolume`: Float multiplier (`0.0` to `1.0`).
- `musicAsset`: Optional `StoryMediaAsset` referencing background soundtrack.
- `musicVolume`: Float multiplier (`0.0` to `1.0`).
- `musicStartTime`: Timestamp offset into soundtrack.

**Configurable Audio Output Specifications:**
Audio export parameters are host-configurable via `StoryVideoExportConfig`:
```dart
enum AudioSampleRate {
  hz44100(44100),
  hz48000(48000);
  final int rate;
  const AudioSampleRate(this.rate);
}
```
- **Configurable Sample Rate:** Host apps can choose `AudioSampleRate.hz44100` (default, standard for music streaming) or `AudioSampleRate.hz48000` (standard for broadcast/post-production).
- **Configurable Bitrate:** Default 128 kbps stereo AAC (configurable up to 256 kbps).

**Frame-Rate-Relative Audio Drift Mitigation Rules:**
1. Master clock is locked to the audio track presentation timestamp (PTS) during native export.
2. If video frames are slightly delayed due to decoding jitter, the audio track continues uninterrupted. Video frames are dropped or duplicated only when drift exceeds the dynamic frame tolerance:
   $$\text{MaxAllowedDrift} = \pm 1 \text{ frame} = \pm \left(\frac{1000}{\text{fps}}\right) \text{ms}$$
3. All input audio streams are resampled to the configured `AudioSampleRate` before multiplexing.

---

## ADR-006: Export Job Lifecycle, Cancellation & Storage Quota Management

### Context
Video exports can take several seconds. Users may cancel an export, receive a phone call, background the app, or run out of disk space. A static multiplier (e.g. 2.5x) is inaccurate for long videos with high resolutions.

### Decision
Model all exports as asynchronous `VideoExportJob` instances:
- Each job generates a unique `jobId` (UUID) and creates an isolated temporary working directory (`<app_temp>/story_export_<jobId>/`).
- **Progress Reporting:** Emits typed `Stream<VideoExportProgress>` with phase indicators (`preparing`, `renderingOverlays`, `encodingVideo`, `muxingAudio`, `finalizing`) and normalized percentage (`0.0` to `1.0`).
- **Cancellation Guarantee:** Calling `job.cancel()` immediately aborts background isolates and native threads, deletes all temporary output files, and guarantees no partial/corrupted video is left on disk or reported as success.

**Dynamic Storage Estimation Strategy:**
Rather than relying on a static 2.5x multiplier, Phase 5 calculates peak disk usage dynamically based on video duration, target bitrates, frame chunking buffers, and container remuxing margins:

$$\text{EstimatedOutputBytes} = \text{TargetDurationSec} \times \left(\frac{\text{VideoBitrateBps} + \text{AudioBitrateBps}}{8}\right)$$

$$\text{PeakTempStorageBytes} = \text{EstimatedOutputBytes} + \text{UncompressedFrameBufferSize} + \text{MuxingBufferMargin}$$

Where:
- $\text{UncompressedFrameBufferSize} = \text{ChunkFrames} \times \text{Width} \times \text{Height} \times 4\text{ bytes (RGBA)}$.
  - Bounded by a sliding window (e.g. 30 frames at $1080 \times 1920 \times 4 \approx 248.8\text{ MB}$), avoiding dumping entire uncompressed videos to disk.
- $\text{MuxingBufferMargin} = 1.2 \times \text{EstimatedOutputBytes}$ (covers temporary MP4 fragment caching and final atom relocation for `faststart`).
- **Safety Minimum Floor:** $\max(\text{EstimatedOutputBytes} \times 1.5 + \text{UncompressedFrameBufferSize}, 50\text{ MB})$.
- **Pre-flight Validation:** Before export commences, the system queries available disk storage (`StatFs` on Android, `volumeAvailableCapacityKey` on iOS). If $\text{AvailableBytes} < \text{PeakTempStorageBytes}$, the job fails fast with `ExportError.insufficientDiskSpace(required: PeakTempStorageBytes, available: AvailableBytes)`.

---

## ADR-007: Long Video Ingestion & Truncation-Prevention Policy

### Context
Per `docs/STORY_KIT_IMPLEMENTATION_PLAN.md` Section 6.15:
> *"Define long video behavior as explicit full clip, selected trim/window, segments, or clear rejection. Acceptance: No video is silently truncated."*

### Decision & Product Defaults
Implement explicit policies with agreed product defaults:

1. **Host-Configurable Maximum Story Duration:**
   - Default: Configurable via `StoryKitConfiguration.maxStoryDuration` (defaults to **15 seconds**, customizable up to 60 seconds by the host app).
2. **Interactive Trim as Product Default (`VideoDurationPolicy.trimWindow`):**
   - When an imported video exceeds `maxStoryDuration`, the interactive video trimmer UI opens automatically, allowing the creator to select their desired start/end window.
3. **Automatic Multi-Page Segmentation as Optional Feature (`VideoDurationPolicy.segmentPages`):**
   - When enabled by host configuration or user toggle, long videos are automatically split across consecutive story pages (e.g., a 45-second video becomes three 15-second pages with contiguous trim ranges).
4. **Deferred Audio Waveform:**
   - In accordance with MVP scoping, visual audio waveform rendering in the timeline scrubber is **deferred** from Phase 5. The Phase 5 scrubber focuses on high-precision video filmstrip thumbnails, draggable playhead, and trim handles.
5. **Strict Prohibition on Silent Truncation:**
   - The engine is strictly forbidden from silently truncating a video to the first $N$ seconds without explicit user configuration or interactive trim confirmation.
