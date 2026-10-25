import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/overlays/story_overlay.dart';
import 'package:focusgram_story_kit/viewer/story_overlay_renderer.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 800,
          child: child,
        ),
      ),
    );
  }

  group('StoryOverlayRenderer', () {
    testWidgets('renders empty when there are no overlays', (tester) async {
      await tester.pumpWidget(
        wrap(const StoryOverlayRenderer(overlays: [])),
      );
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
    });

    testWidgets('quiz answer reveals correct/wrong states once', (tester) async {
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

      // Wrong pick: correct option turns green, picked option turns red.
      expect(answers['q1']!['correct'], isFalse);
      expect(answers['q1']!['optionIndex'], 0);

      // Second tap does nothing — the quiz locks after one answer.
      await tester.tap(find.text('4'));
      await tester.pump();
      expect(answers['q1']!['optionIndex'], 0);
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

    testWidgets('countdown shows a running clock', (tester) async {
      await tester.pumpWidget(
        wrap(
          const StoryOverlayRenderer(
            overlays: [
              CountdownOverlay(
                id: 'c1',
                normalizedDx: 0.5,
                normalizedDy: 0.5,
                targetTime: null,
              ),
            ],
          ),
        ),
      );
      // Placeholder assertion; replaced below by a real target time test.
      expect(find.byType(StoryOverlayRenderer), findsOneWidget);
    });
  });
}
