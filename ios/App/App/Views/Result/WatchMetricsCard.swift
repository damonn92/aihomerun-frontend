import SwiftUI

/// Dedicated Apple Watch metrics dashboard card showing sensor-derived swing data.
/// Displays a hero barrel speed section, 3x2 grid of circular gauges, and session summary footer.
/// Designed to complement the video-based ProMetricsCard with watch-only sensor insights.
struct WatchMetricsCard: View {
    let session: SwingSession
    @State private var appeared = false

    // MARK: - Computed Properties

    private var bestSwing: SwingEvent? {
        session.swings.max(by: { ($0.swingScore ?? 0) < ($1.swingScore ?? 0) })
    }

    private var heroBarrelSpeed: Double {
        session.averageBarrelSpeed ?? session.averageHandSpeed * 2.2
    }

    private var hitRate: Double {
        guard !session.swings.isEmpty else { return 0 }
        return Double(session.hitsCount) / Double(session.swingCount)
    }

    private var sessionDurationFormatted: String {
        let mins = Int(session.duration) / 60
        let secs = Int(session.duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Age-based Reference Values

    private struct ReferenceValues {
        let barrelSpeedExcellent: Double
        let barrelSpeedGood: Double
        let attackAngleIdeal: ClosedRange<Double>
        let ttcExcellent: Double
        let ttcGood: Double
        let rotAccelExcellent: Double
        let rotAccelGood: Double

        static func forAge(_ age: Int) -> ReferenceValues {
            switch age {
            case ...9:
                return ReferenceValues(
                    barrelSpeedExcellent: 35, barrelSpeedGood: 28,
                    attackAngleIdeal: 5...18, ttcExcellent: 220, ttcGood: 260,
                    rotAccelExcellent: 800, rotAccelGood: 600
                )
            case 10...12:
                return ReferenceValues(
                    barrelSpeedExcellent: 45, barrelSpeedGood: 38,
                    attackAngleIdeal: 5...15, ttcExcellent: 200, ttcGood: 240,
                    rotAccelExcellent: 1000, rotAccelGood: 800
                )
            case 13...15:
                return ReferenceValues(
                    barrelSpeedExcellent: 55, barrelSpeedGood: 46,
                    attackAngleIdeal: 5...15, ttcExcellent: 180, ttcGood: 220,
                    rotAccelExcellent: 1200, rotAccelGood: 950
                )
            default:
                return ReferenceValues(
                    barrelSpeedExcellent: 65, barrelSpeedGood: 55,
                    attackAngleIdeal: 5...15, ttcExcellent: 160, ttcGood: 200,
                    rotAccelExcellent: 1500, rotAccelGood: 1200
                )
            }
        }
    }

    private var refs: ReferenceValues {
        ReferenceValues.forAge(session.playerAge)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            heroBarrelSpeedSection
            metricsGrid
            Divider().background(Color.hrDivider)
            sessionFooter
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
            Label("Watch Metrics", systemImage: "applewatch")
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.7)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 8))
                Text(session.sensorRate.rawValue)
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(Color.hrBlue)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.hrBlue.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    // MARK: - Hero Barrel Speed

