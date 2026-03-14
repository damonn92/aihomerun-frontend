import Foundation
import Vision
import AVFoundation
import os.log

private let poseLog = Logger(subsystem: "com.aihomerun.app", category: "PoseService")

// MARK: - Pose Detection Service

actor PoseDetectionService {

    enum PoseError: LocalizedError {
        case videoLoadFailed
        case noVideoTrack
        case cancelled

        var errorDescription: String? {
            switch self {
            case .videoLoadFailed: return "Failed to load video for pose analysis"
            case .noVideoTrack:   return "No video track found"
            case .cancelled:      return "Analysis was cancelled"
            }
        }
    }

    /// Whether the last analysis used mock data (simulator fallback)
    private(set) var usedMockData = false

    /// Analyze the video at the given URL, extracting body pose data at up to 30fps.
    /// Reports progress (0.0-1.0) via the callback.
    func analyzeVideo(
        url: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> VideoPoseData {
        poseDebugLog("[PoseService] analyzeVideo ENTERED for: \(url.lastPathComponent)")

        // Check disk cache first
        if let cached = await PoseDataCache.shared.cached(for: url) {
            poseDebugLog("[PoseService] Cache HIT — returning cached pose data (\(cached.totalFrames) frames)")
            usedMockData = false
            progress(1.0)
            return cached
        }
        poseDebugLog("[PoseService] Cache MISS — analyzing from scratch")

        let asset = AVAsset(url: url)

        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            poseDebugLog("[PoseService] ❌ No video track found!")
            throw PoseError.noVideoTrack
        }
        poseDebugLog("[PoseService] Found video track")

        let duration = try await asset.load(.duration).seconds
        guard duration.isFinite, duration > 0 else {
            poseDebugLog("[PoseService] ❌ Invalid duration: \(duration)")
            throw PoseError.videoLoadFailed
        }

        let nominalRate = try await track.load(.nominalFrameRate)
        let naturalSize = try await track.load(.naturalSize)
        let nativeRate = Double(nominalRate > 0 ? nominalRate : 30)

        // Cap extraction at 30fps for performance
        let effectiveRate = min(nativeRate, 30.0)
        let totalFrames = max(1, Int(duration * effectiveRate))
        poseDebugLog("[PoseService] Video: \(duration)s, \(nominalRate)fps, \(naturalSize), extracting \(totalFrames) frames at \(effectiveRate)fps")

        #if targetEnvironment(simulator)
        // iOS Simulator lacks CoreML model weights for VNDetectHumanBodyPoseRequest.
        // Generate synthetic batting pose data so the overlay UI can be tested.
        poseDebugLog("[PoseService] ⚠️ SIMULATOR detected — using synthetic pose data")
        usedMockData = true
        let result = generateMockPoseData(
            totalFrames: totalFrames,
            effectiveRate: effectiveRate,
            duration: duration,
            naturalSize: naturalSize,
            progress: progress
        )
        let detectedCount = result.frames.filter { $0.detected }.count
        poseDebugLog("[PoseService] Mock data generated: \(result.frames.count) frames, \(detectedCount) detected")
        return result
        #else
        usedMockData = false
        let visionResult = try await analyzeVideoWithVision(
            asset: asset,
            totalFrames: totalFrames,
            effectiveRate: effectiveRate,
            naturalSize: naturalSize,
            progress: progress
        )
        // Store in disk cache for future use
        await PoseDataCache.shared.store(visionResult, for: url)
        poseDebugLog("[PoseService] Cached analysis result for: \(url.lastPathComponent)")
        return visionResult
        #endif
    }

    // MARK: - Real Vision Analysis (Physical Device)

    private func analyzeVideoWithVision(
        asset: AVAsset,
        totalFrames: Int,
        effectiveRate: Double,
        naturalSize: CGSize,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> VideoPoseData {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 720, height: 720)

        var frames: [FramePose] = []
        frames.reserveCapacity(totalFrames)

        for i in 0..<totalFrames {
            try Task.checkCancellation()

            let timestamp = Double(i) / effectiveRate
            let cmTime = CMTime(seconds: timestamp, preferredTimescale: 600)

            var joints: [PoseJoint] = []
            var detected = false

            do {
                let cgImage = try generator.copyCGImage(at: cmTime, actualTime: nil)

                let request = VNDetectHumanBodyPoseRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])

                if let observation = request.results?.first {
                    detected = true
                    for jointName in JointName.allCases {
                        if let point = try? observation.recognizedPoint(jointName.visionKey) {
                            joints.append(PoseJoint(
                                name: jointName,
                                x: point.location.x,
                                y: 1.0 - point.location.y,
                                confidence: point.confidence
                            ))
                        }
                    }
                }
                if i == 0 || i == totalFrames - 1 {
                    poseDebugLog("[PoseService] Frame \(i): detected=\(detected), joints=\(joints.count)")
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                if i < 5 {
                    poseDebugLog("[PoseService] Frame \(i) error: \(error.localizedDescription)")
                }
            }

            frames.append(FramePose(
                id: i,
                timestamp: timestamp,
                joints: joints,
                detected: detected
            ))

            progress(Double(i + 1) / Double(totalFrames))
        }

        let detectedCount = frames.filter { $0.detected }.count
        poseDebugLog("[PoseService] Extraction complete: \(frames.count) frames, \(detectedCount) detected")

        return VideoPoseData(
            frameRate: effectiveRate,
            totalFrames: totalFrames,
            frames: frames,
            videoWidth: Int(naturalSize.width),
            videoHeight: Int(naturalSize.height)
        )
    }

    // MARK: - Mock Pose Data (Simulator Only)

    #if targetEnvironment(simulator)
    /// Generate synthetic batting pose data that animates through a swing motion.
    /// All coordinates are normalized 0-1, UIKit origin (top-left).
    private func generateMockPoseData(
        totalFrames: Int,
        effectiveRate: Double,
        duration: Double,
        naturalSize: CGSize,
        progress: @escaping @Sendable (Double) -> Void
    ) -> VideoPoseData {

        // Base batting stance — a right-handed batter in ready position
        // Coordinates: (x: 0-1 left-to-right, y: 0-1 top-to-bottom)
        struct JointBase { let name: JointName; let x: CGFloat; let y: CGFloat }

        let baseJoints: [JointBase] = [
            // Head
            JointBase(name: .nose,          x: 0.48, y: 0.17),
            JointBase(name: .leftEye,       x: 0.47, y: 0.15),
            JointBase(name: .rightEye,      x: 0.50, y: 0.15),
            JointBase(name: .leftEar,       x: 0.45, y: 0.16),
            JointBase(name: .rightEar,      x: 0.52, y: 0.16),
            // Neck & shoulders
            JointBase(name: .neck,          x: 0.48, y: 0.22),
            JointBase(name: .leftShoulder,  x: 0.41, y: 0.27),
            JointBase(name: .rightShoulder, x: 0.56, y: 0.27),
            // Arms — hands up near bat position
            JointBase(name: .leftElbow,     x: 0.35, y: 0.33),
            JointBase(name: .leftWrist,     x: 0.38, y: 0.23),
            JointBase(name: .rightElbow,    x: 0.60, y: 0.31),
            JointBase(name: .rightWrist,    x: 0.56, y: 0.22),
            // Torso
            JointBase(name: .root,          x: 0.48, y: 0.44),
            JointBase(name: .leftHip,       x: 0.44, y: 0.44),
            JointBase(name: .rightHip,      x: 0.53, y: 0.44),
            // Legs
            JointBase(name: .leftKnee,      x: 0.42, y: 0.58),
            JointBase(name: .rightKnee,     x: 0.55, y: 0.57),
            JointBase(name: .leftAnkle,     x: 0.40, y: 0.74),
            JointBase(name: .rightAnkle,    x: 0.57, y: 0.74),
        ]

        var frames: [FramePose] = []
        frames.reserveCapacity(totalFrames)

        for i in 0..<totalFrames {
            let timestamp = Double(i) / effectiveRate
            let phase = timestamp / duration  // 0..1 through the video

            // Simulate a swing: gradually rotate arms and torso over time
            // Phase 0.0-0.3: load (shift weight back)
            // Phase 0.3-0.6: swing (rotate torso + arms forward)
            // Phase 0.6-1.0: follow-through
            let swingAngle: CGFloat
            if phase < 0.3 {
                swingAngle = CGFloat(phase / 0.3) * (-0.03) // slight lean back
            } else if phase < 0.6 {
                let swingPhase = (phase - 0.3) / 0.3
                swingAngle = -0.03 + CGFloat(swingPhase) * 0.12 // swing forward
            } else {
                let followPhase = (phase - 0.6) / 0.4
                swingAngle = 0.09 + CGFloat(followPhase) * 0.04 // follow-through
            }

            // Add subtle body sway
            let sway = CGFloat(sin(phase * .pi * 4)) * 0.005

            var joints: [PoseJoint] = []
            for base in baseJoints {
                // Apply swing rotation around the root (hips)
                let rootX: CGFloat = 0.48
                let rootY: CGFloat = 0.44
                let dx = base.x - rootX
                let dy = base.y - rootY

                // Only rotate upper body joints (above root)
                let rotatedX: CGFloat
                let rotatedY: CGFloat
                if base.y < rootY || base.name == .root {
                    // Upper body: rotate around root
                    let cos_a = cos(swingAngle)
                    let sin_a = sin(swingAngle)
                    rotatedX = rootX + dx * cos_a - dy * sin_a + sway
                    rotatedY = rootY + dx * sin_a + dy * cos_a
                } else {
                    // Lower body: just add sway
                    rotatedX = base.x + sway * 0.3
                    rotatedY = base.y
                }

                joints.append(PoseJoint(
                    name: base.name,
                    x: max(0, min(1, rotatedX)),
                    y: max(0, min(1, rotatedY)),
                    confidence: 0.95
                ))
            }

            frames.append(FramePose(
                id: i,
                timestamp: timestamp,
                joints: joints,
                detected: true
            ))

            progress(Double(i + 1) / Double(totalFrames))
        }

        return VideoPoseData(
            frameRate: effectiveRate,
            totalFrames: totalFrames,
            frames: frames,
            videoWidth: Int(naturalSize.width),
            videoHeight: Int(naturalSize.height)
        )
    }
    #endif
}
