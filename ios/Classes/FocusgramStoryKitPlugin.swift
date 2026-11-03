import Flutter
import UIKit
import AVFoundation

private struct OverlayFrameDescriptor {
    let compositionTimeSec: Double
    let durationSec: Double
    let imagePath: String
}

private class ActiveExportSession {
    let jobId: String
    let session: AVAssetExportSession
    let outputURL: URL
    private let resultCallback: FlutterResult
    private var hasReplied = false
    private let lock = NSLock()

    var isCancelled: Bool = false
    var cancelCallback: FlutterResult?

    init(jobId: String, session: AVAssetExportSession, outputURL: URL, resultCallback: @escaping FlutterResult) {
        self.jobId = jobId
        self.session = session
        self.outputURL = outputURL
        self.resultCallback = resultCallback
    }

    func complete(result: Any?) {
        lock.lock()
        defer { lock.unlock() }
        guard !hasReplied else { return }
        hasReplied = true
        let cancelCb = self.cancelCallback
        DispatchQueue.main.async {
            self.resultCallback(result)
            cancelCb?(nil)
        }
    }
}

public class FocusgramStoryKitPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var activeSessions = [String: ActiveExportSession]()
    private let sessionsQueue = DispatchQueue(label: "com.focusgram.storykit.sessions")

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.focusgram.storykit/video_export", binaryMessenger: registrar.messenger())
        let instance = FocusgramStoryKitPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isHardwareSupported":
            handleIsHardwareSupported(result: result)
        case "exportVideo":
            handleExportVideo(call: call, result: result)
        case "cancelJob":
            handleCancelJob(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleIsHardwareSupported(result: @escaping FlutterResult) {
        let presets = AVAssetExportSession.allExportPresets()
        let hasH264 = presets.contains(AVAssetExportPreset1920x1080) || presets.contains(AVAssetExportPresetHighestQuality)
        result(hasH264)
    }

    private func handleExportVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let jobId = args["jobId"] as? String,
              let workingDirectory = args["workingDirectory"] as? String,
              let projectMap = args["project"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required export parameters", details: nil))
            return
        }

        var isAlreadyRunning = false
        sessionsQueue.sync {
            if self.activeSessions[jobId] != nil {
                isAlreadyRunning = true
            }
        }
        if isAlreadyRunning {
            result(FlutterError(code: "CONFLICT", message: "An export job with id '\(jobId)' is already running", details: nil))
            return
        }

        let width = args["width"] as? Int ?? 1080
        let height = args["height"] as? Int ?? 1920
        let sampleRate = args["sampleRate"] as? Int ?? 44100
        let requiredBytes = (args["requiredBytes"] as? NSNumber)?.int64Value ?? Int64(50 * 1024 * 1024)

        let outputDir = URL(fileURLWithPath: workingDirectory)

        // 1. Dynamic Storage Pre-Flight Inspection (P0)
        do {
            let values = try outputDir.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey])
            let availableBytes = values.volumeAvailableCapacityForImportantUsage ?? Int64(values.volumeAvailableCapacity ?? 0)
            if availableBytes > 0 && availableBytes < requiredBytes {
                result(FlutterError(
                    code: "INSUFFICIENT_STORAGE",
                    message: "Insufficient storage available on iOS device. Required: \(requiredBytes / (1024 * 1024))MB, Available: \(availableBytes / (1024 * 1024))MB",
                    details: ["requiredBytes": requiredBytes, "availableBytes": availableBytes]
                ))
                return
            }
        } catch {
            // Non-fatal volume capacity lookup fallback
        }

        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true, attributes: nil)
        let outputURL = outputDir.appendingPathComponent("story_export_\(jobId).mp4")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        let pages = projectMap["pages"] as? [[String: Any]] ?? []
        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            result(FlutterError(code: "COMPOSITION_FAILED", message: "Failed to initialize AVMutableComposition tracks", details: nil))
            return
        }

        var insertTime = CMTime.zero
        var hasValidMedia = false
        var allOverlayFrames = [OverlayFrameDescriptor]()
        var layerInstructions = [AVMutableVideoCompositionLayerInstruction]()
        var audioMixParameters = [AVMutableAudioMixInputParameters]()

        let baseVideoInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstructions.append(baseVideoInstruction)

        for page in pages {
            let isVideo = page["isVideoBackground"] as? Bool ?? false
            guard isVideo, let bgPath = page["backgroundPath"] as? String else { continue }
            let assetURL = URL(fileURLWithPath: bgPath)
            guard FileManager.default.fileExists(atPath: assetURL.path) else { continue }

            let asset = AVURLAsset(url: assetURL)
            guard let videoTrack = asset.tracks(withMediaType: .video).first else { continue }

            let duration = asset.duration
            var timeRange = CMTimeRange(start: .zero, duration: duration)

            if let trimStartMs = page["trimStartMs"] as? Double,
               let trimEndMs = page["trimEndMs"] as? Double,
               trimEndMs > trimStartMs {
                let start = CMTime(seconds: trimStartMs / 1000.0, preferredTimescale: 600)
                let dur = CMTime(seconds: (trimEndMs - trimStartMs) / 1000.0, preferredTimescale: 600)
                timeRange = CMTimeRange(start: start, duration: dur)
            }

            do {
                try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: insertTime)
                let muted = page["muted"] as? Bool ?? false
                if !muted, let audioTrack = asset.tracks(withMediaType: .audio).first {
                    try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: insertTime)
                    let audioParams = AVMutableAudioMixInputParameters(track: compositionAudioTrack)
                    let volume = (page["volume"] as? Double) ?? 1.0
                    audioParams.setVolume(Float(volume), at: insertTime)
                    audioMixParameters.append(audioParams)
                }

                // Collect overlay frames for this page relative to composition timeline
                let pageStartSec = CMTimeGetSeconds(insertTime)
                if let overlayFramesRaw = page["overlayFrames"] as? [[String: Any]] {
                    for f in overlayFramesRaw {
                        guard let p = f["path"] as? String, FileManager.default.fileExists(atPath: p) else { continue }
                        let tsMs = (f["timestampMs"] as? Double) ?? 0.0
                        let durMs = (f["durationMs"] as? Double) ?? 33.0
                        allOverlayFrames.append(
                            OverlayFrameDescriptor(
                                compositionTimeSec: pageStartSec + (tsMs / 1000.0),
                                durationSec: durMs / 1000.0,
                                imagePath: p
                            )
                        )
                    }
                }

                // Multi-track floating video elements (P1 Multi-track)
                if let videoElements = page["videoElements"] as? [[String: Any]] {
                    for vElem in videoElements {
                        guard let vPath = vElem["assetPath"] as? String,
                              FileManager.default.fileExists(atPath: vPath) else { continue }
                        let vAsset = AVURLAsset(url: URL(fileURLWithPath: vPath))
                        let vMuted = vElem["muted"] as? Bool ?? false
                        if !vMuted, let vAudioTrack = vAsset.tracks(withMediaType: .audio).first {
                            if let elemAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                                try? elemAudioTrack.insertTimeRange(timeRange, of: vAudioTrack, at: insertTime)
                                let elemAudioParams = AVMutableAudioMixInputParameters(track: elemAudioTrack)
                                let vVolume = (vElem["volume"] as? Double) ?? 1.0
                                elemAudioParams.setVolume(Float(vVolume), at: insertTime)
                                audioMixParameters.append(elemAudioParams)
                            }
                        }
                    }
                }

                insertTime = CMTimeAdd(insertTime, timeRange.duration)
                hasValidMedia = true
            } catch {
                result(FlutterError(code: "TRACK_INSERT_FAILED", message: "Failed to insert track: \(error.localizedDescription)", details: nil))
                return
            }
        }

        guard hasValidMedia else {
            result(FlutterError(code: "NO_MEDIA", message: "No valid video media tracks found", details: nil))
            return
        }

        let totalDurationSec = CMTimeGetSeconds(insertTime)

        // 2. Configure video composition with dimensions and frame rate
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: width, height: height)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: insertTime)
        instruction.layerInstructions = layerInstructions
        videoComposition.instructions = [instruction]

        // 3. P0 Animated Overlay Compositing via AVVideoCompositionCoreAnimationTool
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)

        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)

        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)

        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)

        if allOverlayFrames.count == 1 {
            // Static overlay optimization
            if let image = UIImage(contentsOfFile: allOverlayFrames[0].imagePath)?.cgImage {
                overlayLayer.contents = image
            }
        } else if allOverlayFrames.count > 1 && totalDurationSec > 0 {
            // Animated overlay keyframe sequence
            var cgImages = [CGImage]()
            var keyTimes = [NSNumber]()

            for frame in allOverlayFrames {
                if let image = UIImage(contentsOfFile: frame.imagePath)?.cgImage {
                    cgImages.append(image)
                    let normalizedTime = (frame.compositionTimeSec / totalDurationSec).clamped(to: 0.0...1.0)
                    keyTimes.append(NSNumber(value: normalizedTime))
                }
            }

            if !cgImages.isEmpty {
                // Ensure terminal boundary keyframe at 1.0
                if (keyTimes.last?.doubleValue ?? 0.0) < 1.0 {
                    cgImages.append(cgImages.last!)
                    keyTimes.append(NSNumber(value: 1.0))
                }

                let animation = CAKeyframeAnimation(keyPath: "contents")
                animation.values = cgImages
                animation.keyTimes = keyTimes
                animation.calculationMode = .discrete
                animation.duration = totalDurationSec
                animation.beginTime = AVCoreAnimationBeginTimeAtZero
                animation.isRemovedOnCompletion = false
                animation.fillMode = .forwards
                overlayLayer.add(animation, forKey: "contents")
            }
        }

        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            result(FlutterError(code: "EXPORT_SESSION_FAILED", message: "Unable to create AVAssetExportSession", details: nil))
            return
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        exportSession.shouldOptimizeForNetworkUse = true

        if !audioMixParameters.isEmpty {
            let audioMix = AVMutableAudioMix()
            audioMix.inputParameters = audioMixParameters
            exportSession.audioMix = audioMix
        }

        let activeJob = ActiveExportSession(
            jobId: jobId,
            session: exportSession,
            outputURL: outputURL,
            resultCallback: result
        )

        sessionsQueue.sync {
            self.activeSessions[jobId] = activeJob
        }

        exportSession.exportAsynchronously {
            self.sessionsQueue.sync {
                _ = self.activeSessions.removeValue(forKey: jobId)
            }

            switch exportSession.status {
            case .completed:
                if activeJob.isCancelled {
                    try? FileManager.default.removeItem(at: outputURL)
                    activeJob.complete(result: FlutterError(code: "CANCELLED", message: "Export cancelled by user", details: nil))
                } else {
                    let fileSize = (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int) ?? 0
                    let durationMs = Int(totalDurationSec * 1000.0)
                    let resultMap: [String: Any] = [
                        "jobId": jobId,
                        "outputPath": outputURL.path,
                        "durationMs": durationMs,
                        "width": width,
                        "height": height,
                        "fileSizeBytes": fileSize,
                        "format": "mp4",
                        "videoCodec": "h264",
                        "audioCodec": "aac",
                        "sampleRate": sampleRate
                    ]
                    activeJob.complete(result: resultMap)
                }
            case .cancelled:
                try? FileManager.default.removeItem(at: outputURL)
                activeJob.complete(result: FlutterError(code: "CANCELLED", message: "Export cancelled by user", details: nil))
            case .failed:
                try? FileManager.default.removeItem(at: outputURL)
                let errorMsg = exportSession.error?.localizedDescription ?? "Unknown AVAssetExportSession error"
                activeJob.complete(result: FlutterError(code: "RENDER_FAILED", message: errorMsg, details: nil))
            default:
                break
            }
        }
    }

    private func handleCancelJob(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let jobId = args["jobId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing jobId", details: nil))
            return
        }

        var targetSession: ActiveExportSession?
        sessionsQueue.sync {
            if let active = self.activeSessions[jobId] {
                active.isCancelled = true
                active.cancelCallback = result
                targetSession = active
            }
        }

        guard let active = targetSession else {
            result(nil)
            return
        }

        // Trigger native AVAssetExportSession cancellation.
        // The termination handler inside exportAsynchronously executes after AVFoundation terminates,
        // safely deleting the output file without file lock races, and delivering terminal callbacks.
        active.session.cancelExport()

        // Bounded watchdog timer: if AVAssetExportSession does not trigger its completion within 5 seconds,
        // force termination and clean up deterministically.
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            self.sessionsQueue.sync {
                if let stillActive = self.activeSessions.removeValue(forKey: jobId) {
                    if FileManager.default.fileExists(atPath: stillActive.outputURL.path) {
                        try? FileManager.default.removeItem(at: stillActive.outputURL)
                    }
                    stillActive.complete(result: FlutterError(code: "CANCELLED", message: "Export cancelled by user (timed termination)", details: nil))
                }
            }
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
