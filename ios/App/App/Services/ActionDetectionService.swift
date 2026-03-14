import Foundation
import AVFoundation
import Vision
import os.log

private let detectLog = Logger(subsystem: "com.aihomerun.app", category: "ActionDetect")

// MARK: - Action Detection Service

/// Detects the peak action moment (swing/pitch) in a video using wrist velocity heuristics.
/// Runs VNDetectHumanBodyPoseRequest at low frame rate (~5fps) for speed.
actor ActionDetectionService {

    // MARK: - Types

    struct DetectionResult: Sendable {
        let peakTime: Double                   // Peak action timestamp (seconds)
        let confidence: Double                 // 0-1 based on velocity prominence
        let trimRange: ClosedRange<Double>     // Suggested trim window
        let wristVelocities: [Double]          // Per-scan-frame velocities (normalized)
        let scanTimestamps: [Double]           // Timestamps for each velocity entry
        let videoDuration: Double
    }

    enum DetectionError: LocalizedError {
        case videoLoadFailed
        case noVideoTrack
        case tooShort
        case cancelled

        var errorDescription: String? {
            switch self {
            case .videoLoadFailed: return "Failed to load video for detection"
            case .noVideoTrack:   return "No video track found"
            case .tooShort:       return "Video too short for action detection"
            case .cancelled:      return "Detection was cancelled"
            }
        }
    }

    // MARK: - Configuration

    private let scanFPS: Double = 5.0          // Low frame rate for speed
    private let trimBefore: Double = 2.0       // Seconds before peak to include
    private let trimAfter: Double = 1.5        // Seconds after peak to include
    private let minConfidence: Double = 0.3    // Below this → "no action detected"
    private let minVideoDuration: Double = 3.0 // Skip detection for short videos
    private let minJointConfidence: Float = 0.3

    // MARK: - Detect Action

    /// Scan video at low FPS to find the peak action moment.
    /// Returns nil if no clear action is detected.
    func detectAction(
        videoURL: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> DetectionResult? {
        detectLog.info("detectAction ENTERED for: \(videoURL.lastPathComponent)")

        let asset = AVAsset(url: videoURL)

        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            detectLog.error("No video track found")
            throw DetectionError.noVideoTrack
        }

        let duration = try await asset.load(.duration).seconds
        guard duration.isFinite, duration > 0 else {
            throw DetectionError.videoLoadFailed
        }

        // Skip detection for very short videos
        if duration < minVideoDuration {
            detectLog.info("Video too short (\(duration)s) — skipping detection")
            return nil
        }

        let totalScanFrames = max(2, Int(duration * scanFPS))
        detectLog.info("Scanning \(totalScanFrames) frames at \(self.scanFPS)fps over \(duration)s")

        #if targetEnvironment(simulator)
        // Mock detection on simulator
        detectLog.info("SIMULATOR — generating mock detection")
        return generateMockDetection(duration: duration, totalScanFrames: totalScanFrames, progress: progress)
        #else
        return try await scanWithVision(
            asset: asset,
            duration: duration,
            totalScanFrames: totalScanFrames,
            progress: progress
        )
        #endif
    }

    // MARK: - Vision Scan (Device)

    private func scanWithVision(
        asset: AVAsset,
        duration: Double,
        totalScanFrames: Int,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> DetectionResult? {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 480) // Low-res for speed

        // Track wrist positions per frame
        var lwX: [Double?] = []
        var lwY: [Double?] = []
        var rwX: [Double?] = []
        var rwY: [Double?] = []
        var timestamps: [Double] = []

        for i in 0..<totalScanFrames {
            try Task.checkCancellation()

            let timestamp = Double(i) / scanFPS
            let cmTime = CMTime(seconds: timestamp, preferredTimescale: 600)
            timestamps.append(timestamp)

            do {
                let cgImage = try generator.copyCGImage(at: cmTime, actualTime: nil)
                let request = VNDetectHumanBodyPoseRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])

                if let obs = request.results?.first {
                    let lw = try? obs.recognizedPoint(.leftWrist)
                    let rw = try? obs.recognizedPoint(.rightWrist)

                    if let lw, lw.confidence >= minJointConfidence {
                        lwX.append(Double(lw.location.x))
                        lwY.append(Double(lw.location.y))
                    } else {
                        lwX.append(nil); lwY.append(nil)
                    }

                    if let rw, rw.confidence >= minJointConfidence {
                        rwX.append(Double(rw.location.x))
                        rwY.append(Double(rw.location.y))
                    } else {
                        rwX.append(nil); rwY.append(nil)
                    }
                } else {
                    lwX.append(nil); lwY.append(nil)
                    rwX.append(nil); rwY.append(nil)
                }
            } catch is CancellationError {
                throw DetectionError.cancelled
            } catch {
                lwX.append(nil); lwY.append(nil)
                rwX.append(nil); rwY.append(nil)
                if i < 3 { detectLog.warning("Frame \(i) scan error: \(error.localizedDescription)") }
            }

            progress(Double(i + 1) / Double(totalScanFrames))
        }

        return buildDetectionFromPositions(
            leftWristX: lwX, leftWristY: lwY,
            rightWristX: rwX, rightWristY: rwY,
            timestamps: timestamps, duration: duration
        )
    }

    // MARK: - Core Analysis

    /// Compute velocities and find peak.
    private func computeDetection(
        velocities: [Double],
        timestamps: [Double],
        duration: Double
    ) -> DetectionResult? {
        guard velocities.count >= 3 else { return nil }

        // Find peak velocity
        var peakIdx = 0
        var peakVel: Double = 0
        for (i, v) in velocities.enumerated() {
            if v > peakVel {
                peakVel = v
                peakIdx = i
            }
        }

        // Compute mean and stddev (excluding zeros)
        let nonZero = velocities.filter { $0 > 0.001 }
        guard !nonZero.isEmpty else { return nil }
        let mean = nonZero.reduce(0, +) / Double(nonZero.count)
        let variance = nonZero.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(nonZero.count)
        let stddev = sqrt(variance)

        // Confidence: how prominent is the peak above the noise?
        let confidence: Double
        if mean > 0.001 {
            confidence = min(1.0, max(0, (peakVel - mean) / max(stddev * 2, mean)))
        } else {
            confidence = 0
        }

        detectLog.info("Peak at idx=\(peakIdx), vel=\(peakVel), mean=\(mean), conf=\(confidence)")

        guard confidence >= minConfidence else {
            detectLog.info("Confidence \(confidence) below threshold — no action detected")
            return nil
        }

        let peakTime = peakIdx < timestamps.count ? timestamps[peakIdx] : duration * 0.5
        let trimStart = max(0, peakTime - trimBefore)
        let trimEnd = min(duration, peakTime + trimAfter)

        // Normalize velocities for visualization (0-1)
        let maxVel = velocities.max() ?? 1
        let normalizedVelocities = velocities.map { maxVel > 0 ? $0 / maxVel : 0 }

        return DetectionResult(
            peakTime: peakTime,
            confidence: confidence,
            trimRange: trimStart...trimEnd,
            wristVelocities: normalizedVelocities,
            scanTimestamps: timestamps,
            videoDuration: duration
        )
    }

    // MARK: - Video Trimming

    /// Export a trimmed copy of the video using AVAssetExportSession.
    func trimVideo(
        sourceURL: URL,
        range: ClosedRange<Double>
    ) async throws -> URL {
        detectLog.info("Trimming video: \(range.lowerBound)s — \(range.upperBound)s")

        let asset = AVAsset(url: sourceURL)
        let duration = try await asset.load(.duration).seconds

        let startTime = CMTime(seconds: max(0, range.lowerBound), preferredTimescale: 600)
        let endTime = CMTime(seconds: min(duration, range.upperBound), preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startTime, end: endTime)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw DetectionError.videoLoadFailed
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("trimmed_\(UUID().uuidString)")
            .appendingPathExtension("mov")

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.timeRange = timeRange

        await exportSession.export()

        guard exportSession.status == .completed else {
            let errMsg = exportSession.error?.localizedDescription ?? "Unknown export error"
            detectLog.error("Trim export failed: \(errMsg)")
            throw DetectionError.videoLoadFailed
        }

        let trimmedDuration = range.upperBound - range.lowerBound
        detectLog.info("Trim complete: \(outputURL.lastPathComponent) (\(trimmedDuration)s)")
        return outputURL
    }

    // MARK: - Mock (Simulator)

    #if targetEnvironment(simulator)
    private func generateMockDetection(
        duration: Double,
        totalScanFrames: Int,
        progress: @escaping @Sendable (Double) -> Void
    ) -> DetectionResult {
        // Simulate detection: peak at 40% of video duration
        let peakTime = duration * 0.4
        var velocities: [Double] = []
        var timestamps: [Double] = []

        for i in 0..<totalScanFrames {
            let t = Double(i) / scanFPS
            timestamps.append(t)

            // Gaussian-like velocity profile centered at peakTime
            let dist = abs(t - peakTime)
            let sigma = 0.5
            let vel = exp(-dist * dist / (2 * sigma * sigma))
            // Add noise
            let noise = Double.random(in: 0...0.08)
            velocities.append(vel + noise)

            progress(Double(i + 1) / Double(totalScanFrames))
        }

        let trimStart = max(0, peakTime - trimBefore)
        let trimEnd = min(duration, peakTime + trimAfter)

        return DetectionResult(
            peakTime: peakTime,
            confidence: 0.85,
            trimRange: trimStart...trimEnd,
            wristVelocities: velocities,
            scanTimestamps: timestamps,
            videoDuration: duration
        )
    }
    #endif
}

