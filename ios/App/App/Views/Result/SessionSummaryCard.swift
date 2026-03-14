import SwiftUI
import Charts

/// Comprehensive session overview card combining duration, swing stats, heart rate zones,
/// calorie data, best swing highlight, and improvement trend analysis.
struct SessionSummaryCard: View {
    let session: SwingSession
    let fusionMetrics: SessionFusionMetrics?

    @State private var appeared = false

    // MARK: - Computed Properties

    private var hitRate: Double {
        guard !session.swings.isEmpty else { return 0 }
        return Double(session.hitsCount) / Double(session.swingCount)
    }

    private var bestSwing: SwingEvent? {
        session.swings.max(by: { ($0.swingScore ?? 0) < ($1.swingScore ?? 0) })
    }

    private var durationFormatted: String {
        let mins = Int(session.duration) / 60
        let secs = Int(session.duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var speedSparkline: [Double] {
        session.swings.map { $0.barrelSpeedMPH ?? $0.handSpeedMPH }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            overviewStatsRow
            if speedSparkline.count >= 3 { speedTrendSection }
            if let best = bestSwing { bestSwingSection(best) }
            heartRateSection
            if let fusion = fusionMetrics { improvementSection(fusion) }
        }
        .hrCard()
        .onAppear {
            withAnimation(.spring(duration: 0.5)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Label("Session Summary", systemImage: "chart.xyaxis.line")
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.7)

            Spacer()

            // Session date
            Text(session.startTime, style: .date)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.primary.opacity(0.4))
        }
    }

    // MARK: - Overview Stats Row

