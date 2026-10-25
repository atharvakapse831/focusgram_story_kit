import 'story_overlay.dart';

/// Decodes overlay JSON back into typed overlays.
///
/// Unknown types decode to null (forward compatibility) rather than
/// throwing — an older app version must never crash on a newer payload.
StoryOverlay? decodeStoryOverlay(Map<String, dynamic> json) {
  final type = json['type'] as String?;
  final id = json['id'] as String?;
  final dx = (json['dx'] as num?)?.toDouble() ?? 0.5;
  final dy = (json['dy'] as num?)?.toDouble() ?? 0.5;
  if (type == null || id == null) return null;

  switch (type) {
    case 'poll':
      final options = (json['options'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      return PollOverlay(
        id: id,
        normalizedDx: dx,
        normalizedDy: dy,
        question: json['question']?.toString() ?? '',
        options: List<String>.from(options),
        allowMultiple: json['allowMultiple'] as bool? ?? false,
      );
    case 'quiz':
      final options = (json['options'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[];
      final answerIndex = (json['answerIndex'] as num?)?.toInt() ?? 0;
      return QuizOverlay(
        id: id,
        normalizedDx: dx,
        normalizedDy: dy,
        question: json['question']?.toString() ?? '',
        options: List<String>.from(options),
        answerIndex:
            options.isEmpty ? 0 : answerIndex.clamp(0, options.length - 1),
      );
    case 'slider':
      return SliderOverlay(
        id: id,
        normalizedDx: dx,
        normalizedDy: dy,
        emoji: json['emoji']?.toString() ?? 'smiley',
        question: json['question']?.toString() ?? '',
        minValue: (json['min'] as num?)?.toDouble() ?? 0,
        maxValue: (json['max'] as num?)?.toDouble() ?? 100,
      );
    case 'question':
      return QuestionOverlay(
        id: id,
        normalizedDx: dx,
        normalizedDy: dy,
        prompt: json['prompt']?.toString() ?? '',
      );
    case 'countdown':
      final target = DateTime.tryParse(json['targetTime']?.toString() ?? '');
      if (target == null) return null;
      return CountdownOverlay(
        id: id,
        normalizedDx: dx,
        normalizedDy: dy,
        targetTime: target,
      );
    case 'link':
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
      return null;
  }
}

List<StoryOverlay> decodeOverlayList(List<dynamic>? jsonList) {
  if (jsonList == null) return const [];
  return jsonList
      .whereType<Map>()
      .map((m) => decodeStoryOverlay(Map<String, dynamic>.from(m)))
      .whereType<StoryOverlay>()
      .toList();
}
