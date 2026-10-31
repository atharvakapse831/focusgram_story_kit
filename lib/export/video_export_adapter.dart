import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/element_payloads.dart';
import '../models/story_project.dart';
import 'export_error.dart';
import 'export_result.dart';
import 'video_export_job.dart';

/// Configuration options for video rendering and hardware export.
@immutable
class StoryVideoExportConfig {
  const StoryVideoExportConfig({
    this.width = 1080,
    this.height = 1920,
    this.frameRate = 30,
    this.videoBitrate = 8000000, // 8 Mbps
    this.audioBitrate = 128000, // 128 kbps
    this.sampleRate = AudioSampleRate.hz44100,
    this.outputDirectory,
    this.preferHardwareCodec = true,
    this.timeout = const Duration(minutes: 5),
  });

  /// Target video width in pixels (e.g. 1080).
  final int width;

  /// Target video height in pixels (e.g. 1920 for 9:16 portrait).
  final int height;

  /// Target frame rate in frames per second (e.g. 30 or 60).
  final int frameRate;

  /// Target video encoding bitrate in bits per second.
  final int videoBitrate;

  /// Target audio encoding bitrate in bits per second.
  final int audioBitrate;

  /// Target audio output sample rate.
  final AudioSampleRate sampleRate;

  /// Custom destination directory for exported video. If null, app temp is used.
  final String? outputDirectory;

  /// Whether to prioritize on-chip hardware encoders (MediaCodec / VideoToolbox).
  final bool preferHardwareCodec;

  /// Timeout duration before an export job is forcefully aborted.
  final Duration timeout;
}

/// Represents a rasterized frame overlay at a specific timeline timestamp.
@immutable
class OverlayFrameChunk {
  const OverlayFrameChunk({
    required this.timestamp,
    required this.width,
    required this.height,
    required this.rgbaBytes,
    this.frameFilePath,
  });

  /// Presentation timestamp of this frame.
  final Duration timestamp;

  /// Frame width in pixels.
  final int width;

  /// Frame height in pixels.
  final int height;

  /// Raw 32-bit RGBA byte buffer.
  final Uint8List rgbaBytes;

  /// Optional temporary image file path written to the job sandbox directory.
  final String? frameFilePath;
}

/// Platform contract for hardware video composition, overlay rendering, and multiplexing.
abstract class StoryVideoExportAdapter {
  /// Whether hardware encoding is available on the current device and platform.
  Future<bool> isHardwareSupported();

  /// Executes video export for the given [project] and [config].
  ///
  /// Emits progress snapshots via [onProgress] and checks [checkCancelled] periodically.
  Future<VideoExportResult> exportVideo({
    required String jobId,
    required StoryProject project,
    required StoryVideoExportConfig config,
    required String workingDirectory,
    required void Function(VideoExportProgress progress) onProgress,
    required bool Function() checkCancelled,
  });

  /// Aborts native video encoding and frees platform pipeline resources for [jobId].
  Future<void> cancelJob(String jobId);
}

/// Production video export adapter backed by Android Media3 Transformer and iOS AVFoundation.
class MethodChannelStoryVideoExportAdapter implements StoryVideoExportAdapter {
  const MethodChannelStoryVideoExportAdapter({MethodChannel? methodChannel})
    : _channel =
          methodChannel ??
          const MethodChannel('com.focusgram.storykit/video_export');

  final MethodChannel _channel;

