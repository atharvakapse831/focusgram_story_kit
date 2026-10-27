import 'story_overlay.dart';

/// Decodes known overlay payloads defensively and preserves unknown types.
StoryOverlay? decodeStoryOverlay(Map<String, dynamic> json) {
  try {
    final type = json['type'];
    final id = json['id'];
    if (type is! String || type.isEmpty || id is! String || id.isEmpty) {
      return null;
    }
    final rawDx = json['dx'];
    final rawDy = json['dy'];
    final dx =
        rawDx is num && rawDx.isFinite
            ? rawDx.toDouble().clamp(0.0, 1.0).toDouble()
            : 0.5;
    final dy =
        rawDy is num && rawDy.isFinite
            ? rawDy.toDouble().clamp(0.0, 1.0).toDouble()
            : 0.5;
    bool validPosition() =>
        rawDx is num &&
        rawDx.isFinite &&
        rawDx >= 0 &&
        rawDx <= 1 &&
        rawDy is num &&
        rawDy.isFinite &&
        rawDy >= 0 &&
        rawDy <= 1;

    switch (type) {
      case 'poll':
        if (!validPosition()) return null;
        final options = json['options'];
        final allowMultiple = json['allowMultiple'];
        if ((options != null && options is! List) ||
            (allowMultiple != null && allowMultiple is! bool))
          return null;
        return PollOverlay(
          id: id,
          normalizedDx: dx,
          normalizedDy: dy,
          question: json['question']?.toString() ?? '',
          options:
              options is List
                  ? options.map((value) => value.toString()).toList()
                  : const <String>[],
          allowMultiple: allowMultiple as bool? ?? false,
        );
      case 'quiz':
        if (!validPosition()) return null;
        final options = json['options'];
        final answer = json['answerIndex'];
        if ((options != null && options is! List) ||
            (answer != null && answer is! num))
          return null;
        final values =
            options is List
                ? options.map((value) => value.toString()).toList()
                : const <String>[];
        final answerIndex = answer is num ? answer.toInt() : 0;
        return QuizOverlay(
          id: id,
          normalizedDx: dx,
          normalizedDy: dy,
          question: json['question']?.toString() ?? '',
          options: values,
          answerIndex:
              values.isEmpty
                  ? 0
                  : answerIndex.clamp(0, values.length - 1).toInt(),
        );
      case 'slider':
        if (!validPosition()) return null;
        final min = json['min'];
        final max = json['max'];
        if ((min != null && min is! num) || (max != null && max is! num)) {
          return null;
        }
        final minValue = min is num ? min.toDouble() : 0.0;
        final maxValue = max is num ? max.toDouble() : 100.0;
        if (!minValue.isFinite || !maxValue.isFinite || maxValue < minValue) {
          return null;
        }
        return SliderOverlay(
          id: id,
          normalizedDx: dx,
          normalizedDy: dy,
          emoji: json['emoji']?.toString() ?? '\u{1F600}',
          question: json['question']?.toString() ?? '',
          minValue: minValue,
          maxValue: maxValue,
        );
      case 'question':
        if (!validPosition()) return null;
        return QuestionOverlay(
          id: id,
          normalizedDx: dx,
          normalizedDy: dy,
          prompt: json['prompt']?.toString() ?? '',
        );
      case 'countdown':
        if (!validPosition()) return null;
        final target = DateTime.tryParse(json['targetTime']?.toString() ?? '');
        if (target == null) return null;
        return CountdownOverlay(
          id: id,
          normalizedDx: dx,
          normalizedDy: dy,
          targetTime: target,
        );
      case 'link':
        if (!validPosition()) return null;
        final url = json['url']?.toString() ?? '';
        if (!LinkOverlay.isValidUrl(url)) return null;
        return LinkOverlay(
          id: id,
          normalizedDx: dx,
          normalizedDy: dy,
          url: url,
          displayDomain: json['displayDomain']?.toString() ?? '',
        );
      case 'mention':
        if (!validPosition()) return null;
        final userId = json['userId']?.toString();
        final username = json['username']?.toString();
        if (userId == null || userId.isEmpty || username == null) return null;
        return MentionOverlay(
          id: id,
          normalizedDx: dx,
          normalizedDy: dy,
          userId: userId,
          username: username,
        );
      default:
        return UnknownStoryOverlay(
          id: id,
          normalizedDx: dx,
          normalizedDy: dy,
          type: type,
          rawData: Map<String, dynamic>.from(json),
        );
    }
  } catch (_) {
    return null;
  }
}

/// Decodes a list, skipping non-map and malformed known-type entries.
List<StoryOverlay> decodeOverlayList(List<dynamic>? jsonList) {
  if (jsonList == null) return const [];
  final overlays = <StoryOverlay>[];
  for (final entry in jsonList) {
    if (entry is! Map) continue;
    if (entry.keys.any((key) => key is! String)) continue;
    final overlay = decodeStoryOverlay(Map<String, dynamic>.from(entry));
    if (overlay != null) overlays.add(overlay);
  }
  return overlays;
}