// MARK: - Internal helpers

extension ActionDetectionService {

    /// Compute per-frame wrist velocities from raw wrist positions extracted by Vision scan.
    /// This is the real device code path.
    func buildDetectionFromPositions(
        leftWristX: [Double?], leftWristY: [Double?],
        rightWristX: [Double?], rightWristY: [Double?],
        timestamps: [Double],
        duration: Double
    ) -> DetectionResult? {
        guard timestamps.count >= 3 else { return nil }

        var velocities: [Double] = [0] // first frame has no prior

        for i in 1..<timestamps.count {
            let dt = timestamps[i] - timestamps[i - 1]
            guard dt > 0 else { velocities.append(0); continue }

            var maxVel: Double = 0

            // Left wrist velocity
            if let lx0 = leftWristX[i - 1], let ly0 = leftWristY[i - 1],
               let lx1 = leftWristX[i], let ly1 = leftWristY[i] {
                let dx = lx1 - lx0
                let dy = ly1 - ly0
                let vel = sqrt(dx * dx + dy * dy) / dt
                maxVel = max(maxVel, vel)
            }

            // Right wrist velocity
            if let rx0 = rightWristX[i - 1], let ry0 = rightWristY[i - 1],
               let rx1 = rightWristX[i], let ry1 = rightWristY[i] {
                let dx = rx1 - rx0
                let dy = ry1 - ry0
                let vel = sqrt(dx * dx + dy * dy) / dt
                maxVel = max(maxVel, vel)
            }

            velocities.append(maxVel)
        }

        return computeDetection(velocities: velocities, timestamps: timestamps, duration: duration)
    }
}