    private var overviewStatsRow: some View {
        HStack(spacing: 0) {
            overviewStat(
                icon: "clock.fill",
                iconColor: .hrBlue,
                value: durationFormatted,
                label: "Duration"
            )

            Spacer()

            overviewStat(
                icon: "figure.baseball",
                iconColor: .hrOrange,
                value: "\(session.swingCount)",
                label: "Total Swings"
            )

            Spacer()

            overviewStat(
                icon: "target",
                iconColor: .hrGreen,
                value: String(format: "%.0f%%", hitRate * 100),
                label: "Hit Rate"
            )

            if let cals = session.caloriesBurned ?? fusionMetrics?.caloriesBurned {
                Spacer()
                overviewStat(
                    icon: "flame.fill",
                    iconColor: .hrRed,
                    value: String(format: "%.0f", cals),
                    label: "Calories"
                )
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(duration: 0.5).delay(0.1), value: appeared)
    }

    private func overviewStat(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 30, height: 30)
                .background(iconColor.opacity(0.10))
                .clipShape(Circle())

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.primary.opacity(0.4))
        }
    }

    // MARK: - Speed Trend Sparkline

    private var speedTrendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Speed Trend")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.6))

                Spacer()

                // Min/Max labels
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Text("Min")
                            .font(.system(size: 8))
                            .foregroundStyle(.primary.opacity(0.35))
                        Text(String(format: "%.1f", speedSparkline.min() ?? 0))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary.opacity(0.6))
                    }
                    HStack(spacing: 3) {
                        Text("Max")
                            .font(.system(size: 8))
                            .foregroundStyle(.primary.opacity(0.35))
                        Text(String(format: "%.1f", speedSparkline.max() ?? 0))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.hrGreen)
                    }
                }
            }

            Chart {
                ForEach(Array(speedSparkline.enumerated()), id: \.offset) { index, speed in
                    LineMark(
                        x: .value("Swing", index + 1),
                        y: .value("Speed", speed)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.hrBlue)

                    AreaMark(
                        x: .value("Swing", index + 1),
                        y: .value("Speed", speed)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.hrBlue.opacity(0.25), Color.hrBlue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    PointMark(
                        x: .value("Swing", index + 1),
                        y: .value("Speed", speed)
                    )
                    .foregroundStyle(Color.hrBlue)
                    .symbolSize(16)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 8))
                        .foregroundStyle(.primary.opacity(0.3))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                        .foregroundStyle(.primary.opacity(0.05))
                    AxisValueLabel()
                        .font(.system(size: 8))
                        .foregroundStyle(.primary.opacity(0.3))
                }
            }
            .frame(height: 80)
        }
        .padding(12)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(duration: 0.5).delay(0.15), value: appeared)
    }

    // MARK: - Best Swing Highlight

    private func bestSwingSection(_ swing: SwingEvent) -> some View {
        HStack(spacing: 12) {
            // Crown icon
            ZStack {
                Circle()
                    .fill(Color.hrGold.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "crown.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.hrGold)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Best Swing")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.hrGold)
                    .textCase(.uppercase)
                    .tracking(0.5)

                HStack(spacing: 10) {
                    HStack(spacing: 3) {
                        Text(String(format: "%.1f", swing.barrelSpeedMPH ?? swing.handSpeedMPH))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("mph")
                            .font(.system(size: 10))
                            .foregroundStyle(.primary.opacity(0.4))
                    }

                    if let score = swing.swingScore {
                        HStack(spacing: 3) {
                            Text("Score")
                                .font(.system(size: 9))
                                .foregroundStyle(.primary.opacity(0.4))
                            Text("\(score)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.hrGold)
                        }
                    }
                }
            }

            Spacer()

            if swing.impactDetected {
                Text("HIT")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.hrGreen)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color.hrGold.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.hrGold.opacity(0.15), lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .animation(.spring(duration: 0.5).delay(0.20), value: appeared)
    }

    // MARK: - Heart Rate Section

    private var heartRateSection: some View {
        let avgHR = session.averageHeartRate ?? fusionMetrics?.averageHeartRate
        let peakHR = session.peakHeartRate ?? fusionMetrics?.peakHeartRate

        return Group {
            if avgHR != nil || peakHR != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Heart Rate")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.6))

                    HStack(spacing: 16) {
                        if let avg = avgHR {
                            heartRateItem(
                                label: "Average",
                                value: String(format: "%.0f", avg),
                                zone: heartRateZone(avg),
                                icon: "heart.fill"
                            )
                        }
                        if let peak = peakHR {
                            heartRateItem(
                                label: "Peak",
                                value: String(format: "%.0f", peak),
                                zone: heartRateZone(peak),
                                icon: "heart.circle.fill"
                            )
                        }
                    }

                    // Heart rate zone bar
                    if let avg = avgHR {
                        heartRateZoneBar(bpm: avg)
                    }
                }
                .padding(12)
                .background(Color.primary.opacity(0.02))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.5).delay(0.25), value: appeared)
            }
        }
    }

    private func heartRateItem(label: String, value: String, zone: HeartRateZone, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(zone.color)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 3) {
                    Text(value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("bpm")
                        .font(.system(size: 9))
                        .foregroundStyle(.primary.opacity(0.4))
                }
                Text("\(label) - \(zone.label)")
                    .font(.system(size: 9))
                    .foregroundStyle(zone.color)
            }
        }
    }

    private func heartRateZoneBar(bpm: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Zone segments
                HStack(spacing: 2) {
                    ForEach(HeartRateZone.allCases, id: \.self) { zone in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(zone.color.opacity(0.25))
                            .overlay(
                                Text(zone.label)
                                    .font(.system(size: 6, weight: .medium))
                                    .foregroundStyle(zone.color.opacity(0.7))
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            )
                    }
                }
                .frame(height: 16)

                // Current position indicator
                let position = heartRatePosition(bpm: bpm, totalWidth: geo.size.width)
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                    .offset(x: position - 4)
            }
        }
        .frame(height: 16)
    }

    // MARK: - Improvement Trend

    private func improvementSection(_ fusion: SessionFusionMetrics) -> some View {
        let trend = fusion.improvementTrend
        let isImproving = trend > 0.1
        let isDeclining = trend < -0.1

        return HStack(spacing: 10) {
            Image(systemName: isImproving ? "arrow.up.right.circle.fill" :
                    isDeclining ? "arrow.down.right.circle.fill" : "equal.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(isImproving ? Color.hrGreen : isDeclining ? Color.hrOrange : Color.hrBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text(isImproving ? "Getting Stronger" : isDeclining ? "Fatigue Setting In" : "Steady Performance")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(isImproving
                     ? "Speed is trending up through the session"
                     : isDeclining
                     ? "Consider taking a break to maintain quality"
                     : "Consistent performance throughout session")
                    .font(.system(size: 10))
                    .foregroundStyle(.primary.opacity(0.5))
            }

            Spacer()

            // Trend value
            Text(String(format: "%+.1f%%", trend * 100))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(isImproving ? Color.hrGreen : isDeclining ? Color.hrOrange : Color.hrBlue)
        }
        .padding(12)
        .background(
            (isImproving ? Color.hrGreen : isDeclining ? Color.hrOrange : Color.hrBlue).opacity(0.04)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    (isImproving ? Color.hrGreen : isDeclining ? Color.hrOrange : Color.hrBlue).opacity(0.12),
                    lineWidth: 1
                )
        )
        .opacity(appeared ? 1 : 0)
        .animation(.spring(duration: 0.5).delay(0.30), value: appeared)
    }

    // MARK: - Heart Rate Helpers

    private enum HeartRateZone: CaseIterable {
        case rest, fatBurn, cardio, peak

        var label: String {
            switch self {
            case .rest: return "Rest"
            case .fatBurn: return "Fat Burn"
            case .cardio: return "Cardio"
            case .peak: return "Peak"
            }
        }

        var color: Color {
            switch self {
            case .rest: return Color(red: 0.4, green: 0.7, blue: 1.0)
            case .fatBurn: return .hrGreen
            case .cardio: return .hrOrange
            case .peak: return .hrRed
            }
        }

        var bpmRange: ClosedRange<Double> {
            switch self {
            case .rest: return 60...100
            case .fatBurn: return 100...130
            case .cardio: return 130...160
            case .peak: return 160...200
            }
        }
    }

    private func heartRateZone(_ bpm: Double) -> HeartRateZone {
        switch bpm {
        case ...100: return .rest
        case 100..<130: return .fatBurn
        case 130..<160: return .cardio
        default: return .peak
        }
    }

    private func heartRatePosition(bpm: Double, totalWidth: CGFloat) -> CGFloat {
        let normalized = (bpm - 60) / 140  // 60-200 range
        return max(4, min(totalWidth - 4, totalWidth * normalized))
    }
}

