import SwiftUI
import HealthKit

/// Training dashboard — shows HealthKit data, workout history, and fitness metrics
struct TrainingView: View {
    @StateObject private var healthService = HealthKitService.shared
    @StateObject private var watchManager = WatchSessionManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        // Live Watch session (if active)
                        if watchManager.isWatchSessionActive {
                            liveSessionBanner
                        }

                        // HealthKit not available / not authorized
                        if !healthService.isAvailable {
                            healthKitUnavailableCard
                        } else if !healthService.isAuthorized {
                            healthKitAuthCard
                        } else {
                            // Today's stats
                            todayStatsCard

                            // Weekly overview
                            weeklyOverviewCard

                            // Heart rate card
                            heartRateCard

                            // Training history
                            trainingHistoryCard

                            // Watch connection
                            watchConnectionCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Training")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await healthService.fetchAllData()
            }
            .onAppear {
                Task { await healthService.fetchAllData() }
                watchManager.refreshConnectionStatus()
            }
        }
    }

    // MARK: - Live Watch Session Banner

    private var liveSessionBanner: some View {
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
                    Text("Live Watch Session")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.green)
                }
                Spacer()
                Image(systemName: "applewatch")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 20) {
                VStack {
                    Text("\(watchManager.liveSwingCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("Swings")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Divider().frame(height: 36)

                VStack {
                    Text("\(Int(watchManager.liveLastSpeed))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.hrBlue)
                    Text("Last mph")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                VStack {
                    Text("\(Int(watchManager.liveBestSpeed))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.hrGreen)
                    Text("Best mph")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
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

    // MARK: - Watch Connection Card

    private var watchConnectionCard: some View {
        let connected = watchManager.isWatchConnected
        let reachable = watchManager.isWatchReachable

        return HStack(spacing: 12) {
            Image(systemName: connected ?
                  "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                .font(.system(size: 16))
                .foregroundStyle(connected ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(connected ? "Apple Watch Connected" : "Apple Watch Not Connected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(connected ? .primary : .secondary)
                Text(watchSubtitle(connected: connected, reachable: reachable))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if connected {
                Circle()
                    .fill(reachable ? .green : .orange)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(14)
        .background(connected ? Color.hrGreen.opacity(0.08) : Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.hrStroke, lineWidth: 1)
        )
        .onTapGesture {
            watchManager.refreshConnectionStatus()
        }
    }

    private func watchSubtitle(connected: Bool, reachable: Bool) -> String {
        if !connected {
            return "Pair your Apple Watch and install AIHomeRun"
        }
        if reachable {
            return "Watch app active — real-time sync ready"
        }
        return "Paired — open Watch app for live sync"
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
                .font(.system(size: 56))
                .foregroundStyle(Color.hrBlue)

            VStack(spacing: 6) {
                Text("Connect Apple Health")
                    .font(.system(size: 20, weight: .bold))
                Text("Track your training stats, heart rate,\nand workout history")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(icon: "figure.baseball", text: "Baseball workout tracking", color: Color.hrGold)
                FeatureRow(icon: "heart.fill", text: "Heart rate monitoring", color: .red)
                FeatureRow(icon: "flame.fill", text: "Calories & exercise time", color: Color.hrOrange)
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Training progress over time", color: Color.hrGreen)
            }
            .padding(.vertical, 4)

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
                .frame(height: 52)
                .background(Color.hrBlue)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .hrCard()
    }
}

// MARK: - Sub-components

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

private struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(.primary.opacity(0.8))
        }
    }
}

#Preview {
    TrainingView()
}
