import Foundation
import SwiftUI
import os.log

private let poseLog = Logger(subsystem: "com.aihomerun.app", category: "PoseOverlay")

/// Write debug log to a file in the app's Documents directory for easy retrieval.
/// Callable from any actor/thread — writes to Documents/pose_debug.log.
nonisolated func poseDebugLog(_ message: String) {
    print(message) // stdout
    let fm = FileManager.default
    if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
        let logFile = docs.appendingPathComponent("pose_debug.log")
        let line = "\(Date()): \(message)\n"
        if fm.fileExists(atPath: logFile.path) {
            if let handle = try? FileHandle(forWritingTo: logFile) {
                handle.seekToEndOfFile()
                handle.write(line.data(using: .utf8) ?? Data())
                handle.closeFile()
            }
        } else {
            try? line.write(to: logFile, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - Pose Overlay ViewModel

@MainActor
class PoseOverlayViewModel: ObservableObject {

    // MARK: - Analysis State

    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0
    @Published var analysisError: String?
    @Published var poseData: VideoPoseData?
    @Published var usedMockData = false
    var lastVideoURL: URL?

    // MARK: - Display Settings

    @Published var showSkeleton = true
    @Published var showJointLabels = false
    @Published var showAngles = true
    @Published var skeletonOpacity: Double = 0.85

    // MARK: - Current Frame Pose

    @Published var currentPose: FramePose?
    @Published var computedAngles: [ComputedAngle] = []

    // MARK: - Annotation Drawing

    @Published var isDrawingMode = false
    @Published var activeColor: StrokeColor = .red
    @Published var activeLineWidth: CGFloat = 3.0
    @Published var strokes: [DrawingStroke] = []
    @Published var currentStroke: DrawingStroke?

    // MARK: - Private

    private let poseService = PoseDetectionService()
    private var analysisTask: Task<Void, Never>?

    // MARK: - Analysis Lifecycle

    func startAnalysis(videoURL: URL) {
        lastVideoURL = videoURL
        guard poseData == nil, !isAnalyzing else {
            poseDebugLog("[PoseOverlay] startAnalysis SKIPPED — hasPoseData:\(poseData != nil) isAnalyzing:\(isAnalyzing)")
            return
        }
        let fileExists = FileManager.default.fileExists(atPath: videoURL.path)
        poseDebugLog("[PoseOverlay] startAnalysis STARTING for: \(videoURL.lastPathComponent), exists=\(fileExists)")
        analysisError = nil
        isAnalyzing = true
        analysisProgress = 0

        analysisTask = Task { [weak self] in
            guard let self else {
                poseDebugLog("[PoseOverlay] SELF IS NIL — task aborted")
                return
            }
            poseDebugLog("[PoseOverlay] Task body started — calling analyzeVideo")
            do {
                let data = try await self.poseService.analyzeVideo(url: videoURL) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.analysisProgress = progress
                    }
                }
                let detectedCount = data.frames.filter { $0.detected }.count
                let isMock = await self.poseService.usedMockData
                poseDebugLog("[PoseOverlay] ✅ Analysis COMPLETE — \(data.totalFrames) frames, \(detectedCount) with pose, mock=\(isMock)")
                self.poseData = data
                self.usedMockData = isMock
            } catch is CancellationError {
                poseDebugLog("[PoseOverlay] ⚠️ Analysis CANCELLED")
                // Don't reset isAnalyzing — retryAnalysis() handles state when it cancels us
                return
            } catch {
                poseDebugLog("[PoseOverlay] ❌ Analysis ERROR: \(error)")
                self.analysisError = error.localizedDescription
            }
            self.isAnalyzing = false
            poseDebugLog("[PoseOverlay] isAnalyzing=false, poseData:\(self.poseData != nil), error:\(self.analysisError ?? "nil")")
        }
    }

    /// Manually retry analysis (called from PoseToolbar button)
    func retryAnalysis() {
        guard let url = lastVideoURL else {
            poseDebugLog("[PoseOverlay] retryAnalysis — no lastVideoURL")
            analysisError = "No video URL available"
            return
        }
        poseDebugLog("[PoseOverlay] retryAnalysis triggered for: \(url.lastPathComponent)")
        // Reset state and re-run
        poseData = nil
        analysisError = nil
        isAnalyzing = false
        analysisTask?.cancel()
        analysisTask = nil
        startAnalysis(videoURL: url)
    }

    /// Called from SwiftUI `.task` modifier — runs the analysis cooperatively.
    func runAnalysis(videoURL: URL) async {
        lastVideoURL = videoURL
        guard poseData == nil, !isAnalyzing else {
            poseDebugLog("[PoseOverlay] runAnalysis SKIPPED — hasPoseData:\(poseData != nil) isAnalyzing:\(isAnalyzing)")
            return
        }
        let fileExists = FileManager.default.fileExists(atPath: videoURL.path)
        poseDebugLog("[PoseOverlay] runAnalysis STARTING for: \(videoURL.lastPathComponent), exists=\(fileExists)")
        analysisError = nil
        isAnalyzing = true
        analysisProgress = 0

        do {
            let data = try await poseService.analyzeVideo(url: videoURL) { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.analysisProgress = progress
                }
            }
            let detectedCount = data.frames.filter { $0.detected }.count
            let isMock = await poseService.usedMockData
            poseDebugLog("[PoseOverlay] ✅ runAnalysis COMPLETE — \(data.totalFrames) frames, \(detectedCount) with pose, mock=\(isMock)")
            self.poseData = data
            self.usedMockData = isMock
        } catch is CancellationError {
            poseDebugLog("[PoseOverlay] ⚠️ runAnalysis CANCELLED")
        } catch {
            poseDebugLog("[PoseOverlay] ❌ runAnalysis ERROR: \(error)")
            self.analysisError = error.localizedDescription
        }
        self.isAnalyzing = false
    }

    func cancelAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
        isAnalyzing = false
    }

    // MARK: - Frame Lookup

    /// Update the current pose for the given playback time.
    /// Uses binary search for O(log n) lookup.
    func updatePose(forTime time: Double) {
        guard let data = poseData, !data.frames.isEmpty else {
            currentPose = nil
            computedAngles = []
            return
        }

        let frame = nearestFrame(in: data.frames, for: time)
        currentPose = frame

        if showAngles, let frame, frame.detected {
            computedAngles = computeAngles(from: frame)
        } else {
            computedAngles = []
        }
    }

    private func nearestFrame(in frames: [FramePose], for time: Double) -> FramePose? {
        guard !frames.isEmpty else { return nil }

        // Binary search for the nearest frame by timestamp
        var lo = 0, hi = frames.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            if frames[mid].timestamp < time {
                lo = mid + 1
            } else {
                hi = mid
            }
        }

        // Compare with previous frame to find closest
        if lo > 0 {
            let prev = frames[lo - 1]
            let curr = frames[lo]
            return abs(prev.timestamp - time) < abs(curr.timestamp - time) ? prev : curr
        }
        return frames[lo]
    }

    // MARK: - Load Cached Pose Data

    /// Inject pre-computed pose data directly (from PoseDataCache or previous analysis).
    /// Used by ComparisonViewModel to skip re-analysis.
    func loadCachedPoseData(_ data: VideoPoseData) {
        self.poseData = data
        self.isAnalyzing = false
        self.analysisError = nil
        self.usedMockData = false
        poseDebugLog("[PoseOverlay] Loaded cached pose data: \(data.totalFrames) frames")
    }

    // MARK: - Angle Computation

    /// Compute angles from a frame — accessible for ComparisonViewModel to use.
    func computeAngles(from frame: FramePose) -> [ComputedAngle] {
        var angles: [ComputedAngle] = []

        // Right elbow: shoulder → elbow → wrist
        if let s = frame.joint(.rightShoulder),
           let e = frame.joint(.rightElbow),
           let w = frame.joint(.rightWrist) {
            let deg = angleBetween(
                a: CGPoint(x: s.x, y: s.y),
                b: CGPoint(x: e.x, y: e.y),
                c: CGPoint(x: w.x, y: w.y))
            angles.append(ComputedAngle(name: "R.Elbow", degrees: deg,
                                        position: CGPoint(x: e.x, y: e.y),
                                        jointName: .rightElbow))
        }

        // Left elbow: shoulder → elbow → wrist
        if let s = frame.joint(.leftShoulder),
           let e = frame.joint(.leftElbow),
           let w = frame.joint(.leftWrist) {
            let deg = angleBetween(
                a: CGPoint(x: s.x, y: s.y),
                b: CGPoint(x: e.x, y: e.y),
                c: CGPoint(x: w.x, y: w.y))
            angles.append(ComputedAngle(name: "L.Elbow", degrees: deg,
                                        position: CGPoint(x: e.x, y: e.y),
                                        jointName: .leftElbow))
        }

        // Right knee: hip → knee → ankle
        if let h = frame.joint(.rightHip),
           let k = frame.joint(.rightKnee),
           let a = frame.joint(.rightAnkle) {
            let deg = angleBetween(
                a: CGPoint(x: h.x, y: h.y),
                b: CGPoint(x: k.x, y: k.y),
                c: CGPoint(x: a.x, y: a.y))
            angles.append(ComputedAngle(name: "R.Knee", degrees: deg,
                                        position: CGPoint(x: k.x, y: k.y),
                                        jointName: .rightKnee))
        }

        // Left knee: hip → knee → ankle
        if let h = frame.joint(.leftHip),
           let k = frame.joint(.leftKnee),
           let a = frame.joint(.leftAnkle) {
            let deg = angleBetween(
                a: CGPoint(x: h.x, y: h.y),
                b: CGPoint(x: k.x, y: k.y),
                c: CGPoint(x: a.x, y: a.y))
            angles.append(ComputedAngle(name: "L.Knee", degrees: deg,
                                        position: CGPoint(x: k.x, y: k.y),
                                        jointName: .leftKnee))
        }

        // Hip rotation: leftHip → root → rightHip
        if let lh = frame.joint(.leftHip),
           let r = frame.joint(.root),
           let rh = frame.joint(.rightHip) {
            let deg = angleBetween(
                a: CGPoint(x: lh.x, y: lh.y),
                b: CGPoint(x: r.x, y: r.y),
                c: CGPoint(x: rh.x, y: rh.y))
            angles.append(ComputedAngle(name: "Hips", degrees: deg,
                                        position: CGPoint(x: r.x, y: r.y),
                                        jointName: .root))
        }

        return angles
    }

    /// Returns the angle at vertex b (in degrees) formed by points a-b-c
    private func angleBetween(a: CGPoint, b: CGPoint, c: CGPoint) -> Double {
        let ba = CGPoint(x: a.x - b.x, y: a.y - b.y)
        let bc = CGPoint(x: c.x - b.x, y: c.y - b.y)
        let dot = ba.x * bc.x + ba.y * bc.y
        let magBA = sqrt(ba.x * ba.x + ba.y * ba.y)
        let magBC = sqrt(bc.x * bc.x + bc.y * bc.y)
        guard magBA > 0, magBC > 0 else { return 0 }
        let cosAngle = max(-1, min(1, dot / (magBA * magBC)))
        return acos(cosAngle) * 180.0 / .pi
    }

    // MARK: - Drawing

    func beginStroke(at point: CGPoint, frameTime: Double) {
        currentStroke = DrawingStroke(
            points: [point],
            color: activeColor,
            lineWidth: activeLineWidth,
            frameTimestamp: frameTime
        )
    }

    func continueStroke(to point: CGPoint) {
        currentStroke?.points.append(point)
    }

    func endStroke() {
        if let stroke = currentStroke, stroke.points.count > 1 {
            strokes.append(stroke)
        }
        currentStroke = nil
    }

    func undoLastStroke() {
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
    }

    func clearAnnotations(forTime time: Double? = nil) {
        if let time {
            strokes.removeAll { abs($0.frameTimestamp - time) < 0.05 }
        } else {
            strokes.removeAll()
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        cancelAnalysis()
        poseData = nil
        currentPose = nil
        computedAngles = []
        strokes.removeAll()
        currentStroke = nil
    }
}
