import SwiftUI

struct CompareCardView: View {
    let previous: SessionSummary
    let current: Feedback

    private struct Metric {
        let label: String
        let icon: String
        let prev: Int
        let curr: Int
        var delta: Int { curr - prev }
    }

    private var metrics: [Metric] {
        [
            Metric(label: "Overall",   icon: "star.fill",       prev: previous.overallScore   ?? 0, curr: current.overallScore),
            Metric(label: "Technique", icon: "figure.baseball", prev: previous.techniqueScore ?? 0, curr: current.techniqueScore),
            Metric(label: "Power",     icon: "bolt.fill",       prev: previous.powerScore     ?? 0, curr: current.powerScore),
            Metric(label: "Balance",   icon: "figure.stand",    prev: previous.balanceScore   ?? 0, curr: current.balanceScore),
        ]
    }

    private var mostImproved: Metric? {
        metrics.filter { $0.delta > 0 }.max(by: { $0.delta < $1.delta })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Label("vs. Last Session", systemImage: "arrow.left.arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.7)
                Spacer()
            }

            // Most improved callout
            if let best = mostImproved, best.delta >= 3 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color.hrOrange)
                    Text("\(best.label) improved most (+\(best.delta) pts)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.hrOrange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.hrOrange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Metric rows
            VStack(spacing: 0) {
                ForEach(metrics, id: \.label) { metric in
                    HStack(spacing: 10) {
                        Image(systemName: metric.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.hrBlue)
                            .frame(width: 20)

                        Text(metric.label)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.65))

                        Spacer()

                        // Previous → Current
                        HStack(spacing: 6) {
                            Text("\(metric.prev)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.35))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.22))

                            Text("\(metric.curr)")
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.white)
                        }

                        DeltaBadge(delta: metric.delta)
                    }
                    .padding(.vertical, 10)

                    if metric.label != metrics.last?.label {
                        Divider().background(Color.white.opacity(0.07))
                    }
                }
            }
        }
        .hrCard()
    }
}

struct DeltaBadge: View {
    let delta: Int

    var body: some View {
        Group {
            if delta == 0 {
                Text("—")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.28))
                    .frame(width: 34)
            } else {
                Text("\(delta > 0 ? "+" : "")\(delta)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(delta > 0 ? Color.hrGreen : Color.hrRed)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background((delta > 0 ? Color.hrGreen : Color.hrRed).opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }
}
