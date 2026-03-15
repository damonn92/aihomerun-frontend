import SwiftUI
import HealthKit

/// Training dashboard — Apple Watch integration hub with HealthKit data below
struct TrainingView: View {
    @StateObject private var healthService = HealthKitService.shared
    @StateObject private var watchManager = WatchSessionManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        // Hero: Apple Watch status
                        if watchManager.isWatchConnected {
                            watchConnectedHero
                        } else {
                            watchNotConnectedHero
                        }

                        // Live Watch session (if active)
                        if watchManager.isWatchSessionActive {
                            liveSessionBanner
                        }

                        // How it works (only when not connected)
                        if !watchManager.isWatchConnected {
                            howItWorksCard
                        }

                        // Quick Start button (when connected but no active session)
                        if watchManager.isWatchConnected && !watchManager.isWatchSessionActive {
                            startSessionButton
                        }

                        // HealthKit section
                        if !healthService.isAvailable {
                            healthKitUnavailableCard
                        } else if !healthService.isAuthorized {
                            healthKitAuthCard
                        } else {
                            // Section header
                            sectionHeader("Health & Activity")

                            todayStatsCard
                            weeklyOverviewCard
                            heartRateCard
                            trainingHistoryCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Apple Watch")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await healthService.fetchAllData()
                watchManager.refreshConnectionStatus()
            }
            .onAppear {
                Task { await healthService.fetchAllData() }
                watchManager.refreshConnectionStatus()
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Watch Connected Hero

    private var watchConnectedHero: some View {
        VStack(spacing: 16) {
            // Watch icon with animated ring
            ZStack {
                Circle()
                    .fill(Color.hrGreen.opacity(0.1))
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(Color.hrGreen.opacity(0.2), lineWidth: 3)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.hrGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "applewatch.radiowaves.left.and.right")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.hrGreen)
            }

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Apple Watch Connected")
                        .font(.system(size: 18, weight: .bold))
                }

