import SwiftUI

// MARK: - Comparison Controls Bar

struct ComparisonControlsBar: View {
    @ObservedObject var vm: ComparisonViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Timeline
            VideoTimelineView(
                progress: vm.syncedProgress,
                currentTime: vm.syncedTimeFormatted,
                duration: vm.alignedDurationFormatted,
                onSeek: { fraction in vm.seek(toProgress: fraction) },
                onDragStart: {
                    if vm.isPlaying { vm.pause() }
                },
                onDragEnd: { }
            )

            // Playback controls row
            HStack(spacing: 0) {
                // Frame step
                HStack(spacing: 4) {
                    Button { vm.stepBackward() } label: {
                        Image(systemName: "backward.frame.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.primary.opacity(0.7))
                            .frame(width: 32, height: 30)
                    }
                    .buttonStyle(.plain)

                    Button { vm.togglePlayPause() } label: {
                        Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 30)
                    }
                    .buttonStyle(.plain)

                    Button { vm.stepForward() } label: {
                        Image(systemName: "forward.frame.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.primary.opacity(0.7))
                            .frame(width: 32, height: 30)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // Speed picker
                HStack(spacing: 3) {
                    ForEach(VideoReplayViewModel.speeds, id: \.self) { rate in
                        Button {
                            vm.setSpeed(rate)
                        } label: {
                            Text(speedLabel(rate))
                                .font(.system(size: 10, weight: .semibold).monospacedDigit())
                                .foregroundStyle(vm.playbackRate == rate ? Color.white : Color.primary.opacity(0.55))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(vm.playbackRate == rate ? Color.hrBlue : Color.hrSurface)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Sync point controls
            syncPointControls
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Sync Point Controls

    private var syncPointControls: some View {
        HStack(spacing: 6) {
            // Set sync point A
            Button {
                vm.setSyncPoint(side: .left)
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8))
                    Text("Set A")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(Color.hrGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.hrGreen.opacity(0.15))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Set sync point B
            Button {
                vm.setSyncPoint(side: .right)
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8))
                    Text("Set B")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(Color.hrOrange)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.hrOrange.opacity(0.15))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if vm.hasSyncPoints {
                // Clear sync points
                Button {
                    vm.clearSyncPoints()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                        Text("Clear")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(.primary.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.hrSurface)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Swap sides
            Button {
                vm.swapSides()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 9))
                    Text("Swap")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(.primary.opacity(0.6))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.hrSurface)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func speedLabel(_ rate: Float) -> String {
        if rate == 1.0 { return "1x" }
        return String(format: "%.2gx", rate)
    }
}
