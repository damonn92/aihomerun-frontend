import SwiftUI
import AVFoundation

// MARK: - Trim Preview View

/// Shows the auto-detected action window and allows the user to adjust trim handles
/// before confirming or skipping.
struct TrimPreviewView: View {
    let videoURL: URL
    let detection: ActionDetectionService.DetectionResult
    let onConfirmTrim: (ClosedRange<Double>) -> Void
    let onUseFullVideo: () -> Void

    @State private var trimStart: Double
    @State private var trimEnd: Double
    @State private var isFullVideo = false   // true when "Use Full Video" is selected
    @StateObject private var playerVM = VideoReplayViewModel()
    @State private var isPlaying = false

    init(
        videoURL: URL,
        detection: ActionDetectionService.DetectionResult,
        onConfirmTrim: @escaping (ClosedRange<Double>) -> Void,
        onUseFullVideo: @escaping () -> Void
    ) {
        self.videoURL = videoURL
        self.detection = detection
        self.onConfirmTrim = onConfirmTrim
        self.onUseFullVideo = onUseFullVideo
        _trimStart = State(initialValue: detection.trimRange.lowerBound)
        _trimEnd = State(initialValue: detection.trimRange.upperBound)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Video preview
            videoPreview
                .padding(.horizontal, 12)

            // Timeline with waveform + handles
            TrimTimelineView(
                videoURL: videoURL,
                velocities: detection.wristVelocities,
                scanTimestamps: detection.scanTimestamps,
                videoDuration: detection.videoDuration,
                trimStart: $trimStart,
                trimEnd: $trimEnd,
                peakTime: detection.peakTime
            )
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // Trim info row
            trimInfoRow
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // Action buttons
            actionButtons
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 16)
        }
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hrBlue.opacity(0.25), lineWidth: 1)
        )
        .onAppear {
            playerVM.loadVideo(url: videoURL)
            playerVM.player.isMuted = true
            seekToTrimStart()
        }
        .onDisappear {
            playerVM.cleanup()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.hrBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Action Detected")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                Text("at \(formattedTime(detection.peakTime)) · \(Int(detection.confidence * 100))% confidence")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.55))
            }

            Spacer()

            // Confidence badge
            confidenceBadge
        }
    }

    private var confidenceBadge: some View {
        let color: Color = detection.confidence > 0.7 ? .hrGreen
            : detection.confidence > 0.4 ? .hrOrange : .hrRed

        return HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(detection.confidence > 0.7 ? "Strong" : detection.confidence > 0.4 ? "Moderate" : "Weak")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
    }

    // MARK: - Video Preview

    private var videoPreview: some View {
        ZStack {
            Color.black
            PlayerLayerView(player: playerVM.player)

            // Play/pause overlay
            Button {
                togglePlayback()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.6))
                        .frame(width: 44, height: 44)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            // Trim range label (bottom-right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(formattedTime(trimStart)) — \(formattedTime(trimEnd))")
                        .font(.system(size: 9, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial.opacity(0.7))
                        .clipShape(Capsule())
                        .padding(8)
                }
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.hrStroke, lineWidth: 1)
        )
    }

    // MARK: - Trim Info Row

    private var trimInfoRow: some View {
        HStack(spacing: 16) {
            infoChip(icon: "scissors", label: "Trim", value: String(format: "%.1fs", trimEnd - trimStart))
            infoChip(icon: "film", label: "Original", value: String(format: "%.1fs", detection.videoDuration))
            infoChip(icon: "bolt.fill", label: "Peak", value: formattedTime(detection.peakTime))
            Spacer()
        }
    }

    private func infoChip(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Color.hrBlue.opacity(0.7))
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.primary.opacity(0.50))
            Text(value)
                .font(.system(size: 10, weight: .bold).monospacedDigit())
                .foregroundStyle(.primary.opacity(0.7))
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 10) {
            // Toggle full video / back to trimmed (secondary)
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    if isFullVideo {
                        // Switch back to trimmed range
                        isFullVideo = false
                        trimStart = detection.trimRange.lowerBound
                        trimEnd = detection.trimRange.upperBound
                    } else {
                        // Expand to full video
                        isFullVideo = true
                        trimStart = 0
                        trimEnd = detection.videoDuration
                    }
                }
                seekToTrimStart()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: isFullVideo ? "scissors" : "film")
                        .font(.system(size: 12, weight: .semibold))
                    Text(isFullVideo ? "Use Trimmed" : "Use Full Video")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.primary.opacity(0.7))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color.hrDivider)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            // Confirm selection (primary)
            Button {
                if isFullVideo {
                    onUseFullVideo()
                } else {
                    onConfirmTrim(trimStart...trimEnd)
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: isFullVideo ? "checkmark.circle.fill" : "scissors")
                        .font(.system(size: 12, weight: .semibold))
                    Text(isFullVideo ? "Confirm Full" : "Confirm Trim")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    LinearGradient(
                        colors: [Color.hrBlue, Color(red: 0.04, green: 0.36, blue: 0.80)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func togglePlayback() {
        if isPlaying {
            playerVM.player.pause()
            isPlaying = false
        } else {
            // Seek to trim start and play
            seekToTrimStart()
            playerVM.player.rate = 0.5  // Slow-mo preview
            isPlaying = true

            // Auto-stop at trim end
            let endTime = CMTime(seconds: trimEnd, preferredTimescale: 600)
            playerVM.player.addBoundaryTimeObserver(
                forTimes: [NSValue(time: endTime)],
                queue: .main
            ) { [self] in
                playerVM.player.pause()
                isPlaying = false
                seekToTrimStart()
            }
        }
    }

    private func seekToTrimStart() {
        let time = CMTime(seconds: trimStart, preferredTimescale: 600)
        playerVM.player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func formattedTime(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        let ms = Int((seconds.truncatingRemainder(dividingBy: 1)) * 10)
        if m > 0 {
            return String(format: "%d:%02d.%d", m, s, ms)
        }
        return String(format: "%d.%ds", s, ms)
    }
}
