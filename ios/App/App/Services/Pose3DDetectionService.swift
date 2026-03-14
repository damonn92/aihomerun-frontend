import Foundation
import Vision
import AVFoundation
import os.log

private let pose3DLog = Logger(subsystem: "com.aihomerun.app", category: "Pose3D")

// MARK: - 3D Pose Detection Service

/// Detects 3D human body pose from video using VNDetectHumanBodyPose3DRequest (iOS 17+).
/// Falls back gracefully — callers should check @available before using.
@available(iOS 17, *)
actor Pose3DDetectionService {

    enum Pose3DError: LocalizedError {
        case videoLoadFailed
        case noVideoTrack
        case cancelled
        case unsupported

        var errorDescription: String? {
            switch self {
            case .videoLoadFailed: return "Failed to load video for 3D pose analysis"
            case .noVideoTrack:   return "No video track found"
            case .cancelled:      return "3D analysis was cancelled"
            case .unsupported:    return "3D pose detection not supported on this device"
            }
        }
    }

    // MARK: - Configuration

    /// Lower frame rate than 2D to keep performance reasonable
    private let extractionFPS: Double = 15.0
    private let minJointConfidence: Float = 0.1

    // MARK: - Analyze

    /// Analyze the video for 3D body poses. Reports progress (0.0-1.0) via callback.
    func analyzeVideo3D(
        url: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> VideoPose3DData {
        pose3DLog.info("analyzeVideo3D ENTERED for: \(url.lastPathComponent)")

        // Check 3D disk cache
        if let cached = await PoseDataCache.shared.cached3D(for: url) {
            pose3DLog.info("3D cache HIT — returning cached data (\(cached.totalFrames) frames)")
            progress(1.0)
            return cached
        }

        let asset = AVAsset(url: url)

        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw Pose3DError.noVideoTrack
        }

        let duration = try await asset.load(.duration).seconds
        guard duration.isFinite, duration > 0 else {
            throw Pose3DError.videoLoadFailed
        }

        let naturalSize = try await track.load(.naturalSize)
        let totalFrames = max(1, Int(duration * extractionFPS))
        pose3DLog.info("3D Scan: \(totalFrames) frames at \(self.extractionFPS)fps over \(duration)s")

        #if targetEnvironment(simulator)
        pose3DLog.info("SIMULATOR — generating mock 3D pose data")
        let mockResult = generateMock3DData(
            totalFrames: totalFrames,
            duration: duration,
            naturalSize: naturalSize,
            progress: progress
        )
        return mockResult
        #else
        let result = try await analyzeWithVision3D(
            asset: asset,
            totalFrames: totalFrames,
            duration: duration,
            naturalSize: naturalSize,
            progress: progress
        )
        // Cache result
        await PoseDataCache.shared.store3D(result, for: url)
        pose3DLog.info("3D analysis complete and cached: \(result.totalFrames) frames")
        return result
        #endif
    }

    // MARK: - Real 3D Vision Analysis (Device)

    private func analyzeWithVision3D(
        asset: AVAsset,
        totalFrames: Int,
        duration: Double,
        naturalSize: CGSize,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> VideoPose3DData {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.05, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: 600)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 720, height: 720)

        var frames: [FramePose3D] = []
        frames.reserveCapacity(totalFrames)

        // Joint names that have 3D counterparts
        let jointNames3D = JointName.allCases.filter { $0.vision3DKey != nil }

        for i in 0..<totalFrames {
            try Task.checkCancellation()

            let timestamp = Double(i) / extractionFPS
            let cmTime = CMTime(seconds: timestamp, preferredTimescale: 600)

            var joints: [Pose3DJoint] = []
            var detected = false
            var bodyHeight: Float?

            do {
                let cgImage = try generator.copyCGImage(at: cmTime, actualTime: nil)

                let request = VNDetectHumanBodyPose3DRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])

                if let observation = request.results?.first {
                    detected = true
                    bodyHeight = observation.bodyHeight

                    for jointName in jointNames3D {
                        guard let visionKey = jointName.vision3DKey else { continue }
                        if let point = try? observation.recognizedPoint(visionKey) {
                            // Extract position from simd_float4x4 local transform
                            let transform = point.localPosition
                            let x = transform.columns.3.x
                            let y = transform.columns.3.y
                            let z = transform.columns.3.z

                            joints.append(Pose3DJoint(
                                name: jointName,
                                x: x,
                                y: y,
                                z: z,
                                confidence: 1.0  // 3D points don't expose per-joint confidence; if recognized, treat as high
                            ))
                        }
                    }
                }

                if i == 0 {
                    pose3DLog.info("Frame 0: detected=\(detected), 3D joints=\(joints.count), height=\(bodyHeight ?? -1)")
                }
            } catch is CancellationError {
                throw Pose3DError.cancelled
            } catch {
                if i < 3 {
                    pose3DLog.warning("3D Frame \(i) error: \(error.localizedDescription)")
                }
            }

            frames.append(FramePose3D(
                id: i,
                timestamp: timestamp,
                joints: joints,
                detected: detected,
                bodyHeight: bodyHeight
            ))

            progress(Double(i + 1) / Double(totalFrames))
        }

        return VideoPose3DData(
            frameRate: extractionFPS,
            totalFrames: totalFrames,
            frames: frames,
            videoWidth: Int(naturalSize.width),
            videoHeight: Int(naturalSize.height)
        )
    }

    // MARK: - Mock 3D Data (Simulator)

    #if targetEnvironment(simulator)
    private func generateMock3DData(
        totalFrames: Int,
        duration: Double,
        naturalSize: CGSize,
        progress: @escaping @Sendable (Double) -> Void
    ) -> VideoPose3DData {
        // Simulated 3D batting pose — coordinates in meters relative to root
        struct JointBase3D {
            let name: JointName
            let x: Float; let y: Float; let z: Float
        }

        let baseJoints: [JointBase3D] = [
            // Head (above root by ~0.55m)
            JointBase3D(name: .nose,          x: 0.00, y: 0.55, z: 0.05),
            JointBase3D(name: .neck,          x: 0.00, y: 0.45, z: 0.00),
            // Shoulders
            JointBase3D(name: .leftShoulder,  x: -0.18, y: 0.42, z: 0.00),
            JointBase3D(name: .rightShoulder, x:  0.18, y: 0.42, z: 0.00),
            // Arms (batting stance — hands up)
            JointBase3D(name: .leftElbow,     x: -0.25, y: 0.30, z: 0.10),
            JointBase3D(name: .leftWrist,     x: -0.15, y: 0.45, z: 0.15),
            JointBase3D(name: .rightElbow,    x:  0.28, y: 0.32, z: 0.08),
            JointBase3D(name: .rightWrist,    x:  0.20, y: 0.48, z: 0.12),
            // Root (origin)
            JointBase3D(name: .root,          x: 0.00, y: 0.00, z: 0.00),
            // Hips
            JointBase3D(name: .leftHip,       x: -0.10, y: -0.02, z: 0.00),
            JointBase3D(name: .rightHip,      x:  0.10, y: -0.02, z: 0.00),
            // Knees
            JointBase3D(name: .leftKnee,      x: -0.12, y: -0.38, z: 0.05),
            JointBase3D(name: .rightKnee,     x:  0.12, y: -0.36, z: 0.04),
            // Ankles
            JointBase3D(name: .leftAnkle,     x: -0.14, y: -0.75, z: 0.00),
            JointBase3D(name: .rightAnkle,    x:  0.14, y: -0.75, z: 0.00),
        ]

        var frames: [FramePose3D] = []
        frames.reserveCapacity(totalFrames)

        for i in 0..<totalFrames {
            let timestamp = Double(i) / extractionFPS
            let phase = Float(timestamp / duration) // 0..1

            // Swing animation: rotate upper body around Y-axis
            let swingAngle: Float
            if phase < 0.3 {
                swingAngle = phase / 0.3 * (-0.2)  // load: rotate back
            } else if phase < 0.6 {
                let sp = (phase - 0.3) / 0.3
                swingAngle = -0.2 + sp * 1.2  // swing: rotate through
            } else {
                let fp = (phase - 0.6) / 0.4
                swingAngle = 1.0 + fp * 0.3   // follow-through
            }

            let cosA = cos(swingAngle)
            let sinA = sin(swingAngle)

            var joints: [Pose3DJoint] = []
            for base in baseJoints {
                let rx: Float
                let rz: Float

                // Rotate upper body and arms around Y-axis
                if base.y >= 0 {
                    rx = base.x * cosA + base.z * sinA
                    rz = -base.x * sinA + base.z * cosA
                } else {
                    // Lower body: minimal rotation
                    let factor: Float = max(0, 1.0 + base.y * 0.5) // less rotation for lower joints
                    let partialAngle = swingAngle * factor * 0.3
                    let pc = cos(partialAngle)
                    let ps = sin(partialAngle)
                    rx = base.x * pc + base.z * ps
                    rz = -base.x * ps + base.z * pc
                }

                joints.append(Pose3DJoint(
                    name: base.name,
                    x: rx,
                    y: base.y,
                    z: rz,
                    confidence: 0.9
                ))
            }

            frames.append(FramePose3D(
                id: i,
                timestamp: timestamp,
                joints: joints,
                detected: true,
                bodyHeight: 1.65
            ))

            progress(Double(i + 1) / Double(totalFrames))
        }

        return VideoPose3DData(
            frameRate: extractionFPS,
            totalFrames: totalFrames,
            frames: frames,
            videoWidth: Int(naturalSize.width),
            videoHeight: Int(naturalSize.height)
        )
    }
    #endif
}
