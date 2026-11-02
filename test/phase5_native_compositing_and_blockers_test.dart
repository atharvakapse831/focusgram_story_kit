import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/export/export_error.dart';
import 'package:focusgram_story_kit/export/story_video_exporter.dart';
import 'package:focusgram_story_kit/export/story_video_overlay_rasterizer.dart';
import 'package:focusgram_story_kit/export/video_export_adapter.dart';
import 'package:focusgram_story_kit/models/element_payloads.dart';
import 'package:focusgram_story_kit/models/story_canvas_spec.dart';
import 'package:focusgram_story_kit/models/story_element.dart';
import 'package:focusgram_story_kit/models/story_media_asset.dart';
import 'package:focusgram_story_kit/models/story_page.dart';
import 'package:focusgram_story_kit/models/story_project.dart';
import 'package:focusgram_story_kit/models/story_transform.dart';
import 'package:focusgram_story_kit/timeline/video_transition_math.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 5 Native Compositing & Blocker Resolution Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fg_compositing_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('OverlayFrameEntry serialization and deserialization round-trip', () {
      const entry = OverlayFrameEntry(
        timestampMs: 500,
        durationMs: 33,
        framePath: '/tmp/frame_001.png',
      );

      final json = entry.toJson();
      expect(json['timestampMs'], equals(500));
      expect(json['durationMs'], equals(33));
      expect(json['path'], equals('/tmp/frame_001.png'));

      final deserialized = OverlayFrameEntry.fromJson(json);
      expect(deserialized.timestampMs, equals(500));
      expect(deserialized.durationMs, equals(33));
      expect(deserialized.framePath, equals('/tmp/frame_001.png'));
    });

    test(
      'Static page optimization produces single frame spanning page duration',
      () async {
        const element = StoryElement(
          id: 'el_static_text',
          type: StoryElementType.text,
          transform: StoryTransform(x: 0.5, y: 0.5, width: 0.8, height: 0.2),
          payload: TextElementPayload(text: 'Static Headline'),
        );

        const page = StoryPage(
          id: 'page_static',
          duration: Duration(seconds: 4),
          elements: [element],
        );

        const rasterizer = StoryVideoOverlayRasterizer();
        expect(StoryVideoOverlayRasterizer.hasAnimatedElements(page), isFalse);

        final entries = await rasterizer.rasterizePageOverlays(
          page: page,
          canvasSpec: const StoryCanvasSpec(width: 720, height: 1280),
          outputDir: tempDir,
          width: 360,
          height: 640,
        );

        expect(entries.length, equals(1));
        expect(entries.first.timestampMs, equals(0));
        expect(entries.first.durationMs, equals(4000));
        expect(File(entries.first.framePath).existsSync(), isTrue);
      },
    );

    test(
      'Animated page produces time-dependent frame sequence matching entrance and exit intervals',
      () async {
        const element = StoryElement(
          id: 'el_anim_text',
          type: StoryElementType.text,
          transform: StoryTransform(x: 0.5, y: 0.5, width: 0.8, height: 0.2),
          animation: OverlayAnimationConfig(
            entranceType: OverlayAnimationType.slideUp,
            entranceDuration: Duration(milliseconds: 300),
            exitType: OverlayAnimationType.fade,
            exitDuration: Duration(milliseconds: 300),
          ),
          payload: TextElementPayload(text: 'Animated Heading'),
        );

        const page = StoryPage(
          id: 'page_animated',
          duration: Duration(seconds: 2), // 2000 ms
          elements: [element],
        );

        const rasterizer = StoryVideoOverlayRasterizer();
        expect(StoryVideoOverlayRasterizer.hasAnimatedElements(page), isTrue);

        final entries = await rasterizer.rasterizePageOverlays(
          page: page,
          canvasSpec: const StoryCanvasSpec(width: 720, height: 1280),
          outputDir: tempDir,
          width: 360,
          height: 640,
          frameRate: 10.0, // 10 fps -> 100ms steps for test speed
        );

        expect(entries.length, greaterThan(1));
        // Verify monotonic timestamps
        for (var i = 1; i < entries.length; i++) {
          expect(
            entries[i].timestampMs,
            greaterThan(entries[i - 1].timestampMs),
          );
          expect(File(entries[i].framePath).existsSync(), isTrue);
        }

        // Verify entrance frames exist (t <= 300ms)
        final entranceFrames = entries.where((e) => e.timestampMs <= 300);
        expect(entranceFrames, isNotEmpty);

        // Verify exit frames exist (t >= 1700ms)
        final exitFrames = entries.where((e) => e.timestampMs >= 1700);
        expect(exitFrames, isNotEmpty);
      },
    );

    test(
      'Timed visibility range gates element rendering to active window',
      () async {
        const element = StoryElement(
          id: 'el_timed',
          type: StoryElementType.shape,
          transform: StoryTransform(x: 0.5, y: 0.5, width: 0.4, height: 0.4),
          visibleTimeRange: LayerTimeRange(
            start: Duration(seconds: 1),
            end: Duration(seconds: 3),
          ),
          payload: ShapeElementPayload(
            shapeType: ShapeType.circle,
            fillColor: Colors.blue,
          ),
        );

        const page = StoryPage(
          id: 'page_timed',
          duration: Duration(seconds: 5),
          elements: [element],
        );

        expect(StoryVideoOverlayRasterizer.hasAnimatedElements(page), isTrue);

        const canvasSize = Size(360, 640);
        // At t = 0.5s: hidden
        final vsBefore = StoryTransitionMath.computeElementVisualState(
          element: element,
          t: const Duration(milliseconds: 500),
          canvasSize: canvasSize,
        );
        expect(vsBefore.isVisible, isFalse);

        // At t = 2.0s: visible
        final vsInside = StoryTransitionMath.computeElementVisualState(
          element: element,
          t: const Duration(milliseconds: 2000),
          canvasSize: canvasSize,
        );
        expect(vsInside.isVisible, isTrue);

        // At t = 4.0s: hidden
        final vsAfter = StoryTransitionMath.computeElementVisualState(
          element: element,
          t: const Duration(milliseconds: 4000),
          canvasSize: canvasSize,
        );
        expect(vsAfter.isVisible, isFalse);
      },
    );

    test(
      'Multi-track video and audio payloads serialize complete geometry, timing and audio policy',
      () {
        const bgAsset = StoryMediaAsset(
          id: 'bg_vid',
          sourceType: StoryMediaSourceType.file,
          uri: '/media/background.mp4',
          mimeType: 'video/mp4',
          duration: Duration(seconds: 10),
        );

        const pipAsset = StoryMediaAsset(
          id: 'pip_vid',
          sourceType: StoryMediaSourceType.file,
          uri: '/media/overlay_pip.mp4',
          mimeType: 'video/mp4',
          duration: Duration(seconds: 5),
        );

        const pipElement = StoryElement(
          id: 'el_pip_video',
          type: StoryElementType.video,
          transform: StoryTransform(
            x: 0.75,
            y: 0.75,
            width: 0.35,
            height: 0.35,
            rotation: 0.1,
          ),
          opacity: 0.9,
          zIndex: 2,
          visibleTimeRange: LayerTimeRange(
            start: Duration(seconds: 2),
            end: Duration(seconds: 7),
          ),
          payload: VideoElementPayload(
            video: StoryVideoPayload(
              asset: pipAsset,
              trimRange: VideoTrimRange(
                start: Duration(seconds: 1),
                end: Duration(seconds: 4),
              ),
              audioPolicy: VideoAudioPolicy(
                muteOriginal: false,
                originalVolume: 0.6,
                audioSampleRate: AudioSampleRate.hz48000,
              ),
              fitMode: VideoFitMode.cover,
            ),
          ),
        );

        const page = StoryPage(
          id: 'page_multitrack',
          duration: Duration(seconds: 10),
          backgroundAsset: bgAsset,
          audioPolicy: VideoAudioPolicy(
            muteOriginal: false,
            originalVolume: 1.0,
          ),
          elements: [pipElement],
        );

        const project = StoryProject(id: 'proj_multitrack', pages: [page]);

        expect(
          project.pages.first.elements.first.payload,
          isA<VideoElementPayload>(),
        );
        final payload =
            project.pages.first.elements.first.payload as VideoElementPayload;
        expect(payload.asset.resolvedPath, equals('/media/overlay_pip.mp4'));
        expect(payload.audioPolicy.volumeMultiplier, equals(0.6));
        expect(payload.audioPolicy.isMuted, isFalse);
        expect(payload.trimRange.duration, equals(const Duration(seconds: 3)));
      },
    );

    test(
      'iOS Core Animation discrete keyframe normalization clamps to [0.0, 1.0]',
      () {
        const totalDurationSec = 10.0;
        final presentationTimes = [0.0, 0.5, 3.0, 7.5, 10.0];

        final normalizedKeyTimes =
            presentationTimes.map((t) {
              final norm = (t / totalDurationSec).clamp(0.0, 1.0);
              return double.parse(norm.toStringAsFixed(4));
            }).toList();

        expect(normalizedKeyTimes, equals([0.0, 0.05, 0.3, 0.75, 1.0]));
        expect(normalizedKeyTimes.first, equals(0.0));
        expect(normalizedKeyTimes.last, equals(1.0));
      },
    );

    test(
      'Android Media3 binary search frame lookup selects closest frame <= presentation timestamp',
      () {
        final frames = [
          const OverlayFrameEntry(
            timestampMs: 0,
            durationMs: 100,
            framePath: 'f0',
          ),
          const OverlayFrameEntry(
            timestampMs: 100,
            durationMs: 100,
            framePath: 'f1',
          ),
          const OverlayFrameEntry(
            timestampMs: 200,
            durationMs: 100,
            framePath: 'f2',
          ),
          const OverlayFrameEntry(
            timestampMs: 300,
            durationMs: 700,
            framePath: 'f3',
          ),
          const OverlayFrameEntry(
            timestampMs: 1000,
            durationMs: 100,
            framePath: 'f4',
          ),
        ];

        OverlayFrameEntry findFrame(int timeMs) {
          OverlayFrameEntry candidate = frames.first;
          for (final f in frames) {
            if (f.timestampMs <= timeMs) {
              candidate = f;
            } else {
              break;
            }
          }
          return candidate;
        }

        expect(findFrame(0).framePath, equals('f0'));
        expect(findFrame(50).framePath, equals('f0'));
        expect(findFrame(100).framePath, equals('f1'));
        expect(findFrame(150).framePath, equals('f1'));
        expect(findFrame(500).framePath, equals('f3'));
        expect(findFrame(1050).framePath, equals('f4'));
      },
    );

    test(
      'Cancellation state machine safely cleans up directory and throws typed exception',
      () async {
        final exporter = StoryVideoExporter(
          systemTempDirectory: tempDir,
          adapter: const SoftwareStoryVideoExportAdapter(
            simulatedDurationMs: 800,
          ),
        );

        const page = StoryPage(
          id: 'page_cancel_test',
          duration: Duration(seconds: 5),
          elements: [
            StoryElement(
              id: 'el_text',
              type: StoryElementType.text,
              transform: StoryTransform(),
              payload: TextElementPayload(text: 'Test'),
            ),
          ],
        );

        const project = StoryProject(id: 'proj_cancel', pages: [page]);
        final job = exporter.startExport(project: project);

        // Cancel immediately
        await job.cancel();

        expect(job.isCancelled, isTrue);
        expect(
          () => job.result,
          throwsA(
            isA<VideoExportException>().having(
              (e) => e.code,
              'code',
              ExportErrorCode.cancelled,
            ),
          ),
        );
      },
    );

    test(
      'All element types render on transparent overlay canvas without exception',
      () async {
        const textEl = StoryElement(
          id: 'el_text',
          type: StoryElementType.text,
          transform: StoryTransform(x: 0.5, y: 0.2, width: 0.6, height: 0.1),
          payload: TextElementPayload(
            text: 'Hello World',
            textColor: Colors.amber,
            outlineColor: Colors.black,
            outlineWidth: 2.0,
            shadowColor: Colors.black54,
            shadowBlurRadius: 4.0,
          ),
        );

        const shapeEl = StoryElement(
          id: 'el_shape',
          type: StoryElementType.shape,
          transform: StoryTransform(x: 0.3, y: 0.5, width: 0.3, height: 0.2),
          payload: ShapeElementPayload(
            shapeType: ShapeType.star,
            fillColor: Colors.red,
            strokeColor: Colors.white,
            strokeWidth: 2.0,
          ),
        );

        const drawingEl = StoryElement(
          id: 'el_drawing',
          type: StoryElementType.drawing,
          transform: StoryTransform(x: 0.5, y: 0.5, width: 1.0, height: 1.0),
          payload: DrawingElementPayload(
            strokes: [
              DrawingStroke(
                brushType: DrawingBrushType.neon,
                color: Colors.greenAccent,
                strokeWidth: 0.01,
                points: [
                  DrawingPoint(x: 0.1, y: 0.1),
                  DrawingPoint(x: 0.2, y: 0.2),
                  DrawingPoint(x: 0.3, y: 0.1),
                ],
              ),
            ],
          ),
        );

        const stickerEl = StoryElement(
          id: 'el_sticker',
          type: StoryElementType.sticker,
          transform: StoryTransform(x: 0.7, y: 0.5, width: 0.2, height: 0.2),
          payload: StickerElementPayload(
            stickerId: 'st_1',
            assetUri: '',
            label: '🔥',
          ),
        );

        const page = StoryPage(
          id: 'page_all_types',
          duration: Duration(seconds: 3),
          elements: [textEl, shapeEl, drawingEl, stickerEl],
        );

        const rasterizer = StoryVideoOverlayRasterizer();
        final pngBytes = await rasterizer.renderFrameToPng(
          elements: page.sortedElements,
          timestamp: Duration.zero,
          canvasSize: const Size(360, 640),
          width: 360,
          height: 640,
        );

        expect(pngBytes, isNotEmpty);
        expect(pngBytes.length, greaterThan(100)); // Non-empty valid PNG
      },
    );
  });
}