    private var heroBarrelSpeedSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", heroBarrelSpeed))
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.6).delay(0.15), value: appeared)

                Text("mph")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.4))

                // Trend arrow based on session improvement
                if session.swings.count >= 3 {
                    trendArrow
                }
            }

            Text("Barrel Speed")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary.opacity(0.5))

            // Quality pill
            let quality = barrelSpeedQuality(heroBarrelSpeed)
            Text(quality.label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(quality.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(quality.color.opacity(0.12))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var trendArrow: some View {
        let speeds = session.swings.compactMap(\.barrelSpeedMPH)
        let trend: Double = {
            guard speeds.count >= 3 else { return 0 }
            let firstHalf = Array(speeds.prefix(speeds.count / 2))
            let secondHalf = Array(speeds.suffix(speeds.count / 2))
            let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
            let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
            return secondAvg - firstAvg
        }()

        return Group {
            if abs(trend) > 0.5 {
                Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(trend > 0 ? Color.hrGreen : Color.hrOrange)
            }
        }
    }

    // MARK: - 3x2 Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
        ], spacing: 12) {
            // Row 1
            attackAngleGauge
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(duration: 0.5).delay(0.10), value: appeared)

            timeToContactGauge
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(duration: 0.5).delay(0.15), value: appeared)

            rotationalAccelGauge
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(duration: 0.5).delay(0.20), value: appeared)

            // Row 2
            snapScoreGauge
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(duration: 0.5).delay(0.25), value: appeared)

            powerTransferGauge
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(duration: 0.5).delay(0.30), value: appeared)

            kineticChainGauge
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.spring(duration: 0.5).delay(0.35), value: appeared)
        }
    }

    private var attackAngleGauge: some View {
        let angles = session.swings.compactMap(\.attackAngleDegrees)
        let avg = angles.isEmpty ? 0 : angles.reduce(0, +) / Double(angles.count)
        let quality = angleQuality(avg)
        let fraction = angles.isEmpty ? 0 : min(1.0, avg / 30.0)

        return MetricGaugeView(
            title: "Attack Angle",
            value: angles.isEmpty ? "--" : String(format: "%.1f", avg),
            unit: "deg",
            fraction: fraction,
            quality: quality,
            icon: "arrow.up.right",
            size: 58
        )
    }

    private var timeToContactGauge: some View {
        let ttcs = session.swings.compactMap(\.timeToContactMS)
        let avg = ttcs.isEmpty ? 0 : ttcs.reduce(0, +) / Double(ttcs.count)
        let quality = ttcQuality(avg)
        // Lower is better: invert fraction
        let fraction = ttcs.isEmpty ? 0 : max(0, 1.0 - (avg - 100) / 200.0)

        return MetricGaugeView(
            title: "Time to Contact",
            value: ttcs.isEmpty ? "--" : String(format: "%.0f", avg),
            unit: "ms",
            fraction: min(1.0, fraction),
            quality: quality,
            icon: "stopwatch.fill",
            size: 58
        )
    }

    private var rotationalAccelGauge: some View {
        let accels = session.swings.compactMap(\.rotationalAcceleration)
        let avg = accels.isEmpty ? 0 : accels.reduce(0, +) / Double(accels.count)
        let quality = rotAccelQuality(avg)
        let fraction = accels.isEmpty ? 0 : min(1.0, avg / (refs.rotAccelExcellent * 1.5))

        return MetricGaugeView(
            title: "Rotational Accel",
            value: accels.isEmpty ? "--" : String(format: "%.0f", avg),
            unit: "rad/s\u{00B2}",
            fraction: fraction,
            quality: quality,
            icon: "arrow.triangle.2.circlepath",
            size: 58
        )
    }

    private var snapScoreGauge: some View {
        let scores = session.swings.compactMap(\.snapScore)
        let avg = scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
        let quality = scoreQuality(avg)

        return MetricGaugeView(
            title: "Snap Score",
            value: scores.isEmpty ? "--" : String(format: "%.0f", avg),
            unit: "/100",
            fraction: scores.isEmpty ? 0 : avg / 100.0,
            quality: quality,
            icon: "hands.clap.fill",
            size: 58
        )
    }

    private var powerTransferGauge: some View {
        let values = session.swings.compactMap(\.powerTransferEfficiency)
        let avg = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        let quality = scoreQuality(avg)

        return MetricGaugeView(
            title: "Power Transfer",
            value: values.isEmpty ? "--" : String(format: "%.0f", avg),
            unit: "%",
            fraction: values.isEmpty ? 0 : avg / 100.0,
            quality: quality,
            icon: "bolt.fill",
            size: 58
        )
    }

    private var kineticChainGauge: some View {
        let values = session.swings.compactMap(\.kineticChainScore)
        let avg = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        let quality = scoreQuality(avg)

        return MetricGaugeView(
            title: "Kinetic Chain",
            value: values.isEmpty ? "--" : String(format: "%.0f", avg),
            unit: "/100",
            fraction: values.isEmpty ? 0 : avg / 100.0,
            quality: quality,
            icon: "link",
            size: 58
        )
    }

    // MARK: - Session Footer

    private var sessionFooter: some View {
        HStack(spacing: 0) {
            footerStat(icon: "figure.baseball", label: "Swings", value: "\(session.swingCount)")
            Spacer()
            footerStat(icon: "target", label: "Hit Rate", value: String(format: "%.0f%%", hitRate * 100))
            Spacer()
            footerStat(icon: "clock.fill", label: "Duration", value: sessionDurationFormatted)
            if let hr = session.averageHeartRate {
                Spacer()
                footerStat(icon: "heart.fill", label: "Avg HR", value: String(format: "%.0f", hr))
            }
        }
    }

    private func footerStat(icon: String, label: String, value: String) -> some View {
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

    // MARK: - Quality Assessors

    private func barrelSpeedQuality(_ speed: Double) -> MetricGaugeView.MetricQuality {
        if speed >= refs.barrelSpeedExcellent { return .excellent }
        if speed >= refs.barrelSpeedGood { return .good }
        if speed >= refs.barrelSpeedGood * 0.8 { return .moderate }
        return .needsWork
    }

    private func angleQuality(_ angle: Double) -> MetricGaugeView.MetricQuality {
        if refs.attackAngleIdeal.contains(angle) { return .excellent }
        let lowerDist = abs(angle - refs.attackAngleIdeal.lowerBound)
        let upperDist = abs(angle - refs.attackAngleIdeal.upperBound)
        let dist = min(lowerDist, upperDist)
        if dist < 5 { return .good }
        if dist < 10 { return .moderate }
        return .needsWork
    }

    private func ttcQuality(_ ttc: Double) -> MetricGaugeView.MetricQuality {
        if ttc <= refs.ttcExcellent { return .excellent }
        if ttc <= refs.ttcGood { return .good }
        if ttc <= refs.ttcGood * 1.2 { return .moderate }
        return .needsWork
    }

    private func rotAccelQuality(_ accel: Double) -> MetricGaugeView.MetricQuality {
        if accel >= refs.rotAccelExcellent { return .excellent }
        if accel >= refs.rotAccelGood { return .good }
        if accel >= refs.rotAccelGood * 0.7 { return .moderate }
        return .needsWork
    }

    private func scoreQuality(_ score: Double) -> MetricGaugeView.MetricQuality {
        switch score {
        case 80...: return .excellent
        case 60..<80: return .good
        case 40..<60: return .moderate
        default: return .needsWork
        }
    }
}

