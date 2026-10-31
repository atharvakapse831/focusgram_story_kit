package com.focusgram.storykit

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import androidx.annotation.NonNull
import androidx.media3.common.Effect
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.OverlayEffect
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.TransformationRequest
import androidx.media3.transformer.Transformer
import com.google.common.collect.ImmutableList
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference

/**
 * Metadata for a single rasterized overlay frame.
 */
data class OverlayFrameInfo(
    val timestampMs: Long,
    val durationMs: Long,
    val path: String
)

/**
 * Timestamp-driven animated bitmap overlay backed by Media3's [BitmapOverlay].
 *
 * Samples the rasterized frame sequence according to the exact presentation timestamp
 * and manages an in-memory LRU cache to prevent memory spikes.
 */
@UnstableApi
class TimestampBitmapOverlay(
    private val frames: List<OverlayFrameInfo>,
    private val maxCacheSize: Int = 12
) : BitmapOverlay() {
    private val lruCache = object : LinkedHashMap<String, Bitmap>(maxCacheSize, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Bitmap>?): Boolean {
            return size > maxCacheSize
        }
    }

    override fun getBitmap(presentationTimeUs: Long): Bitmap {
        val presentationTimeMs = presentationTimeUs / 1000L
        val frame = findFrame(presentationTimeMs)
        return getOrLoadBitmap(frame.path)
    }

    private fun findFrame(timeMs: Long): OverlayFrameInfo {
        if (frames.isEmpty()) {
            throw IllegalStateException("No overlay frames registered for presentation")
        }
        var candidate = frames[0]
        for (f in frames) {
            if (f.timestampMs <= timeMs) {
                candidate = f
            } else {
                break
            }
        }
        return candidate
    }

    private fun getOrLoadBitmap(path: String): Bitmap {
        synchronized(lruCache) {
            lruCache[path]?.let { return it }
            val bitmap = BitmapFactory.decodeFile(path)
                ?: throw IllegalStateException("Failed to decode overlay bitmap frame: $path")
            lruCache[path] = bitmap
            return bitmap
        }
    }

    fun release() {
        synchronized(lruCache) {
            lruCache.clear()
        }
    }
}

/**
 * Context container tracking an active export job and its cancellation lifecycle state machine.
 */
@UnstableApi
private class ExportJobContext(
    val jobId: String,
    val transformer: Transformer,
    val outputFile: File,
    val workingDirectory: File,
    val exportResultCallback: Result,
    val overlays: List<TimestampBitmapOverlay>
) {
    val state = AtomicInteger(STATE_RUNNING)
    val cancelResultCallback = AtomicReference<Result?>(null)

    companion object {
        const val STATE_RUNNING = 1
        const val STATE_CANCELLING = 2
        const val STATE_CANCELLED = 3
        const val STATE_COMPLETED = 4
        const val STATE_FAILED = 5
    }
}

