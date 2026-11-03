import 'package:flutter/material.dart';
import 'package:focusgram_story_kit/focusgram_story_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StoryKitExampleApp());
}

class StoryKitExampleApp extends StatelessWidget {
  const StoryKitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusGram Story Kit Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE1306C),
          secondary: Color(0xFF833AB4),
        ),
      ),
      home: const StoryKitExampleScreen(),
    );
  }
}

class StoryKitExampleScreen extends StatefulWidget {
  const StoryKitExampleScreen({super.key});

  @override
  State<StoryKitExampleScreen> createState() => _StoryKitExampleScreenState();
}

class _StoryKitExampleScreenState extends State<StoryKitExampleScreen> {
  late StoryTimelineController _timelineController;
  late InMemoryStoryDraftRepository _draftRepository;
  StoryProject? _activeProject;
  bool _isPlaying = false;
  Duration _currentPos = Duration.zero;
  double _exportProgress = 0.0;
  String _exportPhaseText = 'Idle';
  bool _isExporting = false;
  VideoExportJob? _currentExportJob;

  @override
  void initState() {
    super.initState();
    _draftRepository = InMemoryStoryDraftRepository();
    _initRepresentativeProject();
  }

  void _initRepresentativeProject() {
    // 1. Primary Background Video Media Asset
    const bgAsset = StoryMediaAsset(
      id: 'bg_clip_main',
      sourceType: StoryMediaSourceType.file,
      uri: '/sdcard/Download/sample_background.mp4',
      mimeType: 'video/mp4',
      duration: Duration(seconds: 10),
    );

    // 2. Floating Video Asset (In-Canvas Picture-in-Picture)
    const pipAsset = StoryMediaAsset(
      id: 'pip_clip_floating',
      sourceType: StoryMediaSourceType.file,
      uri: '/sdcard/Download/sample_pip.mp4',
      mimeType: 'video/mp4',
      duration: Duration(seconds: 6),
    );

    // 3. Floating Video Overlay Element
    const floatingVideoElement = StoryElement(
      id: 'el_pip_floating_video',
      type: StoryElementType.video,
      transform: StoryTransform(
        x: 0.72,
        y: 0.68,
        width: 0.36,
        height: 0.36,
        rotation: 0.05,
      ),
      opacity: 0.95,
      zIndex: 10,
      visibleTimeRange: LayerTimeRange(
        start: Duration(seconds: 2),
        end: Duration(seconds: 6),
      ),
      animation: OverlayAnimationConfig(
        entranceType: OverlayAnimationType.scale,
        entranceDuration: Duration(milliseconds: 400),
        exitType: OverlayAnimationType.fade,
        exitDuration: Duration(milliseconds: 400),
      ),
      payload: VideoElementPayload(
        video: StoryVideoPayload(
          asset: pipAsset,
          trimRange: VideoTrimRange(
            start: Duration(seconds: 1),
            end: Duration(seconds: 5),
          ),
          audioPolicy: VideoAudioPolicy(
            muteOriginal: false,
            originalVolume: 0.5,
            audioSampleRate: AudioSampleRate.hz48000,
          ),
          fitMode: VideoFitMode.cover,
        ),
      ),
    );

    // 4. Animated Rich Text Element
    const animatedTextElement = StoryElement(
      id: 'el_animated_text',
      type: StoryElementType.text,
      transform: StoryTransform(x: 0.5, y: 0.22, width: 0.85, height: 0.15),
      opacity: 1.0,
      zIndex: 20,
      visibleTimeRange: LayerTimeRange(
        start: Duration(seconds: 0),
        end: Duration(seconds: 6),
      ),
      animation: OverlayAnimationConfig(
        entranceType: OverlayAnimationType.slideUp,
        entranceDuration: Duration(milliseconds: 500),
        exitType: OverlayAnimationType.fade,
        exitDuration: Duration(milliseconds: 500),
      ),
      payload: TextElementPayload(
        text: 'FocusGram Phase 5 Production Story',
        fontSize: 28.0,
        isBold: true,
        textColor: Colors.white,
        outlineColor: Colors.black,
        outlineWidth: 2.5,
        shadowColor: Colors.black87,
        shadowBlurRadius: 6.0,
        shadowOffsetX: 2.0,
        shadowOffsetY: 2.0,
        backgroundColor: Color(0x66000000),
      ),
    );

    // 5. Animated Vector Shape Element
    const animatedShapeElement = StoryElement(
      id: 'el_animated_shape',
      type: StoryElementType.shape,
      transform: StoryTransform(x: 0.25, y: 0.65, width: 0.28, height: 0.28),
      opacity: 0.9,
      zIndex: 5,
      animation: OverlayAnimationConfig(
        entranceType: OverlayAnimationType.bounce,
        entranceDuration: Duration(milliseconds: 600),
        exitType: OverlayAnimationType.scale,
        exitDuration: Duration(milliseconds: 300),
      ),
      payload: ShapeElementPayload(
        shapeType: ShapeType.star,
        fillColor: Colors.amber,
        strokeColor: Colors.deepOrange,
        strokeWidth: 3.0,
      ),
    );

    // 6. Freehand Drawing Element with Neon Glow
    const drawingElement = StoryElement(
      id: 'el_freehand_drawing',
      type: StoryElementType.drawing,
      transform: StoryTransform(x: 0.5, y: 0.5, width: 1.0, height: 1.0),
      opacity: 0.85,
      zIndex: 4,
      payload: DrawingElementPayload(
        strokes: [
          DrawingStroke(
            brushType: DrawingBrushType.neon,
            color: Colors.cyanAccent,
            strokeWidth: 0.012,
            points: [
              DrawingPoint(x: 0.15, y: 0.40),
              DrawingPoint(x: 0.35, y: 0.45),
              DrawingPoint(x: 0.60, y: 0.38),
              DrawingPoint(x: 0.85, y: 0.42),
            ],
          ),
        ],
      ),
    );

    // 7. Animated Sticker Element
    const stickerElement = StoryElement(
      id: 'el_animated_sticker',
      type: StoryElementType.sticker,
      transform: StoryTransform(x: 0.82, y: 0.20, width: 0.18, height: 0.18),
      opacity: 1.0,
      zIndex: 25,
      visibleTimeRange: LayerTimeRange(
        start: Duration(seconds: 0),
        end: Duration(seconds: 6),
      ),
      animation: OverlayAnimationConfig(
        entranceType: OverlayAnimationType.scale,
        entranceDuration: Duration(milliseconds: 350),
        exitType: OverlayAnimationType.slideRight,
        exitDuration: Duration(milliseconds: 350),
      ),
      payload: StickerElementPayload(
        stickerId: 'stk_fire_badge',
        assetUri: '',
        label: '🔥',
      ),
    );

    // Construct StoryPage with background video and multi-layer timed elements
    const page = StoryPage(
      id: 'page_rep_1',
      duration: Duration(seconds: 7),
      backgroundAsset: bgAsset,
      videoTrimRange: VideoTrimRange(
        start: Duration(seconds: 1),
        end: Duration(seconds: 8),
      ),
      audioPolicy: VideoAudioPolicy(
        muteOriginal: false,
        originalVolume: 0.8,
        audioSampleRate: AudioSampleRate.hz48000,
      ),
      elements: [
        drawingElement,
        animatedShapeElement,
        floatingVideoElement,
        animatedTextElement,
        stickerElement,
      ],
    );

    _activeProject = const StoryProject(id: 'proj_rep_phase5', pages: [page]);

    _timelineController = StoryTimelineController(
      initialDuration: const Duration(seconds: 7),
      initialTrimRange: const VideoTrimRange(
        start: Duration.zero,
        end: Duration(seconds: 7),
      ),
      initialFrameRate: 30.0,
    );

    _timelineController.addListener(_onTimelineChanged);
  }

