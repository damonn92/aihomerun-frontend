import Foundation
import SwiftUI
import AVFoundation
import Combine

// MARK: - Comparison ViewModel

@MainActor
class ComparisonViewModel: ObservableObject, Identifiable {
    nonisolated let id = UUID()

    // MARK: - Sessions

    @Published var leftSession: ComparisonSession
    @Published var rightSession: ComparisonSession

    // MARK: - Players & Pose VMs

    let leftPlayerVM = VideoReplayViewModel()
    let rightPlayerVM = VideoReplayViewModel()
    let leftPoseVM = PoseOverlayViewModel()
    let rightPoseVM = PoseOverlayViewModel()

    // MARK: - Comparison State

    @Published var mode: ComparisonMode = .sideBySide
    @Published var ghostOpacity: Double = 0.45
    @Published var isPlaying = false
    @Published var playbackRate: Float = 0.25
    @Published var syncedProgress: Double = 0
    @Published var syncedCurrentTime: Double = 0
    @Published var alignedDuration: Double = 0
    @Published var angleDeltas: [AngleDelta] = []

    // MARK: - Score Comparison

    var leftScore: Int? { leftSession.overallScore }
    var rightScore: Int? { rightSession.overallScore }
    var scoreDelta: Int? {
        guard let l = leftScore, let r = rightScore else { return nil }
        return r - l
    }

    // MARK: - Sync State

    @Published var leftSyncPoint: Double = 0
    @Published var rightSyncPoint: Double = 0
    @Published var hasSyncPoints: Bool = false

    // MARK: - Loading State

    @Published var isLoadingLeft = false
    @Published var isLoadingRight = false
    var isLoading: Bool { isLoadingLeft || isLoadingRight }

    /// At least one side has a playable video
    var hasAnyVideo: Bool { leftSession.videoAvailable || rightSession.videoAvailable }

    // MARK: - Private

    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private let syncInterval: Double = 1.0 / 30.0  // 30 Hz

    // MARK: - Init

    init(left: ComparisonSession, right: ComparisonSession) {
        self.leftSession = left
        self.rightSession = right
    }

    // MARK: - Load Both Videos

    func loadBothVideos() {
        loadLeft()
        loadRight()
        computeAlignedDuration()
    }

    private func loadLeft() {
        guard let url = leftSession.videoURL, leftSession.videoAvailable else { return }
        leftPlayerVM.loadVideo(url: url)
        leftPlayerVM.player.isMuted = true

        // Check pose cache
        if let cached = leftSession.poseData {
            leftPoseVM.loadCachedPoseData(cached)
        } else {
            isLoadingLeft = true
            Task {
                // Check disk cache first
                if let cachedPose = await PoseDataCache.shared.cached(for: url) {
                    leftPoseVM.loadCachedPoseData(cachedPose)
                    leftSession.poseData = cachedPose
                    isLoadingLeft = false
                } else {
                    await leftPoseVM.runAnalysis(videoURL: url)
                    if let data = leftPoseVM.poseData {
                        leftSession.poseData = data
                        await PoseDataCache.shared.store(data, for: url)
                    }
                    isLoadingLeft = false
                }
            }
        }
    }

    private func loadRight() {
        guard let url = rightSession.videoURL, rightSession.videoAvailable else { return }
        rightPlayerVM.loadVideo(url: url)
        rightPlayerVM.player.isMuted = true
        // Right player is always paused — driven by seek
        rightPlayerVM.player.pause()

        if let cached = rightSession.poseData {
            rightPoseVM.loadCachedPoseData(cached)
        } else {
            isLoadingRight = true
            Task {
                if let cachedPose = await PoseDataCache.shared.cached(for: url) {
                    rightPoseVM.loadCachedPoseData(cachedPose)
                    rightSession.poseData = cachedPose
                    isLoadingRight = false
                } else {
                    await rightPoseVM.runAnalysis(videoURL: url)
                    if let data = rightPoseVM.poseData {
                        rightSession.poseData = data
                        await PoseDataCache.shared.store(data, for: url)
                    }
                    isLoadingRight = false
                }
            }
        }
    }

    // MARK: - Playback Controls

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard !isPlaying else { return }

        // If at end, restart
        if syncedProgress >= 0.99 {
            seek(toProgress: 0)
        }

