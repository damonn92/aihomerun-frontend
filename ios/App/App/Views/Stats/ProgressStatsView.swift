import SwiftUI
import Charts

// MARK: - Progress Stats View

struct ProgressStatsView: View {
    let sessions: [SessionSummary]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedChartMetric: ChartMetric = .overall

    enum ChartMetric: String, CaseIterable {
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

        func score(from session: SessionSummary) -> Int? {
            switch self {
            case .overall:   return session.overallScore
            case .technique: return session.techniqueScore
            case .power:     return session.powerScore
            case .balance:   return session.balanceScore
            }
        }
    }

    // MARK: Computed Stats

    private var scores: [Int] { sessions.compactMap(\.overallScore) }
    private var avgOverall: Int {
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / scores.count
    }
    private var avgTechnique: Int {
        let s = sessions.compactMap(\.techniqueScore)
        guard !s.isEmpty else { return 0 }
        return s.reduce(0, +) / s.count
    }
    private var avgPower: Int {
        let s = sessions.compactMap(\.powerScore)
        guard !s.isEmpty else { return 0 }
        return s.reduce(0, +) / s.count
    }
    private var avgBalance: Int {
        let s = sessions.compactMap(\.balanceScore)
        guard !s.isEmpty else { return 0 }
        return s.reduce(0, +) / s.count
    }
    private var trend: Int {
        guard scores.count >= 2 else { return 0 }
        return (scores.last ?? 0) - (scores.first ?? 0)
    }
    private var bestScore: Int { scores.max() ?? 0 }

    // Chart data
    private func chartData(for metric: ChartMetric) -> [(index: Int, score: Int, label: String)] {
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let short = DateFormatter()
        short.dateFormat = "M/d"

        return sessions.enumerated().map { i, s in
            let label: String
            if let str = s.createdAt, let date = iso.date(from: str) {
                label = short.string(from: date)
            } else {
                label = "#\(i + 1)"
            }
            return (index: i, score: metric.score(from: s) ?? 0, label: label)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                if sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            summaryGrid
                            radarOverview
                            if sessions.count >= 2 { progressChart }
                            categoryBreakdown
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Progress Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.primary.opacity(0.35))
                            .font(.title3)
                    }
                }
            }
        }
    }

    // MARK: - Summary Grid (2×2)

    private var summaryGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            statCard(icon: "chart.line.uptrend.xyaxis", iconColor: .hrGreen,
                     value: "\(avgOverall)", label: "Average Score")
            statCard(icon: trend >= 0 ? "arrow.up.right" : "arrow.down.right",
                     iconColor: trend >= 0 ? .hrGreen : .hrRed,
                     value: "\(trend >= 0 ? "+" : "")\(trend)", label: "Trend")
            statCard(icon: "film.stack", iconColor: .hrBlue,
                     value: "\(sessions.count)", label: "Total Sessions")
            statCard(icon: "star.fill", iconColor: .hrGold,
                     value: "\(bestScore)", label: "Best Score")
        }
    }

    private func statCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.primary.opacity(0.45))
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.hrStroke, lineWidth: 1)
        )
    }

    // MARK: - Radar Overview

    private var radarOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Skills Overview", systemImage: "pentagon")
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary.opacity(0.50))
                .textCase(.uppercase)
                .tracking(0.6)

            HStack {
                Spacer()
                RadarChartView(axes: [
                    .init(label: "Technique", value: Double(avgTechnique),
                          icon: "figure.baseball", color: .hrBlue),
                    .init(label: "Power", value: Double(avgPower),
                          icon: "bolt.fill", color: .hrOrange),
                    .init(label: "Balance", value: Double(avgBalance),
                          icon: "figure.stand", color: .hrGreen),
                ], size: 200)
                Spacer()
            }
        }
        .hrCard()
    }

    // MARK: - Progress Chart

    private var progressChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            chartHeader
            chartMetricPicker
            chartBody
        }
        .hrCard()
    }

    private var chartHeader: some View {
        HStack {
            Label("Score Trend", systemImage: "chart.xyaxis.line")
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary.opacity(0.50))
                .textCase(.uppercase)
                .tracking(0.6)

            Spacer()

            if trend != 0 {
                HStack(spacing: 4) {
                    Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption.weight(.bold))
                    Text("\(trend > 0 ? "+" : "")\(trend) pts")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                }
                .foregroundStyle(trend > 0 ? Color.hrGreen : Color.hrRed)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background((trend > 0 ? Color.hrGreen : Color.hrRed).opacity(0.14))
                .clipShape(Capsule())
            }
        }
    }

    private var chartMetricPicker: some View {
        HStack(spacing: 6) {
            ForEach(ChartMetric.allCases, id: \.self) { metric in
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedChartMetric = metric
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
                    .background(selectedChartMetric == metric ? metric.color.opacity(0.18) : Color.primary.opacity(0.04))
                    .foregroundStyle(selectedChartMetric == metric ? metric.color : .primary.opacity(0.5))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(
                            selectedChartMetric == metric ? metric.color.opacity(0.4) : Color.clear,
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var chartBody: some View {
        let data = chartData(for: selectedChartMetric)
        let avg = data.isEmpty ? 0 : data.map(\.score).reduce(0, +) / data.count
        return Chart(data, id: \.index) { item in
            AreaMark(
                x: .value("Session", item.label),
                y: .value("Score", item.score)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [selectedChartMetric.color.opacity(0.28), selectedChartMetric.color.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Session", item.label),
                y: .value("Score", item.score)
            )
            .foregroundStyle(selectedChartMetric.color)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Session", item.label),
                y: .value("Score", item.score)
            )
            .foregroundStyle(selectedChartMetric.color)
            .symbolSize(32)

            RuleMark(y: .value("Average", avg))
                .foregroundStyle(.primary.opacity(0.15))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
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
                        .font(.system(size: 10))
                        .foregroundStyle(.primary.opacity(0.40))
                }
            }
        }
        .frame(height: 180)
        .animation(.spring(duration: 0.4), value: selectedChartMetric)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Category Averages", systemImage: "chart.bar.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary.opacity(0.50))
                .textCase(.uppercase)
                .tracking(0.6)

            categoryRow("Technique", score: avgTechnique, color: .hrBlue, icon: "figure.baseball")
            categoryRow("Power", score: avgPower, color: .hrOrange, icon: "bolt.fill")
            categoryRow("Balance", score: avgBalance, color: .hrGreen, icon: "figure.stand")
        }
        .hrCard()
    }

    private func categoryRow(_ label: String, score: Int, color: Color, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary.opacity(0.65))
                .frame(width: 72, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.10))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.6), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(4, geo.size.width * CGFloat(score) / 100.0), height: 10)
                }
            }
            .frame(height: 10)

            Text("\(score)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 44))
                .foregroundStyle(Color.hrGreen.opacity(0.35))
            Text("No Data Yet")
                .font(.headline)
            Text("Complete some analyses to see\nyour progress statistics.")
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.50))
                .multilineTextAlignment(.center)
        }
    }
}