  void _onTimelineChanged() {
    if (mounted) {
      setState(() {
        _currentPos = _timelineController.currentPosition;
        _isPlaying = _timelineController.isPlaying;
      });
    }
  }

  @override
  void dispose() {
    _timelineController.removeListener(_onTimelineChanged);
    _timelineController.dispose();
    super.dispose();
  }

  Future<void> _handleSplit() async {
    final splitResult = _timelineController.splitAt(_currentPos);
    if (!mounted) return;

    if (splitResult != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Clip split at ${_currentPos.inMilliseconds}ms:\n'
            'Clip A: [${splitResult.first.start.inSeconds}s - ${splitResult.first.end.inSeconds}s]\n'
            'Clip B: [${splitResult.second.start.inSeconds}s - ${splitResult.second.end.inSeconds}s]',
          ),
          backgroundColor: Colors.green.shade800,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot split at active playhead boundary.'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  Future<void> _handleSaveDraft() async {
    if (_activeProject == null) return;
    await _draftRepository.saveDraft(_activeProject!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Draft saved: ${_activeProject!.id}'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  Future<void> _handleExport() async {
    if (_activeProject == null || _isExporting) return;

    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportPhaseText = 'Starting...';
    });

    final exporter = StoryVideoExporter();
    final job = exporter.startExport(
      project: _activeProject!,
      config: const StoryVideoExportConfig(
        width: 1080,
        height: 1920,
        frameRate: 30,
        videoBitrate: 8000000,
        audioBitrate: 128000,
        sampleRate: AudioSampleRate.hz48000,
      ),
    );

