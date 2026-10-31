import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/assets/asset_provider.dart';
import 'package:focusgram_story_kit/media/capture_adapter.dart';
import 'package:focusgram_story_kit/media/media_picker_adapter.dart';
import 'package:focusgram_story_kit/models/story_media_asset.dart';

void main() {
  group('Phase 4 Adapters & Asset Providers', () {
    test(
      'DefaultMediaPickerAdapter invokes injected handlers and fallback',
      () async {
        final adapter = DefaultMediaPickerAdapter(
          onPickImage:
              () async => const StoryMediaAsset(
                id: 'test_img',
                sourceType: StoryMediaSourceType.file,
                uri: 'file:///test.png',
              ),
        );

        final img = await adapter.pickImage();
        expect(img, isNotNull);
        expect(img!.id, equals('test_img'));

        final multi = await adapter.pickMultipleImages();
        expect(multi, isEmpty);

        final video = await adapter.pickVideo();
        expect(video, isNull);
      },
    );

    test(
      'DefaultCaptureAdapter handles permissions and capture lifecycle',
      () async {
        final capture = DefaultCaptureAdapter();

        expect((await capture.checkPermission()).isGranted, isTrue);

        final photo = await capture.capturePhoto();
        expect(photo, isNotNull);
        expect(photo!.sourceType, equals(StoryMediaSourceType.file));

        // Video recording lifecycle
        expect(capture.isRecording, isFalse);
        await capture.startRecordingVideo();
        expect(capture.isRecording, isTrue);

        final video = await capture.stopRecordingVideo();
        expect(capture.isRecording, isFalse);
        expect(video, isNotNull);
        expect(video!.duration, equals(const Duration(seconds: 10)));

        // Denial behavior
        capture.setPermission(CameraPermissionStatus.denied);
        expect((await capture.checkPermission()).isGranted, isFalse);
        final deniedPhoto = await capture.capturePhoto();
        expect(deniedPhoto, isNull);
      },
    );

    test(
      'DefaultStoryAssetProvider provides categorized stickers and search',
      () async {
        const provider = DefaultStoryAssetProvider();

        final categories = await provider.getCategories();
        expect(categories.length, greaterThanOrEqualTo(5));

        final popularStickers = await provider.getStickers(
          categoryId: 'popular',
        );
        expect(popularStickers.isNotEmpty, isTrue);
        expect(popularStickers.every((s) => s.categoryId == 'popular'), isTrue);

        final searchResults = await provider.searchStickers('fire');
        expect(searchResults.any((s) => s.id == 'stk_fire'), isTrue);

        final searchByTag = await provider.searchStickers('birthday');
        expect(searchByTag.any((s) => s.id == 'stk_cake'), isTrue);
      },
    );
  });
}
