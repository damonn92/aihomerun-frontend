import SwiftUI

struct ResultView: View {
    let result: AnalysisResult
    let onReset: () -> Void

    @State private var parentMode = false
    @State private var appeared = false

    private var feedback: Feedback { result.feedback }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        gradeHero
                            .staggered(appeared, delay: 0.05)

                        if !parentMode {
                            scoreRingsCard
                                .staggered(appeared, delay: 0.12)
                        }

                        if let prev = result.previousSession {
                            CompareCardView(previous: prev, current: feedback)
                                .staggered(appeared, delay: 0.18)
                        }

                        if let history = result.history, history.count >= 2 {
                            GrowthChartView(history: history, currentScore: feedback.overallScore)
                                .staggered(appeared, delay: 0.22)
                        }

                        if parentMode, let tip = feedback.parentTip {
                            parentTipCard(tip: tip)
                                .staggered(appeared, delay: 0.10)
                        }

                        if !feedback.strengths.isEmpty {
                            bulletCard(title: "Strengths", icon: "star.fill",
                                       accent: Color.hrGreen, items: feedback.strengths)
                                .staggered(appeared, delay: 0.26)
                        }

                        if !feedback.improvements.isEmpty {
                            bulletCard(title: "Work On", icon: "arrow.up.circle.fill",
                                       accent: Color.hrOrange, items: feedback.improvements)
                                .staggered(appeared, delay: 0.30)
                        }

                        if let drill = feedback.drill {
                            drillCard(drill: drill)
                                .staggered(appeared, delay: 0.34)
                        }

                        if !parentMode {
                            metricsCard
                                .staggered(appeared, delay: 0.38)
                        }

                        Spacer(minLength: 36)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("\(result.actionType.capitalized) Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onReset()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus.circle.fill")
                            Text("New")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.hrBlue)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(duration: 0.3)) { parentMode.toggle() }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: parentMode ? "person.2.fill" : "person.fill")
                            Text(parentMode ? "Parent" : "Athlete")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(parentMode ? Color.hrGreen : Color.hrBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background((parentMode ? Color.hrGreen : Color.hrBlue).opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .onAppear { appeared = true }
        .preferredColorScheme(.dark)
    }

    // MARK: - Grade hero

    private var gradeHero: some View {
        ZStack {
            Circle()
                .fill(gradeColor.opacity(0.16))
                .frame(width: 160, height: 160)
                .blur(radius: 40)

            VStack(spacing: 10) {
                Text(feedback.grade)
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundStyle(gradeColor)
                    .shadow(color: gradeColor.opacity(0.5), radius: 24)

                Text(feedback.plainSummary)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                if let enc = feedback.encouragement {
                    Text(enc)
                        .font(.callout.italic())
                        .foregroundStyle(Color.hrBlue)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [gradeColor.opacity(0.14), Color.hrCard],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(gradeColor.opacity(0.24), lineWidth: 1)
        )
    }

    // MARK: - Score rings

    private var scoreRingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Performance Scores", icon: "chart.bar.fill")

            HStack(spacing: 10) {
                ScoreRingView(score: feedback.overallScore,   label: "Overall",   size: 70)
                ScoreRingView(score: feedback.techniqueScore, label: "Technique",  size: 70)
                ScoreRingView(score: feedback.powerScore,     label: "Power",      size: 70)
                ScoreRingView(score: feedback.balanceScore,   label: "Balance",    size: 70)
            }
            .frame(maxWidth: .infinity)
        }
        .hrCard()
    }

    // MARK: - Bullet card

    private func bulletCard(title: String, icon: String, accent: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title, icon: icon, accent: accent)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(accent.opacity(0.6))
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.80))
                    }
                }
            }
        }
        .hrCard()
    }

    // MARK: - Drill card

    private func drillCard(drill: DrillInfo) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Practice Drill", icon: "figure.baseball", accent: Color.hrBlue)

            VStack(alignment: .leading, spacing: 6) {
                Text(drill.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(drill.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))

                if let reps = drill.reps {
                    Label(reps, systemImage: "repeat")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.hrBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.hrBlue.opacity(0.15))
                        .clipShape(Capsule())
                        .padding(.top, 4)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.hrBlue.opacity(0.14), Color.hrCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hrBlue.opacity(0.26), lineWidth: 1)
        )
    }

    // MARK: - Parent tip card

    private func parentTipCard(tip: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("For Parents — Today's Practice", icon: "person.2.fill", accent: Color.hrGreen)

            Text(tip)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.hrGreen.opacity(0.13), Color.hrCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hrGreen.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Metrics card

    private var metricsCard: some View {
        let m = result.metrics
        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Motion Data", icon: "waveform.path.ecg")

            VStack(spacing: 0) {
                if let v = m.peakWristSpeed {
                    MetricRow(label: "Peak Wrist Speed",  value: String(format: "%.1f m/s", v))
                }
                if let v = m.hipShoulderSeparation {
                    MetricRow(label: "Hip–Shoulder Sep.", value: String(format: "%.1f°",   v))
                }
                if let v = m.balanceScore {
                    MetricRow(label: "Balance",           value: String(format: "%.0f%%",   v))
                }
                if let v = m.followThrough {
                    MetricRow(label: "Follow-Through",    value: v ? "✓ Yes" : "✗ No",
                              last: m.jointAngles == nil)
                }
                if let ja = m.jointAngles {
                    if let v = ja.elbowAngle {
                        MetricRow(label: "Elbow Angle",   value: String(format: "%.0f°", v))
                    }
                    if let v = ja.shoulderAngle {
                        MetricRow(label: "Shoulder Angle", value: String(format: "%.0f°", v), last: true)
                    }
                }
            }
        }
        .hrCard()
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String, accent: Color = .white.opacity(0.45)) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.bold))
            .foregroundStyle(accent)
            .textCase(.uppercase)
            .tracking(0.7)
    }

    private var gradeColor: Color {
        switch feedback.grade {
        case "A+", "A": return Color.hrGreen
        case "B":        return Color.hrBlue
        case "C":        return Color.hrOrange
        default:         return Color.hrRed
        }
    }
}

// MARK: - Metric row

struct MetricRow: View {
    let label: String
    let value: String
    var last: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.50))
                Spacer()
                Text(value)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 11)

            if !last {
                Divider().background(Color.white.opacity(0.07))
            }
        }
    }
}

// DataRow alias kept for compiler compatibility
typealias DataRow = MetricRow

// MARK: - Stagger animation helper

private extension View {
    func staggered(_ trigger: Bool, delay: Double) -> some View {
        self
            .opacity(trigger ? 1 : 0)
            .offset(y: trigger ? 0 : 18)
            .animation(.spring(duration: 0.5).delay(delay), value: trigger)
    }
}
