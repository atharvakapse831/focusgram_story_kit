import 'package:flutter/material.dart';
import '../../models/video_payload.dart';
import '../editor_controller.dart';

/// Modal sheet for audio mixing, volume control, mute policy, and export sample rate selection.
class AudioSettingsSheet extends StatefulWidget {
  const AudioSettingsSheet({super.key, required this.controller});

  final EditorController controller;

  static Future<void> show(BuildContext context, EditorController controller) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AudioSettingsSheet(controller: controller),
    );
  }

  @override
  State<AudioSettingsSheet> createState() => _AudioSettingsSheetState();
}

class _AudioSettingsSheetState extends State<AudioSettingsSheet> {
  late bool _muteOriginal;
  late double _originalVolume;
  late double _musicVolume;
  late AudioSampleRate _sampleRate;
  late int _bitrateKbps;

  @override
  void initState() {
    super.initState();
    final policy =
        widget.controller.activePage.audioPolicy ?? const VideoAudioPolicy();
    _muteOriginal = policy.muteOriginal;
    _originalVolume = policy.originalVolume;
    _musicVolume = policy.musicVolume;
    _sampleRate = policy.audioSampleRate;
    _bitrateKbps = policy.audioBitrateKbps;
  }

  void _applyChanges() {
    final current =
        widget.controller.activePage.audioPolicy ?? const VideoAudioPolicy();
    final updated = current.copyWith(
      muteOriginal: _muteOriginal,
      originalVolume: _originalVolume,
      musicVolume: _musicVolume,
      audioSampleRate: _sampleRate,
      audioBitrateKbps: _bitrateKbps,
    );
    widget.controller.setAudioPolicy(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E1E),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Audio & Sound Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _applyChanges();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Mute original audio toggle
            SwitchListTile(
              title: const Text(
                'Mute Original Audio',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: const Text(
                'Completely removes sound from original video',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: _muteOriginal,
              activeThumbColor: Colors.amber,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _muteOriginal = val),
            ),

            // Original video volume slider
            if (!_muteOriginal) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.volume_down,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Video Volume (${(_originalVolume * 100).toInt()}%)',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              Slider(
                value: _originalVolume,
                min: 0.0,
                max: 1.0,
                activeColor: Colors.amber,
                onChanged: (val) => setState(() => _originalVolume = val),
              ),
            ],

            const Divider(color: Colors.white24, height: 24),

            // Audio Sample Rate Selection
            const Text(
              'Audio Output Sample Rate',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('44.1 kHz (Music & Web)'),
                  selected: _sampleRate == AudioSampleRate.hz44100,
                  selectedColor: Colors.amber,
                  labelStyle: TextStyle(
                    color:
                        _sampleRate == AudioSampleRate.hz44100
                            ? Colors.black
                            : Colors.white,
                    fontSize: 12,
                  ),
                  onSelected:
                      (_) =>
                          setState(() => _sampleRate = AudioSampleRate.hz44100),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('48.0 kHz (Broadcast)'),
                  selected: _sampleRate == AudioSampleRate.hz48000,
                  selectedColor: Colors.amber,
                  labelStyle: TextStyle(
                    color:
                        _sampleRate == AudioSampleRate.hz48000
                            ? Colors.black
                            : Colors.white,
                    fontSize: 12,
                  ),
                  onSelected:
                      (_) =>
                          setState(() => _sampleRate = AudioSampleRate.hz48000),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Audio Bitrate
            Row(
              children: [
                Text(
                  'Bitrate: $_bitrateKbps kbps AAC',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Expanded(
                  child: Slider(
                    value: _bitrateKbps.toDouble(),
                    min: 64,
                    max: 256,
                    divisions: 6,
                    activeColor: Colors.amber,
                    onChanged:
                        (val) => setState(() => _bitrateKbps = val.toInt()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
