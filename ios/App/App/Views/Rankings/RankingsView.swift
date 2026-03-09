import SwiftUI
import Charts

// MARK: - Rankings View

struct RankingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = RankingsViewModel()
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Demo notice
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.hrOrange)
                            Text("Demo Data — Rankings will use real scores once you have analysis sessions.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.hrOrange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.hrOrange.opacity(0.20), lineWidth: 1)
                        )

                        // Stadium night banner
                        StadiumNightBanner()
                        myRankHeroCard
                        ageGroupSelector
                        podiumSection
                        fullLeaderboard
                        weeklyInsightCard
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(.spring(duration: 0.55, bounce: 0.15).delay(0.05), value: appeared)
                }
            }
            .navigationTitle("Rankings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.hrBg.opacity(0.95), for: .navigationBar)
        }
        .onAppear {
            appeared = true
            vm.loadData()
        }
    }

    // MARK: - My Rank Hero Card

    private var myRankHeroCard: some View {
        ZStack {
            LinearGradient(
                colors: [Color.hrBlue.opacity(0.35), Color.hrCard],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Rank badge
                    ZStack {
                        Circle()
                            .fill(Color.hrGold.opacity(0.18))
                            .frame(width: 70, height: 70)
                        Circle()
                            .stroke(Color.hrGold.opacity(0.45), lineWidth: 1.5)
                            .frame(width: 70, height: 70)
                        VStack(spacing: 0) {
                            Text("#\(vm.myRank)")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundStyle(Color.hrGold)
                            Text("RANK")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.hrGold.opacity(0.70))
                                .tracking(1.5)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Standing")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("Top")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.55))
                            Text("\(vm.myPercentile)%")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(Color.hrGold)
                        }
                        Text("Age \(vm.selectedAgeRange) group · \(vm.totalPlayers) players")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.38))
                    }

                    Spacer()

                    // Score ring
                    ZStack {
                        Circle()
                            .stroke(Color.hrBlue.opacity(0.18), lineWidth: 5)
                            .frame(width: 60, height: 60)
                        Circle()
                            .trim(from: 0, to: appeared ? CGFloat(vm.myScore) / 100 : 0)
                            .stroke(Color.hrBlue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(duration: 1.2, bounce: 0.2).delay(0.3), value: appeared)
                        VStack(spacing: 0) {
                            Text("\(vm.myScore)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("pts")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.40))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(
                                colors: [Color.hrGold, Color.hrOrange],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: appeared
                                   ? geo.size.width * (1.0 - CGFloat(vm.myPercentile) / 100.0)
                                   : 0,
                                   height: 5)
                            .animation(.spring(duration: 1.0).delay(0.4), value: appeared)
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.hrBlue.opacity(0.22), lineWidth: 1)
        )
    }

    // MARK: - Age Group Selector

    private var ageGroupSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RankingsViewModel.ageGroups, id: \.self) { group in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            vm.selectedAgeRange = group
                            vm.loadData()
                        }
                    } label: {
                        Text("Age \(group)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(vm.selectedAgeRange == group ? .white : .white.opacity(0.40))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                vm.selectedAgeRange == group
                                ? Color.hrBlue
                                : Color.white.opacity(0.07)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Podium (Top 3)

    private var podiumSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(icon: "trophy.fill", title: "Top Performers", color: .hrGold)

            HStack(alignment: .bottom, spacing: 12) {
                // 2nd place
                podiumPillar(entry: vm.leaders[safe: 1], place: 2, height: 90)
                // 1st place
                podiumPillar(entry: vm.leaders[safe: 0], place: 1, height: 120)
                // 3rd place
                podiumPillar(entry: vm.leaders[safe: 2], place: 3, height: 72)
            }
        }
        .hrCard()
    }

    private func podiumPillar(entry: RankingsViewModel.LeaderEntry?, place: Int, height: CGFloat) -> some View {
        let colors: [Color] = [.hrGold, Color(white: 0.65), Color(red: 0.8, green: 0.52, blue: 0.25)]
        let color = colors[safe: place - 1] ?? .hrBlue

        return VStack(spacing: 6) {
            // Medal icon using SF Symbols
            medalIcon(place: place, color: color)

            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 44, height: 44)
                Circle().stroke(color.opacity(0.40), lineWidth: 1.5).frame(width: 44, height: 44)
                Text(entry?.initials ?? "--")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }

            Text(entry?.displayName ?? "—")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.70))
                .lineLimit(1)

            Text("\(entry?.score ?? 0)")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            // Pillar
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(color.opacity(0.28), lineWidth: 1)
                    )
                Text("#\(place)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color.opacity(0.80))
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: appeared ? height : 0)
            .animation(.spring(duration: 0.8, bounce: 0.25).delay(Double(place) * 0.08), value: appeared)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Full Leaderboard

    private var fullLeaderboard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionLabel(icon: "list.number", title: "Full Rankings", color: .hrBlue)
                Spacer()
                Text("\(vm.totalPlayers) players")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.30))
            }

            VStack(spacing: 6) {
                // Header row
                HStack {
                    Text("RANK").frame(width: 40, alignment: .leading)
                    Text("PLAYER").frame(maxWidth: .infinity, alignment: .leading)
                    Text("SCORE").frame(width: 50, alignment: .trailing)
                    Text("GRADE").frame(width: 44, alignment: .trailing)
                }
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.28))
                .tracking(0.8)
                .padding(.horizontal, 2)

                Divider()
                    .background(Color.white.opacity(0.07))

                ForEach(Array(vm.leaders.enumerated()), id: \.element.id) { idx, entry in
                    leaderRow(entry: entry, rank: idx + 1)
                    if idx < vm.leaders.count - 1 {
                        Divider().background(Color.white.opacity(0.06))
                    }
                }

                if vm.myRank > vm.leaders.count {
                    Divider().background(Color.white.opacity(0.10))
                    Text("··· \(vm.myRank - vm.leaders.count) players between ···")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.22))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                    Divider().background(Color.white.opacity(0.10))
                    leaderRow(entry: vm.myEntry, rank: vm.myRank)
                }
            }
        }
        .hrCard()
    }

    private func leaderRow(entry: RankingsViewModel.LeaderEntry, rank: Int) -> some View {
        let rankColor: Color = rank == 1 ? .hrGold : rank == 2 ? Color(white: 0.65) : rank == 3 ? Color(red: 0.8, green: 0.52, blue: 0.25) : .white.opacity(0.50)

        return HStack(spacing: 0) {
            // Rank
            HStack(spacing: 4) {
                if rank <= 3 {
                    medalIcon(place: rank, color: rankColor, size: 18)
                } else {
                    Text("#\(rank)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(rankColor)
                }
            }
            .frame(width: 40, alignment: .leading)

            // Initials + name
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(entry.isMe ? Color.hrBlue.opacity(0.22) : Color.white.opacity(0.07))
                        .frame(width: 30, height: 30)
                    Text(entry.initials)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(entry.isMe ? Color.hrBlue : .white.opacity(0.60))
                }
                Text(entry.displayName)
                    .font(.subheadline.weight(entry.isMe ? .semibold : .regular))
                    .foregroundStyle(entry.isMe ? Color.hrBlue : .white)
                if entry.isMe {
                    Text("YOU")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(Color.hrBlue)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.hrBlue.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Score
            Text("\(entry.score)")
                .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 50, alignment: .trailing)

            // Grade
            Text(entry.grade)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(gradeColor(entry.grade))
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .background(entry.isMe ? Color.hrBlue.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, -4)
    }

    // MARK: - Weekly Insight

    private var weeklyInsightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel(icon: "chart.line.uptrend.xyaxis", title: "Score Trend This Month", color: .hrGreen)

            Chart(vm.trendData, id: \.week) { item in
                AreaMark(x: .value("Week", item.week), y: .value("Score", item.score))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.hrBlue.opacity(0.28), .clear],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value("Week", item.week), y: .value("Score", item.score))
                    .foregroundStyle(Color.hrBlue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Week", item.week), y: .value("Score", item.score))
                    .foregroundStyle(.white)
                    .symbolSize(25)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks { v in
                    AxisValueLabel {
                        if let i = v.as(Int.self) {
                            Text("Wk \(i)")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.30))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.07))
                    AxisValueLabel {
                        Text("\(v.as(Int.self) ?? 0)")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                }
            }
            .frame(height: 110)

            HStack(spacing: 20) {
                statPill(label: "Best", value: "\(vm.trendData.map(\.score).max() ?? 0)", color: .hrGreen)
                statPill(label: "Avg", value: "\(vm.trendData.map(\.score).reduce(0,+) / max(1, vm.trendData.count))", color: .hrBlue)
                statPill(label: "Change", value: vm.trendChange, color: vm.trendChange.hasPrefix("+") ? .hrGreen : .hrRed)
            }
        }
        .hrCard()
    }

    // MARK: - Helpers

    private func medalIcon(place: Int, color: Color, size: CGFloat = 26) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: size, height: size)
            Image(systemName: place == 1 ? "trophy.fill" : "medal.fill")
                .font(.system(size: size * 0.52, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private func sectionLabel(icon: String, title: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.footnote.weight(.bold))
            .foregroundStyle(color)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    private func statPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
                .textCase(.uppercase)
                .tracking(0.5)
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
}

// MARK: - Rankings ViewModel

@MainActor
class RankingsViewModel: ObservableObject {
    static let ageGroups = ["8-10", "11-13", "14-16", "17-18"]

    struct LeaderEntry: Identifiable {
        let id = UUID()
        let initials: String
        let displayName: String
        let score: Int
        let grade: String
        let isMe: Bool
    }

    struct TrendPoint {
        let week: Int
        let score: Int
    }

    @Published var selectedAgeRange = "11-13"
    @Published var leaders: [LeaderEntry] = []
    @Published var myRank = 7
    @Published var myPercentile = 43
    @Published var myScore = 72
    @Published var totalPlayers = 284
    @Published var trendData: [TrendPoint] = []
    @Published var trendChange = "+6"

    var myEntry: LeaderEntry {
        LeaderEntry(initials: "ME", displayName: "You", score: myScore, grade: "B", isMe: true)
    }

    var selectedAgeDisplay: String { selectedAgeRange }

    func loadData() {
        // Simulated leaderboard based on selected age group
        let allNames: [(String, String)] = [
            ("JL", "Jordan L."), ("MC", "Marcus C."), ("TR", "Tyler R."),
            ("DS", "Derek S."), ("AM", "Alex M."), ("RB", "Ryan B."),
            ("CW", "Chris W."), ("BH", "Blake H."), ("NJ", "Noah J."),
            ("KP", "Kyle P.")
        ]
        let scores = [96, 91, 87, 84, 80, 77, 74, 71, 68, 65]
        let grades = ["A+", "A", "A", "B", "B", "B", "B", "B", "C", "C"]

        leaders = zip(allNames, zip(scores, grades)).map { name, sg in
            LeaderEntry(initials: name.0, displayName: name.1,
                       score: sg.0, grade: sg.1, isMe: false)
        }

        trendData = [
            TrendPoint(week: 1, score: 54),
            TrendPoint(week: 2, score: 61),
            TrendPoint(week: 3, score: 68),
            TrendPoint(week: 4, score: 72),
        ]

        switch selectedAgeRange {
        case "8-10":
            myRank = 4; myPercentile = 24; myScore = 68; totalPlayers = 142
        case "14-16":
            myRank = 12; myPercentile = 58; myScore = 75; totalPlayers = 391
        case "17-18":
            myRank = 18; myPercentile = 72; myScore = 71; totalPlayers = 210
        default:
            myRank = 7; myPercentile = 43; myScore = 72; totalPlayers = 284
        }
    }
}

// MARK: - Safe Array Subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
