import 'dart:async';

import 'package:flutter/material.dart';

import '../overlays/story_overlay.dart';

/// Renders a story item's overlays as tappable, interactive widgets
/// positioned over the media.
///
/// Hit-testing: each overlay widget absorbs taps inside its bounds; taps
/// outside them fall through to the viewer's 30%/70% navigation zones.
/// Interacting with an overlay pauses the story while its input UI is up —
/// the host app calls [onOverlayInteraction] and resumes when it sees fit.
class StoryOverlayRenderer extends StatelessWidget {
  final List<StoryOverlay> overlays;
  final OnOverlayInteraction? onOverlayInteraction;
  final VoidCallback? onOverlayInteractionStarted;

  const StoryOverlayRenderer({
    super.key,
    required this.overlays,
    this.onOverlayInteraction,
    this.onOverlayInteractionStarted,
  });

  @override
  Widget build(BuildContext context) {
    if (overlays.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final overlay in overlays)
              Positioned(
                left: overlay.normalizedDx * size.width,
                top: overlay.normalizedDy * size.height,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: _buildOverlayWidget(overlay),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOverlayWidget(StoryOverlay overlay) {
    return switch (overlay) {
      PollOverlay poll => _PollWidget(
        poll: poll,
        onVote: (index) => _interact(poll.id, {
          'type': 'poll',
          'optionIndex': index,
        }),
      ),
      QuizOverlay quiz => _QuizWidget(
        quiz: quiz,
        onAnswer: (index) => _interact(quiz.id, {
          'type': 'quiz',
          'optionIndex': index,
          'correct': index == quiz.answerIndex,
        }),
      ),
      SliderOverlay slider => _SliderWidget(
        slider: slider,
        onSlide: (value) => _interact(slider.id, {
          'type': 'slider',
          'value': value,
        }),
      ),
      QuestionOverlay question => _QuestionWidget(
        question: question,
        onSubmit: (text) => _interact(question.id, {
          'type': 'question',
          'text': text,
        }),
      ),
      CountdownOverlay countdown => _CountdownWidget(countdown: countdown),
      LinkOverlay link => _LinkWidget(
        link: link,
        onTap: () => _interact(link.id, {
          'type': 'link',
          'url': link.url,
        }),
      ),
      MentionOverlay mention => _MentionWidget(
        mention: mention,
        onTap: () => _interact(mention.id, {
          'type': 'mention',
          'userId': mention.userId,
          'username': mention.username,
        }),
      ),
      UnknownStoryOverlay _ => const SizedBox.shrink(),
    };
  }

  void _interact(String overlayId, Map<String, dynamic> payload) {
    onOverlayInteractionStarted?.call();
    onOverlayInteraction?.call(overlayId, payload);
  }
}

// ---------------------------------------------------------------------------
// Poll
// ---------------------------------------------------------------------------

class _PollWidget extends StatefulWidget {
  final PollOverlay poll;
  final void Function(int index) onVote;

  const _PollWidget({required this.poll, required this.onVote});

  @override
  State<_PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<_PollWidget> {
  int? _votedIndex;

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    return _OverlayCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll.question,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < poll.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _PollOptionRow(
                label: poll.options[i],
                selected: _votedIndex == i,
                onTap: () {
                  if (_votedIndex != null) return;
                  setState(() => _votedIndex = i);
                  widget.onVote(i);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PollOptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PollOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quiz
// ---------------------------------------------------------------------------

class _QuizWidget extends StatefulWidget {
  final QuizOverlay quiz;
  final void Function(int index) onAnswer;

  const _QuizWidget({required this.quiz, required this.onAnswer});

  @override
  State<_QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<_QuizWidget> {
  int? _answeredIndex;

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    return _OverlayCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quiz.question,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < quiz.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _QuizOptionRow(
                label: quiz.options[i],
                state: _stateFor(i),
                onTap: _answeredIndex == null
                    ? () {
                        setState(() => _answeredIndex = i);
                        widget.onAnswer(i);
                      }
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  _QuizOptionState _stateFor(int index) {
    if (_answeredIndex == null) return _QuizOptionState.idle;
    if (index == widget.quiz.answerIndex) return _QuizOptionState.correct;
    if (index == _answeredIndex) return _QuizOptionState.wrong;
    return _QuizOptionState.dimmed;
  }
}

enum _QuizOptionState { idle, correct, wrong, dimmed }

class _QuizOptionRow extends StatelessWidget {
  final String label;
  final _QuizOptionState state;
  final VoidCallback? onTap;

  const _QuizOptionRow({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (color, textColor, icon) = switch (state) {
      _QuizOptionState.idle => (Colors.white24, Colors.white, null),
      _QuizOptionState.correct => (
        Colors.green,
        Colors.white,
        Icons.check_circle_outline,
      ),
      _QuizOptionState.wrong => (
        Colors.red,
        Colors.white,
        Icons.cancel_outlined,
      ),
      _QuizOptionState.dimmed => (Colors.white12, Colors.white54, null),
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Emoji slider
// ---------------------------------------------------------------------------

class _SliderWidget extends StatefulWidget {
  final SliderOverlay slider;
  final void Function(double value) onSlide;

  const _SliderWidget({required this.slider, required this.onSlide});

  @override
  State<_SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<_SliderWidget> {
  // Attached to the slider track so drag positions map to the track's own
  // bounds, not the whole overlay card (which includes the question text).
  final GlobalKey _sliderTrackKey = GlobalKey();
  late double _value;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _value = widget.slider.minValue;
  }

  @override
  void didUpdateWidget(covariant _SliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slider.id != widget.slider.id ||
        oldWidget.slider.minValue != widget.slider.minValue ||
        oldWidget.slider.maxValue != widget.slider.maxValue) {
      _value = widget.slider.minValue;
      _dragging = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final slider = widget.slider;
    return _OverlayCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (slider.question.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                slider.question,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              final box =
                  _sliderTrackKey.currentContext?.findRenderObject()
                      as RenderBox?;
              if (box == null || box.size.width <= 0) return;
              final localX = box
                  .globalToLocal(details.globalPosition)
                  .dx
                  .clamp(0.0, box.size.width)
                  .toDouble();
              final fraction = localX / box.size.width;
              final value = slider.minValue +
                  fraction * (slider.maxValue - slider.minValue);
              setState(() {
                _value = value;
                _dragging = true;
              });
            },
            onHorizontalDragEnd: (_) {
              setState(() => _dragging = false);
              widget.onSlide(_value);
            },
            child: Container(
              key: _sliderTrackKey,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    slider.emoji,
                    style: TextStyle(fontSize: 24 + (_dragging ? 8 : 0)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Question box
// ---------------------------------------------------------------------------

class _QuestionWidget extends StatefulWidget {
  final QuestionOverlay question;
  final void Function(String text) onSubmit;

  const _QuestionWidget({required this.question, required this.onSubmit});

  @override
  State<_QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<_QuestionWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _OverlayCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question.prompt,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_submitted)
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text('Sent', style: TextStyle(color: Colors.white70)),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Type your reply',
                      hintStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white38),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    widget.onSubmit(text);
                    setState(() => _submitted = true);
                  },
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Countdown
// ---------------------------------------------------------------------------

class _CountdownWidget extends StatefulWidget {
  final CountdownOverlay countdown;

  const _CountdownWidget({required this.countdown});

  @override
  State<_CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<_CountdownWidget> {
  late Timer _timer;
  Duration _remaining = widget.countdown.targetTime.difference(DateTime.now());

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = widget.countdown.targetTime.difference(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining.isNegative;
    final text = expired
        ? 'Done'
        : '${_remaining.inHours.toString().padLeft(2, '0')}:'
            '${(_remaining.inMinutes % 60).toString().padLeft(2, '0')}:'
            '${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    return _OverlayCard(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Link / Mention
// ---------------------------------------------------------------------------

class _LinkWidget extends StatelessWidget {
  final LinkOverlay link;
  final VoidCallback onTap;

  const _LinkWidget({required this.link, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _OverlayCard(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                link.displayDomain.isNotEmpty ? link.displayDomain : link.url,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MentionWidget extends StatelessWidget {
  final MentionOverlay mention;
  final VoidCallback onTap;

  const _MentionWidget({required this.mention, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _OverlayCard(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alternate_email, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              mention.username,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared card chrome
// ---------------------------------------------------------------------------

class _OverlayCard extends StatelessWidget {
  final Widget child;

  const _OverlayCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: child,
    );
  }
}
