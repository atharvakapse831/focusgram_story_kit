import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/overlays/story_overlay.dart';
import 'package:focusgram_story_kit/viewer/story_overlay_renderer.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: SizedBox(width: 400, height: 800, child: child)),
    );
  }

  group('StoryOverlayRenderer', () {
    testWidgets('renders empty when there are no overlays', (tester) async {
      await tester.pumpWidget(wrap(const StoryOverlayRenderer(overlays: [])));
      expect(find.byType(StoryOverlayRenderer), findsOneWidget);
    });

    testWidgets('poll tap votes and reports the option index', (tester) async {
      final interactions = <String, Map<String, dynamic>>{};
      var pauseRequested = 0;

      await tester.pumpWidget(
        wrap(
          StoryOverlayRenderer(
            overlays: const [
              PollOverlay(
                id: 'p1',
                normalizedDx: 0.5,
                normalizedDy: 0.5,
                question: 'Cats or dogs?',
                options: ['Cats', 'Dogs'],
              ),
            ],
            onOverlayInteractionStarted: () => pauseRequested++,
            onOverlayInteraction: (id, payload) => interactions[id] = payload,
          ),
        ),
      );

      expect(find.text('Cats or dogs?'), findsOneWidget);
      expect(find.text('Dogs'), findsOneWidget);

      await tester.tap(find.text('Dogs'));
      await tester.pump();

      expect(interactions['p1'], isNotNull);
      expect(interactions['p1']!['optionIndex'], 1);
      expect(pauseRequested, 1);

      // The poll freezes after the first vote — a second option tap must not
      // re-vote or re-fire the interaction.
      await tester.tap(find.text('Cats'));
      await tester.pump();
      expect(interactions['p1']!['optionIndex'], 1);
      expect(pauseRequested, 1);
    });

    testWidgets('quiz answer reveals correct/wrong states once', (
      tester,
    ) async {
      final answers = <String, Map<String, dynamic>>{};

      await tester.pumpWidget(
        wrap(
          StoryOverlayRenderer(
            overlays: const [
              QuizOverlay(
                id: 'q1',
                normalizedDx: 0.5,
                normalizedDy: 0.5,
                question: '2 + 2?',
                options: ['3', '4', '5'],
                answerIndex: 1,
              ),
            ],
            onOverlayInteraction: (id, payload) => answers[id] = payload,
          ),
        ),
      );

      await tester.tap(find.text('3'));
      await tester.pump();

      // Wrong pick reported as incorrect.
      expect(answers['q1']!['correct'], isFalse);
      expect(answers['q1']!['optionIndex'], 0);

      // Second tap does nothing — the quiz locks after one answer.
      await tester.tap(find.text('4'));
      await tester.pump();
      expect(answers['q1']!['optionIndex'], 0);
    });

    testWidgets('slider drag maps track bounds to min and max values', (
      tester,
    ) async {
      final slides = <double>[];

      await tester.pumpWidget(
        wrap(
          StoryOverlayRenderer(
            overlays: const [
              SliderOverlay(
                id: 's1',
                normalizedDx: 0.5,
                normalizedDy: 0.5,
                emoji: '\u{1F600}',
                question: 'How much?',
                minValue: 0,
                maxValue: 100,
              ),
            ],
            onOverlayInteraction:
                (id, payload) => slides.add(payload['value'] as double),
          ),
        ),
      );
      await tester.pump();

      final trackRect = tester.getRect(
        find.text('\u{1F600}').hitTestable().first,
      );

      // Drag from the far left of the track to its far right: the reported
      // value must span the slider's [min, max] range, not the card's bounds.
      final gesture = await tester.startGesture(trackRect.centerLeft);
      await gesture.moveBy(const Offset(200, 0));
      await gesture.up();
      await tester.pump();

      expect(slides.length, 1);
      expect(slides.first, 100);
    });

    testWidgets('question submit reports the typed text', (tester) async {
      final submissions = <String, Map<String, dynamic>>{};

      await tester.pumpWidget(
        wrap(
          StoryOverlayRenderer(
            overlays: const [
              QuestionOverlay(
                id: 'ask1',
                normalizedDx: 0.5,
                normalizedDy: 0.6,
                prompt: 'Ask me anything',
              ),
            ],
            onOverlayInteraction: (id, payload) => submissions[id] = payload,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello!');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(submissions['ask1']!['text'], 'hello!');
      // After submit the input is replaced by a confirmation.
      expect(find.text('Sent'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('link tap reports the url to the host', (tester) async {
      final taps = <String, Map<String, dynamic>>{};

      await tester.pumpWidget(
        wrap(
          StoryOverlayRenderer(
            overlays: const [
              LinkOverlay(
                id: 'l1',
                normalizedDx: 0.5,
                normalizedDy: 0.5,
                url: 'https://focusgram.example',
                displayDomain: 'focusgram.example',
              ),
            ],
            onOverlayInteraction: (id, payload) => taps[id] = payload,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.link));
      await tester.pump();

      expect(taps['l1']!['url'], 'https://focusgram.example');
    });

    testWidgets('mention tap reports userId and username', (tester) async {
      final taps = <String, Map<String, dynamic>>{};

      await tester.pumpWidget(
        wrap(
          StoryOverlayRenderer(
            overlays: const [
              MentionOverlay(
                id: 'm1',
                normalizedDx: 0.5,
                normalizedDy: 0.5,
                userId: 'u42',
                username: 'someone',
              ),
            ],
            onOverlayInteraction: (id, payload) => taps[id] = payload,
          ),
        ),
      );

      await tester.tap(find.text('someone'));
      await tester.pump();

      expect(taps['m1']!['userId'], 'u42');
      expect(taps['m1']!['username'], 'someone');
    });

    testWidgets('countdown renders a live clock for a future target', (
      tester,
    ) async {
      // Use a target 3h out and assert on the hours digits only; a target
      // of now+2h renders 01:59:xx because Duration.inHours truncates.
      final target = DateTime.now().add(const Duration(hours: 3));

      await tester.pumpWidget(
        wrap(
          StoryOverlayRenderer(
            overlays: [
              CountdownOverlay(
                id: 'c1',
                normalizedDx: 0.5,
                normalizedDy: 0.5,
                targetTime: target,
              ),
            ],
          ),
        ),
      );

      // A 3h countdown renders as 02:59:xx (truncating, not rounding).
      expect(find.textContaining('02:59:'), findsOneWidget);
    });
  });
}
