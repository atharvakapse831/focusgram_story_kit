import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/story_item_model.dart';
import '../models/story_project.dart';
import 'export_result.dart';
import 'still_image_exporter.dart';
import 'story_video_exporter.dart';
import 'video_export_adapter.dart';

/// Represents the exported media artifact for a single page in a story project.
@immutable
class StoryPageExportOutput {
  const StoryPageExportOutput({
    required this.pageId,
    required this.filePath,
    required this.mediaType,
    required this.duration,
    this.stillBytes,
    this.videoResult,
  });

  /// The unique page identifier.
  final String pageId;

  /// Absolute filesystem path to the rendered media artifact (PNG or MP4).
  final String filePath;

  /// Media type of this page (image or video).
  final StoryItemType mediaType;

  /// Playback or display duration for this page.
  final Duration duration;

  /// Raw raster bytes if this was a still image export.
  final Uint8List? stillBytes;

  /// Native video export metadata if this was a video export.
  final VideoExportResult? videoResult;

  /// Whether this exported slide is a video.
  bool get isVideo => mediaType == StoryItemType.video;
}

/// Unified export result for an entire [StoryProject].
@immutable
class StoryProjectExportResult {
  const StoryProjectExportResult({
    required this.projectId,
    required this.pageOutputs,
  });

  /// ID of the exported story project.
  final String projectId;

  /// Ordered list of exported page artifacts.
  final List<StoryPageExportOutput> pageOutputs;

  /// Convenience getter for the total number of exported pages.
  int get pageCount => pageOutputs.length;
}

/// Orchestrates export of multi-page, mixed-media [StoryProject]s.
///
/// Dispatches video pages to [StoryVideoExporter] for hardware-accelerated Media3/AVFoundation
/// encoding with animated overlay compositing, and still photo/canvas pages to [StoryStillImageExporter]
/// for deterministic off-screen rasterization.
class StoryProjectExporter {
  StoryProjectExporter({
    StoryVideoExporter? videoExporter,
    StoryStillImageExporter? stillImageExporter,
    Directory? outputDirectory,
  }) : _videoExporter = videoExporter ?? StoryVideoExporter(),
       _stillImageExporter =
           stillImageExporter ?? const StoryStillImageExporter(),
       _outputDir = outputDirectory;

  final StoryVideoExporter _videoExporter;
  final StoryStillImageExporter _stillImageExporter;
  final Directory? _outputDir;

  /// Renders all pages of [project] deterministically to their respective media formats.
  Future<StoryProjectExportResult> exportProject({
    required StoryProject project,
    StoryVideoExportConfig videoConfig = const StoryVideoExportConfig(),
    void Function(
      int pageIndex,
      int totalPages,
      double progress,
      String message,
    )?
    onProgress,
    bool Function()? checkCancelled,
  }) async {
    final baseDir = _outputDir ?? Directory.systemTemp;
    final exportDir = Directory(
      '${baseDir.path}/focusgram_story_${project.id}_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final outputs = <StoryPageExportOutput>[];
    final totalPages = project.pages.length;

    for (var i = 0; i < totalPages; i++) {
      if (checkCancelled?.call() == true) {
        throw Exception('Story export was cancelled by user.');
      }

      final page = project.pages[i];
      final isVideo = page.backgroundAsset?.isVideo == true;

      onProgress?.call(
        i,
        totalPages,
        i / totalPages,
        'Exporting page ${i + 1} of $totalPages (${isVideo ? "Video" : "Photo"})...',
      );

      if (isVideo) {
        // Build a single-page sub-project for the video exporter
        final subProject = StoryProject(
          id: '${project.id}_page_${page.id}',
          canvasSpec: project.canvasSpec,
          pages: [page],
        );

        final job = _videoExporter.startExport(
          project: subProject,
          config: videoConfig,
        );

        // Forward inner video export progress
        final progressSub = job.progressStream.listen((p) {
          final pageFraction = (i + p.progress) / totalPages;
          onProgress?.call(
            i,
            totalPages,
            pageFraction.clamp(0.0, 1.0),
            'Page ${i + 1}/$totalPages: ${p.message}',
          );
        });

        try {
          final videoResult = await job.result;
          outputs.add(
            StoryPageExportOutput(
              pageId: page.id,
              filePath: videoResult.outputPath,
              mediaType: StoryItemType.video,
              duration: videoResult.duration,
              videoResult: videoResult,
            ),
          );
        } finally {
          await progressSub.cancel();
        }
      } else {
        // Still photo or canvas page
        final stillResult = await _stillImageExporter.exportPage(
          page,
          project.canvasSpec,
          targetWidth: videoConfig.width,
          targetHeight: videoConfig.height,
        );

        final filePath = '${exportDir.path}/page_${i + 1}_${page.id}.png';
        final file = File(filePath);
        await file.writeAsBytes(stillResult.bytes, flush: true);

        outputs.add(
          StoryPageExportOutput(
            pageId: page.id,
            filePath: file.path,
            mediaType: StoryItemType.image,
            duration: page.duration,
            stillBytes: stillResult.bytes,
          ),
        );
      }
    }

    onProgress?.call(totalPages, totalPages, 1.0, 'Export complete!');

    return StoryProjectExportResult(
      projectId: project.id,
      pageOutputs: outputs,
    );
  }
}
