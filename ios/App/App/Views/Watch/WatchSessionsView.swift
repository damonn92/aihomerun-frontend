import SwiftUI

/// iPhone view showing Watch practice sessions
struct WatchSessionsView: View {
    @StateObject private var manager = WatchSessionManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "applewatch")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.hrBlue)
                    Text("Watch Sessions")
                        .font(.system(size: 22, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal, 20)

                // Live session card (if active)
                if manager.isWatchSessionActive {
                    LiveWatchCard(
                        swingCount: manager.liveSwingCount,
                        lastSpeed: manager.liveLastSpeed,
                        bestSpeed: manager.liveBestSpeed,
                        heartRate: manager.liveHeartRate
                    )
                    .padding(.horizontal, 20)
                }

                // Connection status
                WatchConnectionBanner(isConnected: manager.isWatchConnected)
                    .padding(.horizontal, 20)

                // Session list
                if manager.sessions.isEmpty {
                    EmptyWatchView()
                        .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(manager.sessions) { session in
                            WatchSessionCard(session: session)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 16)
        }
        .background(Color.hrBg)
    }
}

// MARK: - Live Watch Card

struct LiveWatchCard: View {
    let swingCount: Int
    let lastSpeed: Double
    let bestSpeed: Double
    let heartRate: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .fill(.green.opacity(0.3))
                                .frame(width: 16, height: 16)
                        )
                    Text("Live Session")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.green)
                }
                Spacer()
                Image(systemName: "applewatch")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 20) {
                VStack {
                    Text("\(swingCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("Swings")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("\(Int(lastSpeed))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.hrBlue)
                    Text("Last mph")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                VStack {
                    Text("\(Int(bestSpeed))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.hrGreen)
                    Text("Best mph")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            if heartRate > 0 {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                    Text("\(Int(heartRate)) bpm")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
        )
    }
}

// MARK: - Watch Session Card

struct WatchSessionCard: View {
    let session: SwingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.startTime, style: .date)
                        .font(.system(size: 14, weight: .semibold))
                    Text(session.startTime, style: .time)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatDuration(session.duration))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text(session.battingHand.abbreviation)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.hrBlue.opacity(0.15))
                            .clipShape(Capsule())

                        Text(session.sensorRate.rawValue)
                            .font(.system(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                session.sensorRate == .highFrequency ?
                                Color.hrGreen.opacity(0.15) : Color.hrOrange.opacity(0.15)
                            )
                            .clipShape(Capsule())
                    }
                }
            }

            // Metrics grid
            HStack(spacing: 0) {
                MetricCell(value: "\(session.swingCount)", label: "Swings", icon: "figure.baseball")
                MetricCell(value: "\(Int(session.maxHandSpeed))", label: "Best mph", icon: "bolt.fill")
                MetricCell(value: "\(Int(session.averageHandSpeed))", label: "Avg mph", icon: "chart.line.uptrend.xyaxis")
                MetricCell(value: "\(session.hitsCount)", label: "Hits", icon: "target")
            }

            // Health stats
            if let hr = session.averageHeartRate, hr > 0 {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.red)
                        Text("Avg \(Int(hr)) bpm")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    if let cal = session.caloriesBurned, cal > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                            Text("\(Int(cal)) kcal")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .hrCard(padding: 16)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
    }
}

// MARK: - Metric Cell

struct MetricCell: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.hrBlue)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Connection Banner

struct WatchConnectionBanner: View {
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isConnected ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                .font(.system(size: 14))
                .foregroundStyle(isConnected ? .green : .secondary)
            Text(isConnected ? "Apple Watch Connected" : "Apple Watch Not Connected")
                .font(.system(size: 13))
                .foregroundStyle(isConnected ? .primary : .secondary)
            Spacer()
            if isConnected {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(12)
        .background(isConnected ? Color.hrGreen.opacity(0.08) : Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Empty State

struct EmptyWatchView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "applewatch")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("No Watch Sessions Yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Start a practice session on your\nApple Watch to see swing data here")
                .font(.system(size: 14))
                .foregroundStyle(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                StepRow(number: 1, text: "Open AIHomeRun on Apple Watch")
                StepRow(number: 2, text: "Select batting hand")
                StepRow(number: 3, text: "Tap \"Start Practice\"")
                StepRow(number: 4, text: "Swing away! Data syncs automatically")
            }
            .padding(16)
            .background(Color.hrCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 32)
    }
}

struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.hrBlue)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.primary.opacity(0.8))
        }
    }
}

#Preview {
    WatchSessionsView()
}
