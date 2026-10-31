import 'package:flutter/foundation.dart';
import '../models/story_media_asset.dart';

/// Camera and microphone permission statuses.
enum CameraPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted;

  bool get isGranted => this == CameraPermissionStatus.granted;
}

/// Abstract contract for camera capture operations.
///
/// Injected by host applications to provide camera functionality (e.g. `camera` plugin).
abstract class StoryCaptureAdapter {
  const StoryCaptureAdapter();

  /// Checks the current camera permission status.
  Future<CameraPermissionStatus> checkPermission();

  /// Requests camera permission from the system.
  Future<CameraPermissionStatus> requestPermission();

  /// Captures a still photo and returns a media asset reference.
  Future<StoryMediaAsset?> capturePhoto();

  /// Begins video recording if supported.
  Future<void> startRecordingVideo();

  /// Stops video recording and returns the recorded asset.
  Future<StoryMediaAsset?> stopRecordingVideo();

  /// Whether video is currently recording.
  bool get isRecording;

  /// Releases camera hardware resources.
  Future<void> dispose() async {}
}

/// Default fallback capture adapter for headless tests or platforms without camera.
class DefaultCaptureAdapter extends StoryCaptureAdapter {
  DefaultCaptureAdapter({
    CameraPermissionStatus initialPermission = CameraPermissionStatus.granted,
    this.onCapturePhoto,
  }) : _permission = initialPermission;

  CameraPermissionStatus _permission;
  bool _recording = false;
  final AsyncValueGetter<StoryMediaAsset?>? onCapturePhoto;

  @override
  Future<CameraPermissionStatus> checkPermission() async => _permission;

  @override
  Future<CameraPermissionStatus> requestPermission() async {
    return _permission;
  }

  void setPermission(CameraPermissionStatus status) {
    _permission = status;
  }

  @override
  Future<StoryMediaAsset?> capturePhoto() async {
    if (!_permission.isGranted) return null;
    if (onCapturePhoto != null) {
      return onCapturePhoto!();
    }
    return StoryMediaAsset(
      id: 'captured_${DateTime.now().millisecondsSinceEpoch}',
      sourceType: StoryMediaSourceType.file,
      uri: 'file:///simulated/capture.jpg',
      mimeType: 'image/jpeg',
      width: 1080,
      height: 1920,
    );
  }

  @override
  Future<void> startRecordingVideo() async {
    if (_permission.isGranted) {
      _recording = true;
    }
  }

  @override
  Future<StoryMediaAsset?> stopRecordingVideo() async {
    if (!_recording) return null;
    _recording = false;
    return StoryMediaAsset(
      id: 'recorded_${DateTime.now().millisecondsSinceEpoch}',
      sourceType: StoryMediaSourceType.file,
      uri: 'file:///simulated/recording.mp4',
      mimeType: 'video/mp4',
      duration: const Duration(seconds: 10),
      width: 1080,
      height: 1920,
    );
  }

  @override
  bool get isRecording => _recording;
}
