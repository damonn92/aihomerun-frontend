import SwiftUI

// MARK: - Comparison View (Top-Level)

struct ComparisonView: View {
    @ObservedObject var vm: ComparisonViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.hrBg.ignoresSafeArea()

            VStack(spacing: 10) {
                // Top bar — always visible
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        // Mode picker (only useful when at least one video exists)
                        if vm.hasAnyVideo {
                            modePicker
                        }

                        // Video area
                        Group {
                            switch vm.mode {
                            case .sideBySide:
                                SideBySideView(vm: vm)
                            case .ghostOverlay:
                                GhostOverlayView(vm: vm)
                            }
                        }
                        .padding(.horizontal, 8)

                        // Ghost opacity slider (only in ghost mode)
                        if vm.mode == .ghostOverlay, vm.hasAnyVideo {
                            ghostOpacitySlider
                                .padding(.horizontal, 16)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Playback controls (only when video exists)
                        if vm.hasAnyVideo {
                            ComparisonControlsBar(vm: vm)
                                .padding(.horizontal, 12)
                        }

                        // Metrics panel — always show (scores work without video)
                        ComparisonMetricsPanel(vm: vm)
                            .padding(.horizontal, 12)

                        Spacer(minLength: 20)
                    }
                }
            }
        }
        .statusBarHidden(false)
        .onAppear {
            vm.loadBothVideos()
        }
        .onDisappear {
            vm.cleanup()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Close")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.hrSurface)
                .clipShape(Capsule())
            }

            Spacer()

            Text("Compare Swings")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)

            Spacer()

            // Placeholder for symmetry
            Color.clear
                .frame(width: 90, height: 34)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 4) {
            ForEach(ComparisonMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        vm.mode = mode
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(mode.label)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(vm.mode == mode ? Color.white : Color.primary.opacity(0.55))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(vm.mode == mode ? Color.hrBlue : Color.hrSurface)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Ghost Opacity Slider

    private var ghostOpacitySlider: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.lefthalf.filled")
                .font(.system(size: 10))
                .foregroundStyle(Color.hrOrange.opacity(0.6))

            Slider(value: $vm.ghostOpacity, in: 0.1...1.0, step: 0.05)
                .tint(Color.hrOrange)

            Text("\(Int(vm.ghostOpacity * 100))%")
                .font(.system(size: 10, weight: .medium).monospacedDigit())
                .foregroundStyle(.primary.opacity(0.60))
                .frame(width: 32)
        }
    }
}
