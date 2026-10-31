import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/export/story_video_exporter.dart';
import 'package:focusgram_story_kit/export/story_video_overlay_rasterizer.dart';
import 'package:focusgram_story_kit/export/video_export_adapter.dart';
import 'package:focusgram_story_kit/export/video_export_job.dart';
import 'package:focusgram_story_kit/models/element_payloads.dart';
import 'package:focusgram_story_kit/models/story_canvas_spec.dart';
import 'package:focusgram_story_kit/models/story_element.dart';
import 'package:focusgram_story_kit/models/story_media_asset.dart';
import 'package:focusgram_story_kit/models/story_page.dart';
import 'package:focusgram_story_kit/models/story_project.dart';
import 'package:focusgram_story_kit/models/story_transform.dart';
import 'package:focusgram_story_kit/timeline/timeline_controller.dart';
import 'package:focusgram_story_kit/timeline/video_transition_math.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 5 Representative Project & Multi-Track Validation', () {
    late Directory tempDir;
    late StoryProject representativeProject;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'fg_representative_test_',
      );

      // 1. Primary Background Video Asset & Track
      const bgAsset = StoryMediaAsset(
        id: 'bg_clip_main',
        sourceType: StoryMediaSourceType.file,
        uri: '/test_media/bg_main.mp4',
        mimeType: 'video/mp4',
        duration: Duration(seconds: 10),
      );

      // 2. Floating Video Asset & Track (In-Canvas PIP)
      const pipAsset = StoryMediaAsset(
        id: 'pip_clip_floating',
        sourceType: StoryMediaSourceType.file,
        uri: '/test_media/pip_floating.mp4',
        mimeType: 'video/mp4',
        duration: Duration(seconds: 6),
      );

      // 3. Floating Video Overlay Element
      const floatingVideoElement = StoryElement(
        id: 'el_pip_floating_video',
        type: StoryElementType.video,
        transform: StoryTransform(
          x: 0.72,
          y: 0.68,
          width: 0.36,
          height: 0.36,
          rotation: 0.05,
        ),
        opacity: 0.95,
        zIndex: 10,
        visibleTimeRange: LayerTimeRange(
          start: Duration(seconds: 2),
          end: Duration(seconds: 6),
        ),
        animation: OverlayAnimationConfig(
          entranceType: OverlayAnimationType.scale,
          entranceDuration: Duration(milliseconds: 400),
          exitType: OverlayAnimationType.fade,
          exitDuration: Duration(milliseconds: 400),
        ),
        payload: VideoElementPayload(
          video: StoryVideoPayload(
            asset: pipAsset,
            trimRange: VideoTrimRange(
              start: Duration(seconds: 1),
              end: Duration(seconds: 5),
            ),
            audioPolicy: VideoAudioPolicy(
              muteOriginal: false,
              originalVolume: 0.5,
              audioSampleRate: AudioSampleRate.hz48000,
            ),
            fitMode: VideoFitMode.cover,
          ),
        ),
      );

      // 4. Animated Rich Text Element
      const animatedTextElement = StoryElement(
        id: 'el_animated_text',
        type: StoryElementType.text,
        transform: StoryTransform(x: 0.5, y: 0.22, width: 0.85, height: 0.15),
        opacity: 1.0,
        zIndex: 20,
        visibleTimeRange: LayerTimeRange(
          start: Duration(seconds: 0),
          end: Duration(seconds: 6),
        ),
        animation: OverlayAnimationConfig(
          entranceType: OverlayAnimationType.slideUp,
          entranceDuration: Duration(milliseconds: 500),
          exitType: OverlayAnimationType.fade,
          exitDuration: Duration(milliseconds: 500),
        ),
        payload: TextElementPayload(
          text: 'FocusGram Phase 5 Production Story',
          fontSize: 28.0,
          isBold: true,
          textColor: Colors.white,
          outlineColor: Colors.black,
          outlineWidth: 2.5,
          shadowColor: Colors.black87,
          shadowBlurRadius: 6.0,
          shadowOffsetX: 2.0,
          shadowOffsetY: 2.0,
          backgroundColor: Color(0x66000000),
        ),
      );

      // 5. Animated Vector Shape Element
      const animatedShapeElement = StoryElement(
        id: 'el_animated_shape',
        type: StoryElementType.shape,
        transform: StoryTransform(x: 0.25, y: 0.65, width: 0.28, height: 0.28),
        opacity: 0.9,
        zIndex: 5,
        animation: OverlayAnimationConfig(
          entranceType: OverlayAnimationType.bounce,
          entranceDuration: Duration(milliseconds: 600),
          exitType: OverlayAnimationType.scale,
          exitDuration: Duration(milliseconds: 300),
        ),
        payload: ShapeElementPayload(
          shapeType: ShapeType.star,
          fillColor: Colors.amber,
          strokeColor: Colors.deepOrange,
          strokeWidth: 3.0,
        ),
      );

      // 6. Freehand Drawing Element with Neon Glow
      const drawingElement = StoryElement(
        id: 'el_freehand_drawing',
        type: StoryElementType.drawing,
        transform: StoryTransform(x: 0.5, y: 0.5, width: 1.0, height: 1.0),
        opacity: 0.85,
        zIndex: 4,
        payload: DrawingElementPayload(
          strokes: [
            DrawingStroke(
              brushType: DrawingBrushType.neon,
              color: Colors.cyanAccent,
              strokeWidth: 0.012,
              points: [
                DrawingPoint(x: 0.15, y: 0.40),
                DrawingPoint(x: 0.35, y: 0.45),
                DrawingPoint(x: 0.60, y: 0.38),
                DrawingPoint(x: 0.85, y: 0.42),
              ],
            ),
          ],
        ),
      );

      // 7. Animated Sticker Element
      const stickerElement = StoryElement(
        id: 'el_animated_sticker',
        type: StoryElementType.sticker,
        transform: StoryTransform(x: 0.82, y: 0.20, width: 0.18, height: 0.18),
        opacity: 1.0,
        zIndex: 25,
        visibleTimeRange: LayerTimeRange(
          start: Duration(seconds: 0),
          end: Duration(seconds: 6),
        ),
        animation: OverlayAnimationConfig(
          entranceType: OverlayAnimationType.scale,
          entranceDuration: Duration(milliseconds: 350),
          exitType: OverlayAnimationType.slideRight,
          exitDuration: Duration(milliseconds: 350),
        ),
        payload: StickerElementPayload(
          stickerId: 'stk_fire_badge',
          assetUri: '',
          label: '🔥',
        ),
      );

      // Construct StoryPage with background video and multi-layer timed elements
      const page = StoryPage(
        id: 'page_rep_1',
        duration: Duration(seconds: 7),
        backgroundAsset: bgAsset,
        videoTrimRange: VideoTrimRange(
          start: Duration(seconds: 1),
          end: Duration(seconds: 8),
        ),
        audioPolicy: VideoAudioPolicy(
          muteOriginal: false,
          originalVolume: 0.8,
          audioSampleRate: AudioSampleRate.hz48000,
        ),
        elements: [
          drawingElement,
          animatedShapeElement,
          floatingVideoElement,
          animatedTextElement,
          stickerElement,
        ],
      );

      representativeProject = const StoryProject(
        id: 'proj_rep_phase5',
        pages: [page],
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'Representative project structure satisfies all Phase 5 specifications',
      () {
        final page = representativeProject.pages.first;
        expect(page.backgroundAsset, isNotNull);
        expect(page.backgroundAsset!.isVideo, isTrue);
        expect(page.videoTrimRange, isNotNull);
        expect(
          page.videoTrimRange!.duration,
          equals(const Duration(seconds: 7)),
        );
        expect(page.audioPolicy, isNotNull);
        expect(page.audioPolicy!.originalVolume, equals(0.8));

        // Verify all 5 element layers are present and ordered
        expect(page.elements.length, equals(5));
        expect(page.sortedElements.first.zIndex, equals(4)); // drawing
        expect(page.sortedElements.last.zIndex, equals(25)); // sticker

        // Verify floating video overlay track
        final videoElem = page.elements.firstWhere(
          (e) => e.payload is VideoElementPayload,
        );
        final vPayload = videoElem.payload as VideoElementPayload;
        expect(vPayload.asset.uri, equals('/test_media/pip_floating.mp4'));
        expect(vPayload.audioPolicy.volumeMultiplier, equals(0.5));
        expect(
          videoElem.visibleTimeRange?.start,
          equals(const Duration(seconds: 2)),
        );
        expect(
          videoElem.visibleTimeRange?.end,
          equals(const Duration(seconds: 6)),
        );
      },
    );

    test(
      'Deterministic preview visual states evaluated across 4 representative timeline timestamps',
      () {
        const canvasSize = Size(1080, 1920);
        final page = representativeProject.pages.first;

        final textEl = page.getElement('el_animated_text')!;
        final videoEl = page.getElement('el_pip_floating_video')!;
        final shapeEl = page.getElement('el_animated_shape')!;
        final stickerEl = page.getElement('el_animated_sticker')!;

        // --- Timestamp 1: t = 0.2s (During entrance transitions) ---
        const t1 = Duration(milliseconds: 200);

        // Text is actively sliding up (entranceDuration = 500ms)
        final vsTextT1 = StoryTransitionMath.computeElementVisualState(
          element: textEl,
          t: t1,
          canvasSize: canvasSize,
        );
        expect(vsTextT1.isVisible, isTrue);
        expect(vsTextT1.opacity, greaterThan(0.0));
        expect(vsTextT1.opacity, lessThanOrEqualTo(1.0));
        expect(vsTextT1.transformMatrix, isNotNull);

        // Floating video is outside its visibleTimeRange [2s..6s] -> completely hidden
        final vsVideoT1 = StoryTransitionMath.computeElementVisualState(
          element: videoEl,
          t: t1,
          canvasSize: canvasSize,
        );
        expect(vsVideoT1.isVisible, isFalse);
        expect(vsVideoT1.opacity, equals(0.0));

        // --- Timestamp 2: t = 2.5s (Sustained state: all layers visible) ---
        const t2 = Duration(milliseconds: 2500);

        final vsTextT2 = StoryTransitionMath.computeElementVisualState(
          element: textEl,
          t: t2,
          canvasSize: canvasSize,
        );
        expect(vsTextT2.isVisible, isTrue);
        expect(vsTextT2.opacity, equals(1.0));

        final vsVideoT2 = StoryTransitionMath.computeElementVisualState(
          element: videoEl,
          t: t2,
          canvasSize: canvasSize,
        );
        expect(vsVideoT2.isVisible, isTrue);
        expect(vsVideoT2.opacity, equals(0.95)); // Base element opacity

        final vsShapeT2 = StoryTransitionMath.computeElementVisualState(
          element: shapeEl,
          t: t2,
          canvasSize: canvasSize,
        );
        expect(vsShapeT2.isVisible, isTrue);

        // --- Timestamp 3: t = 5.8s (During exit transitions) ---
        const t3 = Duration(milliseconds: 5800);

        // Floating video exit transition (fade from 5.6s to 6.0s)
        final vsVideoT3 = StoryTransitionMath.computeElementVisualState(
          element: videoEl,
          t: t3,
          canvasSize: canvasSize,
        );
        expect(vsVideoT3.isVisible, isTrue);
        expect(vsVideoT3.opacity, lessThan(0.95)); // Fading out

        // Text exit transition (fade from 5.5s to 6.0s)
        final vsTextT3 = StoryTransitionMath.computeElementVisualState(
          element: textEl,
          t: t3,
          canvasSize: canvasSize,
        );
        expect(vsTextT3.isVisible, isTrue);
        expect(vsTextT3.opacity, lessThan(1.0)); // Fading out

        // --- Timestamp 4: t = 6.5s (Post-exit state) ---
        const t4 = Duration(milliseconds: 6500);

        // Both text and floating video are now past visible interval
        final vsTextT4 = StoryTransitionMath.computeElementVisualState(
          element: textEl,
          t: t4,
          canvasSize: canvasSize,
        );
        expect(vsTextT4.isVisible, isFalse);

        final vsVideoT4 = StoryTransitionMath.computeElementVisualState(
          element: videoEl,
          t: t4,
          canvasSize: canvasSize,
        );
        expect(vsVideoT4.isVisible, isFalse);

        // Sticker post-exit
        final vsStickerT4 = StoryTransitionMath.computeElementVisualState(
          element: stickerEl,
          t: t4,
          canvasSize: canvasSize,
        );
        expect(vsStickerT4.isVisible, isFalse);
      },
    );

    test(
      'Overlay rasterizer generates valid transparent PNG frame sequences for representative project',
      () async {
        const rasterizer = StoryVideoOverlayRasterizer();
        final page = representativeProject.pages.first;

        final frames = await rasterizer.rasterizePageOverlays(
          page: page,
          canvasSpec: const StoryCanvasSpec(width: 1080, height: 1920),
          outputDir: tempDir,
          width: 1080,
          height: 1920,
          frameRate: 15.0, // 15 fps for fast test execution
        );

        expect(frames, isNotEmpty);
        expect(frames.length, greaterThan(10));

        // Verify every generated frame exists on disk and is non-empty
        for (final f in frames) {
          final file = File(f.framePath);
          expect(file.existsSync(), isTrue);
          expect(
            file.lengthSync(),
            greaterThan(200),
          ); // Valid non-empty PNG header
        }

        // Verify monotonic timestamp progression across frames
        for (var i = 1; i < frames.length; i++) {
          expect(frames[i].timestampMs, greaterThan(frames[i - 1].timestampMs));
        }
      },
    );

    test('Independent clip trimming, splitting, and reordering operations', () {
      final page = representativeProject.pages.first;
      final timeline = StoryTimelineController(
        initialDuration: page.duration,
        initialTrimRange: page.videoTrimRange,
        initialFrameRate: 30.0,
      );

      // 1. Verify dynamic synchronization tolerance
      expect(timeline.syncToleranceMs, closeTo(33.33, 0.01));

      // 2. Verify clip splitting at t = 4.0s
      final splitResult = timeline.splitAt(const Duration(seconds: 4));
      expect(splitResult, isNotNull);
      expect(splitResult!.first.start, equals(const Duration(seconds: 1)));
      expect(splitResult.first.end, equals(const Duration(seconds: 4)));
      expect(splitResult.second.start, equals(const Duration(seconds: 4)));
      expect(splitResult.second.end, equals(const Duration(seconds: 8)));

      // 3. Verify independent trim boundary adjustments
      timeline.setTrimRange(
        const VideoTrimRange(
          start: Duration(seconds: 2),
          end: Duration(seconds: 6),
        ),
      );
      expect(timeline.trimRange?.start, equals(const Duration(seconds: 2)));
      expect(timeline.trimRange?.end, equals(const Duration(seconds: 6)));
      expect(
        timeline.state.effectiveDuration,
        equals(const Duration(seconds: 4)),
      );

      // 4. Verify element reordering by z-index
      final updatedElements =
          page.elements.map((el) {
            if (el.id == 'el_pip_floating_video') {
              return el.copyWith(zIndex: 100); // Bring to front
            }
            return el;
          }).toList();

      final reorderedPage = page.copyWith(elements: updatedElements);
      expect(
        reorderedPage.sortedElements.last.id,
        equals('el_pip_floating_video'),
      );
      expect(reorderedPage.sortedElements.last.zIndex, equals(100));
    });

    test(
      'End-to-end export execution through StoryVideoExporter returns full VideoExportResult',
      () async {
        final exporter = StoryVideoExporter(
          systemTempDirectory: tempDir,
          adapter: const SoftwareStoryVideoExportAdapter(
            simulatedDurationMs: 40,
          ),
        );

        final job = exporter.startExport(
          project: representativeProject,
          config: const StoryVideoExportConfig(
            width: 1080,
            height: 1920,
            frameRate: 30,
            videoBitrate: 8000000,
            audioBitrate: 128000,
            sampleRate: AudioSampleRate.hz48000,
          ),
        );

        final phases = <VideoExportPhase>[];
        job.progressStream.listen((p) {
          if (!phases.contains(p.phase)) phases.add(p.phase);
        });

        final result = await job.result;

        expect(result.jobId, equals(job.id));
        expect(result.width, equals(1080));
        expect(result.height, equals(1920));
        expect(result.duration, equals(const Duration(seconds: 7)));
        expect(result.format, equals('mp4'));
        expect(result.videoCodec, equals('h264'));
        expect(result.audioCodec, equals('aac'));
        expect(result.sampleRate, equals(48000));
        expect(result.fileSizeBytes, greaterThan(0));

        expect(phases, contains(VideoExportPhase.preparing));
        expect(phases, contains(VideoExportPhase.renderingOverlays));
        expect(phases, contains(VideoExportPhase.encodingVideo));
        expect(phases, contains(VideoExportPhase.muxingAudio));
        expect(phases, contains(VideoExportPhase.finalizing));
      },
    );
  });
}