        isPlaying = true
        leftPlayerVM.player.rate = playbackRate
        // Right player stays rate=0, driven by sync engine
        rightPlayerVM.player.pause()
        startSyncEngine()
    }

    func pause() {
        isPlaying = false
        leftPlayerVM.player.pause()
        rightPlayerVM.player.pause()
        stopSyncEngine()
        // Snap final positions
        syncRightToLeft()
    }

    func setSpeed(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            leftPlayerVM.player.rate = rate
        }
    }

    func stepForward() {
        pause()
        leftPlayerVM.player.currentItem?.step(byCount: 1)
        // Let time observer update, then sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.syncRightToLeft()
        }
    }

    func stepBackward() {
        pause()
        leftPlayerVM.player.currentItem?.step(byCount: -1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.syncRightToLeft()
        }
    }

    /// Seek both videos by aligned progress (0...1)
    func seek(toProgress fraction: Double) {
        guard alignedDuration > 0 else { return }
        let alignedTime = fraction * alignedDuration
        seekToAlignedTime(alignedTime)
    }

    /// Seek both videos to a specific aligned time
    func seekToAlignedTime(_ alignedTime: Double) {
        let leftTime = alignedTime + leftAlignedOffset
        let rightTime = alignedTime + rightAlignedOffset

        leftPlayerVM.seekToTime(leftTime)
        rightPlayerVM.seekToTime(rightTime)

        syncedCurrentTime = alignedTime
        syncedProgress = alignedDuration > 0 ? alignedTime / alignedDuration : 0

        // Update pose for both sides
        leftPoseVM.updatePose(forTime: leftTime)
        rightPoseVM.updatePose(forTime: rightTime)
        computeAngleDeltas()
    }

    // MARK: - Sync Points

    func setSyncPoint(side: SyncSide) {
        switch side {
        case .left:
            leftSyncPoint = leftPlayerVM.currentTime
        case .right:
            rightSyncPoint = rightPlayerVM.currentTime
        }
        hasSyncPoints = true
        computeAlignedDuration()
    }

    func clearSyncPoints() {
        leftSyncPoint = 0
        rightSyncPoint = 0
        hasSyncPoints = false
        computeAlignedDuration()
    }

    func swapSides() {
        let tempSession = leftSession
        leftSession = rightSession
        rightSession = tempSession

        let tempSync = leftSyncPoint
        leftSyncPoint = rightSyncPoint
        rightSyncPoint = tempSync

        // Swap VMs by reloading
        cleanup()
        loadBothVideos()
    }

    // MARK: - Sync Engine (Master-Slave)

    private func startSyncEngine() {
        stopSyncEngine()
        let interval = CMTime(seconds: syncInterval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = leftPlayerVM.player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                self?.onMasterTick(leftTime: time.seconds)
            }
        }
    }

    private func stopSyncEngine() {
        if let observer = timeObserver {
            leftPlayerVM.player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func onMasterTick(leftTime: Double) {
        guard leftTime.isFinite else { return }

        let rightTime = alignedRightTime(forLeftTime: leftTime)
        let alignedTime = leftTime - leftAlignedOffset

        // Check if we've reached the end of aligned range
        if alignedTime >= alignedDuration {
            pause()
            return
        }

        // Seek right player
        rightPlayerVM.seekToTime(rightTime)

        // Update state
        syncedCurrentTime = max(0, alignedTime)
        syncedProgress = alignedDuration > 0 ? max(0, alignedTime / alignedDuration) : 0

        // Update both pose overlays
        leftPoseVM.updatePose(forTime: leftTime)
        rightPoseVM.updatePose(forTime: rightTime)

        // Compute angle differences
        computeAngleDeltas()
    }

    private func syncRightToLeft() {
        let leftTime = leftPlayerVM.currentTime
        let rightTime = alignedRightTime(forLeftTime: leftTime)
        let alignedTime = leftTime - leftAlignedOffset

        rightPlayerVM.seekToTime(rightTime)

        syncedCurrentTime = max(0, alignedTime)
        syncedProgress = alignedDuration > 0 ? max(0, alignedTime / alignedDuration) : 0

        leftPoseVM.updatePose(forTime: leftTime)
        rightPoseVM.updatePose(forTime: rightTime)
        computeAngleDeltas()
    }

    // MARK: - Alignment Math

    /// Compute the right video time that corresponds to a given left video time
    private func alignedRightTime(forLeftTime leftTime: Double) -> Double {
        return leftTime - leftSyncPoint + rightSyncPoint
    }

    /// The offset from aligned time=0 to left video time
    private var leftAlignedOffset: Double {
        return max(0, leftSyncPoint - rightSyncPoint)
    }

    /// The offset from aligned time=0 to right video time
    private var rightAlignedOffset: Double {
        return max(0, rightSyncPoint - leftSyncPoint)
    }

    /// Compute the overlapping duration of both videos after alignment
    private func computeAlignedDuration() {
        let leftDur = leftPlayerVM.duration > 0 ? leftPlayerVM.duration : 10
        let rightDur = rightPlayerVM.duration > 0 ? rightPlayerVM.duration : 10

        // Time before sync point
        let beforeSync = min(leftSyncPoint, rightSyncPoint)
        // Time after sync point
        let leftAfterSync = leftDur - leftSyncPoint
        let rightAfterSync = rightDur - rightSyncPoint
        let afterSync = min(leftAfterSync, rightAfterSync)

        alignedDuration = beforeSync + afterSync
    }

    // MARK: - Angle Deltas

    private func computeAngleDeltas() {
        let leftAngles = leftPoseVM.computedAngles
        let rightAngles = rightPoseVM.computedAngles

        guard !leftAngles.isEmpty, !rightAngles.isEmpty else {
            angleDeltas = []
            return
        }

        var deltas: [AngleDelta] = []

        for leftAngle in leftAngles {
            if let rightAngle = rightAngles.first(where: { $0.jointName == leftAngle.jointName }) {
                deltas.append(AngleDelta(
                    name: leftAngle.name,
                    jointName: leftAngle.jointName,
                    leftDegrees: leftAngle.degrees,
                    rightDegrees: rightAngle.degrees,
                    position: leftAngle.position
                ))
            }
        }

        angleDeltas = deltas
    }

    // MARK: - Formatted Time

    var syncedTimeFormatted: String { formatTime(syncedCurrentTime) }
    var alignedDurationFormatted: String { formatTime(alignedDuration) }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return "\(m):\(String(format: "%02d", s))"
    }

    // MARK: - Cleanup

    func cleanup() {
        stopSyncEngine()
        leftPlayerVM.cleanup()
        rightPlayerVM.cleanup()
        leftPoseVM.cleanup()
        rightPoseVM.cleanup()
        cancellables.removeAll()
    }
}
