import SwiftUI

/// Session complete summary view
struct SessionCompleteView: View {
    @EnvironmentObject var viewModel: SessionViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
                    .padding(.top, 4)

                Text("Practice Complete!")
                    .font(.system(size: 16, weight: .bold))

                // Duration
                if let session = viewModel.currentSession {
                    Text(formatDuration(session.duration))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .padding(.horizontal, 8)

                // Summary stats
                if let session = viewModel.currentSession {
                    VStack(spacing: 8) {
                        SummaryRow(
                            icon: "figure.baseball",
                            label: "Total Swings",
                            value: "\(session.swingCount)",
                            color: .blue
                        )

                        SummaryRow(
                            icon: "bolt.fill",
                            label: "Best Speed",
                            value: "\(Int(session.maxHandSpeed)) mph",
                            color: .green
                        )

                        SummaryRow(
                            icon: "chart.line.uptrend.xyaxis",
                            label: "Avg Speed",
                            value: "\(Int(session.averageHandSpeed)) mph",
                            color: .blue
                        )

                        SummaryRow(
                            icon: "target",
                            label: "Hits",
                            value: "\(session.hitsCount)/\(session.swingCount)",
                            color: .orange
                        )

                        if let ttc = session.averageTimeToContact {
                            SummaryRow(
                                icon: "timer",
                                label: "Avg Contact Time",
                                value: "\(Int(ttc)) ms",
                                color: .purple
                            )
                        }

                        if let avgScore = session.averageSwingScore {
                            SummaryRow(
                                icon: "star.fill",
                                label: "Avg Score",
                                value: "\(Int(avgScore))/100",
                                color: .yellow
                            )
                        }

                        if let bestScore = session.bestSwingScore {
                            SummaryRow(
                                icon: "trophy.fill",
                                label: "Best Score",
                                value: "\(bestScore)/100",
                                color: .yellow
                            )
                        }

                        if let rotAccel = session.averageRotationalAcceleration {
                            SummaryRow(
                                icon: "arrow.triangle.2.circlepath",
                                label: "Avg Rot. Accel",
                                value: String(format: "%.0f rad/s²", rotAccel),
                                color: .purple
                            )
                        }

                        if let hr = session.averageHeartRate, hr > 0 {
                            SummaryRow(
                                icon: "heart.fill",
                                label: "Avg Heart Rate",
                                value: "\(Int(hr)) bpm",
                                color: .red
                            )
                        }

                        if let cal = session.caloriesBurned, cal > 0 {
                            SummaryRow(
                                icon: "flame.fill",
                                label: "Calories",
                                value: "\(Int(cal)) kcal",
                                color: .orange
                            )
                        }
                    }
                }

                Divider()
                    .padding(.horizontal, 8)

                // iPhone prompt
                HStack(spacing: 6) {
                    Image(systemName: "iphone")
                        .font(.system(size: 12))
                        .foregroundStyle(.blue)
                    Text("Open iPhone for full analysis")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                // New session button
                Button {
                    viewModel.state = .idle
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("New Session")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.horizontal, 4)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

// MARK: - Summary Row

struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
    }
}

#Preview {
    SessionCompleteView()
        .environmentObject(SessionViewModel())
}
