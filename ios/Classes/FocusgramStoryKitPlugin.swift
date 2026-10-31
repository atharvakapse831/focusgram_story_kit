import Flutter
import UIKit
import AVFoundation

public class FocusgramStoryKitPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var activeSessions = [String: AVAssetExportSession]()
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
        // All iOS devices running iOS 13+ support hardware H.264/HEVC encoding via VideoToolbox
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

        let width = args["width"] as? Int ?? 1080
        let height = args["height"] as? Int ?? 1920
        let sampleRate = args["sampleRate"] as? Int ?? 44100

        let outputDir = URL(fileURLWithPath: workingDirectory)
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

        // Configure video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: width, height: height)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: insertTime)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            result(FlutterError(code: "EXPORT_SESSION_FAILED", message: "Unable to create AVAssetExportSession", details: nil))
            return
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        exportSession.shouldOptimizeForNetworkUse = true

        sessionsQueue.sync {
            self.activeSessions[jobId] = exportSession
        }

        exportSession.exportAsynchronously {
            self.sessionsQueue.sync {
                _ = self.activeSessions.removeValue(forKey: jobId)
            }

            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    let fileSize = (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int) ?? 0
                    let durationMs = Int(CMTimeGetSeconds(insertTime) * 1000.0)
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
                    result(resultMap)
                case .cancelled:
                    try? FileManager.default.removeItem(at: outputURL)
                    result(FlutterError(code: "CANCELLED", message: "Export cancelled by user", details: nil))
                case .failed:
                    try? FileManager.default.removeItem(at: outputURL)
                    let errorMsg = exportSession.error?.localizedDescription ?? "Unknown AVAssetExportSession error"
                    result(FlutterError(code: "RENDER_FAILED", message: errorMsg, details: nil))
                default:
                    break
                }
            }
        }
    }

    private func handleCancelJob(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let jobId = args["jobId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing jobId", details: nil))
            return
        }

        sessionsQueue.sync {
            if let session = self.activeSessions.removeValue(forKey: jobId) {
                session.cancelExport()
            }
        }
        result(nil)
    }
}
