import SwiftUI
import Charts

struct GrowthChartView: View {
    let history: [SessionSummary]
    let currentScore: Int
    @State private var selectedMetric: ScoreMetric = .overall

    enum ScoreMetric: String, CaseIterable {
        case overall = "Overall"
        case technique = "Technique"
        case power = "Power"
        case balance = "Balance"

        var color: Color {
            switch self {
            case .overall:   return .hrBlue
            case .technique: return .hrBlue
            case .power:     return .hrOrange
            case .balance:   return .hrGreen
            }
        }

        var icon: String {
            switch self {
            case .overall:   return "star.fill"
            case .technique: return "figure.baseball"
            case .power:     return "bolt.fill"
            case .balance:   return "figure.stand"
            }
        }
    }

    private struct ChartPoint: Identifiable {
        let id: Int
        let label: String
        let score: Int
    }

    private func chartData(for metric: ScoreMetric) -> [ChartPoint] {
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let short = DateFormatter()
        short.dateFormat = "MMM d"

        return history.enumerated().map { i, s in
            let label: String
            if let str = s.createdAt, let date = iso.date(from: str) {
                label = short.string(from: date)
            } else {
                label = "S\(i + 1)"
            }
            let score: Int
            switch metric {
            case .overall:   score = s.overallScore ?? 0
            case .technique: score = s.techniqueScore ?? 0
            case .power:     score = s.powerScore ?? 0
            case .balance:   score = s.balanceScore ?? 0
            }
            return ChartPoint(id: i, label: label, score: score)
        }
    }

    private var currentData: [ChartPoint] { chartData(for: selectedMetric) }

    private var delta: Int {
        guard currentData.count >= 2 else { return 0 }
        return (currentData.last?.score ?? 0) - (currentData.first?.score ?? 0)
    }

    private var average: Int {
        guard !currentData.isEmpty else { return 0 }
        return currentData.map(\.score).reduce(0, +) / currentData.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection
            metricPicker
            chartSection
            statsRow
        }
        .hrCard()
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.7)

            Spacer()

            if delta != 0 {
                deltaBadge
            }
        }
    }

    private var deltaBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: delta > 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption.weight(.bold))
            Text("\(delta > 0 ? "+" : "")\(delta) pts")
                .font(.subheadline.weight(.bold).monospacedDigit())
        }
        .foregroundStyle(delta > 0 ? Color.hrGreen : Color.hrRed)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background((delta > 0 ? Color.hrGreen : Color.hrRed).opacity(0.14))
        .clipShape(Capsule())
    }

    // MARK: - Metric Picker

    private var metricPicker: some View {
        HStack(spacing: 6) {
            ForEach(ScoreMetric.allCases, id: \.self) { metric in
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedMetric = metric
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: metric.icon)
                            .font(.system(size: 9))
                        Text(metric.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(selectedMetric == metric ? metric.color.opacity(0.18) : Color.primary.opacity(0.04))
                    .foregroundStyle(selectedMetric == metric ? metric.color : .primary.opacity(0.5))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            selectedMetric == metric ? metric.color.opacity(0.4) : Color.clear,
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        Chart(currentData) { item in
            AreaMark(
                x: .value("Session", item.label),
                y: .value("Score", item.score)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [selectedMetric.color.opacity(0.28), selectedMetric.color.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Session", item.label),
                y: .value("Score", item.score)
            )
            .foregroundStyle(selectedMetric.color)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Session", item.label),
                y: .value("Score", item.score)
            )
            .foregroundStyle(selectedMetric.color)
            .symbolSize(32)

            // Average reference line
            RuleMark(y: .value("Average", average))
                .foregroundStyle(.primary.opacity(0.15))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("avg \(average)")
                        .font(.system(size: 8))
                        .foregroundStyle(.primary.opacity(0.3))
                }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    Text(value.as(String.self) ?? "")
                        .font(.system(size: 10))
                        .foregroundStyle(.primary.opacity(0.50))
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.hrDivider)
                AxisValueLabel {
                    Text("\(value.as(Int.self) ?? 0)")
                        .font(.system(size: 9))
                        .foregroundStyle(.primary.opacity(0.35))
                }
            }
        }
        .frame(height: 160)
        .animation(.spring(duration: 0.4), value: selectedMetric)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(label: "Sessions", value: "\(currentData.count)", icon: "number")
            Divider().frame(height: 24)
            statItem(label: "Average", value: "\(average)", icon: "chart.bar")
            Divider().frame(height: 24)
            statItem(label: "Best", value: "\(currentData.map(\.score).max() ?? 0)", icon: "trophy")
            Divider().frame(height: 24)
            statItem(label: "Latest", value: "\(currentData.last?.score ?? 0)", icon: "clock")
        }
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func statItem(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundStyle(selectedMetric.color.opacity(0.6))
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.primary.opacity(0.45))
            }
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}
