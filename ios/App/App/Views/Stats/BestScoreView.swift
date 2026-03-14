import SwiftUI

// MARK: - Best Score View

struct BestScoreView: View {
    let sessions: [SessionSummary]
    @Environment(\.dismiss) private var dismiss

    private var bestSession: SessionSummary? {
        sessions.max(by: { ($0.overallScore ?? 0) < ($1.overallScore ?? 0) })
    }

    private var avgScore: Int {
        let scores = sessions.compactMap(\.overallScore)
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

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                if let best = bestSession, let score = best.overallScore {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Trophy badge
                            trophyBadge

                            // Grade hero
                            gradeHero(score: score)

                            // Score rings
                            scoreRings(best)

                            // Comparison to average
                            comparisonCard(best)

                            // Date info
                            dateCard(best)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle("Personal Best")
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

    // MARK: - Trophy Badge

    private var trophyBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.hrGold)
            Text("Personal Best")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.hrGold)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.hrGold.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Grade Hero

    private func gradeHero(score: Int) -> some View {
        let g = grade(for: score)
        let gc = gradeColor(g)

        return VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(gc.opacity(0.12))
                    .frame(width: 110, height: 110)
                Circle()
                    .stroke(gc.opacity(0.30), lineWidth: 5)
                    .frame(width: 110, height: 110)
                VStack(spacing: 2) {
                    Text(g)
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(gc)
                    Text("\(score) pts")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.55))
                }
            }

            if avgScore > 0 {
                let delta = score - avgScore
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 11, weight: .bold))
                    Text("+\(delta) above average")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.hrGreen)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.hrGreen.opacity(0.10))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Score Rings

    private func scoreRings(_ session: SessionSummary) -> some View {
        HStack(spacing: 16) {
            ScoreRingView(score: session.techniqueScore ?? 0, label: "Technique", size: 64, lineWidth: 6)
            ScoreRingView(score: session.powerScore ?? 0, label: "Power", size: 64, lineWidth: 6)
            ScoreRingView(score: session.balanceScore ?? 0, label: "Balance", size: 64, lineWidth: 6)
        }
        .hrCard()
    }

    // MARK: - Comparison Card

    private func comparisonCard(_ best: SessionSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Best vs Average", systemImage: "chart.bar.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary.opacity(0.50))
                .textCase(.uppercase)
                .tracking(0.6)

            comparisonRow("Overall", best: best.overallScore ?? 0, avg: avgScore, color: .hrBlue)
            comparisonRow("Technique", best: best.techniqueScore ?? 0, avg: avgTechnique, color: .hrBlue)
            comparisonRow("Power", best: best.powerScore ?? 0, avg: avgPower, color: .hrOrange)
            comparisonRow("Balance", best: best.balanceScore ?? 0, avg: avgBalance, color: .hrGreen)
        }
        .hrCard()
    }

    private func comparisonRow(_ label: String, best: Int, avg: Int, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary.opacity(0.65))
                .frame(width: 72, alignment: .leading)

            // Best bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.10))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(4, geo.size.width * CGFloat(best) / 100.0), height: 8)
                }
            }
            .frame(height: 8)

            Text("\(best)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: 28, alignment: .trailing)

            // Delta
            let diff = best - avg
            if diff > 0 {
                Text("+\(diff)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.hrGreen)
                    .frame(width: 32, alignment: .trailing)
            } else {
                Text("\(diff)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.primary.opacity(0.35))
                    .frame(width: 32, alignment: .trailing)
            }
        }
    }

    // MARK: - Date Card

    private func dateCard(_ session: SessionSummary) -> some View {
        HStack {
            Image(systemName: "calendar")
                .font(.system(size: 14))
                .foregroundStyle(Color.hrBlue)
            Text("Achieved")
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.55))
            Spacer()
            Text(formattedDate(session.createdAt))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .hrCard()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.hrGold.opacity(0.35))
            Text("No Scores Yet")
                .font(.headline)
            Text("Complete your first analysis\nto set a personal best!")
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.50))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helpers

    private func grade(for score: Int) -> String {
        switch score {
        case 90...100: return "A+"
        case 80..<90:  return "A"
        case 70..<80:  return "B"
        case 60..<70:  return "C"
        default:       return "D"
        }
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A+", "A": return .hrGreen
        case "B":        return .hrBlue
        case "C":        return .hrOrange
        default:         return .hrRed
        }
    }

    private func formattedDate(_ isoString: String?) -> String {
        guard let str = isoString else { return "Unknown" }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fb = ISO8601DateFormatter()
        fb.formatOptions = [.withInternetDateTime]
        guard let date = fmt.date(from: str) ?? fb.date(from: str) else { return str }
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy"
        return df.string(from: date)
    }
}
