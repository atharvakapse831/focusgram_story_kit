import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/editor/editor_controller.dart';
import 'package:focusgram_story_kit/editor/panels/animation_picker_sheet.dart';
import 'package:focusgram_story_kit/editor/panels/audio_settings_sheet.dart';
import 'package:focusgram_story_kit/editor/panels/cover_picker_sheet.dart';
import 'package:focusgram_story_kit/editor/panels/timeline_scrubber.dart';
import 'package:focusgram_story_kit/editor/story_kit_editor.dart';
import 'package:focusgram_story_kit/models/element_payloads.dart';
import 'package:focusgram_story_kit/models/story_element.dart';
import 'package:focusgram_story_kit/models/story_media_asset.dart';
import 'package:focusgram_story_kit/models/story_page.dart';
import 'package:focusgram_story_kit/models/story_project.dart';
import 'package:focusgram_story_kit/models/story_transform.dart';

void main() {
  group('Phase 5 StoryKitEditor & Timeline Widgets', () {
    late StoryProject videoProject;

    setUp(() {
      const videoAsset = StoryMediaAsset(
        id: 'vid_asset_w1',
        sourceType: StoryMediaSourceType.file,
        uri: '/tmp/sample_video.mp4',
        mimeType: 'video/mp4',
        duration: Duration(seconds: 15),
      );

      const videoPage = StoryPage(
        id: 'page_vid_w1',
        duration: Duration(seconds: 15),
        backgroundAsset: videoAsset,
        videoTrimRange: VideoTrimRange(
          start: Duration(seconds: 2),
          end: Duration(seconds: 12),
        ),
        audioPolicy: VideoAudioPolicy(
          muteOriginal: false,
          originalVolume: 0.9,
          audioSampleRate: AudioSampleRate.hz44100,
        ),
        elements: [
          StoryElement(
            id: 'text_timed_1',
            type: StoryElementType.text,
            payload: TextElementPayload(text: 'Hello Timeline!'),
            transform: StoryTransform(),
            visibleTimeRange: LayerTimeRange(
              start: Duration(seconds: 2),
              end: Duration(seconds: 8),
            ),
          ),
        ],
      );

      videoProject = const StoryProject(id: 'proj_vid_w1', pages: [videoPage]);
    });

    testWidgets('Editor mounts and shows timeline toggle button', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = EditorController(initialProject: videoProject);

      await tester.pumpWidget(
        MaterialApp(
          home: StoryKitEditor(
            controller: controller,
            config: const StoryKitEditorConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Timeline toggle button should be present in top bar
      final timelineToggle = find.byIcon(Icons.movie_filter_outlined);
      expect(timelineToggle, findsOneWidget);

      // Initially timeline scrubber is not shown (showTimeline defaults to false)
      expect(find.byType(TimelineScrubber), findsNothing);

      // Tap timeline toggle
      await tester.tap(timelineToggle);
      await tester.pumpAndSettle();

      // Timeline scrubber is now visible
      expect(find.byType(TimelineScrubber), findsOneWidget);
    });

    testWidgets('TimelineScrubber playback toggle updates play/pause state', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = EditorController(initialProject: videoProject);
      controller.toggleTimeline(); // enable timeline

      await tester.pumpWidget(
        MaterialApp(
          home: StoryKitEditor(
            controller: controller,
            config: const StoryKitEditorConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.timelineController.isPlaying, isFalse);

      // Find the play button in TimelineScrubber
      final playButton = find.byIcon(Icons.play_circle_filled);
      expect(playButton, findsOneWidget);

      await tester.tap(playButton);
      await tester.pump();

      // Playing state toggled
      expect(controller.timelineController.isPlaying, isTrue);
      expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);

      // Pause again
      await tester.tap(find.byIcon(Icons.pause_circle_filled));
      await tester.pump();
      expect(controller.timelineController.isPlaying, isFalse);
    });

    testWidgets(
      'AnimationPickerSheet displays entrance/exit options and applies selection',
      (tester) async {
        final controller = EditorController(initialProject: videoProject);
        controller.selectElement('text_timed_1');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: AnimationPickerSheet(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        // Verify animation sheet header and presets
        expect(find.text('Layer Timing & Animation'), findsOneWidget);
        expect(find.text('fade'), findsAtLeastNWidgets(1));
        expect(find.text('scale'), findsAtLeastNWidgets(1));
        expect(find.text('slideUp'), findsAtLeastNWidgets(1));

        // Tap 'slideUp' preset
        await tester.tap(find.text('slideUp').first);
        await tester.pumpAndSettle();

        // Tap 'Apply' to apply changes
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        // Check that the selected element now has slideUp animation
        final updatedEl = controller.activePage.getElement('text_timed_1');
        expect(
          updatedEl?.animation?.entranceType,
          equals(OverlayAnimationType.slideUp),
        );
      },
    );

    testWidgets(
      'AudioSettingsSheet displays mute toggle, volume and sample rate controls',
      (tester) async {
        final controller = EditorController(initialProject: videoProject);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: AudioSettingsSheet(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Audio & Sound Settings'), findsOneWidget);
        expect(find.text('Mute Original Audio'), findsOneWidget);
        expect(find.text('44.1 kHz (Music & Web)'), findsOneWidget);
        expect(find.text('48.0 kHz (Broadcast)'), findsOneWidget);

        // Tap 48 kHz chip
        await tester.tap(find.text('48.0 kHz (Broadcast)'));
        await tester.pumpAndSettle();

        // Toggle mute switch
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();

        // Tap Apply
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        // Verify controller was updated
        expect(controller.activePage.audioPolicy?.isMuted, isTrue);
        expect(
          controller.activePage.audioPolicy?.audioSampleRate,
          equals(AudioSampleRate.hz48000),
        );
      },
    );

    testWidgets(
      'CoverPickerSheet displays timestamp scrubber and applies cover frame',
      (tester) async {
        final controller = EditorController(initialProject: videoProject);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: CoverPickerSheet(controller: controller)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Select Story Cover Frame'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);

        // Tap 'Save'
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(controller.activePage.coverTimestamp, isNotNull);
      },
    );
  });
}
