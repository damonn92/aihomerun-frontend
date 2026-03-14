import SwiftUI

/// Live practice session view — shows real-time swing metrics
struct LiveSessionView: View {
    @EnvironmentObject var viewModel: SessionViewModel
    @State private var showEndConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Timer
                HStack {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                    Text(viewModel.formattedTime)
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                }
                .padding(.bottom, 2)

                // Swing count — big number
                VStack(spacing: 2) {
                    Text("\(viewModel.swingCount)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: viewModel.swingCount)

                    Text("SWINGS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .tracking(2)
                }

                Divider()
                    .padding(.horizontal, 10)

                // Last swing speed
                if viewModel.lastSwingSpeed > 0 {
                    HStack(spacing: 16) {
                        MetricBubble(
                            value: String(format: "%.0f", viewModel.lastSwingSpeed),
                            unit: "mph",
                            label: "LAST",
                            color: speedColor(viewModel.lastSwingSpeed)
                        )

                        MetricBubble(
                            value: String(format: "%.0f", viewModel.bestSwingSpeed),
                            unit: "mph",
                            label: "BEST",
                            color: .green
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Swing Score (new!)
                if viewModel.lastSwingScore > 0 {
                    HStack(spacing: 16) {
                        MetricBubble(
                            value: "\(viewModel.lastSwingScore)",
                            unit: "/100",
                            label: "SCORE",
                            color: scoreColor(viewModel.lastSwingScore)
                        )

                        MetricBubble(
                            value: "\(viewModel.bestSwingScore)",
                            unit: "/100",
                            label: "BEST",
                            color: .yellow
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Average speed & Heart rate
                HStack(spacing: 16) {
                    if viewModel.averageSpeed > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 10))
                                .foregroundStyle(.blue)
                            Text("Avg: \(Int(viewModel.averageSpeed)) mph")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.red)
                        Text(viewModel.formattedHeartRate)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                        if viewModel.heartRate > 0 {
                            Text("bpm")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary.opacity(0.7))
                        }
                    }
                }
                .padding(.top, 4)

                // Last swing detail (if impact detected)
                if let lastSwing = viewModel.currentSession?.swings.last {
                    LastSwingDetail(swing: lastSwing)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // End session button
                Button(role: .destructive) {
                    showEndConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("End Session")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.8))
                .padding(.top, 8)
            }
            .padding(.horizontal, 4)
        }
        .confirmationDialog("End Practice?", isPresented: $showEndConfirmation) {
            Button("End Session", role: .destructive) {
                Task {
                    await viewModel.endSession()
                }
            }
            Button("Continue", role: .cancel) {}
        }
    }

    private func speedColor(_ speed: Double) -> Color {
        switch speed {
        case 0..<30: return .blue
        case 30..<50: return .green
        case 50..<65: return .orange
        default: return .red
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 0..<40: return .red
        case 40..<60: return .orange
        case 60..<80: return .yellow
        default: return .green
        }
    }
}

// MARK: - Metric Bubble

struct MetricBubble: View {
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 1) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(color.opacity(0.7))
            }
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Last Swing Detail

struct LastSwingDetail: View {
    let swing: SwingEvent

    var body: some View {
        VStack(spacing: 4) {
            if let ttc = swing.timeToContactMS {
                HStack {
                    Text("Time to Contact")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(ttc)) ms")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
            }

            if let angle = swing.attackAngleDegrees {
                HStack {
                    Text("Attack Angle")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f°", angle))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
            }

            if let rotAccel = swing.rotationalAcceleration {
                HStack {
                    Text("Rot. Accel")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f rad/s²", rotAccel))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.purple)
                }
            }

            HStack {
                Text("Impact")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(swing.impactDetected ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(swing.impactDetected ? "Hit" : "Miss")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(swing.impactDetected ? .green : .orange)
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    LiveSessionView()
        .environmentObject(SessionViewModel())
}