#Preview {
    ScrollView {
        SessionSummaryCard(
            session: {
                var s = SwingSession(
                    playerName: "Alex",
                    playerAge: 12,
                    battingHand: .right,
                    practiceMode: .standard,
                    watchModel: "Apple Watch Series 9",
                    sensorRate: .highFrequency
                )
                s.swings = [
                    SwingEvent(handSpeedMPH: 18.2, peakAccelerationG: 12.5, timeToContactMS: 175,
                               attackAngleDegrees: 8.5, swingDurationMS: 185, impactDetected: true,
                               rotationRateDPS: 1250, swingScore: 78, barrelSpeedMPH: 48.2),
                    SwingEvent(handSpeedMPH: 16.8, peakAccelerationG: 11.2, timeToContactMS: 195,
                               attackAngleDegrees: 12.1, swingDurationMS: 210, impactDetected: false,
                               rotationRateDPS: 1100, swingScore: 65, barrelSpeedMPH: 44.8),
                    SwingEvent(handSpeedMPH: 19.5, peakAccelerationG: 13.8, timeToContactMS: 162,
                               attackAngleDegrees: 6.2, swingDurationMS: 172, impactDetected: true,
                               rotationRateDPS: 1380, swingScore: 88, barrelSpeedMPH: 52.1),
                    SwingEvent(handSpeedMPH: 17.5, peakAccelerationG: 12.0, timeToContactMS: 188,
                               attackAngleDegrees: 9.8, swingDurationMS: 195, impactDetected: true,
                               rotationRateDPS: 1180, swingScore: 72, barrelSpeedMPH: 46.5),
                ]
                s.averageHeartRate = 138
                s.peakHeartRate = 165
                s.caloriesBurned = 95
                s.endTime = Date().addingTimeInterval(-120)
                return s
            }(),
            fusionMetrics: SessionFusionMetrics(
                speedDistribution: [48.2, 44.8, 52.1, 46.5],
                speedMean: 47.9,
                speedStdDev: 2.8,
                speedMin: 44.8,
                speedMax: 52.1,
                angleDistribution: [8.5, 12.1, 6.2, 9.8],
                angleMean: 9.15,
                angleStdDev: 2.1,
                sessionConsistencyScore: 68,
                improvementTrend: 0.35,
                hitRate: 0.75,
                totalSwings: 4,
                totalHits: 3,
                sessionDurationSeconds: 480,
                averageHeartRate: 138,
                peakHeartRate: 165,
                caloriesBurned: 95
            )
        )
        .padding()
    }
    .background(Color.hrBg)
}
