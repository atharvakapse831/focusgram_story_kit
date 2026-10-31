import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/export/export_error.dart';
import 'package:focusgram_story_kit/export/story_video_exporter.dart';
import 'package:focusgram_story_kit/export/video_export_adapter.dart';
import 'package:focusgram_story_kit/export/video_export_job.dart';
import 'package:focusgram_story_kit/models/element_payloads.dart';
import 'package:focusgram_story_kit/models/story_media_asset.dart';
import 'package:focusgram_story_kit/models/story_page.dart';
import 'package:focusgram_story_kit/models/story_project.dart';

void main() {
  group('Phase 5 Video Export Pipeline & Quota Tests', () {
    late StoryProject testProject;

    setUp(() {
      const asset = StoryMediaAsset(
        id: 'asset_vid_1',
        sourceType: StoryMediaSourceType.file,
        uri: '/tmp/test_clip.mp4',
        mimeType: 'video/mp4',
        duration: Duration(seconds: 10),
      );

      const page = StoryPage(
        id: 'page_vid_1',
        duration: Duration(seconds: 10),
        backgroundAsset: asset,
        videoTrimRange: VideoTrimRange(
          start: Duration(seconds: 1),
          end: Duration(seconds: 6),
        ),
        audioPolicy: VideoAudioPolicy(
          muteOriginal: false,
          originalVolume: 0.8,
          audioSampleRate: AudioSampleRate.hz48000,
        ),
      );

      testProject = const StoryProject(id: 'proj_export_test', pages: [page]);
    });

    test('Pre-flight dynamic storage estimation satisfies ADR-006 formula', () {
      const duration = Duration(seconds: 15);
      const videoBitrate = 8000000; // 8 Mbps
      const audioBitrate = 128000; // 128 kbps
      const width = 1080;
      const height = 1920;

      final estimatedOutput = StoryVideoExporter.estimateOutputBytes(
        duration: duration,
        videoBitrateBps: videoBitrate,
        audioBitrateBps: audioBitrate,
      );

      // (8,128,000 bps * 15s) / 8 = 15,240,000 bytes (~14.5 MB)
      expect(estimatedOutput, equals(15240000));

      final peakStorage = StoryVideoExporter.estimatePeakTempStorageBytes(
        duration: duration,
        width: width,
        height: height,
        videoBitrateBps: videoBitrate,
        audioBitrateBps: audioBitrate,
        chunkWindowFrames: 15,
      );

      // Uncompressed RGBA = 1080 * 1920 * 4 * 15 = 124,416,000 bytes (~118.6 MB)
      // Peak = (15,240,000 * 1.5) + 124,416,000 = 22,860,000 + 124,416,000 = 147,276,000 bytes (~140.4 MB)
      expect(peakStorage, greaterThan(140 * 1024 * 1024));
      expect(peakStorage, equals(147276000));
    });

    test(
      'Pre-flight check enforces 50MB safety minimum floor for short clips',
      () {
        const duration = Duration(seconds: 1);
        const videoBitrate = 500000;
        const audioBitrate = 64000;

        final peak = StoryVideoExporter.estimatePeakTempStorageBytes(
          duration: duration,
          width: 100,
          height: 100,
          videoBitrateBps: videoBitrate,
          audioBitrateBps: audioBitrate,
          chunkWindowFrames: 1,
        );

        expect(peak, equals(50 * 1024 * 1024)); // 50MB floor
      },
    );

    test(
      'Fails fast with insufficientDiskSpace when available storage < peak',
      () async {
        final exporter = StoryVideoExporter(
          adapter: const SoftwareStoryVideoExportAdapter(
            simulatedDurationMs: 10,
          ),
        );

        // Provide only 1 MB available disk space (required is >50MB)
        final job = exporter.startExport(
          project: testProject,
          availableDiskBytes: 1024 * 1024,
        );

        expect(job.isDone, isTrue);
        expect(
          () => job.result,
          throwsA(
            isA<VideoExportException>().having(
              (e) => e.code,
              'code',
              ExportErrorCode.insufficientDiskSpace,
            ),
          ),
        );
      },
    );

    test(
      'Successful export progresses through all phases and returns VideoExportResult',
      () async {
        final recordedPhases = <VideoExportPhase>[];
        final recordedProgress = <double>[];

        final exporter = StoryVideoExporter(
          adapter: const SoftwareStoryVideoExportAdapter(
            simulatedDurationMs: 20,
          ),
        );

        final job = exporter.startExport(
          project: testProject,
          config: const StoryVideoExportConfig(
            width: 720,
            height: 1280,
            sampleRate: AudioSampleRate.hz48000,
          ),
        );

        job.progressStream.listen((p) {
          recordedPhases.add(p.phase);
          recordedProgress.add(p.progress);
        });

        final result = await job.result;

        expect(result.jobId, equals(job.id));
        expect(result.width, equals(720));
        expect(result.height, equals(1280));
        expect(result.duration, equals(const Duration(seconds: 10)));
        expect(result.sampleRate, equals(48000));
        expect(result.format, equals('mp4'));
        expect(result.videoCodec, equals('h264'));
        expect(result.audioCodec, equals('aac'));
        expect(result.fileSizeBytes, greaterThan(0));

        // Validate phase progression
        expect(recordedPhases, contains(VideoExportPhase.preparing));
        expect(recordedPhases, contains(VideoExportPhase.renderingOverlays));
        expect(recordedPhases, contains(VideoExportPhase.encodingVideo));
        expect(recordedPhases, contains(VideoExportPhase.muxingAudio));
        expect(recordedPhases, contains(VideoExportPhase.finalizing));

        // Validate monotonic progress
        for (var i = 1; i < recordedProgress.length; i++) {
          expect(
            recordedProgress[i],
            greaterThanOrEqualTo(recordedProgress[i - 1]),
          );
        }
      },
    );

    test(
      'Cancellation aborts active job and completes with ExportErrorCode.cancelled',
      () async {
        final exporter = StoryVideoExporter(
          adapter: const SoftwareStoryVideoExportAdapter(
            simulatedDurationMs: 500,
          ),
        );

        final job = exporter.startExport(project: testProject);

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

    test('Failed export cleanly surfaces underlying exception', () async {
      final exporter = StoryVideoExporter(
        adapter: const SoftwareStoryVideoExportAdapter(
          simulatedDurationMs: 20,
          simulateFailure: true,
          failureErrorCode: ExportErrorCode.unsupportedCodec,
        ),
      );

      final job = exporter.startExport(project: testProject);

      expect(
        () => job.result,
        throwsA(
          isA<VideoExportException>().having(
            (e) => e.code,
            'code',
            ExportErrorCode.unsupportedCodec,
          ),
        ),
      );
    });
  });
}
