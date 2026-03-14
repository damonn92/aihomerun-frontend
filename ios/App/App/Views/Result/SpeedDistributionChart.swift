import SwiftUI
import Charts

/// Professional speed distribution histogram for swing session data.
/// Shows swing speed buckets with color-coded zones and mean reference line.
struct SpeedDistributionChart: View {
    let speeds: [Double]
    let meanSpeed: Double
    let stdDev: Double
    var title: String = "Speed Distribution"

    @State private var animationProgress: CGFloat = 0

    private var buckets: [SpeedBucket] {
        guard !speeds.isEmpty else { return [] }
        let minSpeed = (speeds.min() ?? 0)
        let maxSpeed = (speeds.max() ?? 0)
        let range = maxSpeed - minSpeed
        let bucketCount = min(8, max(4, speeds.count / 3))
        let bucketWidth = range / Double(bucketCount)

        guard bucketWidth > 0 else {
            return [SpeedBucket(
                rangeStart: minSpeed,
                rangeEnd: maxSpeed,
                count: speeds.count,
                zone: speedZone(for: meanSpeed)
            )]
        }

        var result: [SpeedBucket] = []
        for i in 0..<bucketCount {
            let start = minSpeed + Double(i) * bucketWidth
            let end = start + bucketWidth
            let count = speeds.filter { s in
                i == bucketCount - 1 ? s >= start && s <= end : s >= start && s < end
            }.count
            let midpoint = (start + end) / 2
            result.append(SpeedBucket(
                rangeStart: start,
                rangeEnd: end,
                count: count,
                zone: speedZone(for: midpoint)
            ))
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label(title, systemImage: "chart.bar.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary.opacity(0.55))
                    .textCase(.uppercase)
                    .tracking(0.7)

                Spacer()

                // Zone legend
                HStack(spacing: 8) {
                    zoneLegendDot("Elite", color: .hrGreen)
                    zoneLegendDot("Good", color: .hrBlue)
                    zoneLegendDot("Avg", color: .hrOrange)
                }
            }

            if !buckets.isEmpty {
                Chart {
                    ForEach(Array(buckets.enumerated()), id: \.offset) { index, bucket in
                        BarMark(
                            x: .value("Speed", bucket.label),
                            y: .value("Count", Double(bucket.count) * animationProgress)
                        )
                        .foregroundStyle(bucket.zone.color.gradient)
                        .cornerRadius(4)
                    }

                    // Mean line
                    RuleMark(x: .value("Mean", meanLabel))
                        .foregroundStyle(.primary.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .annotation(position: .top, alignment: .center) {
                            Text("Avg \(String(format: "%.1f", meanSpeed))")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.primary.opacity(0.5))
                        }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 8))
                            .foregroundStyle(.primary.opacity(0.4))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(.primary.opacity(0.06))
                        AxisValueLabel()
                            .font(.system(size: 9))
                            .foregroundStyle(.primary.opacity(0.35))
                    }
                }
                .frame(height: 140)
            }

            // Stats row
            HStack(spacing: 0) {
                statItem("Min", value: String(format: "%.1f", speeds.min() ?? 0), unit: "mph")
                Spacer()
                statItem("Mean", value: String(format: "%.1f", meanSpeed), unit: "mph")
                Spacer()
                statItem("Max", value: String(format: "%.1f", speeds.max() ?? 0), unit: "mph")
                Spacer()
                statItem("Std Dev", value: String(format: "%.1f", stdDev), unit: "mph")
            }
        }
        .hrCard()
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.15).delay(0.2)) {
                animationProgress = 1.0
            }
        }
    }

    private var meanLabel: String {
        // Find the bucket that contains the mean
        if let bucket = buckets.first(where: { meanSpeed >= $0.rangeStart && meanSpeed <= $0.rangeEnd }) {
            return bucket.label
        }
        return buckets.first?.label ?? ""
    }

    private func zoneLegendDot(_ label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(label).font(.system(size: 8)).foregroundStyle(.primary.opacity(0.45))
        }
    }

    private func statItem(_ label: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.primary.opacity(0.4))
        }
    }

    private func speedZone(for speed: Double) -> SpeedZoneType {
        let z = stdDev > 0 ? (speed - meanSpeed) / stdDev : 0
        if z > 1.0 { return .elite }
        if z > -0.5 { return .good }
        return .average
    }
}

// MARK: - Supporting Types

private struct SpeedBucket {
    let rangeStart: Double
    let rangeEnd: Double
    let count: Int
    let zone: SpeedZoneType

    var label: String {
        String(format: "%.0f", (rangeStart + rangeEnd) / 2)
    }
}

private enum SpeedZoneType {
    case elite, good, average

    var color: Color {
        switch self {
        case .elite:   return .hrGreen
        case .good:    return .hrBlue
        case .average: return .hrOrange
        }
    }
}

#Preview {
    SpeedDistributionChart(
        speeds: [42.5, 45.1, 43.8, 46.2, 41.9, 44.7, 47.3, 43.1, 45.8, 42.0, 48.1, 44.2],
        meanSpeed: 44.6,
        stdDev: 1.9
    )
    .padding()
    .background(Color.hrBg)
}
