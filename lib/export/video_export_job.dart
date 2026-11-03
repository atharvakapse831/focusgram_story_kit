import 'dart:async';
import 'package:flutter/foundation.dart';
import 'export_error.dart';
import 'export_result.dart';

/// Phase indicator for a video export pipeline job.
enum VideoExportPhase {
  preparing,
  renderingOverlays,
  encodingVideo,
  muxingAudio,
  finalizing,
}

/// Progress snapshot emitted during an active video export job.
@immutable
class VideoExportProgress {
  const VideoExportProgress({
    required this.jobId,
    required this.phase,
    required this.progress,
    this.etaDuration,
    this.message,
  });

  /// The export job ID.
  final String jobId;

  /// Current processing phase.
  final VideoExportPhase phase;

  /// Normalized progress in range [0.0, 1.0].
  final double progress;

  /// Optional estimated remaining duration until completion.
  final Duration? etaDuration;

  /// Optional human-readable status message.
  final String? message;

  @override
  String toString() =>
      'VideoExportProgress($jobId: ${(progress * 100).toStringAsFixed(1)}% - $phase)';
}

/// Token representing an in-flight video export task.
///
/// Exposes real-time progress streaming, cancellation controls, and completion futures.
class VideoExportJob {
  VideoExportJob({
    required this.id,
    Future<void> Function(String jobId)? onCancel,
  }) : _onCancel = onCancel;

  /// Unique job identifier (UUID).
  final String id;

  final Future<void> Function(String jobId)? _onCancel;
  final StreamController<VideoExportProgress> _progressController =
      StreamController<VideoExportProgress>.broadcast();
  final Completer<VideoExportResult> _completer =
      Completer<VideoExportResult>();

  bool _isCancelled = false;
  bool _isDisposed = false;

  /// Broadcast stream of progress snapshots emitted during export.
  Stream<VideoExportProgress> get progressStream => _progressController.stream;

  /// Future that completes when the video has been rendered and muxed to disk.
  Future<VideoExportResult> get result => _completer.future;

  /// Whether cancellation has been requested for this job.
  bool get isCancelled => _isCancelled;

  /// Whether the job has completed, failed, or was cancelled.
  bool get isDone => _completer.isCompleted;

  /// Emits a progress update to listeners.
  void emitProgress(
    VideoExportPhase phase,
    double progress, {
    Duration? eta,
    String? message,
  }) {
    if (_isCancelled || _isDisposed || _progressController.isClosed) return;
    final clamped = progress.clamp(0.0, 1.0);
    _progressController.add(
      VideoExportProgress(
        jobId: id,
        phase: phase,
        progress: clamped,
        etaDuration: eta,
        message: message,
      ),
    );
  }

  /// Completes the export job successfully with the output result.
  void complete(VideoExportResult exportResult) {
    if (_completer.isCompleted) return;
    emitProgress(VideoExportPhase.finalizing, 1.0);
    _completer.complete(exportResult);
    _dispose();
  }

  /// Fails the export job with a typed exception.
  void completeError(Object error, [StackTrace? stackTrace]) {
    if (_completer.isCompleted) return;
    _completer.completeError(error, stackTrace);
    _dispose();
  }

  /// Cancels the export job, aborts platform encoding tasks, and triggers cleanup.
  Future<void> cancel() async {
    if (_isCancelled || _completer.isCompleted) return;
    _isCancelled = true;
    try {
      if (_onCancel != null) {
        await _onCancel(id);
      }
    } finally {
      if (!_completer.isCompleted) {
        _completer.completeError(
          VideoExportException(
            code: ExportErrorCode.cancelled,
            message: 'Export job $id was cancelled by the user.',
            jobId: id,
          ),
        );
      }
      _dispose();
    }
  }

  void _dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _progressController.close();
  }
}
