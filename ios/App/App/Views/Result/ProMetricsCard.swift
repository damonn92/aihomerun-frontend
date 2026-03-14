import SwiftUI

/// Professional-grade fusion metrics card displaying calibrated bat speed,
/// power index, timing, efficiency, and consistency from multi-modal sensor fusion.
/// Inspired by Blast Baseball's dashboard with enhanced data visualization.
struct ProMetricsCard: View {
    let fusion: FusionResult
    var previousFusion: FusionResult? = nil

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Header
            headerSection

            // MARK: - Data Source Badge
            dataSourceBadge

            // MARK: - Hero Speed
            heroSpeedSection

            // MARK: - Metric Grid
            metricsGrid

            // MARK: - Attack Angle + Time to Contact
            if fusion.attackAngleDeg != nil || fusion.timeToContactMS != nil {
                supplementaryRow
            }

            // MARK: - Session Quick Stats
            if let session = fusion.sessionMetrics {
                sessionStatsRow(session)
            }
        }
        .hrCard()
        .onAppear { appeared = true }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Label("Fusion Metrics", systemImage: "wand.and.stars")
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.7)

            Spacer()

            // Confidence indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(confidenceColor)
                    .frame(width: 6, height: 6)
                Text(String(format: "%.0f%%", fusion.fusionConfidence * 100))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(confidenceColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(confidenceColor.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    // MARK: - Data Source Badge

    private var dataSourceBadge: some View {
        let source: FusionDataSource = {
            if fusion.hasVideoData && fusion.hasWatchData { return .fused }
            if fusion.hasWatchData { return .watchOnly }
            return .videoOnly
        }()

        return HStack(spacing: 6) {
            Image(systemName: source.icon)
                .font(.system(size: 10))
            Text(source.rawValue)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(dataSourceColor(source))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(dataSourceColor(source).opacity(0.10))
        .clipShape(Capsule())
    }

    // MARK: - Hero Speed Section

    private var heroSpeedSection: some View {
        VStack(spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", fusion.calibratedBatSpeedMPH))
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.6).delay(0.1), value: appeared)
                Text("mph")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.4))
            }

            Text("Calibrated Bat Speed")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary.opacity(0.5))

            if let prev = previousFusion {
                TrendDeltaBadge(
                    current: fusion.calibratedBatSpeedMPH,
                    previous: prev.calibratedBatSpeedMPH,
                    format: "%.1f"
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Metrics Grid (2x2)

    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
        ], spacing: 10) {
            metricCell(
                title: "Power",
                value: String(format: "%.0f", fusion.powerIndex),
                unit: "/100",
                fraction: fusion.powerIndex / 100,
                quality: scoreQuality(fusion.powerIndex),
                icon: "bolt.fill",
                color: .hrOrange
            )

            metricCell(
                title: "Timing",
                value: String(format: "%.0f", fusion.timingScore),
                unit: "/100",
                fraction: fusion.timingScore / 100,
                quality: scoreQuality(fusion.timingScore),
                icon: "timer",
                color: Color.purple
            )

            metricCell(
                title: "Efficiency",
                value: String(format: "%.0f", fusion.biomechanicalEfficiency),
                unit: "/100",
                fraction: fusion.biomechanicalEfficiency / 100,
                quality: scoreQuality(fusion.biomechanicalEfficiency),
                icon: "arrow.triangle.2.circlepath",
                color: .hrBlue
            )

            metricCell(
                title: "Consistency",
                value: String(format: "%.0f", fusion.consistencyIndex),
                unit: "/100",
                fraction: fusion.consistencyIndex / 100,
                quality: scoreQuality(fusion.consistencyIndex),
                icon: "equal.circle.fill",
                color: .hrGold
            )
        }
    }

    // MARK: - Metric Cell

    private func metricCell(
        title: String, value: String, unit: String,
        fraction: Double, quality: MetricGaugeView.MetricQuality,
        icon: String, color: Color
    ) -> some View {
        VStack(spacing: 8) {
            MetricGaugeView(
                title: title,
                value: value,
                unit: unit,
                fraction: fraction,
                quality: quality,
                icon: icon,
                size: 56
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.10), lineWidth: 1)
        )
    }

    // MARK: - Supplementary Row

    private var supplementaryRow: some View {
        HStack(spacing: 12) {
            if let angle = fusion.attackAngleDeg {
                supplementaryItem(
                    icon: "arrow.up.right",
                    label: "Attack Angle",
                    value: String(format: "%.1f°", angle),
                    color: angleQualityColor(angle)
                )
            }

            if let ttc = fusion.timeToContactMS {
                supplementaryItem(
                    icon: "stopwatch.fill",
                    label: "Time to Contact",
                    value: String(format: "%.0f ms", ttc),
                    color: ttcQualityColor(ttc)
                )
            }

            if let rotAccel = fusion.peakRotationalAccel {
                supplementaryItem(
                    icon: "arrow.triangle.2.circlepath",
                    label: "Peak Rotation",
                    value: String(format: "%.0f rad/s²", rotAccel),
                    color: .hrOrange
                )
            }
        }
    }

    private func supplementaryItem(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.primary.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Session Stats Row

    private func sessionStatsRow(_ session: SessionFusionMetrics) -> some View {
        VStack(spacing: 8) {
            Divider().background(Color.hrDivider)

            HStack(spacing: 0) {
                sessionStat("Swings", value: "\(session.totalSwings)", icon: "figure.baseball")
                Spacer()
                sessionStat("Hit Rate", value: String(format: "%.0f%%", session.hitRate * 100), icon: "target")
                Spacer()
                sessionStat("Duration", value: formatDuration(session.sessionDurationSeconds), icon: "clock.fill")
                if let hr = session.averageHeartRate {
                    Spacer()
                    sessionStat("Avg HR", value: String(format: "%.0f", hr), icon: "heart.fill")
                }
            }
        }
    }

    private func sessionStat(_ label: String, value: String, icon: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.primary.opacity(0.35))
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(.primary.opacity(0.4))
        }
    }

    // MARK: - Helpers

    private func scoreQuality(_ score: Double) -> MetricGaugeView.MetricQuality {
        switch score {
        case 80...:  return .excellent
        case 60..<80: return .good
        case 40..<60: return .moderate
        default:     return .needsWork
        }
    }

    private var confidenceColor: Color {
        switch fusion.fusionConfidence {
        case 0.8...:  return .hrGreen
        case 0.6..<0.8: return .hrBlue
        case 0.4..<0.6: return .hrOrange
        default:      return .hrRed
        }
    }

    private func dataSourceColor(_ source: FusionDataSource) -> Color {
        switch source {
        case .videoOnly: return .hrBlue
        case .watchOnly: return .hrOrange
        case .fused:     return .hrGreen
        }
    }

    private func angleQualityColor(_ angle: Double) -> Color {
        // Ideal attack angle: 5-15 degrees (slight upswing)
        switch angle {
        case 5...15: return .hrGreen
        case 0..<5, 15..<25: return .hrBlue
        default: return .hrOrange
        }
    }

    private func ttcQualityColor(_ ttc: Double) -> Color {
        switch ttc {
        case ...160: return .hrGreen
        case 160..<200: return .hrBlue
        case 200..<250: return .hrOrange
        default: return .hrRed
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    ScrollView {
        ProMetricsCard(
            fusion: FusionResult(
                calibratedBatSpeedMPH: 52.3,
                powerIndex: 78,
                timingScore: 72,
                biomechanicalEfficiency: 81,
                consistencyIndex: 65,
                attackAngleDeg: 8.5,
                timeToContactMS: 168,
                peakRotationalAccel: 1240,
                fusionConfidence: 0.95,
                hasVideoData: true,
                hasWatchData: true,
                sessionMetrics: SessionFusionMetrics(
                    speedDistribution: [42, 45, 43, 47, 44, 46],
                    speedMean: 44.5,
                    speedStdDev: 1.7,
                    speedMin: 42,
                    speedMax: 47,
                    angleDistribution: [8, 10, 7, 12, 9],
                    angleMean: 9.2,
                    angleStdDev: 1.8,
                    sessionConsistencyScore: 72,
                    improvementTrend: 0.5,
                    hitRate: 0.83,
                    totalSwings: 12,
                    totalHits: 10,
                    sessionDurationSeconds: 480,
                    averageHeartRate: 138,
                    peakHeartRate: 165,
                    caloriesBurned: 120
                )
            )
        )
        .padding()
    }
    .background(Color.hrBg)
}