    _currentExportJob = job;

    job.progressStream.listen(
      (progress) {
        if (mounted) {
          setState(() {
            _exportProgress = progress.progress;
            _exportPhaseText =
                '${progress.phase.name} (${(progress.progress * 100).toStringAsFixed(1)}%)';
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isExporting = false;
            _exportPhaseText = 'Error: $err';
          });
        }
      },
    );

    try {
      final result = await job.result;
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportPhaseText = 'Complete!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: ${result.outputPath}'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportPhaseText = 'Failed: $e';
        });
      }
    }
  }

  Future<void> _handleCancelExport() async {
    if (_currentExportJob != null && _isExporting) {
      await _currentExportJob!.cancel();
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportPhaseText = 'Export Cancelled';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusGram Story Kit Showcase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save Draft',
            onPressed: _handleSaveDraft,
          ),
          IconButton(
            icon: const Icon(Icons.movie_creation_outlined),
            tooltip: 'Export MP4',
            onPressed: _isExporting ? null : _handleExport,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Preview Canvas Container (9:16 aspect ratio box)
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Background placeholder / visual representation
                        Container(
                          color: const Color(0xFF1E1E2C),
                          child: const Center(
                            child: Icon(
                              Icons.video_library_rounded,
                              size: 64,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                        // Overlay badge representation
                        Positioned(
                          top: 80,
                          left: 24,
                          right: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'FocusGram Phase 5 Production Story',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // Floating PiP overlay representation
                        Positioned(
                          bottom: 120,
                          right: 24,
                          width: 120,
                          height: 120,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade700,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber, width: 2),
                            ),
                            child: const Center(
                              child: Text(
                                'PIP Video\n(Track 2)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        // Neon Stroke Indicator
                        Positioned(
                          bottom: 60,
                          left: 24,
                          child: Row(
                            children: const [
                              Icon(
                                Icons.brush,
                                color: Colors.cyanAccent,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Neon Glow Drawing & Shapes Active',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Export Overlay Indicator
                        if (_isExporting)
                          Container(
                            color: Colors.black87,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Color(0xFFE1306C),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _exportPhaseText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: _exportProgress,
                                      backgroundColor: Colors.white24,
                                      color: const Color(0xFFE1306C),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _handleCancelExport,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      child: const Text('Cancel Export'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Timeline Controls & Scrubber Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1A1A1A),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Playhead: ${_currentPos.inMilliseconds}ms / 7000ms',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'FPS: 30.0 | Sync Tol: ${_timelineController.syncToleranceMs.toStringAsFixed(1)}ms',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: (_currentPos.inMilliseconds / 7000.0).clamp(
                      0.0,
                      1.0,
                    ),
                    onChanged: (val) {
                      _timelineController.scrubToNormalized(val);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                        ),
                        iconSize: 40,
                        color: const Color(0xFFE1306C),
                        onPressed: () => _timelineController.togglePlayPause(),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.content_cut, size: 16),
                        label: const Text('Split Clip'),
                        onPressed: _handleSplit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset'),
                        onPressed: () =>
                            _timelineController.seekTo(Duration.zero),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