                Text(watchManager.isWatchReachable
                     ? "Watch app active — ready to train"
                     : "Open AIHomeRun on Watch to start")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Connection details
            HStack(spacing: 16) {
                WatchStatusPill(
                    icon: "antenna.radiowaves.left.and.right",
                    label: "Paired",
                    color: .hrGreen
                )
                WatchStatusPill(
                    icon: watchManager.isWatchReachable ? "wifi" : "wifi.slash",
                    label: watchManager.isWatchReachable ? "Reachable" : "Not Active",
                    color: watchManager.isWatchReachable ? .hrBlue : .hrOrange
                )
                WatchStatusPill(
                    icon: "heart.fill",
                    label: "HealthKit",
                    color: healthService.isAuthorized ? .hrGreen : .secondary
                )
            }
        }
        .padding(20)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hrGreen.opacity(0.25), lineWidth: 1.5)
        )
    }

    // MARK: - Watch Not Connected Hero

    private var watchNotConnectedHero: some View {
        VStack(spacing: 20) {
            // Watch icon
            ZStack {
                Circle()
                    .fill(Color.hrBlue.opacity(0.08))
                    .frame(width: 110, height: 110)

                // Dashed ring
                Circle()
                    .stroke(Color.hrBlue.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .frame(width: 110, height: 110)

                Image(systemName: "applewatch")
                    .font(.system(size: 42))
                    .foregroundStyle(Color.hrBlue)
            }

            VStack(spacing: 8) {
                Text("Connect Apple Watch")
                    .font(.system(size: 20, weight: .bold))

                Text("Wear your Apple Watch during batting\npractice for real-time swing tracking")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            // Feature highlights
            VStack(spacing: 12) {
                WatchFeatureRow(
                    icon: "figure.baseball",
                    title: "Auto Swing Detection",
                    subtitle: "Detects every swing automatically",
                    color: Color.hrGold
                )
                WatchFeatureRow(
                    icon: "speedometer",
                    title: "Swing Speed",
                    subtitle: "Measure bat speed in real-time",
                    color: Color.hrBlue
                )
                WatchFeatureRow(
                    icon: "heart.fill",
                    title: "Heart Rate Tracking",
                    subtitle: "Monitor intensity during training",
                    color: .red
                )
                WatchFeatureRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Sync with iPhone",
                    subtitle: "Combine video + sensor data for deeper analysis",
                    color: Color.hrGreen
                )
            }
            .padding(.top, 4)

            // Refresh button
            Button {
                watchManager.refreshConnectionStatus()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Check Connection")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.hrBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color.hrBlue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(20)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hrStroke, lineWidth: 1)
        )
    }

    // MARK: - How It Works Card

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.hrBlue)
                Text("How to Set Up")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                SetupStep(number: 1, text: "Pair Apple Watch with your iPhone in Settings")
                SetupStep(number: 2, text: "Install AIHomeRun on your Apple Watch")
                SetupStep(number: 3, text: "Open the Watch app and start a session")
                SetupStep(number: 4, text: "Swing! Data syncs to your iPhone automatically")
            }
        }
        .hrCard()
    }

    // MARK: - Start Session Button

    private var startSessionButton: some View {
        Button {
            let savedAge = UserDefaults.standard.integer(forKey: "com.aihomerun.lastAge")
            watchManager.startWatchSession(
                playerName: "",
                playerAge: (6...18).contains(savedAge) ? savedAge : 12,
                battingHand: .right
            )
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "figure.baseball")
                    .font(.system(size: 16, weight: .semibold))
                Text("Start Training Session")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [Color.hrGreen, Color.hrGreen.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Live Watch Session Banner

    private var liveSessionBanner: some View {
        VStack(spacing: 14) {
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
                Button {
                    watchManager.stopWatchSession()
                } label: {
                    Text("End")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("\(watchManager.liveSwingCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("Swings")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(Int(watchManager.liveLastSpeed))")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.hrBlue)
                    Text("Last mph")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(Int(watchManager.liveBestSpeed))")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.hrGreen)
                    Text("Best mph")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
        )
    }

    // MARK: - Today Stats Card

    private var todayStatsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.hrBlue)
                Text("Today")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text(Date(), style: .date)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                TodayStatCell(
                    value: "\(healthService.todaySteps)",
                    label: "Steps",
                    icon: "figure.walk",
                    color: Color.hrGreen
                )
                TodayStatCell(
                    value: "\(Int(healthService.todayActiveCalories))",
                    label: "Calories",
                    icon: "flame.fill",
                    color: Color.hrOrange
                )
                TodayStatCell(
                    value: "\(Int(healthService.todayExerciseMinutes))",
                    label: "Exercise min",
                    icon: "figure.run",
                    color: Color.hrBlue
                )
                TodayStatCell(
                    value: healthService.restingHeartRate > 0 ? "\(Int(healthService.restingHeartRate))" : "--",
                    label: "Resting HR",
                    icon: "heart.fill",
                    color: .red
                )
            }
        }
        .hrCard()
    }

    // MARK: - Weekly Overview Card

    private var weeklyOverviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.hrBlue)
                Text("This Week")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
            }

            HStack(spacing: 16) {
                WeeklyMetricRing(
                    value: Double(healthService.weeklyWorkoutCount),
                    maxValue: 7,
                    label: "Workouts",
                    valueText: "\(healthService.weeklyWorkoutCount)",
                    color: Color.hrBlue
                )

                WeeklyMetricRing(
                    value: healthService.weeklyExerciseMinutes,
                    maxValue: 300,
                    label: "Minutes",
                    valueText: "\(Int(healthService.weeklyExerciseMinutes))",
                    color: Color.hrGreen
                )

                WeeklyMetricRing(
                    value: healthService.weeklyActiveCalories,
                    maxValue: 3500,
                    label: "Calories",
                    valueText: "\(Int(healthService.weeklyActiveCalories))",
                    color: Color.hrOrange
                )
            }
            .frame(maxWidth: .infinity)

            // Baseball workouts this week
            let baseballThisWeek = healthService.weeklyWorkouts.filter { $0.workoutActivityType == .baseball }
            if !baseballThisWeek.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "figure.baseball")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.hrGold)
                    Text("\(baseballThisWeek.count) baseball session\(baseballThisWeek.count == 1 ? "" : "s") this week")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.hrGold.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .hrCard()
    }

    // MARK: - Heart Rate Card

    private var heartRateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.red)
                Text("Heart Rate")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                if healthService.restingHeartRate > 0 {
                    Text("Resting: \(Int(healthService.restingHeartRate)) bpm")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            if healthService.recentHeartRates.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text("No recent heart rate data")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text("Wear your Apple Watch to track")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
            } else {
                // Mini heart rate chart
                HeartRateChartView(samples: healthService.recentHeartRates)
                    .frame(height: 100)

                // Stats row
                let bpms = healthService.recentHeartRates.map(\.bpm)
                let minBPM = bpms.min() ?? 0
                let maxBPM = bpms.max() ?? 0
                let avgBPM = bpms.isEmpty ? 0 : bpms.reduce(0, +) / Double(bpms.count)

                HStack(spacing: 0) {
                    HeartRateStatItem(label: "Min", value: "\(Int(minBPM))", color: Color.hrGreen)
                    HeartRateStatItem(label: "Avg", value: "\(Int(avgBPM))", color: Color.hrBlue)
                    HeartRateStatItem(label: "Max", value: "\(Int(maxBPM))", color: Color.hrRed)
                }
            }
        }
        .hrCard()
    }

    // MARK: - Training History Card

    private var trainingHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "figure.baseball")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.hrGold)
                Text("Training Summary")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
            }

            HStack(spacing: 0) {
                TrainingSummaryCell(
                    value: "\(healthService.totalBaseballWorkouts)",
                    label: "Sessions",
                    icon: "sportscourt.fill"
                )
                TrainingSummaryCell(
                    value: healthService.totalTrainingMinutes > 60
                        ? String(format: "%.1fh", healthService.totalTrainingMinutes / 60)
                        : "\(Int(healthService.totalTrainingMinutes))m",
                    label: "Total Time",
                    icon: "clock.fill"
                )
                TrainingSummaryCell(
                    value: "\(Int(healthService.totalCaloriesBurned))",
                    label: "Calories",
                    icon: "flame.fill"
                )
            }

            // Recent workouts list
            if !healthService.weeklyWorkouts.isEmpty {
                VStack(spacing: 0) {
                    ForEach(healthService.weeklyWorkouts.prefix(5), id: \.uuid) { workout in
                        WorkoutRow(workout: workout)
                        if workout.uuid != healthService.weeklyWorkouts.prefix(5).last?.uuid {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(Color.hrSurface.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .hrCard()
    }

    // MARK: - HealthKit Not Available

    private var healthKitUnavailableCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("HealthKit Not Available")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("This device does not support HealthKit.\nUse an iPhone with Apple Health to see training data.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    // MARK: - HealthKit Auth Card

    private var healthKitAuthCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.hrBlue)

            VStack(spacing: 6) {
                Text("Connect Apple Health")
                    .font(.system(size: 18, weight: .bold))
                Text("Enable HealthKit to see your training\nstats and heart rate data")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await healthService.requestAuthorization() }
            } label: {
                HStack {
                    Image(systemName: "heart.fill")
                    Text("Enable HealthKit")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.hrBlue)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .hrCard()
    }
}

// MARK: - Watch-specific Sub-components

private struct WatchStatusPill: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct WatchFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

private struct SetupStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
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

// MARK: - Original Sub-components (preserved)

private struct TodayStatCell: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WeeklyMetricRing: View {
    let value: Double
    let maxValue: Double
    let label: String
    let valueText: String
    let color: Color

    private var progress: Double {
        min(value / maxValue, 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: progress)

                Text(valueText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HeartRateChartView: View {
    let samples: [HeartRateSample]

    var body: some View {
        GeometryReader { geo in
            let bpms = samples.reversed().map(\.bpm)
            let minBPM = (bpms.min() ?? 50) - 10
            let maxBPM = (bpms.max() ?? 100) + 10
            let range = maxBPM - minBPM

            if bpms.count >= 2 {
                Path { path in
                    let stepX = geo.size.width / CGFloat(bpms.count - 1)
                    for (index, bpm) in bpms.enumerated() {
                        let x = stepX * CGFloat(index)
                        let y = geo.size.height * (1 - CGFloat((bpm - minBPM) / range))
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(colors: [.red.opacity(0.6), .red], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )

                // Fill gradient
                Path { path in
                    let stepX = geo.size.width / CGFloat(bpms.count - 1)
                    path.move(to: CGPoint(x: 0, y: geo.size.height))
                    for (index, bpm) in bpms.enumerated() {
                        let x = stepX * CGFloat(index)
                        let y = geo.size.height * (1 - CGFloat((bpm - minBPM) / range))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [.red.opacity(0.15), .red.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}

private struct HeartRateStatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TrainingSummaryCell: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.hrGold)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WorkoutRow: View {
    let workout: HKWorkout

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(activityColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: activityIcon)
                    .font(.system(size: 13))
                    .foregroundStyle(activityColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(activityName)
                    .font(.system(size: 13, weight: .medium))
                Text(workout.startDate, style: .date)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(workout.duration))
                    .font(.system(size: 13, weight: .semibold))
                if let cal = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()), cal > 0 {
                    Text("\(Int(cal)) kcal")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.hrOrange)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var activityName: String {
        switch workout.workoutActivityType {
        case .baseball: return "Baseball Practice"
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .functionalStrengthTraining: return "Strength Training"
        default: return "Workout"
        }
    }

    private var activityIcon: String {
        switch workout.workoutActivityType {
        case .baseball: return "figure.baseball"
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "figure.outdoor.cycle"
        case .functionalStrengthTraining: return "dumbbell.fill"
        default: return "figure.mixed.cardio"
        }
    }

    private var activityColor: Color {
        switch workout.workoutActivityType {
        case .baseball: return Color.hrGold
        case .running: return Color.hrGreen
        case .walking: return Color.hrBlue
        default: return Color.hrOrange
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return minutes >= 60
            ? String(format: "%dh %dm", minutes / 60, minutes % 60)
            : "\(minutes) min"
    }
}

#Preview {
    TrainingView()
}
