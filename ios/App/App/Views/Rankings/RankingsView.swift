import SwiftUI
import Charts

// MARK: - Rankings View

struct RankingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = RankingsViewModel()
    @State private var appeared = false

    private var userId: String? {
        authVM.user?.id.uuidString
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                if vm.isLoading && vm.leaders.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.primary)
                            .scaleEffect(1.2)
                        Text("Loading rankings…")
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.55))
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Demo notice — only show when user has no real data
                            if !vm.hasRealData {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.hrOrange)
                                    Text("Complete an analysis session to see your ranking among other players!")
                                        .font(.caption)
                                        .foregroundStyle(.primary.opacity(0.55))
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.hrOrange.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.hrOrange.opacity(0.20), lineWidth: 1)
                                )
                            }

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
            }
            .navigationTitle("Rankings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.hrBg.opacity(0.95), for: .navigationBar)
        }
        .onAppear {
            appeared = true
            Task { await vm.loadData(userId: userId) }
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
                            .foregroundStyle(.primary.opacity(0.55))
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("Top")
                                .font(.subheadline)
                                .foregroundStyle(.primary.opacity(0.55))
                            Text("\(vm.myPercentile)%")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(Color.hrGold)
                        }
                        Text("Age \(vm.selectedAgeRange) group · \(vm.totalPlayers) players")
                            .font(.caption)
                            .foregroundStyle(.primary.opacity(0.50))
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
                                .foregroundStyle(.primary)
                            Text("pts")
                                .font(.system(size: 9))
                                .foregroundStyle(.primary.opacity(0.55))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.hrSurface)
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
                        }
                        Task { await vm.loadData(userId: userId) }
                    } label: {
                        Text("Age \(group)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(vm.selectedAgeRange == group ? Color.white : Color.primary.opacity(0.55))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                vm.selectedAgeRange == group
                                ? Color.hrBlue
                                : Color.hrSurface
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
                .foregroundStyle(.primary.opacity(0.70))
                .lineLimit(1)

            Text("\(entry?.score ?? 0)")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.primary)

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
        let displayLimit = 20
        let displayLeaders = Array(vm.leaders.prefix(displayLimit))
        let myRankInTop = vm.myRank <= displayLimit && vm.myRank > 0

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionLabel(icon: "list.number", title: "Full Rankings", color: .hrBlue)
                Spacer()
                Text("\(vm.totalPlayers) players")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.45))
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
                .foregroundStyle(.primary.opacity(0.40))
                .tracking(0.8)
                .padding(.horizontal, 2)

                Divider()
                    .background(Color.hrSurface)

                ForEach(Array(displayLeaders.enumerated()), id: \.element.id) { idx, entry in
                    leaderRow(entry: entry, rank: idx + 1)
                    if idx < displayLeaders.count - 1 {
                        Divider().background(Color.hrSurface)
                    }
                }

                // Show user's position if they're ranked below the top N
                if vm.hasRealData && !myRankInTop {
                    Divider().background(Color.hrStroke)
                    Text("···")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.35))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                    Divider().background(Color.hrStroke)
                    leaderRow(entry: vm.myEntry, rank: vm.myRank)
                }
            }
        }
        .hrCard()
    }

    private func leaderRow(entry: RankingsViewModel.LeaderEntry, rank: Int) -> some View {
        let rankColor: Color = rank == 1 ? .hrGold : rank == 2 ? Color(white: 0.65) : rank == 3 ? Color(red: 0.8, green: 0.52, blue: 0.25) : .primary.opacity(0.60)

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
                        .fill(entry.isMe ? Color.hrBlue.opacity(0.22) : Color.hrSurface)
                        .frame(width: 30, height: 30)
                    Text(entry.initials)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(entry.isMe ? Color.hrBlue : .primary.opacity(0.60))
                }
                Text(entry.displayName)
                    .font(.subheadline.weight(entry.isMe ? .semibold : .regular))
                    .foregroundStyle(entry.isMe ? Color.hrBlue : .primary)
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
                .foregroundStyle(.primary)
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
            sectionLabel(icon: "chart.line.uptrend.xyaxis", title: "Score Trend", color: .hrGreen)

            if vm.trendData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 28))
                        .foregroundStyle(.primary.opacity(0.35))
                    Text("Complete analysis sessions to see your score trend")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.50))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 110)
            } else {
                Chart(vm.trendData, id: \.session) { item in
                    AreaMark(x: .value("Session", item.session), y: .value("Score", item.score))
                        .foregroundStyle(LinearGradient(
                            colors: [Color.hrBlue.opacity(0.28), .clear],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("Session", item.session), y: .value("Score", item.score))
                        .foregroundStyle(Color.hrBlue)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Session", item.session), y: .value("Score", item.score))
                        .foregroundStyle(.primary)
                        .symbolSize(25)
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks { v in
                        AxisValueLabel {
                            if let i = v.as(Int.self) {
                                Text("#\(i)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.primary.opacity(0.45))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 50, 100]) { v in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.hrSurface)
                        AxisValueLabel {
                            Text("\(v.as(Int.self) ?? 0)")
                                .font(.system(size: 9))
                                .foregroundStyle(.primary.opacity(0.40))
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
                .foregroundStyle(.primary.opacity(0.50))
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
        let id: String
        let initials: String
        let displayName: String
        let score: Int
        let grade: String
        let isMe: Bool
    }

    struct TrendPoint {
        let session: Int
        let score: Int
    }

    @Published var selectedAgeRange = "11-13"
    @Published var leaders: [LeaderEntry] = []
    @Published var myRank = 0
    @Published var myPercentile = 0
    @Published var myScore = 0
    @Published var totalPlayers = 0
    @Published var trendData: [TrendPoint] = []
    @Published var trendChange = "—"
    @Published var isLoading = false
    @Published var hasRealData = false
    @Published var error: String?

    var myEntry: LeaderEntry {
        LeaderEntry(id: "me", initials: "ME", displayName: "You",
                   score: myScore, grade: gradeFor(score: myScore), isMe: true)
    }

    var selectedAgeDisplay: String { selectedAgeRange }

    func loadData(userId: String?) async {
        isLoading = true
        error = nil

        do {
            // Fetch leaderboard from Supabase RPC
            let rows = try await SupabaseService.shared.fetchLeaderboard(
                ageGroup: selectedAgeRange,
                userId: userId
            )

            // Convert to LeaderEntry
            leaders = rows.map { row in
                LeaderEntry(
                    id: row.entryId,
                    initials: row.isMe ? "ME" : row.initials,
                    displayName: row.isMe ? "You" : row.displayName,
                    score: row.score,
                    grade: gradeFor(score: row.score),
                    isMe: row.isMe
                )
            }

            totalPlayers = leaders.count

            // Find current user's rank
            if let meIndex = leaders.firstIndex(where: { $0.isMe }) {
                myRank = meIndex + 1
                myScore = leaders[meIndex].score
                myPercentile = totalPlayers > 0 ? max(1, (myRank * 100) / totalPlayers) : 0
                hasRealData = true
            } else {
                // User has no score — place them last
                myRank = totalPlayers + 1
                myScore = 0
                myPercentile = 100
                hasRealData = false
            }

            // Fetch trend data if user is logged in
            if let uid = userId {
                let trendRows = try await SupabaseService.shared.fetchMyTrend(userId: uid)
                // Sort by session_number ascending for chart
                let sorted = trendRows.sorted { $0.sessionNumber < $1.sessionNumber }
                trendData = sorted.map { row in
                    TrendPoint(session: Int(row.sessionNumber), score: row.overallScore)
                }

                // Calculate change
                if trendData.count >= 2 {
                    let latest = trendData.last!.score
                    let previous = trendData[trendData.count - 2].score
                    let diff = latest - previous
                    trendChange = diff >= 0 ? "+\(diff)" : "\(diff)"
                } else {
                    trendChange = "—"
                }
            } else {
                trendData = []
                trendChange = "—"
            }

        } catch {
            self.error = error.localizedDescription
            print("Rankings load error: \(error)")
        }

        isLoading = false
    }

    private func gradeFor(score: Int) -> String {
        switch score {
        case 90...100: return "A+"
        case 80..<90:  return "A"
        case 70..<80:  return "B"
        case 60..<70:  return "C"
        default:       return "D"
        }
    }
}

// MARK: - Safe Array Subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
