import SwiftUI
import AVFoundation

// MARK: - Side by Side Comparison View

struct SideBySideView: View {
    @ObservedObject var vm: ComparisonViewModel

    var body: some View {
        GeometryReader { geo in
            let panelWidth = (geo.size.width - 4) / 2  // 4pt gap

            HStack(spacing: 4) {
                // Left panel
                comparisonPanel(
                    playerVM: vm.leftPlayerVM,
                    poseVM: vm.leftPoseVM,
                    session: vm.leftSession,
                    label: "A",
                    syncPoint: vm.leftSyncPoint,
                    hasSyncPoint: vm.hasSyncPoints,
                    width: panelWidth
                )

                // Right panel
                comparisonPanel(
                    playerVM: vm.rightPlayerVM,
                    poseVM: vm.rightPoseVM,
                    session: vm.rightSession,
                    label: "B",
                    syncPoint: vm.rightSyncPoint,
                    hasSyncPoint: vm.hasSyncPoints,
                    width: panelWidth
                )
            }
        }
        .aspectRatio(32.0 / 9.0, contentMode: .fit)
    }

    // MARK: - Single Panel

    @ViewBuilder
    private func comparisonPanel(
        playerVM: VideoReplayViewModel,
        poseVM: PoseOverlayViewModel,
        session: ComparisonSession,
        label: String,
        syncPoint: Double,
        hasSyncPoint: Bool,
        width: CGFloat
    ) -> some View {
        ZStack(alignment: .topLeading) {
            // Video + Skeleton
            if session.videoAvailable {
                ZStack {
                    Color.black
                    PlayerLayerView(player: playerVM.player)
                    SkeletonOverlayView(poseVM: poseVM, currentTime: playerVM.currentTime)
                }
            } else {
                videoUnavailablePlaceholder
            }

            // Session info badge (top-left)
            sessionBadge(session: session, label: label)
                .padding(6)

            // Sync point marker (top-right)
            if hasSyncPoint {
                syncMarker(time: syncPoint)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                    .padding(6)
            }

            // Analysis loading indicator
            if poseVM.isAnalyzing {
                analysisLoadingOverlay(progress: poseVM.analysisProgress)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.hrStroke, lineWidth: 1)
        )
    }

    // MARK: - Session Badge

    private func sessionBadge(session: ComparisonSession, label: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(label == "A" ? Color.hrGreen : Color.hrOrange)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 0) {
                Text(session.displayLabel)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                if let score = session.overallScore {
                    Text("\(score)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.hrGold)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    // MARK: - Sync Marker

    private func syncMarker(time: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "pin.fill")
                .font(.system(size: 7))
            Text(formatTime(time))
                .font(.system(size: 8, weight: .medium).monospacedDigit())
        }
        .foregroundStyle(Color.hrBlue)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(Color.hrBlue.opacity(0.2))
        .clipShape(Capsule())
    }

    // MARK: - Unavailable Placeholder

    private var videoUnavailablePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.hrCard, Color.black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(spacing: 8) {
                Image(systemName: "film.slash")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.3))
                Text("Video Unavailable")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                Text("Score data is shown below")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.25))
            }
        }
    }

    // MARK: - Analysis Loading

    private func analysisLoadingOverlay(progress: Double) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 4) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.hrBlue)
                    .scaleEffect(0.5)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 9, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial.opacity(0.6))
            .clipShape(Capsule())
            .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0.0s" }
        return String(format: "%.1fs", seconds)
    }
}
