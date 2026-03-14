import SwiftUI

// MARK: - Comparison Metrics Panel

struct ComparisonMetricsPanel: View {
    @ObservedObject var vm: ComparisonViewModel
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header (tap to expand/collapse)
            Button {
                withAnimation(.spring(duration: 0.25)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.hrBlue)
                    Text("Comparison")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.primary.opacity(0.8))
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.primary.opacity(0.55))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    // Score comparison
                    if vm.leftScore != nil || vm.rightScore != nil {
                        scoreComparisonRow
                        Divider().background(Color.hrSurface)
                    }

                    // Real-time angle deltas
                    if !vm.angleDeltas.isEmpty {
                        angleDeltasSection
                    } else {
                        HStack {
                            Text("Angle data will appear during playback")
                                .font(.system(size: 10))
                                .foregroundStyle(.primary.opacity(0.45))
                        }
                        .padding(.vertical, 10)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.hrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.hrStroke, lineWidth: 1)
        )
    }

    // MARK: - Score Comparison

    private var scoreComparisonRow: some View {
        HStack(spacing: 0) {
            // Left score
            scoreCell(
                label: vm.leftSession.displayLabel,
                score: vm.leftScore,
                color: .hrGreen,
                side: "A"
            )

            // Delta badge in center
            if let delta = vm.scoreDelta {
                DeltaBadge(delta: delta)
                    .padding(.horizontal, 8)
            } else {
                Text("vs")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.45))
                    .padding(.horizontal, 8)
            }

            // Right score
            scoreCell(
                label: vm.rightSession.displayLabel,
                score: vm.rightScore,
                color: .hrOrange,
                side: "B"
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func scoreCell(label: String, score: Int?, color: Color, side: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.60))
            }

            if let score {
                Text("\(score)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            } else {
                Text("--")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Angle Deltas

    private var angleDeltasSection: some View {
        VStack(spacing: 0) {
            ForEach(vm.angleDeltas) { delta in
                angleDeltaRow(delta: delta)
                if delta.id != vm.angleDeltas.last?.id {
                    Divider().background(Color.hrSurface)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func angleDeltaRow(delta: AngleDelta) -> some View {
        HStack {
            Text(delta.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary.opacity(0.60))
                .frame(width: 55, alignment: .leading)

            Spacer()

            // Left value
            Text(String(format: "%.0f\u{00B0}", delta.leftDegrees))
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(Color.hrGreen)
                .frame(width: 40, alignment: .trailing)

            // Delta
            let absDelta = abs(delta.delta)
            let sign = delta.delta >= 0 ? "+" : "-"
            Text(String(format: "%@%.0f\u{00B0}", sign, absDelta))
                .font(.system(size: 10, weight: .bold).monospacedDigit())
                .foregroundStyle(deltaColor(delta.delta))
                .frame(width: 40, alignment: .center)

            // Right value
            Text(String(format: "%.0f\u{00B0}", delta.rightDegrees))
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(Color.hrOrange)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 7)
    }

    private func deltaColor(_ delta: Double) -> Color {
        let abs = abs(delta)
        if abs < 5 { return .primary.opacity(0.55) }
        if abs < 15 { return Color.hrGold }
        return Color.hrRed
    }
}

// Note: DeltaBadge is defined in CompareCardView.swift and reused here.
