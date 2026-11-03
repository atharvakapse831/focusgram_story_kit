import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/models/element_payloads.dart';
import 'package:focusgram_story_kit/models/story_element.dart';
import 'package:focusgram_story_kit/models/story_kit_configuration.dart';
import 'package:focusgram_story_kit/models/story_media_asset.dart';
import 'package:focusgram_story_kit/models/story_page.dart';
import 'package:focusgram_story_kit/models/story_project.dart';
import 'package:focusgram_story_kit/models/story_transform.dart';

void main() {
  group('Phase 5 Models & Serialization', () {
    test('VideoTrimRange round-trip and containment math', () {
      const trim = VideoTrimRange(
        start: Duration(seconds: 2),
        end: Duration(seconds: 7),
      );
      expect(trim.duration, const Duration(seconds: 5));
      expect(trim.contains(const Duration(seconds: 1)), isFalse);
      expect(trim.contains(const Duration(seconds: 2)), isTrue);
      expect(trim.contains(const Duration(seconds: 5)), isTrue);
      expect(trim.contains(const Duration(seconds: 7)), isTrue);
      expect(trim.contains(const Duration(seconds: 8)), isFalse);

      final json = trim.toJson();
      final restored = VideoTrimRange.fromJson(json);
      expect(restored, trim);
      expect(restored.start, const Duration(seconds: 2));
      expect(restored.end, const Duration(seconds: 7));
    });

    test('VideoAudioPolicy round-trip with configurable sample rate', () {
      const audioPolicy = VideoAudioPolicy(
        muteOriginal: true,
        originalVolume: 0.5,
        musicAsset: StoryMediaAsset(
          id: 'audio_1',
          uri: 'assets/audio/soundtrack.mp3',
          sourceType: StoryMediaSourceType.asset,
          mimeType: 'audio/mpeg',
        ),
        musicVolume: 0.8,
        musicStartTime: Duration(seconds: 10),
        audioSampleRate: AudioSampleRate.hz48000,
        audioBitrateKbps: 192,
      );

      final json = audioPolicy.toJson();
      final restored = VideoAudioPolicy.fromJson(json);
      expect(restored, audioPolicy);
      expect(restored.muteOriginal, isTrue);
      expect(restored.audioSampleRate, AudioSampleRate.hz48000);
      expect(restored.audioBitrateKbps, 192);
      expect(restored.musicAsset?.uri, 'assets/audio/soundtrack.mp3');
    });

    test('StoryVideoPayload round-trip serialization', () {
      const videoPayload = StoryVideoPayload(
        asset: StoryMediaAsset(
          id: 'video_asset_1',
          uri: 'file:///data/user/0/video.mp4',
          sourceType: StoryMediaSourceType.file,
          mimeType: 'video/mp4',
        ),
        trimRange: VideoTrimRange(
          start: Duration(milliseconds: 500),
          end: Duration(seconds: 15),
        ),
        fitMode: VideoFitMode.contain,
        playbackSpeed: 1.5,
        coverTimestamp: Duration(seconds: 3),
      );

      final json = videoPayload.toJson();
      final restored = StoryVideoPayload.fromJson(json);
      expect(restored, videoPayload);
      expect(restored.effectiveDuration, const Duration(milliseconds: 14500));
      expect(restored.fitMode, VideoFitMode.contain);
      expect(restored.playbackSpeed, 1.5);
      expect(restored.coverTimestamp, const Duration(seconds: 3));
    });

    test('LayerTimeRange boundary math and clamping', () {
      const range = LayerTimeRange(
        start: Duration(seconds: 3),
        end: Duration(seconds: 8),
      );
      expect(range.duration, const Duration(seconds: 5));
      expect(range.isVisibleAt(const Duration(seconds: 2)), isFalse);
      expect(range.isVisibleAt(const Duration(seconds: 3)), isTrue);
      expect(range.isVisibleAt(const Duration(seconds: 5)), isTrue);
      expect(range.isVisibleAt(const Duration(seconds: 8)), isTrue);
      expect(range.isVisibleAt(const Duration(seconds: 9)), isFalse);

      final clamped = range.clampTo(const Duration(seconds: 6));
      expect(clamped.start, const Duration(seconds: 3));
      expect(clamped.end, const Duration(seconds: 6));

      final json = range.toJson();
      final restored = LayerTimeRange.fromJson(json);
      expect(restored, range);
    });

    test('OverlayAnimationConfig round-trip and curve resolution', () {
      const config = OverlayAnimationConfig(
        entranceType: OverlayAnimationType.slideUp,
        entranceDuration: Duration(milliseconds: 400),
        exitType: OverlayAnimationType.fade,
        exitDuration: Duration(milliseconds: 250),
        curveName: 'bounceOut',
      );

      expect(config.curve, Curves.bounceOut);
      final json = config.toJson();
      final restored = OverlayAnimationConfig.fromJson(json);
      expect(restored, config);
      expect(restored.entranceType, OverlayAnimationType.slideUp);
      expect(restored.exitType, OverlayAnimationType.fade);
    });

    test('VideoElementPayload integrates into StoryElement', () {
      const videoElement = StoryElement(
        id: 'video_elem_1',
        type: StoryElementType.video,
        transform: StoryTransform(x: 0.1, y: 0.2, width: 0.8, height: 0.6),
        visibleTimeRange: LayerTimeRange(
          start: Duration(seconds: 1),
          end: Duration(seconds: 10),
        ),
        animation: OverlayAnimationConfig(
          entranceType: OverlayAnimationType.scale,
          exitType: OverlayAnimationType.fade,
        ),
        payload: VideoElementPayload(
          video: StoryVideoPayload(
            asset: StoryMediaAsset(
              id: 'video_stream_1',
              uri: 'https://example.com/stream.mp4',
              sourceType: StoryMediaSourceType.network,
              mimeType: 'video/mp4',
            ),
            trimRange: VideoTrimRange(
              start: Duration.zero,
              end: Duration(seconds: 10),
            ),
          ),
        ),
      );

      final json = videoElement.toJson();
      final restored = StoryElement.fromJson(json);
      expect(restored.id, 'video_elem_1');
      expect(restored.type, StoryElementType.video);
      expect(restored.visibleTimeRange?.start, const Duration(seconds: 1));
      expect(restored.visibleTimeRange?.end, const Duration(seconds: 10));
      expect(restored.animation?.entranceType, OverlayAnimationType.scale);
      expect(restored.payload, isA<VideoElementPayload>());

      final restoredVideo = (restored.payload as VideoElementPayload).video;
      expect(restoredVideo.asset.uri, 'https://example.com/stream.mp4');
    });

    test('StoryPage with background video and trim range round-trips', () {
      const page = StoryPage(
        id: 'page_video_1',
        duration: Duration(seconds: 15),
        backgroundAsset: StoryMediaAsset(
          id: 'bg_video_1',
          uri: 'file:///movies/story.mp4',
          sourceType: StoryMediaSourceType.file,
          mimeType: 'video/mp4',
        ),
        videoTrimRange: VideoTrimRange(
          start: Duration(seconds: 2),
          end: Duration(seconds: 17),
        ),
        audioPolicy: VideoAudioPolicy(
          muteOriginal: false,
          originalVolume: 0.9,
          audioSampleRate: AudioSampleRate.hz48000,
        ),
        coverTimestamp: Duration(seconds: 5),
      );

      final json = page.toJson();
      final restored = StoryPage.fromJson(json);
      expect(restored.id, page.id);
      expect(restored.duration, const Duration(seconds: 15));
      expect(restored.videoTrimRange?.start, const Duration(seconds: 2));
      expect(restored.videoTrimRange?.end, const Duration(seconds: 17));
      expect(restored.audioPolicy?.audioSampleRate, AudioSampleRate.hz48000);
      expect(restored.coverTimestamp, const Duration(seconds: 5));
    });

    test('StoryKitConfiguration defaults and serialization', () {
      const config = StoryKitConfiguration();
      expect(config.maxStoryDuration, const Duration(seconds: 15));
      expect(config.minStoryDuration, const Duration(seconds: 1));
      expect(config.defaultVideoDurationPolicy, VideoDurationPolicy.trimWindow);
      expect(config.defaultAudioSampleRate, AudioSampleRate.hz44100);
      expect(config.enableMultiPageSegmentation, isTrue);

      final custom = config.copyWith(
        maxStoryDuration: const Duration(seconds: 60),
        defaultVideoDurationPolicy: VideoDurationPolicy.segmentPages,
        defaultAudioSampleRate: AudioSampleRate.hz48000,
      );
      final json = custom.toJson();
      final restored = StoryKitConfiguration.fromJson(json);
      expect(restored.maxStoryDuration, const Duration(seconds: 60));
      expect(
        restored.defaultVideoDurationPolicy,
        VideoDurationPolicy.segmentPages,
      );
      expect(restored.defaultAudioSampleRate, AudioSampleRate.hz48000);
    });

    test('Backward compatibility: Phase 1-4 projects deserialize safely', () {
      final legacyJson = {
        'id': 'legacy_project',
        'schemaVersion': 1,
        'revision': 3,
        'pages': [
          {
            'id': 'p1',
            'durationMs': 5000,
            'backgroundColor': 4278190080,
            'elements': [
              {
                'id': 'el_1',
                'type': 'text',
                'transform': {
                  'x': 0.1,
                  'y': 0.2,
                  'width': 0.5,
                  'height': 0.1,
                  'rotation': 0.0,
                  'scale': 1.0,
                },
                'payload': {'text': 'Legacy Text', 'fontSize': 24.0},
              },
            ],
          },
        ],
      };

      final project = StoryProject.fromJson(legacyJson);
      expect(project.id, 'legacy_project');
      expect(project.pages.length, 1);
      final page = project.pages.first;
      expect(page.videoTrimRange, isNull);
      expect(page.audioPolicy, isNull);
      expect(page.coverTimestamp, isNull);

      final el = page.elements.first;
      expect(el.visibleTimeRange, isNull);
      expect(el.animation, isNull);
      expect(el.payload, isA<TextElementPayload>());
    });
  });
}
