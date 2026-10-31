package com.focusgram.storykit

import android.content.Context
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import androidx.annotation.NonNull
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.TransformationRequest
import androidx.media3.transformer.Transformer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.util.concurrent.ConcurrentHashMap

@UnstableApi
class FocusgramStoryKitPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var applicationContext: Context? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val activeTransformers = ConcurrentHashMap<String, Transformer>()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.focusgram.storykit/video_export")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        activeTransformers.values.forEach { it.cancel() }
        activeTransformers.clear()
        applicationContext = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "isHardwareSupported" -> handleIsHardwareSupported(result)
            "exportVideo" -> handleExportVideo(call, result)
            "cancelJob" -> handleCancelJob(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleIsHardwareSupported(result: Result) {
        try {
            val codecList = MediaCodecList(MediaCodecList.REGULAR_CODECS)
            var hasHardwareH264 = false
            for (info in codecList.codecInfos) {
                if (!info.isEncoder) continue
                for (type in info.supportedTypes) {
                    if (type.equals(MediaFormat.MIMETYPE_VIDEO_AVC, ignoreCase = true)) {
                        if (info.isHardwareAccelerated) {
                            hasHardwareH264 = true
                            break
                        }
                    }
                }
                if (hasHardwareH264) break
            }
            result.success(hasHardwareH264)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun handleExportVideo(call: MethodCall, result: Result) {
        val context = applicationContext ?: run {
            result.error("NO_CONTEXT", "Application context not available", null)
            return
        }

        val jobId = call.argument<String>("jobId") ?: run {
            result.error("INVALID_ARGS", "Missing jobId", null)
            return
        }

        val workingDirectory = call.argument<String>("workingDirectory") ?: run {
            result.error("INVALID_ARGS", "Missing workingDirectory", null)
            return
        }

        val width = call.argument<Int>("width") ?: 1080
        val height = call.argument<Int>("height") ?: 1920
        val videoBitrate = call.argument<Int>("videoBitrate") ?: 8000000
        val audioBitrate = call.argument<Int>("audioBitrate") ?: 128000
        val sampleRate = call.argument<Int>("sampleRate") ?: 44100

        val projectMap = call.argument<Map<String, Any>>("project") ?: run {
            result.error("INVALID_ARGS", "Missing project data", null)
            return
        }

        // Validate storage
        try {
            val stat = StatFs(workingDirectory)
            val availableBytes = stat.availableBlocksLong * stat.blockSizeLong
            val requiredBytes = 50L * 1024 * 1024 // 50MB minimal floor
            if (availableBytes < requiredBytes) {
                result.error("INSUFFICIENT_STORAGE", "Not enough disk space for export", null)
                return
            }
        } catch (_: Exception) {}

        val outputDir = File(workingDirectory)
        if (!outputDir.exists()) outputDir.mkdirs()
        val outputFile = File(outputDir, "story_export_$jobId.mp4")

        val pages = projectMap["pages"] as? List<Map<String, Any>> ?: emptyList()
        val editedMediaItems = mutableListOf<EditedMediaItem>()

        for (page in pages) {
            val isVideo = page["isVideoBackground"] as? Boolean ?: false
            val backgroundPath = page["backgroundPath"] as? String
            val durationMs = (page["durationMs"] as? Number)?.toLong() ?: 5000L

            if (isVideo && backgroundPath != null && File(backgroundPath).exists()) {
                val mediaItemBuilder = MediaItem.Builder().setUri(backgroundPath)
                val trimStartMs = (page["trimStartMs"] as? Number)?.toLong()
                val trimEndMs = (page["trimEndMs"] as? Number)?.toLong()

                if (trimStartMs != null && trimEndMs != null && trimEndMs > trimStartMs) {
                    mediaItemBuilder
                        .setClippingConfiguration(
                            MediaItem.ClippingConfiguration.Builder()
                                .setStartPositionMs(trimStartMs)
                                .setEndPositionMs(trimEndMs)
                                .build()
                        )
                }

                val muted = page["muted"] as? Boolean ?: false
                val editedItemBuilder = EditedMediaItem.Builder(mediaItemBuilder.build())
                    .setRemoveAudio(muted)

                editedMediaItems.add(editedItemBuilder.build())
            }
        }

        if (editedMediaItems.isEmpty()) {
            result.error("NO_MEDIA", "No valid video media items found in project", null)
            return
        }

        try {
            val sequence = EditedMediaItemSequence(editedMediaItems)
            val composition = Composition.Builder(sequence).build()

            val transformationRequest = TransformationRequest.Builder()
                .setVideoMimeType(MimeTypes.VIDEO_H264)
                .setAudioMimeType(MimeTypes.AUDIO_AAC)
                .build()

            var transformerRef: Transformer? = null

            val listener = object : Transformer.Listener {
                override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                    activeTransformers.remove(jobId)
                    mainHandler.post {
                        val durationMs = exportResult.durationMs
                        val fileSizeBytes = outputFile.length()
                        val resultMap = mapOf(
                            "jobId" to jobId,
                            "outputPath" to outputFile.absolutePath,
                            "durationMs" to (if (durationMs > 0) durationMs else 5000L),
                            "width" to width,
                            "height" to height,
                            "fileSizeBytes" to fileSizeBytes,
                            "format" to "mp4",
                            "videoCodec" to "h264",
                            "audioCodec" to "aac"
                        )
                        result.success(resultMap)
                    }
                }

                override fun onError(
                    composition: Composition,
                    exportResult: ExportResult,
                    exportException: ExportException
                ) {
                    activeTransformers.remove(jobId)
                    if (outputFile.exists()) outputFile.delete()
                    mainHandler.post {
                        result.error(
                            "RENDER_FAILED",
                            "Media3 Transformer export failed: ${exportException.message}",
                            exportException.errorCode
                        )
                    }
                }
            }

            val transformer = Transformer.Builder(context)
                .setTransformationRequest(transformationRequest)
                .addListener(listener)
                .build()

            activeTransformers[jobId] = transformer
            transformerRef = transformer
            transformer.start(composition, outputFile.absolutePath)
        } catch (e: Exception) {
            activeTransformers.remove(jobId)
            result.error("RENDER_FAILED", "Failed to start Media3 export: ${e.message}", null)
        }
    }

    private fun handleCancelJob(call: MethodCall, result: Result) {
        val jobId = call.argument<String>("jobId") ?: run {
            result.error("INVALID_ARGS", "Missing jobId", null)
            return
        }

        val transformer = activeTransformers.remove(jobId)
        if (transformer != null) {
            try {
                transformer.cancel()
            } catch (_: Exception) {}
        }
        result.success(null)
    }
}