#Preview {
    ScrollView {
        WatchMetricsCard(
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
                               rotationRateDPS: 1250, rotationalAcceleration: 1100, swingScore: 78,
                               barrelSpeedMPH: 48.2, powerTransferEfficiency: 72, snapScore: 81,
                               kineticChainScore: 75),
                    SwingEvent(handSpeedMPH: 16.8, peakAccelerationG: 11.2, timeToContactMS: 195,
                               attackAngleDegrees: 12.1, swingDurationMS: 210, impactDetected: false,
                               rotationRateDPS: 1100, rotationalAcceleration: 950, swingScore: 65,
                               barrelSpeedMPH: 44.8, powerTransferEfficiency: 65, snapScore: 68,
                               kineticChainScore: 62),
                    SwingEvent(handSpeedMPH: 19.5, peakAccelerationG: 13.8, timeToContactMS: 162,
                               attackAngleDegrees: 6.2, swingDurationMS: 172, impactDetected: true,
                               rotationRateDPS: 1380, rotationalAcceleration: 1250, swingScore: 88,
                               barrelSpeedMPH: 52.1, powerTransferEfficiency: 85, snapScore: 90,
                               kineticChainScore: 84),
                ]
                s.averageHeartRate = 142
                s.peakHeartRate = 168
                s.caloriesBurned = 95
                s.endTime = Date().addingTimeInterval(-60)
                return s
            }()
        )
        .padding()
    }
    .background(Color.hrBg)
}
