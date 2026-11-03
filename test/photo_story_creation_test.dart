import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/focusgram_story_kit.dart';

Future<Uint8List> _createTestPngBytes({
  int width = 100,
  int height = 100,
  Color color = const Color(0xFF0000FF),
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return byteData!.buffer.asUint8List();
}

class FakeVideoExportAdapter implements StoryVideoExportAdapter {
  const FakeVideoExportAdapter();

  @override
  Future<bool> isHardwareSupported() async => true;

  @override
  Future<VideoExportResult> exportVideo({
    required String jobId,
    required StoryProject project,
    required StoryVideoExportConfig config,
    required String workingDirectory,
    required void Function(VideoExportProgress progress) onProgress,
    required bool Function() checkCancelled,
    Map<String, List<OverlayFrameEntry>>? pageOverlayFrames,
    int? requiredStorageBytes,
  }) async {
    final fakeOut = '$workingDirectory/test_$jobId.mp4';
    final file = File(fakeOut);
    await file.writeAsString('fake mp4 content');
    return VideoExportResult(
      jobId: jobId,
      outputPath: fakeOut,
      duration: const Duration(seconds: 5),
      fileSizeBytes: 2048,
      width: config.width,
      height: config.height,
    );
  }

  @override
  Future<void> cancelJob(String jobId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File sampleImageFile;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('story_photo_test_');
    final pngBytes = await _createTestPngBytes(
      width: 200,
      height: 200,
      color: const Color(0xFF123456),
    );
    sampleImageFile = File('${tempDir.path}/sample.png');
    await sampleImageFile.writeAsBytes(pngBytes);
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Photo Story Creation & Still Image Exporter (P0 Verification)', () {
    test('StoryPage supports imageAdjustments serialization and equality', () {
      const adj = ImageAdjustments(
        brightness: 0.2,
        contrast: 1.1,
        saturation: 1.2,
        filterPreset: ImageFilterPreset.vintage,
        isFlippedHorizontally: true,
      );

      const page = StoryPage(
        id: 'photo_page_1',
        duration: Duration(seconds: 5),
        imageAdjustments: adj,
      );

      final json = page.toJson();
      expect(json['imageAdjustments'], isNotNull);
      final decoded = StoryPage.fromJson(json);
      expect(decoded.imageAdjustments, equals(adj));
      expect(decoded, equals(page));
      expect(decoded.imageAdjustments!.isFlippedHorizontally, isTrue);
    });

    test(
      'StoryStillImageExporter renders background photo with adjustments',
      () async {
        const exporter = StoryStillImageExporter();
        final asset = StoryMediaAsset(
          id: 'bg_photo',
          uri: sampleImageFile.path,
          sourceType: StoryMediaSourceType.file,
          mimeType: 'image/png',
        );

        final page = StoryPage(
          id: 'page_photo_adjusted',
          backgroundAsset: asset,
          imageAdjustments: const ImageAdjustments(
            brightness: 0.5,
            filterPreset: ImageFilterPreset.grayscale,
          ),
          elements: const [
            StoryElement(
              id: 'text_1',
              type: StoryElementType.text,
              payload: TextElementPayload(
                text: 'Photo Story Text',
                fontSize: 24,
                textColor: Colors.white,
              ),
              transform: StoryTransform(
                x: 0.5,
                y: 0.5,
                width: 0.6,
                height: 0.1,
              ),
            ),
          ],
        );

        const canvasSpec = StoryCanvasSpec(width: 360, height: 640);
        final result = await exporter.exportPage(page, canvasSpec);

        expect(result.pageId, 'page_photo_adjusted');
        expect(result.format, 'png');
        expect(result.bytes.isNotEmpty, isTrue);
        expect(result.width, 360);
        expect(result.height, 640);

        // Decode exported image to verify valid raster
        final codec = await ui.instantiateImageCodec(result.bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 360);
        expect(frame.image.height, 640);
        frame.image.dispose();
      },
    );

    test(
      'StoryStillImageExporter renders ImageElementPayload overlays',
      () async {
        const exporter = StoryStillImageExporter();
        final imageElement = StoryElement(
          id: 'overlay_img',
          type: StoryElementType.image,
          payload: ImageElementPayload(
            asset: StoryMediaAsset(
              id: 'overlay_asset',
              uri: sampleImageFile.path,
              sourceType: StoryMediaSourceType.file,
            ),
            adjustments: const ImageAdjustments(
              filterPreset: ImageFilterPreset.sepia,
            ),
          ),
          transform: const StoryTransform(
            x: 0.5,
            y: 0.5,
            width: 0.5,
            height: 0.5,
          ),
        );

        final page = StoryPage(
          id: 'page_with_image_overlay',
          backgroundColor: Colors.black,
          elements: [imageElement],
        );

        final result = await exporter.exportPage(
          page,
          const StoryCanvasSpec(width: 200, height: 200),
        );

        expect(result.bytes.isNotEmpty, isTrue);
        final codec = await ui.instantiateImageCodec(result.bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 200);
        frame.image.dispose();
      },
    );

    test(
      'StoryProjectExporter routes photos to StillImageExporter and never VideoExporter',
      () async {
        final videoExporter = StoryVideoExporter(
          adapter: const FakeVideoExportAdapter(),
        );
        final projectExporter = StoryProjectExporter(
          videoExporter: videoExporter,
          outputDirectory: tempDir,
        );

        final photoAsset = StoryMediaAsset(
          id: 'photo_asset_1',
          uri: sampleImageFile.path,
          sourceType: StoryMediaSourceType.file,
          mimeType: 'image/png',
        );

        final videoAsset = StoryMediaAsset(
          id: 'video_asset_1',
          uri: '${tempDir.path}/sample.mp4',
          sourceType: StoryMediaSourceType.file,
          mimeType: 'video/mp4',
        );

        final project = StoryProject(
          id: 'mixed_project_1',
          pages: [
            StoryPage(
              id: 'page_photo',
              backgroundAsset: photoAsset,
              elements: const [
                StoryElement(
                  id: 'text_photo',
                  type: StoryElementType.text,
                  payload: TextElementPayload(text: 'Still photo page'),
                  transform: StoryTransform(
                    x: 0.5,
                    y: 0.5,
                    width: 0.5,
                    height: 0.1,
                  ),
                ),
              ],
            ),
            StoryPage(
              id: 'page_video',
              backgroundAsset: videoAsset,
              duration: const Duration(seconds: 4),
            ),
          ],
        );

        final result = await projectExporter.exportProject(project: project);
        expect(result.pageCount, 2);

        // Page 1 must be Image
        final page1 = result.pageOutputs[0];
        expect(page1.mediaType, equals(StoryItemType.image));
        expect(page1.isVideo, isFalse);
        expect(page1.filePath.endsWith('.png'), isTrue);
        expect(page1.stillBytes, isNotNull);
        expect(page1.videoResult, isNull);
        expect(File(page1.filePath).existsSync(), isTrue);

        // Page 2 must be Video
        final page2 = result.pageOutputs[1];
        expect(page2.mediaType, equals(StoryItemType.video));
        expect(page2.isVideo, isTrue);
        expect(page2.filePath.endsWith('.mp4'), isTrue);
        expect(page2.stillBytes, isNull);
        expect(page2.videoResult, isNotNull);
      },
    );
  });

  group('Video Splitting & Timeline Synchronization (Task 2 Verification)', () {
    test(
      'EditorController.splitVideoClip creates contiguous clips and syncs timeline',
      () {
        final timelineController = StoryTimelineController(
          initialDuration: const Duration(seconds: 12),
          initialTrimRange: const VideoTrimRange(
            start: Duration(seconds: 0),
            end: Duration(seconds: 12),
          ),
        );

        const videoAsset = StoryMediaAsset(
          id: 'vid_1',
          uri: '/path/video.mp4',
          sourceType: StoryMediaSourceType.file,
          mimeType: 'video/mp4',
        );

        const initialPage = StoryPage(
          id: 'page_video_root',
          duration: Duration(seconds: 12),
          backgroundAsset: videoAsset,
          videoTrimRange: VideoTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 12),
          ),
        );

        const project = StoryProject(id: 'proj_split', pages: [initialPage]);

        final controller = EditorController(
          initialProject: project,
          timelineController: timelineController,
        );

        expect(controller.project.pages.length, 1);
        expect(timelineController.totalDuration, const Duration(seconds: 12));

        // Split video clip at 5 seconds
        controller.splitVideoClip(const Duration(seconds: 5));

        expect(controller.project.pages.length, 2);

        final p1 = controller.project.pages[0];
        final p2 = controller.project.pages[1];

        // Page 1 duration: 5s, trim: [0s, 5s]
        expect(p1.id, 'page_video_root');
        expect(p1.duration, const Duration(seconds: 5));
        expect(p1.videoTrimRange?.start, Duration.zero);
        expect(p1.videoTrimRange?.end, const Duration(seconds: 5));

        // Page 2 duration: 7s, trim: [5s, 12s]
        expect(p2.duration, const Duration(seconds: 7));
        expect(p2.videoTrimRange?.start, const Duration(seconds: 5));
        expect(p2.videoTrimRange?.end, const Duration(seconds: 12));

        // Active page is p1, so timelineController should have synced to 5s
        expect(timelineController.totalDuration, const Duration(seconds: 5));
        expect(timelineController.trimRange?.start, Duration.zero);
        expect(timelineController.trimRange?.end, const Duration(seconds: 5));

        // Undo split
        expect(controller.canUndo, isTrue);
        controller.undo();

        expect(controller.project.pages.length, 1);
        final restored = controller.project.pages[0];
        expect(restored.duration, const Duration(seconds: 12));
        expect(restored.videoTrimRange?.start, Duration.zero);
        expect(restored.videoTrimRange?.end, const Duration(seconds: 12));

        // Timeline controller must be restored to 12s
        expect(timelineController.totalDuration, const Duration(seconds: 12));
        expect(timelineController.trimRange?.start, Duration.zero);
        expect(timelineController.trimRange?.end, const Duration(seconds: 12));

        // Redo split
        expect(controller.canRedo, isTrue);
        controller.redo();

        expect(controller.project.pages.length, 2);
        expect(timelineController.totalDuration, const Duration(seconds: 5));
      },
    );

    test('EditorController page adjustments command execution and undo', () {
      const photoAsset = StoryMediaAsset(
        id: 'photo_bg',
        uri: '/path/photo.png',
        sourceType: StoryMediaSourceType.file,
      );

      const project = StoryProject(
        id: 'proj_adj',
        pages: [StoryPage(id: 'page_bg_adj', backgroundAsset: photoAsset)],
      );

      final controller = EditorController(initialProject: project);
      expect(controller.activePage.imageAdjustments, isNull);

      const adj = ImageAdjustments(
        brightness: 0.3,
        contrast: 1.4,
        saturation: 1.1,
        filterPreset: ImageFilterPreset.cool,
      );

      controller.updatePageImageAdjustments(adj);
      expect(controller.activePage.imageAdjustments, equals(adj));

      // Undo
      controller.undo();
      expect(controller.activePage.imageAdjustments, isNull);

      // Redo
      controller.redo();
      expect(controller.activePage.imageAdjustments, equals(adj));
    });
  });
}
