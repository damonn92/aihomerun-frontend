import SwiftUI
import Charts

struct GrowthChartView: View {
    let history: [SessionSummary]
    let currentScore: Int

    private var chartData: [(index: Int, score: Int, label: String)] {
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
            return (index: i, score: s.overallScore ?? 0, label: label)
        }
    }

    private var delta: Int {
        guard chartData.count >= 2 else { return 0 }
        return (chartData.last?.score ?? 0) - (chartData.first?.score ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.7)

                Spacer()

                if delta != 0 {
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
            }

            // Chart
            Chart(chartData, id: \.index) { item in
                // Area fill
                AreaMark(
                    x: .value("Session", item.label),
                    y: .value("Score", item.score)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.hrBlue.opacity(0.28), Color.hrBlue.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                // Line
                LineMark(
                    x: .value("Session", item.label),
                    y: .value("Score", item.score)
                )
                .foregroundStyle(Color.hrBlue)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)

                // Points
                PointMark(
                    x: .value("Session", item.label),
                    y: .value("Score", item.score)
                )
                .foregroundStyle(.white)
                .symbolSize(28)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        Text(value.as(String.self) ?? "")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.38))
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.28))
                    }
                }
            }
            .frame(height: 130)
        }
        .hrCard()
    }
}
