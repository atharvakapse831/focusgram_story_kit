/// Signature for interaction callbacks (poll vote, quiz answer, link tap).
///
/// Lives in this base file so the viewer and renderer share one canonical
/// typedef without circular imports or duplicate exports.
typedef OnOverlayInteraction = void Function(
  String overlayId,
  Map<String, dynamic> payload,
);

/// Base for every interactive overlay placed on a story item.
///
/// Overlays are data, not pixels: the editor serializes them with
/// [toJson], the viewer rebuilds them as widgets. This is the deliberate
/// inversion of flutter_story_editor's flatten-to-pixels export.
abstract class StoryOverlay {
  const StoryOverlay({
    required this.id,
    required this.normalizedDx,
    required this.normalizedDy,
  });

  final String id;

  /// Normalized center position 0.0-1.0, resolution-independent.
  final double normalizedDx;
  final double normalizedDy;

  Map<String, dynamic> toJson();
}

/// Poll overlay — reuses FocusGram's chat poll wire format
/// (`poll_options` structured maps, legacy `options` fallback).
class PollOverlay extends StoryOverlay {
  final String question;
  final List<String> options;
  final bool allowMultiple;

  const PollOverlay({
    required super.id,
    required super.normalizedDx,
    required super.normalizedDy,
    required this.question,
    required this.options,
    this.allowMultiple = false,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'poll',
    'id': id,
    'dx': normalizedDx,
    'dy': normalizedDy,
    'question': question,
    'options': options,
    'allowMultiple': allowMultiple,
  };
}

/// Quiz overlay — one correct answer among [options].
class QuizOverlay extends StoryOverlay {
  final String question;
  final List<String> options;
  final int answerIndex;

  const QuizOverlay({
    required super.id,
    required super.normalizedDx,
    required super.normalizedDy,
    required this.question,
    required this.options,
    required this.answerIndex,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'quiz',
    'id': id,
    'dx': normalizedDx,
    'dy': normalizedDy,
    'question': question,
    'options': options,
    'answerIndex': answerIndex,
  };
}

/// Emoji slider overlay (Instagram-style).
class SliderOverlay extends StoryOverlay {
  final String emoji;
  final String question;
  final double minValue;
  final double maxValue;

  const SliderOverlay({
    required super.id,
    required super.normalizedDx,
    required super.normalizedDy,
    required this.emoji,
    required this.question,
    this.minValue = 0,
    this.maxValue = 100,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'slider',
    'id': id,
    'dx': normalizedDx,
    'dy': normalizedDy,
    'emoji': emoji,
    'question': question,
    'min': minValue,
    'max': maxValue,
  };
}

/// Question box overlay — replies are delivered as story interactions,
/// optionally forwarded to the author's DM.
class QuestionOverlay extends StoryOverlay {
  final String prompt;

  const QuestionOverlay({
    required super.id,
    required super.normalizedDx,
    required super.normalizedDy,
    required this.prompt,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'question',
    'id': id,
    'dx': normalizedDx,
    'dy': normalizedDy,
    'prompt': prompt,
  };
}

/// Countdown overlay to a fixed target time.
class CountdownOverlay extends StoryOverlay {
  final DateTime targetTime;

  const CountdownOverlay({
    required super.id,
    required super.normalizedDx,
    required super.normalizedDy,
    required this.targetTime,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'countdown',
    'id': id,
    'dx': normalizedDx,
    'dy': normalizedDy,
    'targetTime': targetTime.toUtc().toIso8601String(),
  };
}

/// Link sticker overlay. Only absolute http(s) URLs survive serialization.
class LinkOverlay extends StoryOverlay {
  final String url;
  final String displayDomain;

  const LinkOverlay({
    required super.id,
    required super.normalizedDx,
    required super.normalizedDy,
    required this.url,
    required this.displayDomain,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'link',
    'id': id,
    'dx': normalizedDx,
    'dy': normalizedDy,
    'url': url,
    'displayDomain': displayDomain,
  };

  /// Rejects anything that is not a plain http(s) URL before the viewer
  /// ever tries to open it.
  static bool isValidUrl(String candidate) {
    final uri = Uri.tryParse(candidate.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}

/// Mention overlay — taps navigate to the mentioned user's profile.
class MentionOverlay extends StoryOverlay {
  final String userId;
  final String username;

  const MentionOverlay({
    required super.id,
    required super.normalizedDx,
    required super.normalizedDy,
    required this.userId,
    required this.username,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'mention',
    'id': id,
    'dx': normalizedDx,
    'dy': normalizedDy,
    'userId': userId,
    'username': username,
  };
}

/// Placeholder for overlay payloads this app version does not understand.
///
/// Forward compatibility: the codec wraps unrecognized types so a
/// decode/re-encode round-trip never drops content written by newer app
/// versions. The renderer skips it instead of crashing.
class UnknownStoryOverlay extends StoryOverlay {
  /// The unrecognized `type` value from the source payload.
  final String type;

  /// The original payload, preserved so re-encoding is lossless.
  final Map<String, dynamic> rawData;

  const UnknownStoryOverlay({
    required super.id,
    required super.normalizedDx,
    required super.normalizedDy,
    required this.type,
    required this.rawData,
  });

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(rawData);
}
