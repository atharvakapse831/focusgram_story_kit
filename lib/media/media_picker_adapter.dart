import 'package:flutter/foundation.dart';
import '../models/story_media_asset.dart';

/// Abstract contract for media picking operations within the Story Kit.
///
/// Host applications inject an implementation that delegates to native pickers
/// (e.g. `image_picker`, custom asset pickers) without coupling the kit to host dependencies.
abstract class StoryMediaPickerAdapter {
  const StoryMediaPickerAdapter();

  /// Prompts the user to select a single image.
  ///
  /// Returns `null` if the user cancels or dismisses the picker.
  Future<StoryMediaAsset?> pickImage();

  /// Prompts the user to select one or more images.
  ///
  /// Returns an empty list if cancelled.
  Future<List<StoryMediaAsset>> pickMultipleImages();

  /// Prompts the user to select a single video asset.
  Future<StoryMediaAsset?> pickVideo();

  /// Cleans up any resources or observers.
  Future<void> dispose() async {}
}

/// Default in-memory/test-friendly media picker adapter.
///
/// Can be pre-populated with fixtures or custom resolvers for testing and preview modes.
class DefaultMediaPickerAdapter extends StoryMediaPickerAdapter {
  DefaultMediaPickerAdapter({
    this.onPickImage,
    this.onPickMultipleImages,
    this.onPickVideo,
  });

  final AsyncValueGetter<StoryMediaAsset?>? onPickImage;
  final AsyncValueGetter<List<StoryMediaAsset>>? onPickMultipleImages;
  final AsyncValueGetter<StoryMediaAsset?>? onPickVideo;

  @override
  Future<StoryMediaAsset?> pickImage() async {
    if (onPickImage != null) {
      return onPickImage!();
    }
    return null;
  }

  @override
  Future<List<StoryMediaAsset>> pickMultipleImages() async {
    if (onPickMultipleImages != null) {
      return onPickMultipleImages!();
    }
    return const [];
  }

  @override
  Future<StoryMediaAsset?> pickVideo() async {
    if (onPickVideo != null) {
      return onPickVideo!();
    }
    return null;
  }
}
