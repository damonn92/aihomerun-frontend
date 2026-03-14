import SwiftUI

// MARK: - Session History View

struct SessionHistoryView: View {
    let sessions: [SessionSummary]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSession: SessionSummary?

    private var sortedSessions: [SessionSummary] {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fmtFallback = ISO8601DateFormatter()
        fmtFallback.formatOptions = [.withInternetDateTime]

        return sessions.sorted { a, b in
            let dateA = parseDate(a.createdAt, fmt: fmt, fallback: fmtFallback) ?? .distantPast
            let dateB = parseDate(b.createdAt, fmt: fmt, fallback: fmtFallback) ?? .distantPast
            return dateA > dateB
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
                        LazyVStack(spacing: 10) {
                            ForEach(sortedSessions) { session in
                                sessionRow(session)
                                    .onTapGesture { selectedSession = session }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Session History")
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
            .sheet(item: $selectedSession) { session in
                SessionDetailSheet(session: session)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 44))
                .foregroundStyle(Color.hrBlue.opacity(0.35))
            Text("No Sessions Yet")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("Analyze your first video to start\nbuilding your session history.")
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.50))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Session Row

    private func sessionRow(_ session: SessionSummary) -> some View {
        HStack(spacing: 12) {
            // Date + action type
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate(session.createdAt))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: session.actionType == "pitch" ? "figure.softball" : "figure.baseball")
                        .font(.system(size: 10))
                        .foregroundStyle(.primary.opacity(0.45))
                    Text((session.actionType ?? "swing").capitalized)
                        .font(.system(size: 11))
                        .foregroundStyle(.primary.opacity(0.45))
                }
            }

            Spacer()

            // Score pills
            if let t = session.techniqueScore {
                miniPill("T", t, .hrBlue)
            }
            if let p = session.powerScore {
                miniPill("P", p, .hrOrange)
            }
            if let b = session.balanceScore {
                miniPill("B", b, .hrGreen)
            }

            // Grade circle
            if let score = session.overallScore {
                let g = grade(for: score)
                Text(g)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(gradeColor(g))
                    .clipShape(Circle())
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.25))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.hrStroke, lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func miniPill(_ label: String, _ value: Int, _ color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label).font(.system(size: 8, weight: .bold)).foregroundStyle(color.opacity(0.70))
            Text("\(value)").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(.primary.opacity(0.70))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.10))
        .clipShape(Capsule())
    }

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
        guard let str = isoString else { return "Unknown date" }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fmtFallback = ISO8601DateFormatter()
        fmtFallback.formatOptions = [.withInternetDateTime]

        guard let date = parseDate(str, fmt: fmt, fallback: fmtFallback) else { return str }

        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let tf = DateFormatter()
            tf.dateFormat = "h:mm a"
            return "Today, \(tf.string(from: date))"
        } else if cal.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let df = DateFormatter()
            df.dateFormat = "MMM d, yyyy"
            return df.string(from: date)
        }
    }

    private func parseDate(_ str: String?, fmt: ISO8601DateFormatter, fallback: ISO8601DateFormatter) -> Date? {
        guard let str else { return nil }
        return fmt.date(from: str) ?? fallback.date(from: str)
    }
}

// MARK: - Session Detail Sheet

struct SessionDetailSheet: View {
    let session: SessionSummary
    @Environment(\.dismiss) private var dismiss

    private var overallScore: Int { session.overallScore ?? 0 }

    private var gradeString: String {
        switch overallScore {
        case 90...100: return "A+"
        case 80..<90:  return "A"
        case 70..<80:  return "B"
        case 60..<70:  return "C"
        default:       return "D"
        }
    }

    private var gradeColor: Color {
        switch gradeString {
        case "A+", "A": return .hrGreen
        case "B":        return .hrBlue
        case "C":        return .hrOrange
        default:         return .hrRed
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Grade hero
                        gradeHero

                        // Score rings
                        scoreRings

                        // Session info
                        sessionInfo
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Session Detail")
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

    // MARK: - Grade Hero

    private var gradeHero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gradeColor.opacity(0.14))
                    .frame(width: 96, height: 96)
                Circle()
                    .stroke(gradeColor.opacity(0.30), lineWidth: 4)
                    .frame(width: 96, height: 96)
                VStack(spacing: 2) {
                    Text(gradeString)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(gradeColor)
                    Text("\(overallScore)/100")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.50))
                }
            }

            Text("Overall Score")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary.opacity(0.45))
                .textCase(.uppercase)
                .tracking(0.8)
        }
    }

    // MARK: - Score Rings

    private var scoreRings: some View {
        HStack(spacing: 16) {
            ScoreRingView(score: session.techniqueScore ?? 0, label: "Technique", size: 64, lineWidth: 6)
            ScoreRingView(score: session.powerScore ?? 0, label: "Power", size: 64, lineWidth: 6)
            ScoreRingView(score: session.balanceScore ?? 0, label: "Balance", size: 64, lineWidth: 6)
        }
        .hrCard()
    }

    // MARK: - Session Info

    private var sessionInfo: some View {
        VStack(spacing: 12) {
            infoRow(icon: "calendar", label: "Date", value: formattedDate(session.createdAt))
            Divider().background(Color.hrDivider)
            infoRow(
                icon: session.actionType == "pitch" ? "figure.softball" : "figure.baseball",
                label: "Type",
                value: (session.actionType ?? "swing").capitalized
            )
            if let vid = session.videoId {
                Divider().background(Color.hrDivider)
                infoRow(icon: "film", label: "Video ID", value: String(vid.prefix(12)) + "...")
            }
        }
        .hrCard()
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.hrBlue)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.55))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
    }

    private func formattedDate(_ isoString: String?) -> String {
        guard let str = isoString else { return "Unknown" }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fmtFallback = ISO8601DateFormatter()
        fmtFallback.formatOptions = [.withInternetDateTime]
        guard let date = fmt.date(from: str) ?? fmtFallback.date(from: str) else { return str }
        let df = DateFormatter()
        df.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return df.string(from: date)
    }
}
