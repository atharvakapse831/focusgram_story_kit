import 'package:flutter/foundation.dart';

/// Error categories for video export operations.
enum ExportErrorCode {
  insufficientDiskSpace,
  unsupportedCodec,
  cancelled,
  timeout,
  corruptSource,
  renderFailed,
  muxFailed,
  unknown,
}

/// Typed exception thrown when video export fails or is aborted.
@immutable
class VideoExportException implements Exception {
  const VideoExportException({
    required this.code,
    required this.message,
    this.jobId,
    this.requiredBytes,
    this.availableBytes,
    this.underlyingError,
  });

  /// Category code of the export failure.
  final ExportErrorCode code;

  /// Human-readable description of what went wrong.
  final String message;

  /// Identifier of the active export job when failure occurred.
  final String? jobId;

  /// Dynamic storage bytes required by pre-flight checks (if disk space error).
  final int? requiredBytes;

  /// Storage bytes available on the target filesystem (if disk space error).
  final int? availableBytes;

  /// Original root cause error or exception (if available).
  final Object? underlyingError;

  @override
  String toString() {
    final buffer = StringBuffer('VideoExportException($code: $message)');
    if (jobId != null) buffer.write(' [job: $jobId]');
    if (requiredBytes != null && availableBytes != null) {
      buffer.write(' [req: ${requiredBytes}B, avail: ${availableBytes}B]');
    }
    if (underlyingError != null) {
      buffer.write(' Cause: $underlyingError');
    }
    return buffer.toString();
  }
}
