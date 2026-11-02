import 'package:flutter_test/flutter_test.dart';
import 'package:focusgram_story_kit/overlays/story_overlay.dart';
import 'package:focusgram_story_kit/overlays/overlay_codec.dart';

void main() {
  group('decodeStoryOverlay', () {
    test('poll round-trips with options and allowMultiple', () {
      const overlay = PollOverlay(
        id: 'p1',
        normalizedDx: 0.5,
        normalizedDy: 0.4,
        question: 'Cats or dogs?',
        options: ['Cats', 'Dogs'],
        allowMultiple: true,
      );
      final decoded = decodeStoryOverlay(
        Map<String, dynamic>.from(overlay.toJson()),
      );
      expect(decoded, isA<PollOverlay>());
      final poll = decoded! as PollOverlay;
      expect(poll.question, 'Cats or dogs?');
      expect(poll.options, ['Cats', 'Dogs']);
      expect(poll.allowMultiple, isTrue);
    });

    test('quiz clamps answerIndex into range', () {
      final decoded = decodeStoryOverlay({
        'type': 'quiz',
        'id': 'q1',
        'dx': 0.5,
        'dy': 0.5,
        'question': 'Pick one',
        'options': ['A', 'B', 'C'],
        'answerIndex': 99,
      });
      expect(decoded, isA<QuizOverlay>());
      expect((decoded! as QuizOverlay).answerIndex, 2);
    });

    test('link rejects non-http schemes', () {
      expect(
        decodeStoryOverlay({
          'type': 'link',
          'id': 'l1',
          'dx': 0.5,
          'dy': 0.5,
          'url': 'javascript:alert(1)',
          'displayDomain': 'x',
        }),
        isNull,
      );
      expect(
        decodeStoryOverlay({
          'type': 'link',
          'id': 'l2',
          'dx': 0.5,
          'dy': 0.5,
          'url': 'https://focusgram.example',
          'displayDomain': 'focusgram.example',
        }),
        isA<LinkOverlay>(),
      );
    });

    test('countdown rejects invalid timestamps', () {
      expect(
        decodeStoryOverlay({
          'type': 'countdown',
          'id': 'c1',
          'dx': 0.5,
          'dy': 0.5,
          'targetTime': 'not-a-date',
        }),
        isNull,
      );
    });

    test('unknown type is preserved for forward compatibility', () {
      final decoded = decodeStoryOverlay({
        'type': 'hologram',
        'id': 'h1',
        'dx': 0.5,
        'dy': 0.5,
        'hologramPayload': {'depth': 3},
      });
      expect(decoded, isA<UnknownStoryOverlay>());
      final unknown = decoded! as UnknownStoryOverlay;
      expect(unknown.type, 'hologram');
      expect(unknown.id, 'h1');
    });

    test('unknown overlay survives a decode/re-encode round-trip', () {
      const source = {
        'type': 'hologram',
        'id': 'h1',
        'dx': 0.5,
        'dy': 0.5,
        'hologramPayload': {'depth': 3},
      };
      final decoded = decodeStoryOverlay(source);
      expect(decoded, isA<UnknownStoryOverlay>());
      final reEncoded = decoded!.toJson();
      expect(reEncoded, source);
    });

    test('malformed known types are rejected, not wrapped', () {
      // Invalid position on a known type must not be preserved as playable
      // content; only unknown types are wrapped.
      expect(
        decodeStoryOverlay({
          'type': 'poll',
          'id': 'p2',
          'dx': 5,
          'dy': 0.5,
          'question': 'Broken position',
          'options': ['A'],
        }),
        isNull,
      );
      expect(
        decodeStoryOverlay({
          'type': 'slider',
          'id': 's2',
          'dx': 0.5,
          'dy': 0.5,
          'min': 100,
          'max': 0,
        }),
        isNull,
      );
      expect(
        decodeStoryOverlay({
          'type': 'countdown',
          'id': 'c2',
          'dx': 0.5,
          'dy': 0.5,
          'targetTime': 'also not a date',
        }),
        isNull,
      );
    });

    test('mention requires userId and username', () {
      expect(
        decodeStoryOverlay({
          'type': 'mention',
          'id': 'm1',
          'dx': 0.5,
          'dy': 0.5,
          'username': 'someone',
        }),
        isNull,
      );
    });
  });

  group('decodeOverlayList', () {
    test('skips non-map entries and malformed known types', () {
      final list = decodeOverlayList([
        'junk-string',
        {
          'type': 'question',
          'id': 'q1',
          'dx': 0.5,
          'dy': 0.5,
          'prompt': 'Ask me',
        },
        {
          // Malformed known type (position out of range) is dropped.
          'type': 'poll',
          'id': 'p3',
          'dx': 7,
          'dy': 0.5,
          'question': 'Broken',
          'options': ['A'],
        },
        42,
      ]);
      expect(list.length, 1);
      expect(list.first, isA<QuestionOverlay>());
    });

    test('preserves unknown overlay types in lists', () {
      final list = decodeOverlayList([
        {'type': 'hologram', 'id': 'h1', 'dx': 0.5, 'dy': 0.5},
        {
          'type': 'question',
          'id': 'q1',
          'dx': 0.5,
          'dy': 0.5,
          'prompt': 'Ask me',
        },
      ]);
      expect(list.length, 2);
      expect(list.whereType<UnknownStoryOverlay>(), isNotEmpty);
    });
  });

  group('LinkOverlay.isValidUrl', () {
    test('accepts absolute http and https only', () {
      expect(LinkOverlay.isValidUrl('https://a.com'), isTrue);
      expect(LinkOverlay.isValidUrl('http://a.com'), isTrue);
      expect(LinkOverlay.isValidUrl('file:///etc/passwd'), isFalse);
      expect(LinkOverlay.isValidUrl('not a url'), isFalse);
      expect(LinkOverlay.isValidUrl(''), isFalse);
    });
  });
}
