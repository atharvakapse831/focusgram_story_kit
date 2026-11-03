import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/focusgram_story_kit.dart';

class FakeTestVideoExportAdapter implements StoryVideoExportAdapter {
  const FakeTestVideoExportAdapter();

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
    onProgress(
      VideoExportProgress(
        jobId: jobId,
        phase: VideoExportPhase.finalizing,
        progress: 1.0,
        message: 'Completed fake video export',
      ),
    );
    final fakeOut = '$workingDirectory/output_$jobId.mp4';
    final file = File(fakeOut);
    await file.writeAsString('fake mp4 video content');
    return VideoExportResult(
      jobId: jobId,
      outputPath: fakeOut,
      duration: const Duration(seconds: 4),
      fileSizeBytes: 1024,
      width: config.width,
      height: config.height,
    );
  }

  @override
  Future<void> cancelJob(String jobId) async {}
}

void main() {
  group('Mixed-Media Story Studio & Multi-Page Operations', () {
    test(
      'ReorderPageCommand and controller.reorderPage reorders pages and undoes cleanly',
      () {
        const p1 = StoryPage(id: 'page_1');
        const p2 = StoryPage(id: 'page_2');
        const p3 = StoryPage(id: 'page_3');
        const project = StoryProject(id: 'test_proj', pages: [p1, p2, p3]);

        final controller = EditorController(initialProject: project);
        expect(controller.project.pages.map((p) => p.id).toList(), [
          'page_1',
          'page_2',
          'page_3',
        ]);

        // Move page_1 (index 0) to index 2
        controller.reorderPage(0, 2);
        expect(controller.project.pages.map((p) => p.id).toList(), [
          'page_2',
          'page_3',
          'page_1',
        ]);

        // Undo reorder
        controller.undo();
        expect(controller.project.pages.map((p) => p.id).toList(), [
          'page_1',
          'page_2',
          'page_3',
        ]);

        // Redo reorder
        controller.redo();
        expect(controller.project.pages.map((p) => p.id).toList(), [
          'page_2',
          'page_3',
          'page_1',
        ]);
      },
    );

    test(
      'EditorController.addMediaPage appends video and photo pages with correct durations',
      () {
        final controller = EditorController();
        expect(controller.project.pages.length, 1);

        // Add a photo page
        controller.addMediaPage(
          const StoryMediaAsset(
            id: 'asset_photo_1',
            sourceType: StoryMediaSourceType.file,
            uri: '/path/to/photo.jpg',
            mimeType: 'image/jpeg',
          ),
        );
        expect(controller.project.pages.length, 2);
        expect(controller.activePage.backgroundAsset?.isVideo, false);
        expect(controller.activePage.duration, const Duration(seconds: 5));

        // Add a video page
        controller.addMediaPage(
          const StoryMediaAsset(
            id: 'asset_video_1',
            sourceType: StoryMediaSourceType.file,
            uri: '/path/to/video.mp4',
            mimeType: 'video/mp4',
            duration: Duration(seconds: 12),
          ),
          duration: const Duration(seconds: 12),
        );
        expect(controller.project.pages.length, 3);
        expect(controller.activePage.backgroundAsset?.isVideo, true);
        expect(controller.activePage.duration, const Duration(seconds: 12));
        expect(
          controller.activePage.videoTrimRange?.end,
          const Duration(seconds: 12),
        );
      },
    );

    test(
      'StoryProjectExporter exports mixed-media multi-page project (photo + video)',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'mixed_export_test_',
        );

        try {
          const photoPage = StoryPage(
            id: 'page_photo_1',
            backgroundColor: Colors.deepPurple,
            duration: Duration(seconds: 5),
            elements: [
              StoryElement(
                id: 'text_1',
                type: StoryElementType.text,
                transform: StoryTransform(),
                payload: TextElementPayload(text: 'Photo slide heading'),
              ),
            ],
          );

          const videoPage = StoryPage(
            id: 'page_video_2',
            backgroundAsset: StoryMediaAsset(
              id: 'video_asset_2',
              sourceType: StoryMediaSourceType.file,
              uri: '/fake/video.mp4',
              mimeType: 'video/mp4',
            ),
            duration: Duration(seconds: 4),
            elements: [
              StoryElement(
                id: 'sticker_1',
                type: StoryElementType.sticker,
                transform: StoryTransform(),
                payload: StickerElementPayload(
                  stickerId: 'sparkle',
                  assetUri: 'asset://sparkle',
                ),
              ),
            ],
          );

          const project = StoryProject(
            id: 'proj_mixed_1',
            pages: [photoPage, videoPage],
          );

          final exporter = StoryProjectExporter(
            videoExporter: StoryVideoExporter(
              adapter: const FakeTestVideoExportAdapter(),
              systemTempDirectory: tempDir,
            ),
            outputDirectory: tempDir,
          );

          final result = await exporter.exportProject(project: project);

          expect(result.projectId, 'proj_mixed_1');
          expect(result.pageCount, 2);

          // Page 1 is image
          final page1Output = result.pageOutputs[0];
          expect(page1Output.pageId, 'page_photo_1');
          expect(page1Output.mediaType, StoryItemType.image);
          expect(page1Output.isVideo, false);
          expect(File(page1Output.filePath).existsSync(), true);

          // Page 2 is video
          final page2Output = result.pageOutputs[1];
          expect(page2Output.pageId, 'page_video_2');
          expect(page2Output.mediaType, StoryItemType.video);
          expect(page2Output.isVideo, true);
          expect(File(page2Output.filePath).existsSync(), true);
        } finally {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        }
      },
    );

    testWidgets(
      'StoryKitEditor supports page strip reordering and Add Media button',
      (tester) async {
        const p1 = StoryPage(id: 'page_1', backgroundColor: Colors.red);
        const p2 = StoryPage(id: 'page_2', backgroundColor: Colors.blue);
        const project = StoryProject(id: 'proj_test', pages: [p1, p2]);
        final controller = EditorController(initialProject: project);

        await tester.pumpWidget(
          MaterialApp(
            home: StoryKitEditor(
              controller: controller,
              config: StoryKitEditorConfig(
                mediaPickerAdapter: DefaultMediaPickerAdapter(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Add Media button is present in the top bar
        expect(find.byTooltip('Add Media'), findsOneWidget);

        // Verify page strip controls (Move left, Move right, Add page)
        expect(find.byTooltip('Move Left'), findsOneWidget);
        expect(find.byTooltip('Move Right'), findsOneWidget);
        expect(find.byTooltip('Add Page'), findsOneWidget);

        // Move page 1 right
        await tester.tap(find.byTooltip('Move Right'));
        await tester.pumpAndSettle();
        expect(controller.project.pages.first.id, 'page_2');
      },
    );
  });
}
