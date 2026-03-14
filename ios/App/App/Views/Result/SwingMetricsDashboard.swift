import SwiftUI

/// Professional swing metrics dashboard — categorized gauges and bars inspired by Blast Baseball.
/// Replaces the old flat MetricRow list with visual, color-coded metric cards.
struct SwingMetricsDashboard: View {
    let metrics: Metrics
    let actionType: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // SECTION: Key Performance Gauges
            sectionHeader("Key Metrics", icon: "gauge.with.dots.needle.67percent", accent: Color.hrBlue)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    if let speed = metrics.peakWristSpeed {
                        MetricGaugeView(
                            title: "Wrist Speed",
                            value: String(format: "%.1f", speed),
                            unit: "px/f",
                            fraction: min(1.0, speed / 25.0),
                            quality: wristSpeedQuality(speed),
                            icon: "bolt.fill"
                        )
                    }

                    if let sep = metrics.hipShoulderSeparation {
                        MetricGaugeView(
                            title: "Hip-Shoulder",
                            value: String(format: "%.0f", sep),
                            unit: "deg",
                            fraction: min(1.0, sep / 45.0),
                            quality: hipShoulderQuality(sep),
                            icon: "arrow.triangle.2.circlepath"
                        )
                    }

                    if let bal = metrics.balanceScore {
                        MetricGaugeView(
                            title: "Balance",
                            value: String(format: "%.0f", bal * 100),
                            unit: "%",
                            fraction: bal,
                            quality: balanceQuality(bal),
                            icon: "figure.stand"
                        )
                    }

                    if let ft = metrics.followThrough {
                        MetricGaugeView(
                            title: "Follow-Thru",
                            value: ft ? "Yes" : "No",
                            unit: "",
                            fraction: ft ? 1.0 : 0.2,
                            quality: ft ? .excellent : .needsWork,
                            icon: ft ? "checkmark.circle.fill" : "xmark.circle"
                        )
                    }
                }
                .padding(.horizontal, 2)
            }

            // SECTION: Joint Angles (bar gauges)
            if let ja = metrics.jointAngles {
                Divider().background(Color.hrDivider).padding(.vertical, 4)

                sectionHeader("Body Mechanics", icon: "figure.baseball", accent: Color.hrOrange)

                VStack(spacing: 2) {
                    if let v = ja.elbowAngle {
                        MetricBarView(
                            label: actionType == "swing" ? "Elbow Angle" : "Throwing Elbow",
                            value: v,
                            unit: "°",
                            range: 50...170,
                            idealRange: actionType == "swing" ? 90...110 : 85...105,
                            icon: "angle"
                        )
                    }

                    if let v = ja.shoulderAngle {
                        MetricBarView(
                            label: "Shoulder Tilt",
                            value: v,
                            unit: "°",
                            range: 0...45,
                            idealRange: 0...15,
                            icon: "arrow.up.and.down"
                        )
                    }

                    if let v = ja.kneeBend {
                        MetricBarView(
                            label: "Knee Bend",
                            value: v,
                            unit: "°",
                            range: 100...180,
                            idealRange: 130...160,
                            icon: "arrow.down.right"
                        )
                    }

                    if let v = ja.hipRotation {
                        MetricBarView(
                            label: "Hip Rotation",
                            value: v,
                            unit: "°",
                            range: 0...60,
                            idealRange: 25...45,
                            icon: "arrow.triangle.2.circlepath"
                        )
                    }
                }
            }

            // SECTION: Frames info
            if let frames = metrics.framesAnalyzed {
                Divider().background(Color.hrDivider).padding(.vertical, 4)
                HStack {
                    Image(systemName: "film.stack")
                        .font(.system(size: 11))
                        .foregroundStyle(.primary.opacity(0.4))
                    Text("\(frames) frames analyzed")
                        .font(.system(size: 11))
                        .foregroundStyle(.primary.opacity(0.4))
                    Spacer()
                }
            }
        }
        .hrCard()
    }

    // MARK: - Quality Assessment

    private func wristSpeedQuality(_ v: Double) -> MetricGaugeView.MetricQuality {
        switch v {
        case 18...:    return .excellent
        case 15..<18:  return .good
        case 10..<15:  return .moderate
        default:       return .needsWork
        }
    }

    private func hipShoulderQuality(_ v: Double) -> MetricGaugeView.MetricQuality {
        switch v {
        case 30...:    return .excellent
        case 25..<30:  return .good
        case 15..<25:  return .moderate
        default:       return .needsWork
        }
    }

    private func balanceQuality(_ v: Double) -> MetricGaugeView.MetricQuality {
        switch v {
        case 0.80...:    return .excellent
        case 0.65..<0.80: return .good
        case 0.45..<0.65: return .moderate
        default:          return .needsWork
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, icon: String, accent: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.bold))
            .foregroundStyle(accent)
            .textCase(.uppercase)
            .tracking(0.7)
    }
}

#Preview {
    ScrollView {
        SwingMetricsDashboard(
            metrics: Metrics(
                peakWristSpeed: 17.3,
                hipShoulderSeparation: 28.5,
                balanceScore: 0.82,
                followThrough: true,
                jointAngles: JointAngles(
                    elbowAngle: 95,
                    shoulderAngle: 12,
                    hipRotation: 28,
                    kneeBend: 142
                ),
                framesAnalyzed: 45,
                planeEfficiency: 85.2,
                batPathConsistency: 72.1
            ),
            actionType: "swing"
        )
        .padding()
    }
    .background(Color.hrBg)
}
