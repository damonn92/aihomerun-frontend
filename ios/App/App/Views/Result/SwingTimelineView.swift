import SwiftUI

/// Interactive timeline showing each swing in a session with speed bars and quality indicators.
/// Tap a swing to see detailed metrics in a popover.
struct SwingTimelineView: View {
    let swings: [SwingFusionMetric]
    var maxSpeed: Double = 0

    @State private var selectedSwing: SwingFusionMetric?
    @State private var animationProgress: CGFloat = 0

    private var effectiveMaxSpeed: Double {
        maxSpeed > 0 ? maxSpeed : (swings.map(\.calibratedSpeed).max() ?? 50) * 1.15
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Swing Timeline", systemImage: "chart.bar.xaxis")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary.opacity(0.55))
                    .textCase(.uppercase)
                    .tracking(0.7)

                Spacer()

                Text("\(swings.count) swings")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.4))
            }

            // Timeline bars
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(swings) { swing in
                        swingBar(swing)
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedSwing = selectedSwing?.id == swing.id ? nil : swing
                                }
                            }
                    }
                }
                .padding(.horizontal, 2)
                .frame(height: 130)
            }

            // Selected swing detail
            if let swing = selectedSwing {
                swingDetailCard(swing)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .hrCard()
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.1).delay(0.15)) {
                animationProgress = 1.0
            }
        }
    }

    // MARK: - Swing Bar

    private func swingBar(_ swing: SwingFusionMetric) -> some View {
        let fraction = swing.calibratedSpeed / effectiveMaxSpeed
        let isSelected = selectedSwing?.id == swing.id
        let quality = swingQuality(swing.compositeScore)

        return VStack(spacing: 4) {
            // Speed label
            Text(String(format: "%.0f", swing.calibratedSpeed))
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? quality.color : .primary.opacity(0.45))

            // Bar
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [quality.color.opacity(0.4), quality.color],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: isSelected ? 20 : 16, height: max(8, 90 * fraction * animationProgress))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(isSelected ? quality.color : Color.clear, lineWidth: 1.5)
                )
                .shadow(color: isSelected ? quality.color.opacity(0.4) : .clear, radius: 4)

            // Impact indicator
            if swing.impactDetected {
                Circle()
                    .fill(Color.hrGreen)
                    .frame(width: 5, height: 5)
            } else {
                Circle()
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    .frame(width: 5, height: 5)
            }

            // Swing number
            Text("#\(swing.swingIndex)")
                .font(.system(size: 7, weight: .medium))
                .foregroundStyle(.primary.opacity(0.35))
        }
    }

    // MARK: - Swing Detail Card

    private func swingDetailCard(_ swing: SwingFusionMetric) -> some View {
        let quality = swingQuality(swing.compositeScore)

        return VStack(spacing: 10) {
            HStack {
                Text("Swing #\(swing.swingIndex)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                // Composite score
                HStack(spacing: 4) {
                    Circle()
                        .fill(quality.color)
                        .frame(width: 7, height: 7)
                    Text(String(format: "%.0f", swing.compositeScore))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(quality.color)
                }

                if swing.impactDetected {
                    Text("HIT")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.hrGreen)
                        .clipShape(Capsule())
                }
            }

            // Metrics grid
            HStack(spacing: 0) {
                detailMetric("Speed", value: String(format: "%.1f", swing.calibratedSpeed), unit: "mph")
                Spacer()
                detailMetric("Power", value: String(format: "%.0f", swing.powerIndex), unit: "/100")
                Spacer()
                detailMetric("Timing", value: String(format: "%.0f", swing.timingScore), unit: "/100")
                Spacer()
                detailMetric("Duration", value: String(format: "%.0f", swing.swingDurationMS), unit: "ms")
                if let angle = swing.attackAngle {
                    Spacer()
                    detailMetric("Angle", value: String(format: "%.1f", angle), unit: "deg")
                }
            }
        }
        .padding(12)
        .background(quality.color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(quality.color.opacity(0.2), lineWidth: 1)
        )
    }

    private func detailMetric(_ label: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.system(size: 8))
                    .foregroundStyle(.primary.opacity(0.4))
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.primary.opacity(0.45))
        }
    }

    // MARK: - Quality

    private func swingQuality(_ score: Double) -> MetricGaugeView.MetricQuality {
        switch score {
        case 80...:  return .excellent
        case 60..<80: return .good
        case 40..<60: return .moderate
        default:     return .needsWork
        }
    }
}

#Preview {
    SwingTimelineView(swings: [
        SwingFusionMetric(id: UUID(), swingIndex: 1, timestamp: Date(), calibratedSpeed: 45.2, powerIndex: 72, timingScore: 68, efficiency: 75, attackAngle: 8.5, impactDetected: true, rawHandSpeedMPH: 16.1, swingDurationMS: 185),
        SwingFusionMetric(id: UUID(), swingIndex: 2, timestamp: Date(), calibratedSpeed: 42.8, powerIndex: 65, timingScore: 72, efficiency: 70, attackAngle: 12.1, impactDetected: false, rawHandSpeedMPH: 15.3, swingDurationMS: 210),
        SwingFusionMetric(id: UUID(), swingIndex: 3, timestamp: Date(), calibratedSpeed: 48.1, powerIndex: 81, timingScore: 85, efficiency: 82, attackAngle: 6.2, impactDetected: true, rawHandSpeedMPH: 17.2, swingDurationMS: 172),
        SwingFusionMetric(id: UUID(), swingIndex: 4, timestamp: Date(), calibratedSpeed: 44.5, powerIndex: 70, timingScore: 74, efficiency: 73, attackAngle: 9.8, impactDetected: true, rawHandSpeedMPH: 15.9, swingDurationMS: 195),
        SwingFusionMetric(id: UUID(), swingIndex: 5, timestamp: Date(), calibratedSpeed: 46.9, powerIndex: 78, timingScore: 80, efficiency: 79, attackAngle: 7.4, impactDetected: true, rawHandSpeedMPH: 16.7, swingDurationMS: 180),
    ])
    .padding()
    .background(Color.hrBg)
}