  @override
  Future<bool> isHardwareSupported() async {
    try {
      final supported = await _channel.invokeMethod<bool>(
        'isHardwareSupported',
      );
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<VideoExportResult> exportVideo({
    required String jobId,
    required StoryProject project,
    required StoryVideoExportConfig config,
    required String workingDirectory,
    required void Function(VideoExportProgress progress) onProgress,
    required bool Function() checkCancelled,
  }) async {
    if (checkCancelled()) {
      throw VideoExportException(
        code: ExportErrorCode.cancelled,
        message: 'Job $jobId was cancelled before start.',
        jobId: jobId,
      );
    }

    onProgress(
      VideoExportProgress(
        jobId: jobId,
        phase: VideoExportPhase.preparing,
        progress: 0.05,
        message: 'Initializing native hardware encoder...',
      ),
    );

    // Build serialized export descriptor for platform channel
    final pagesPayload = <Map<String, dynamic>>[];
    for (final page in project.pages) {
      final videoElements =
          page.elements.where((e) => e.payload is VideoElementPayload).map((e) {
            final p = e.payload as VideoElementPayload;
            return {
              'id': e.id,
              'assetPath': p.asset.resolvedPath,
              'durationMs': p.asset.duration?.inMilliseconds ?? 0,
              'trimStartMs': p.trimRange.start.inMilliseconds,
              'trimEndMs': p.trimRange.end.inMilliseconds,
              'volume': p.audioPolicy.volumeMultiplier,
              'muted': p.audioPolicy.isMuted,
            };
          }).toList();

      pagesPayload.add({
        'id': page.id,
        'backgroundPath': page.backgroundAsset?.resolvedPath,
        'isVideoBackground': page.backgroundAsset?.isVideo ?? false,
        'durationMs': page.duration.inMilliseconds,
        'trimStartMs': page.videoTrimRange?.start.inMilliseconds,
        'trimEndMs': page.videoTrimRange?.end.inMilliseconds,
        'muted': page.audioPolicy?.isMuted ?? false,
        'volume': page.audioPolicy?.volumeMultiplier ?? 1.0,
        'videoElements': videoElements,
      });
    }

    final arguments = {
      'jobId': jobId,
      'workingDirectory': workingDirectory,
      'width': config.width,
      'height': config.height,
      'frameRate': config.frameRate,
      'videoBitrate': config.videoBitrate,
      'audioBitrate': config.audioBitrate,
      'sampleRate': config.sampleRate.sampleRateHz,
      'preferHardware': config.preferHardwareCodec,
      'project': {
        'id': project.id,
        'name': project.metadata?['name'] as String? ?? project.id,
        'pages': pagesPayload,
      },
    };

    try {
      final rawResult = await _channel.invokeMapMethod<String, dynamic>(
        'exportVideo',
        arguments,
      );

      if (checkCancelled()) {
        throw VideoExportException(
          code: ExportErrorCode.cancelled,
          message: 'Job $jobId cancelled during native execution.',
          jobId: jobId,
        );
      }

      if (rawResult == null) {
        throw VideoExportException(
          code: ExportErrorCode.renderFailed,
          message: 'Native export returned null result.',
          jobId: jobId,
        );
      }

      onProgress(
        VideoExportProgress(
          jobId: jobId,
          phase: VideoExportPhase.finalizing,
          progress: 1.0,
          message: 'Video export complete.',
        ),
      );

      return VideoExportResult(
        jobId: jobId,
        outputPath: rawResult['outputPath'] as String,
        duration: Duration(milliseconds: rawResult['durationMs'] as int? ?? 0),
        width: rawResult['width'] as int? ?? config.width,
        height: rawResult['height'] as int? ?? config.height,
        fileSizeBytes: rawResult['fileSizeBytes'] as int? ?? 0,
        format: rawResult['format'] as String? ?? 'mp4',
        videoCodec: rawResult['videoCodec'] as String? ?? 'h264',
        audioCodec: rawResult['audioCodec'] as String? ?? 'aac',
        sampleRate: config.sampleRate.sampleRateHz,
        coverFramePath: rawResult['coverFramePath'] as String?,
        exportedAt: DateTime.now(),
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELLED') {
        throw VideoExportException(
          code: ExportErrorCode.cancelled,
          message: e.message ?? 'Export cancelled',
          jobId: jobId,
        );
      } else if (e.code == 'INSUFFICIENT_STORAGE') {
        throw VideoExportException(
          code: ExportErrorCode.insufficientDiskSpace,
          message: e.message ?? 'Insufficient storage space',
          jobId: jobId,
        );
      } else if (e.code == 'UNSUPPORTED_CODEC') {
        throw VideoExportException(
          code: ExportErrorCode.unsupportedCodec,
          message: e.message ?? 'Unsupported video/audio codec',
          jobId: jobId,
        );
      } else {
        throw VideoExportException(
          code: ExportErrorCode.renderFailed,
          message: e.message ?? 'Platform video export error',
          jobId: jobId,
          underlyingError: e,
        );
      }
    }
  }

  @override
  Future<void> cancelJob(String jobId) async {
    try {
      await _channel.invokeMethod<void>('cancelJob', {'jobId': jobId});
    } catch (_) {
      // Ignore channel disposal errors
    }
  }
}

/// Deterministic in-memory software export adapter for headless testing, CI, and non-mobile platforms.
class SoftwareStoryVideoExportAdapter implements StoryVideoExportAdapter {
  const SoftwareStoryVideoExportAdapter({
    this.simulatedDurationMs = 200,
    this.simulateFailure = false,
    this.failureErrorCode = ExportErrorCode.renderFailed,
  });

  final int simulatedDurationMs;
  final bool simulateFailure;
  final ExportErrorCode failureErrorCode;

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
  }) async {
    final phases = [
      VideoExportPhase.preparing,
      VideoExportPhase.renderingOverlays,
      VideoExportPhase.encodingVideo,
      VideoExportPhase.muxingAudio,
      VideoExportPhase.finalizing,
    ];

    for (var i = 0; i < phases.length; i++) {
      if (checkCancelled()) {
        throw VideoExportException(
          code: ExportErrorCode.cancelled,
          message: 'Export job $jobId was cancelled.',
          jobId: jobId,
        );
      }

      if (simulateFailure && i == 2) {
        throw VideoExportException(
          code: failureErrorCode,
          message: 'Simulated failure during ${phases[i]}',
          jobId: jobId,
        );
      }

      final progressVal = (i + 1) / phases.length;
      onProgress(
        VideoExportProgress(
          jobId: jobId,
          phase: phases[i],
          progress: progressVal,
          message: 'Processing ${phases[i].name}...',
        ),
      );

      if (simulatedDurationMs > 0) {
        await Future<void>.delayed(
          Duration(milliseconds: simulatedDurationMs ~/ phases.length),
        );
      }
    }

    // Compute total project duration
    final totalDurationMs = project.pages.fold<int>(
      0,
      (sum, p) => sum + p.duration.inMilliseconds,
    );

    return VideoExportResult(
      jobId: jobId,
      outputPath: '$workingDirectory/export_$jobId.mp4',
      duration: Duration(milliseconds: totalDurationMs),
      width: config.width,
      height: config.height,
      fileSizeBytes: 2048576, // 2 MB synthetic output
      format: 'mp4',
      videoCodec: 'h264',
      audioCodec: 'aac',
      sampleRate: config.sampleRate.sampleRateHz,
      exportedAt: DateTime.now(),
    );
  }

  @override
  Future<void> cancelJob(String jobId) async {}
}
