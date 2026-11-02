import 'package:flutter/foundation.dart';
import '../overlays/story_overlay.dart';

/// Structured outcome of a deterministic still-image story export.
@immutable
class StillImageExportResult {
  const StillImageExportResult({
    required this.pageId,
    required this.bytes,
    required this.width,
    required this.height,
    this.format = 'png',
    this.overlays = const [],
    this.duration = const Duration(seconds: 5),
  });

  /// Identifier of the rendered page/slide.
  final String pageId;

  /// Encoded image raster bytes (e.g., PNG).
  final Uint8List bytes;

  /// Output pixel width.
  final int width;

  /// Output pixel height.
  final int height;

  /// Image container format ('png', 'jpeg').
  final String format;

  /// Structured interactive overlays extracted separately from raster pixels.
  final List<StoryOverlay> overlays;

  /// Recommended display duration for the rendered story slide.
  final Duration duration;
}

/// Structured outcome of a deterministic video story export.
@immutable
class VideoExportResult {
  const VideoExportResult({
    required this.jobId,
    required this.outputPath,
    required this.duration,
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    this.coverFramePath,
    this.coverFrameBytes,
    this.format = 'mp4',
    this.videoCodec = 'h264',
    this.audioCodec = 'aac',
    this.sampleRate = 44100,
    this.overlays = const [],
    this.exportedAt,
  });

  /// Unique identifier of the export job.
  final String jobId;

  /// Absolute filesystem path to the rendered video file.
  final String outputPath;

  /// Total duration of the rendered video.
  final Duration duration;

  /// Video width in pixels.
  final int width;

  /// Video height in pixels.
  final int height;

  /// Total size of the output video file in bytes.
  final int fileSizeBytes;

  /// Optional filesystem path to the extracted cover frame image.
  final String? coverFramePath;

  /// Optional bytes of the extracted cover frame image.
  final Uint8List? coverFrameBytes;

  /// Output container format ('mp4', 'mov').
  final String format;

  /// Video compression codec ('h264', 'hevc').
  final String videoCodec;

  /// Audio compression codec ('aac').
  final String audioCodec;

  /// Audio sample rate in Hz (e.g. 44100, 48000).
  final int sampleRate;

  /// Structured interactive overlays extracted separately from video pixels.
  final List<StoryOverlay> overlays;

  /// Timestamp when the export completed.
  final DateTime? exportedAt;
}
