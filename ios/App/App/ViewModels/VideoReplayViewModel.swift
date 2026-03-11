import Foundation
import SwiftUI
import AVFoundation

// MARK: - Video Replay ViewModel

@MainActor
class VideoReplayViewModel: ObservableObject {

    // MARK: Published state

    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var playbackRate: Float = 1.0
    @Published var isFullScreen = false
    @Published var zoomScale: CGFloat = 1.0
    @Published var panOffset: CGSize = .zero
    @Published var loadError: String?
    @Published var videoURL: URL?

    // MARK: Player

    let player = AVPlayer()
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?
    private(set) var frameInterval: Double = 1.0 / 30.0 // default 30fps

    // MARK: Available speeds

    static let speeds: [Float] = [0.25, 0.5, 1.0]

    // MARK: Lifecycle

    func loadVideo(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            loadError = "Video no longer available"
            return
        }

        self.videoURL = url

        let asset = AVAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
        player.isMuted = true

        // Observe item status for duration & frame rate
        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.duration = item.duration.seconds.isFinite ? item.duration.seconds : 0

                    // Get nominal frame rate from first video track
                    Task {
                        if let tracks = try? await asset.loadTracks(withMediaType: .video),
                           let track = tracks.first {
                            let rate = try? await track.load(.nominalFrameRate)
                            await MainActor.run {
                                if let rate, rate > 0 {
                                    self.frameInterval = 1.0 / Double(rate)
                                }
                            }
                        }
                    }

                case .failed:
                    self.loadError = item.error?.localizedDescription ?? "Failed to load video"
                default:
                    break
                }
            }
        }

        // Periodic time observer at ~30 Hz
        let interval = CMTime(seconds: 1.0 / 30.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let t = time.seconds
                if t.isFinite { self.currentTime = t }
            }
        }

        // End-of-playback observer
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isPlaying = false
            }
        }
    }

    // MARK: Play / Pause

    func togglePlayPause() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            // If at the end, restart from beginning
            if let item = player.currentItem,
               currentTime >= duration - 0.05,
               duration > 0 {
                item.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
            }
            player.rate = playbackRate
            isPlaying = true
        }
    }

    // MARK: Speed control

    func setSpeed(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player.rate = rate
        }
    }

    // MARK: Frame stepping

    func stepForward() {
        player.pause()
        isPlaying = false
        player.currentItem?.step(byCount: 1)
    }

    func stepBackward() {
        player.pause()
        isPlaying = false
        player.currentItem?.step(byCount: -1)
    }

    // MARK: Seeking

    func seek(to fraction: Double) {
        guard duration > 0 else { return }
        let target = CMTime(seconds: fraction * duration, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    // MARK: Zoom / Pan

    func resetZoom() {
        withAnimation(.spring(duration: 0.3)) {
            zoomScale = 1.0
            panOffset = .zero
        }
    }

    func toggleZoom() {
        withAnimation(.spring(duration: 0.3)) {
            if zoomScale > 1.5 {
                zoomScale = 1.0
                panOffset = .zero
            } else {
                zoomScale = 2.5
            }
        }
    }

    func clampZoom() {
        zoomScale = min(max(zoomScale, 1.0), 5.0)
        if zoomScale <= 1.01 {
            panOffset = .zero
        }
    }

    // MARK: Formatted time helpers

    var currentTimeFormatted: String { formatTime(currentTime) }
    var durationFormatted: String { formatTime(duration) }
    var progress: Double { duration > 0 ? currentTime / duration : 0 }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return "\(m):\(String(format: "%02d", s))"
    }

    // MARK: Cleanup

    func cleanup() {
        player.pause()
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil
    }
}
