import SwiftUI
import Charts

/// Compact sparkline mini chart for embedding inside metric cards.
/// Shows a trend line with gradient area fill, no axes or labels.
struct MetricTrendMiniChart: View {
    let dataPoints: [Double]
    var accentColor: Color = .hrBlue
    var width: CGFloat = 60
    var height: CGFloat = 28

    var body: some View {
        if dataPoints.count >= 2 {
            Chart {
                ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(accentColor)

                    AreaMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor.opacity(0.3), accentColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .frame(width: width, height: height)
        }
    }
}

/// Shows a delta badge with arrow and value change
struct TrendDeltaBadge: View {
    let current: Double
    let previous: Double
    var format: String = "%.0f"

    private var delta: Double { current - previous }
    private var isPositive: Bool { delta >= 0 }

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 7, weight: .bold))
            Text(String(format: format, abs(delta)))
                .font(.system(size: 9, weight: .bold, design: .rounded))
        }
        .foregroundStyle(isPositive ? Color.hrGreen : Color.hrRed)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background((isPositive ? Color.hrGreen : Color.hrRed).opacity(0.12))
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 20) {
        MetricTrendMiniChart(
            dataPoints: [45, 52, 48, 55, 60, 58, 63],
            accentColor: .hrBlue
        )

        MetricTrendMiniChart(
            dataPoints: [20, 18, 22, 25, 23, 28],
            accentColor: .hrGreen
        )

        TrendDeltaBadge(current: 65, previous: 58)
        TrendDeltaBadge(current: 42, previous: 55)
    }
    .padding()
    .background(Color.hrBg)
}
