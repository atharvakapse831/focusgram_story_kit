import 'dart:async';
import 'dart:io';
import '../models/story_project.dart';
import 'export_error.dart';
import 'video_export_adapter.dart';
import 'video_export_job.dart';

/// High-level orchestrator for video rendering, dynamic storage pre-flight validation,
/// temporary sandbox management, and hardware-accelerated multiplexing.
class StoryVideoExporter {
  StoryVideoExporter({
    StoryVideoExportAdapter? adapter,
    Directory? systemTempDirectory,
  }) : _adapter = adapter ?? const MethodChannelStoryVideoExportAdapter(),
       _systemTempDir = systemTempDirectory;

  final StoryVideoExportAdapter _adapter;
  final Directory? _systemTempDir;

  /// Pure deterministic function to estimate output MP4 size in bytes.
  static int estimateOutputBytes({
    required Duration duration,
    required int videoBitrateBps,
    required int audioBitrateBps,
  }) {
    final durationSec = duration.inMilliseconds / 1000.0;
    final totalBitrate = videoBitrateBps + audioBitrateBps;
    return ((totalBitrate * durationSec) / 8.0).ceil();
  }

  /// Calculates dynamic peak temporary storage requirement based on video duration,
  /// frame dimensions, bitrate, and uncompressed chunk buffer size (ADR-006).
  static int estimatePeakTempStorageBytes({
    required Duration duration,
    required int width,
    required int height,
    required int videoBitrateBps,
    required int audioBitrateBps,
    int chunkWindowFrames = 15,
  }) {
    final estimatedOutput = estimateOutputBytes(
      duration: duration,
      videoBitrateBps: videoBitrateBps,
      audioBitrateBps: audioBitrateBps,
    );
    // Uncompressed RGBA buffer: width * height * 4 bytes * window
    final uncompressedFrameBufferSize = width * height * 4 * chunkWindowFrames;
    final peak = (estimatedOutput * 1.5).ceil() + uncompressedFrameBufferSize;
    const safetyFloor = 50 * 1024 * 1024; // 50 MB safety minimum floor
    return peak > safetyFloor ? peak : safetyFloor;
  }

  /// Initiates an asynchronous video export job.
  ///
  /// Returns a [VideoExportJob] token containing progress streams, cancellation handle,
  /// and completion future.
  VideoExportJob startExport({
    required StoryProject project,
    StoryVideoExportConfig config = const StoryVideoExportConfig(),
    int? availableDiskBytes,
  }) {
    final jobId = _generateJobId();
    final totalDuration = _calculateTotalDuration(project);

    // 1. Dynamic Storage Pre-Flight Validation
    final peakStorageRequired = estimatePeakTempStorageBytes(
      duration: totalDuration,
      width: config.width,
      height: config.height,
      videoBitrateBps: config.videoBitrate,
      audioBitrateBps: config.audioBitrate,
    );

    if (availableDiskBytes != null &&
        availableDiskBytes < peakStorageRequired) {
      final job = VideoExportJob(id: jobId);
      job.completeError(
        VideoExportException(
          code: ExportErrorCode.insufficientDiskSpace,
          message:
              'Insufficient disk space for video export. '
              'Required: ${peakStorageRequired ~/ (1024 * 1024)}MB, '
              'Available: ${availableDiskBytes ~/ (1024 * 1024)}MB',
          jobId: jobId,
          requiredBytes: peakStorageRequired,
          availableBytes: availableDiskBytes,
        ),
      );
      return job;
    }

    // 2. Instantiate Job Token with Cancellation Callback
    final job = VideoExportJob(
      id: jobId,
      onCancel: (id) async {
        await _adapter.cancelJob(id);
      },
    );

    // 3. Launch Export Pipeline in Background
    _runExportPipeline(
      job: job,
      project: project,
      config: config,
      jobId: jobId,
    );

    return job;
  }

  Future<void> _runExportPipeline({
    required VideoExportJob job,
    required StoryProject project,
    required StoryVideoExportConfig config,
    required String jobId,
  }) async {
    Directory? jobDir;
    try {
      final baseTemp = _systemTempDir ?? Directory.systemTemp;
      jobDir = Directory('${baseTemp.path}/story_export_$jobId');
      if (!await jobDir.exists()) {
        await jobDir.create(recursive: true);
      }

      job.emitProgress(
        VideoExportPhase.preparing,
        0.05,
        message: 'Sandbox directory prepared: ${jobDir.path}',
      );

      final result = await _adapter
          .exportVideo(
            jobId: jobId,
            project: project,
            config: config,
            workingDirectory: jobDir.path,
            onProgress:
                (p) => job.emitProgress(
                  p.phase,
                  p.progress,
                  eta: p.etaDuration,
                  message: p.message,
                ),
            checkCancelled: () => job.isCancelled,
          )
          .timeout(
            config.timeout,
            onTimeout: () {
              throw VideoExportException(
                code: ExportErrorCode.timeout,
                message:
                    'Video export timed out after ${config.timeout.inSeconds}s',
                jobId: jobId,
              );
            },
          );

      if (job.isCancelled) {
        throw VideoExportException(
          code: ExportErrorCode.cancelled,
          message: 'Export was cancelled.',
          jobId: jobId,
        );
      }

      job.complete(result);
    } catch (e, stack) {
      if (!job.isCancelled) {
        if (e is VideoExportException) {
          job.completeError(e, stack);
        } else {
          job.completeError(
            VideoExportException(
              code: ExportErrorCode.renderFailed,
              message: 'Video export failed: $e',
              jobId: jobId,
              underlyingError: e,
            ),
            stack,
          );
        }
      }
      // On failure or cancellation, clean up sandbox directory completely
      if (jobDir != null && await jobDir.exists()) {
        try {
          await jobDir.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  Duration _calculateTotalDuration(StoryProject project) {
    if (project.pages.isEmpty) return const Duration(seconds: 5);
    return project.pages.fold<Duration>(
      Duration.zero,
      (sum, page) => sum + page.duration,
    );
  }

  String _generateJobId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = (timestamp % 100000).toString().padLeft(5, '0');
    return 'job_${timestamp}_$randomPart';
  }
}