@UnstableApi
class FocusgramStoryKitPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var applicationContext: Context? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val activeJobs = ConcurrentHashMap<String, ExportJobContext>()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.focusgram.storykit/video_export")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        activeJobs.values.forEach { job ->
            try {
                job.transformer.cancel()
                job.overlays.forEach { it.release() }
            } catch (_: Exception) {}
        }
        activeJobs.clear()
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
        val requiredBytes = (call.argument<Number>("requiredBytes"))?.toLong() ?: (50L * 1024 * 1024)

        val projectMap = call.argument<Map<String, Any>>("project") ?: run {
            result.error("INVALID_ARGS", "Missing project data", null)
            return
        }

        // 1. Dynamic Storage Pre-Flight Inspection (P0)
        try {
            val stat = StatFs(workingDirectory)
            val availableBytes = stat.availableBlocksLong * stat.blockSizeLong
            if (availableBytes < requiredBytes) {
                result.error(
                    "INSUFFICIENT_STORAGE",
                    "Insufficient storage available on Android device. Required: ${requiredBytes / (1024 * 1024)}MB, Available: ${availableBytes / (1024 * 1024)}MB",
                    mapOf("requiredBytes" to requiredBytes, "availableBytes" to availableBytes)
                )
                return
            }
        } catch (_: Exception) {}

        val outputDir = File(workingDirectory)
        if (!outputDir.exists()) outputDir.mkdirs()
        val outputFile = File(outputDir, "story_export_$jobId.mp4")

        val pages = projectMap["pages"] as? List<Map<String, Any>> ?: emptyList()
        val editedMediaItems = mutableListOf<EditedMediaItem>()
        val secondaryAudioSequences = mutableListOf<EditedMediaItemSequence>()
        val activeOverlays = mutableListOf<TimestampBitmapOverlay>()

        // 2. Build multi-page and multi-track composition with overlay effects
        for (page in pages) {
            val isVideo = page["isVideoBackground"] as? Boolean ?: false
            val backgroundPath = page["backgroundPath"] as? String
            val durationMs = (page["durationMs"] as? Number)?.toLong() ?: 5000L

            // Parse overlay frames for this page (P0 Animated Overlay Compositing)
            val overlayFramesRaw = page["overlayFrames"] as? List<Map<String, Any>> ?: emptyList()
            val overlayFrames = overlayFramesRaw.mapNotNull { f ->
                val path = f["path"] as? String
                val ts = (f["timestampMs"] as? Number)?.toLong() ?: 0L
                val dur = (f["durationMs"] as? Number)?.toLong() ?: 33L
                if (path != null && File(path).exists()) {
                    OverlayFrameInfo(timestampMs = ts, durationMs = dur, path = path)
                } else null
            }

            val effectsList = ArrayList<Effect>()
            if (overlayFrames.isNotEmpty()) {
                val timestampOverlay = TimestampBitmapOverlay(overlayFrames)
                activeOverlays.add(timestampOverlay)
                effectsList.add(OverlayEffect(ImmutableList.of(timestampOverlay)))
            }

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
                val effects = Effects(/* audioProcessors = */ emptyList(), /* videoEffects = */ effectsList)
                val editedItemBuilder = EditedMediaItem.Builder(mediaItemBuilder.build())
                    .setRemoveAudio(muted)
                    .setEffects(effects)

                editedMediaItems.add(editedItemBuilder.build())
            }

            // Multi-track audio from floating video elements (P1 Multi-track)
            val videoElements = page["videoElements"] as? List<Map<String, Any>> ?: emptyList()
            for (vElem in videoElements) {
                val vAssetPath = vElem["assetPath"] as? String
                val vMuted = vElem["muted"] as? Boolean ?: false
                if (!vMuted && vAssetPath != null && File(vAssetPath).exists()) {
                    val elemMediaItemBuilder = MediaItem.Builder().setUri(vAssetPath)
                    val vTrimStart = (vElem["trimStartMs"] as? Number)?.toLong()
                    val vTrimEnd = (vElem["trimEndMs"] as? Number)?.toLong()
                    if (vTrimStart != null && vTrimEnd != null && vTrimEnd > vTrimStart) {
                        elemMediaItemBuilder.setClippingConfiguration(
                            MediaItem.ClippingConfiguration.Builder()
                                .setStartPositionMs(vTrimStart)
                                .setEndPositionMs(vTrimEnd)
                                .build()
                        )
                    }
                    val audioItem = EditedMediaItem.Builder(elemMediaItemBuilder.build())
                        .setRemoveVideo(true)
                        .build()
                    secondaryAudioSequences.add(EditedMediaItemSequence(listOf(audioItem)))
                }
            }
        }

        if (editedMediaItems.isEmpty()) {
            activeOverlays.forEach { it.release() }
            result.error("NO_MEDIA", "No valid video media items found in project", null)
            return
        }

        try {
            val allSequences = mutableListOf<EditedMediaItemSequence>()
            allSequences.add(EditedMediaItemSequence(editedMediaItems))
            allSequences.addAll(secondaryAudioSequences)

            val composition = Composition.Builder(allSequences).build()

            val transformationRequest = TransformationRequest.Builder()
                .setVideoMimeType(MimeTypes.VIDEO_H264)
                .setAudioMimeType(MimeTypes.AUDIO_AAC)
                .build()

            val listener = object : Transformer.Listener {
                override fun onCompleted(comp: Composition, exportResult: ExportResult) {
                    val job = activeJobs.remove(jobId) ?: return
                    if (job.state.compareAndSet(ExportJobContext.STATE_RUNNING, ExportJobContext.STATE_COMPLETED)) {
                        job.overlays.forEach { it.release() }
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
                                "audioCodec" to "aac",
                                "sampleRate" to sampleRate
                            )
                            job.exportResultCallback.success(resultMap)
                        }
                    }
                }

                override fun onError(
                    comp: Composition,
                    exportResult: ExportResult,
                    exportException: ExportException
                ) {
                    val job = activeJobs.remove(jobId) ?: return
                    if (job.state.compareAndSet(ExportJobContext.STATE_RUNNING, ExportJobContext.STATE_FAILED)) {
                        job.overlays.forEach { it.release() }
                        if (job.outputFile.exists()) job.outputFile.delete()
                        mainHandler.post {
                            job.exportResultCallback.error(
                                "RENDER_FAILED",
                                "Media3 Transformer export failed: ${exportException.message}",
                                exportException.errorCode
                            )
                        }
                    }
                }
            }

            val transformer = Transformer.Builder(context)
                .setTransformationRequest(transformationRequest)
                .addListener(listener)
                .build()

            val jobContext = ExportJobContext(
                jobId = jobId,
                transformer = transformer,
                outputFile = outputFile,
                workingDirectory = outputDir,
                exportResultCallback = result,
                overlays = activeOverlays
            )

            activeJobs[jobId] = jobContext
            transformer.start(composition, outputFile.absolutePath)
        } catch (e: Exception) {
            activeOverlays.forEach { it.release() }
            activeJobs.remove(jobId)
            result.error("RENDER_FAILED", "Failed to start Media3 export: ${e.message}", null)
        }
    }

    private fun handleCancelJob(call: MethodCall, result: Result) {
        val jobId = call.argument<String>("jobId") ?: run {
            result.error("INVALID_ARGS", "Missing jobId", null)
            return
        }

        val job = activeJobs[jobId] ?: run {
            result.success(null)
            return
        }

        // P0 Cancellation State Machine: explicit native termination acknowledgement
        if (job.state.compareAndSet(ExportJobContext.STATE_RUNNING, ExportJobContext.STATE_CANCELLING)) {
            job.cancelResultCallback.set(result)
            Thread {
                try {
                    job.transformer.cancel()
                } catch (_: Exception) {}

                // Explicit native termination acknowledgement: wait until Media3 reports NOT_STARTED
                val progressHolder = ProgressHolder()
                var pollCycles = 0
                val maxCycles = 100
                while (job.transformer.getProgress(progressHolder) != Transformer.PROGRESS_STATE_NOT_STARTED && pollCycles < maxCycles) {
                    try {
                        Thread.sleep(10)
                    } catch (_: InterruptedException) {}
                    pollCycles++
                }

                // Release all cached overlay bitmaps from memory
                job.overlays.forEach { it.release() }

                // Explicit verification that native file handles are released before deleting files
                if (job.outputFile.exists()) {
                    var fileReleased = false
                    var fileCycles = 0
                    while (!fileReleased && fileCycles < maxCycles) {
                        try {
                            java.io.RandomAccessFile(job.outputFile, "rw").use { raf ->
                                val lock = raf.channel.tryLock()
                                if (lock != null) {
                                    lock.release()
                                    fileReleased = true
                                }
                            }
                        } catch (_: Exception) {
                            try {
                                Thread.sleep(10)
                            } catch (_: InterruptedException) {}
                        }
                        fileCycles++
                    }

                    try {
                        job.outputFile.delete()
                    } catch (_: Exception) {}
                }

                job.state.set(ExportJobContext.STATE_CANCELLED)
                activeJobs.remove(jobId)

                mainHandler.post {
                    try {
                        job.exportResultCallback.error(
                            "CANCELLED",
                            "Export job was cancelled by user.",
                            null
                        )
                    } catch (_: Exception) {}
                    result.success(null)
                }
            }.start()
        } else {
            result.success(null)
        }
    }
}
