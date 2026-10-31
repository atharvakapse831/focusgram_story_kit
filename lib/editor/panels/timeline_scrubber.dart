import 'package:flutter/material.dart';
import '../../models/video_payload.dart';
import '../editor_controller.dart';

/// Interactive timeline scrubber widget displaying playhead, trim handles,
/// thumbnail filmstrip preview, and playback controls.
class TimelineScrubber extends StatelessWidget {
  const TimelineScrubber({
    super.key,
    required this.controller,
    this.onOpenAnimationSheet,
    this.onOpenAudioSheet,
    this.onOpenCoverSheet,
  });

  final EditorController controller;
  final VoidCallback? onOpenAnimationSheet;
  final VoidCallback? onOpenAudioSheet;
  final VoidCallback? onOpenCoverSheet;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '$minutes:$seconds.$millis';
  }

  @override
  Widget build(BuildContext context) {
    final tc = controller.timelineController;

    return ListenableBuilder(
      listenable: tc,
      builder: (context, _) {
        final state = tc.state;
        final totalMs = state.totalDuration.inMilliseconds.toDouble();
        final currentMs = state.currentPosition.inMilliseconds.toDouble().clamp(
          0.0,
          totalMs > 0 ? totalMs : 1.0,
        );
        final trimStartMs = (state.trimRange?.start.inMilliseconds.toDouble() ??
                0.0)
            .clamp(0.0, totalMs);
        final trimEndMs = (state.trimRange?.end.inMilliseconds.toDouble() ??
                totalMs)
            .clamp(trimStartMs, totalMs);

        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header controls: Play/Pause, timestamps, tool shortcuts
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      state.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: tc.togglePlayPause,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDuration(state.currentPosition)} / ${_formatDuration(state.effectiveDuration)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  // Split clip button
                  IconButton(
                    tooltip: 'Split Clip',
                    icon: const Icon(
                      Icons.content_cut,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () {
                      final current = state.currentPosition;
                      if (current > state.effectiveStart &&
                          current < state.effectiveEnd) {
                        controller.splitVideoClip(current);
                      }
                    },
                  ),
                  // Animation sheet button
                  IconButton(
                    tooltip: 'Layer Animation',
                    icon: const Icon(
                      Icons.animation,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: onOpenAnimationSheet,
                  ),
                  // Audio settings button
                  IconButton(
                    tooltip: 'Audio Settings',
                    icon: const Icon(
                      Icons.volume_up,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: onOpenAudioSheet,
                  ),
                  // Cover picker button
                  IconButton(
                    tooltip: 'Cover Frame',
                    icon: const Icon(
                      Icons.photo_size_select_actual,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: onOpenCoverSheet,
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // 2. Filmstrip Track & Range / Playhead Scrubber
              SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Simulated filmstrip background bar (waveform deferred per plan)
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: List.generate(
                          8,
                          (i) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Icon(
                                Icons.movie_creation_outlined,
                                color: Colors.white12,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Active trim window highlight
                    if (totalMs > 0)
                      Positioned(
                        left:
                            (trimStartMs / totalMs) *
                            (MediaQuery.of(context).size.width - 32),
                        width:
                            ((trimEndMs - trimStartMs) / totalMs) *
                            (MediaQuery.of(context).size.width - 32),
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.amber, width: 2),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.amber.withValues(alpha: 0.15),
                          ),
                        ),
                      ),

                    // Playhead slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 36,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        thumbColor: Colors.white,
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: currentMs,
                        min: 0.0,
                        max: totalMs > 0 ? totalMs : 1.0,
                        onChangeStart: (_) => tc.startScrubbing(),
                        onChanged: (val) {
                          tc.seekTo(
                            Duration(milliseconds: val.toInt()),
                            exact: false,
                          );
                        },
                        onChangeEnd: (_) => tc.endScrubbing(),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Trim handle sliders (fine-grained trim control)
              if (totalMs > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      const Text(
                        'Trim:',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      Expanded(
                        child: RangeSlider(
                          values: RangeValues(trimStartMs, trimEndMs),
                          min: 0.0,
                          max: totalMs,
                          activeColor: Colors.amber,
                          inactiveColor: Colors.white24,
                          onChanged: (values) {
                            final newTrim = VideoTrimRange(
                              start: Duration(
                                milliseconds: values.start.toInt(),
                              ),
                              end: Duration(milliseconds: values.end.toInt()),
                            );
                            controller.setVideoTrimRange(newTrim);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
