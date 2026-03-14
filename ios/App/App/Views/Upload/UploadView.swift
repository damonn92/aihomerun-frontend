import SwiftUI
import PhotosUI
import Charts
import UniformTypeIdentifiers

// MARK: - Video file transferable for PhotosPicker

struct MovieTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            try FileManager.default.copyItem(at: received.file, to: dest)
            return Self(url: dest)
        }
    }
}

// MARK: - UploadView (Training Dashboard Home)

// MARK: - Stats Sheet Type
private enum StatsSheet: String, Identifiable {
    case sessions, bestScore, avgScore
    var id: String { rawValue }
}

struct UploadView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var deepLink: DeepLinkRouter
    @StateObject private var vm   = UploadViewModel()
    @StateObject private var feed = HomeFeedViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var activeStatsSheet: StatsSheet?

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    LoadingView(step: vm.loadStep, progress: vm.uploadProgress)
                } else if let result = vm.result {
                    ResultView(result: result, videoURL: vm.videoURL, usedCache: vm.usedCache, onReanalyze: {
                        Task {
                            let token = await authVM.accessToken()
                            await vm.reanalyze(token: token)
                        }
                    }) {
                        feed.saveLastResult(result)
                        vm.reset()
                    }
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("AIHomeRun")
            .navigationBarTitleDisplayMode(.large)
            .alert("Analysis Error", isPresented: Binding(
                get: { vm.error != nil },
                set: { if !$0 { vm.error = nil } }
            )) {
                Button("OK") { vm.error = nil }
            } message: { Text(vm.error ?? "") }
            .sheet(isPresented: Binding(
                get: { vm.qualityError != nil },
                set: { if !$0 { vm.qualityError = nil } }
            )) {
                if let qe = vm.qualityError {
                    QualityErrorSheet(qualityError: qe) { vm.qualityError = nil }
                        .presentationDetents([.medium])
                }
            }
            .fullScreenCover(item: $activeStatsSheet) { sheet in
                switch sheet {
                case .sessions:
                    SessionHistoryView(sessions: feed.sessionHistory)
                case .bestScore:
                    BestScoreView(sessions: feed.sessionHistory)
                case .avgScore:
                    ProgressStatsView(sessions: feed.sessionHistory)
                }
            }
        }
        .task {
            let token = await authVM.accessToken()
            await feed.loadFeed(token: token)
        }
        .onChange(of: selectedItems) { items in
            Task {
                guard let item = items.first else { return }
                await vm.prepareVideo(from: item)
            }
        }
        .onReceive(deepLink.$statsRoute) { route in
            guard let route else { return }
            DispatchQueue.main.async {
                deepLink.statsRoute = nil
                activeStatsSheet = StatsSheet(rawValue: route == "best" ? "bestScore" : route == "avg" ? "avgScore" : route)
            }
        }
    }

    // MARK: - Dashboard

    private var dashboardContent: some View {
        ZStack {
            Color.hrBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // Hero banner with stats overlapping at the bottom
                    ZStack(alignment: .bottom) {
                        BaseballHeroBanner(greeting: greeting, subtitle: dateString)
                            .padding(.bottom, 22)
                            .allowsHitTesting(false)
                        quickStatsSummary
                            .padding(.horizontal, 12)
                            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
                            .zIndex(1)
                    }

                    // Primary CTA
                    quickRecordCard

                    // Auto-detect / trim flow
                    if vm.isDetecting {
                        autoDetectCard
                    }
                    if vm.showTrimPreview, let detection = vm.detectionResult {
                        TrimPreviewView(
                            videoURL: vm.videoURL!,
                            detection: detection,
                            onConfirmTrim: { range in
                                Task { await vm.applyTrim(range: range) }
                            },
                            onUseFullVideo: {
                                vm.skipTrim()
                            }
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    if vm.isTrimming { trimmingCard }
                    if vm.trimmedVideoURL != nil { trimResultBadge }
                    if vm.videoURL != nil && !vm.isPreparing && !vm.isDetecting && !vm.showTrimPreview && !vm.isTrimming { startAnalysisButton }

                    // 2-column compact grid
                    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                    LazyVGrid(columns: columns, spacing: 12) {
                        if let cached = feed.lastResult {
                            compactAnalysisCard(cached)
                        } else {
                            compactEmptyCard
                        }
                        compactDrillCard
                    }

                    // Progress chart (visual, not text-heavy)
                    if feed.sessionHistory.count >= 2 { progressTrendCard }

                    // Filming guide (collapsed)
                    filmingGuideCard

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 40)
                .frame(width: UIScreen.main.bounds.width)
            }
        }
    }

    // MARK: - 1. Quick Stats

    private var quickStatsSummary: some View {
        let scores = feed.sessionHistory.compactMap { $0.overallScore }
        let best   = scores.max() ?? 0
        let avg    = scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count
        return QuickStatsBar(
            sessions:  feed.sessionHistory.count,
            bestScore: best,
            avgScore:  avg,
            onTapSessions:  { activeStatsSheet = .sessions },
            onTapBestScore: { activeStatsSheet = .bestScore },
            onTapAvgScore:  { activeStatsSheet = .avgScore }
        )
    }

    // MARK: - 2. Quick Record

    private var quickRecordCard: some View {
        VStack(spacing: 12) {
            // Hero tap area
            PhotosPicker(selection: $selectedItems, matching: .videos) {
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [Color.hrBlue, Color(red: 0.04, green: 0.36, blue: 0.82)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    HStack(spacing: 18) {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.18)).frame(width: 64, height: 64)
                            Circle().fill(Color.white.opacity(0.22)).frame(width: 52, height: 52)
                            if vm.isPreparing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: vm.videoURL == nil ? "video.badge.plus" : "video.fill.badge.checkmark")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            Text(vm.isPreparing ? "Preparing Video…"
                                 : vm.videoURL == nil ? "Analyze Your Swing"
                                 : "Video Ready")
                                .font(.title3.bold()).foregroundStyle(.white)
                            Text(vm.isPreparing ? "Loading your video, please wait"
                                 : vm.videoURL == nil
                                 ? "Choose a video to get your AI coaching report"
                                 : "Tap here to change video")
                                .font(.footnote).foregroundStyle(.white.opacity(0.75))
                                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                            if vm.videoURL != nil && !vm.isPreparing {
                                Label("Selected ✓", systemImage: "checkmark.circle.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.hrGreen)
                                    .padding(.top, 2)
                            }
                        }
                        Spacer(minLength: 0)
                        if !vm.isPreparing {
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    .padding(20)

                    // Inline progress bar at the bottom of the card
                    if vm.isPreparing || (vm.prepareProgress > 0 && vm.prepareProgress < 1.0) {
                        GeometryReader { geo in
                            VStack(spacing: 0) {
                                Spacer()
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white.opacity(0.25))
                                        .frame(height: 4)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white)
                                        .frame(width: geo.size.width * vm.prepareProgress, height: 4)
                                        .animation(.easeOut(duration: 0.15), value: vm.prepareProgress)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(vm.isPreparing ? Color.hrBlue.opacity(0.50) : Color.hrBlue.opacity(0.32), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(vm.isPreparing)

            // Inline settings row
            HStack(spacing: 12) {
                // Action type toggle
                HStack(spacing: 0) {
                    ForEach(ActionType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.spring(duration: 0.25)) { vm.actionType = type }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: type.icon).font(.system(size: 12))
                                Text(type.label).font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(vm.actionType == type ? Color.white : Color.primary.opacity(0.50))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(vm.actionType == type ? Color.hrBlue : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color.hrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                Spacer()

                // Age stepper
                HStack(spacing: 0) {
                    Button {
                        if vm.age > 6 { withAnimation(.spring(duration: 0.2)) { vm.age -= 1 } }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.primary.opacity(vm.age > 6 ? 1.0 : 0.35))
                            .frame(width: 36, height: 36)
                    }
                    Text("Age \(vm.age)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.primary)
                        .frame(width: 54)
                        .contentTransition(.numericText())
                    Button {
                        if vm.age < 18 { withAnimation(.spring(duration: 0.2)) { vm.age += 1 } }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.primary.opacity(vm.age < 18 ? 1.0 : 0.35))
                            .frame(width: 36, height: 36)
                    }
                }
                .background(Color.hrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    // MARK: - 3. Last Analysis

    private func lastAnalysisCard(_ cached: HomeFeedViewModel.CachedResult) -> some View {
        let fb = cached.result.feedback
        let gradeClr: Color = gradeColor(fb.grade)

        return VStack(alignment: .leading, spacing: 14) {
            feedSectionHeader(icon: "clock.arrow.circlepath", title: "Last Analysis",
                              subtitle: relativeDate(cached.date))
            HStack(spacing: 16) {
                // Grade bubble
                ZStack {
                    Circle().fill(gradeClr.opacity(0.14)).frame(width: 68, height: 68)
                    Circle().stroke(gradeClr.opacity(0.30), lineWidth: 1.5).frame(width: 68, height: 68)
                    Text(fb.grade)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(gradeClr)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(cached.result.actionType.capitalized)
                        .font(.caption).foregroundStyle(.primary.opacity(0.60))
                    HStack(spacing: 6) {
                        scorePill("Tech", fb.techniqueScore, .hrBlue)
                        scorePill("Pwr",  fb.powerScore,     .hrOrange)
                        scorePill("Bal",  fb.balanceScore,   .hrGreen)
                    }
                    Text(fb.plainSummary)
                        .font(.footnote).foregroundStyle(.primary.opacity(0.55))
                        .lineLimit(2)
                }
            }
        }
        .hrCard()
    }

    private var emptyLastAnalysisCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 28))
                .foregroundStyle(.primary.opacity(0.30))
            VStack(alignment: .leading, spacing: 4) {
                Text("No analysis yet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary.opacity(0.55))
                Text("Record your first video to see your AI coaching report")
                    .font(.caption).foregroundStyle(.primary.opacity(0.40))
            }
            Spacer()
        }
        .hrCard()
    }

    // MARK: - Compact Grid Cards

    private func compactAnalysisCard(_ cached: HomeFeedViewModel.CachedResult) -> some View {
        let fb = cached.result.feedback
        let gradeClr = gradeColor(fb.grade)
        return VStack(spacing: 12) {
            // Large grade circle
            ZStack {
                Circle().fill(gradeClr.opacity(0.14)).frame(width: 56, height: 56)
                Circle().stroke(gradeClr.opacity(0.35), lineWidth: 1.5).frame(width: 56, height: 56)
                Text(fb.grade)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(gradeClr)
            }
            Text("Last Score")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.45))
                .textCase(.uppercase).tracking(0.5)
            HStack(spacing: 4) {
                scorePill("T", fb.techniqueScore, .hrBlue)
                scorePill("P", fb.powerScore, .hrOrange)
                scorePill("B", fb.balanceScore, .hrGreen)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.hrStroke, lineWidth: 1))
    }

    private var compactEmptyCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.primary.opacity(0.20))
            Text("No Analysis")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.40))
                .textCase(.uppercase).tracking(0.5)
            Text("Record a video\nto get started")
                .font(.caption)
                .foregroundStyle(.primary.opacity(0.35))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.hrStroke, lineWidth: 1))
    }

    private var compactDrillCard: some View {
        let drill = feed.todaysDrill
        return VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.hrOrange.opacity(0.14)).frame(width: 56, height: 56)
                Image(systemName: "figure.baseball")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color.hrOrange)
            }
            Text("Today's Drill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.45))
                .textCase(.uppercase).tracking(0.5)
            Text(drill.name)
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if let reps = drill.reps {
                Text(reps)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.hrOrange)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.hrOrange.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            LinearGradient(
                colors: [Color.hrOrange.opacity(0.08), Color.hrCard],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.hrOrange.opacity(0.18), lineWidth: 1))
    }

    // MARK: - 4. Today's Drill (full-width — kept for reference but replaced by compactDrillCard)

    private var todaysDrillCard: some View {
        let drill = feed.todaysDrill
        return VStack(alignment: .leading, spacing: 14) {
            feedSectionHeader(icon: "figure.baseball", title: "Today's Drill",
                              subtitle: dayOfWeekString)
            VStack(alignment: .leading, spacing: 8) {
                Text(drill.name)
                    .font(.headline).foregroundStyle(.primary)
                Text(drill.description)
                    .font(.subheadline).foregroundStyle(.primary.opacity(0.60))
                    .fixedSize(horizontal: false, vertical: true)
                if let reps = drill.reps {
                    Label(reps, systemImage: "repeat")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.hrOrange)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.hrOrange.opacity(0.14))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.hrOrange.opacity(0.12), Color.hrCard],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.hrOrange.opacity(0.22), lineWidth: 1))
    }

    // MARK: - 5. Progress Trend

    private var progressTrendCard: some View {
        let history = feed.sessionHistory
        let delta = feed.progressDelta
        let chartData = history.enumerated().map { (i: $0.offset, s: $0.element.overallScore ?? 0) }

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                feedSectionHeader(icon: "chart.line.uptrend.xyaxis", title: "Progress",
                                  subtitle: "\(history.count) sessions")
                Spacer()
                if let d = delta {
                    HStack(spacing: 4) {
                        Image(systemName: d >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.weight(.bold))
                        Text("\(d > 0 ? "+" : "")\(d) pts")
                            .font(.caption.weight(.bold).monospacedDigit())
                    }
                    .foregroundStyle(d >= 0 ? Color.hrGreen : Color.hrRed)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background((d >= 0 ? Color.hrGreen : Color.hrRed).opacity(0.14))
                    .clipShape(Capsule())
                }
            }
            Chart(chartData, id: \.i) { item in
                AreaMark(x: .value("S", item.i), y: .value("Score", item.s))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.hrBlue.opacity(0.28), Color.hrBlue.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value("S", item.i), y: .value("Score", item.s))
                    .foregroundStyle(Color.hrBlue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("S", item.i), y: .value("Score", item.s))
                    .foregroundStyle(.primary).symbolSize(22)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.hrSurface)
                    AxisValueLabel {
                        Text("\(v.as(Int.self) ?? 0)")
                            .font(.system(size: 9)).foregroundStyle(.primary.opacity(0.40))
                    }
                }
            }
            .frame(height: 90)
        }
        .hrCard()
    }

    // MARK: - 6. Age Ranking

    private var ageRankingCard: some View {
        let pct = feed.estimatedPercentile(age: vm.age)
        return VStack(alignment: .leading, spacing: 14) {
            feedSectionHeader(icon: "rosette", title: "Your Ranking",
                              subtitle: "Age \(vm.age) group")
            if let p = pct {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Top").font(.subheadline).foregroundStyle(.primary.opacity(0.60))
                        Text("\(p)%")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(Color.hrGold)
                        Text("in your age group")
                            .font(.subheadline).foregroundStyle(.primary.opacity(0.55))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.hrSurface).frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(
                                    colors: [Color.hrGold, Color.hrOrange],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: geo.size.width * (1.0 - Double(p) / 100.0), height: 8)
                        }
                    }
                    .frame(height: 8)
                    Text("Based on AI benchmark estimates · Peer comparison coming soon")
                        .font(.system(size: 10)).foregroundStyle(.primary.opacity(0.35))
                }
            } else {
                Text("Analyze a video to see how you rank against players your age")
                    .font(.subheadline).foregroundStyle(.primary.opacity(0.50))
            }
        }
        .hrCard()
    }

    // MARK: - 7. Filming Guide

    @State private var showFullGuide = false

    private var filmingGuideCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.spring(duration: 0.35)) { showFullGuide.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.hrBlue)
                    Text("Filming Guide")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showFullGuide ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary.opacity(0.40))
                }
            }
            .buttonStyle(.plain)

            if showFullGuide {
                FilmingDiagramView(actionType: vm.actionType)

                VStack(alignment: .leading, spacing: 14) {
                    Divider().background(Color.hrDivider)
                    filmingTip(icon: "camera.fill", color: .hrBlue, title: "Camera Position",
                               items: vm.actionType == .swing
                               ? ["Side view — level with batter's waist",
                                  "Keep full body in frame at all times",
                                  "3–5 meters from home plate"]
                               : ["Behind catcher at catcher's height",
                                  "Capture full pitching motion",
                                  "3–5 meters behind home plate"])
                    filmingTip(icon: "checkmark.circle.fill", color: .hrGreen,
                               title: "Before Recording",
                               items: ["Good lighting — outdoors or bright gym",
                                       "Plain background if possible",
                                       "Landscape (horizontal) orientation"])
                    filmingTip(icon: "xmark.circle.fill", color: .hrRed, title: "Avoid",
                               items: ["Shaky handheld camera",
                                       "Partial body cutoff",
                                       "Very dark or backlit scenes"])
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .hrCard()
    }

    private func filmingTip(icon: String, color: Color, title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: icon)
                .font(.footnote.weight(.semibold)).foregroundStyle(color)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(Color.hrDivider)
                        .frame(width: 4, height: 4).padding(.top, 6)
                    Text(item).font(.footnote).foregroundStyle(.primary.opacity(0.60))
                }
            }
        }
    }

    // MARK: - Auto-Detect Card

    private var autoDetectCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Color.hrBlue.opacity(0.3), lineWidth: 2)
                        .frame(width: 36, height: 36)
                    Circle()
                        .trim(from: 0, to: vm.detectProgress)
                        .stroke(Color.hrBlue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.15), value: vm.detectProgress)
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.hrBlue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Detecting Action...")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("Scanning for swing/pitch moments")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.55))
                }

                Spacer()

                Text("\(Int(vm.detectProgress * 100))%")
                    .font(.system(size: 12, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color.hrBlue)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.hrDivider)
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.hrBlue)
                        .frame(width: geo.size.width * vm.detectProgress, height: 3)
                        .animation(.easeOut(duration: 0.15), value: vm.detectProgress)
                }
            }
            .frame(height: 3)
        }
        .padding(16)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.hrBlue.opacity(0.2), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Trimming Card

    private var trimmingCard: some View {
        HStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.hrBlue)
                .scaleEffect(0.8)
            Text("Trimming video...")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.7))
            Spacer()
        }
        .padding(16)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .transition(.opacity)
    }

    // MARK: - Trim Result Badge

    private var trimResultBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.hrGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text("Video Trimmed")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primary)
                if let detection = vm.detectionResult {
                    Text("Action clip: \(String(format: "%.1fs", detection.trimRange.upperBound - detection.trimRange.lowerBound)) of \(String(format: "%.1fs", detection.videoDuration))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.55))
                }
            }
            Spacer()
            Button {
                vm.trimmedVideoURL = nil
                vm.showTrimPreview = true
            } label: {
                Text("Undo")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.hrBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.hrBlue.opacity(0.14))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.hrGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.hrGreen.opacity(0.2), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - 8. Start Analysis Button

    private var startAnalysisButton: some View {
        Button {
            Task {
                let token = await authVM.accessToken()
                await vm.analyze(token: token)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "waveform.and.magnifyingglass")
                    .font(.system(size: 17, weight: .semibold))
                Text("Start Analysis").font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(LinearGradient(
                colors: [Color.hrBlue, Color(red: 0.04, green: 0.36, blue: 0.80)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.hrBlue.opacity(0.55), radius: 14, y: 5)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Shared helpers

    private func feedSectionHeader(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.hrBlue)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary.opacity(0.60))
                    .textCase(.uppercase).tracking(0.6)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.primary.opacity(0.40))
            }
        }
    }

    private func scorePill(_ label: String, _ value: Int, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(color.opacity(0.80))
            Text("\(value)").font(.system(size: 11, weight: .bold).monospacedDigit()).foregroundStyle(.primary)
        }
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(color.opacity(0.14)).clipShape(Capsule())
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A+", "A": return .hrGreen
        case "B":        return .hrBlue
        case "C":        return .hrOrange
        default:         return .hrRed
        }
    }

    // MARK: - Date helpers

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }
    private var dateString: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"; return f.string(from: Date())
    }
    private var dayOfWeekString: String {
        let f = DateFormatter(); f.dateFormat = "EEEE"; return f.string(from: Date())
    }
    private func relativeDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: date)
    }
}

// MARK: - Filming Diagram Animation

struct FilmingDiagramView: View {
    let actionType: ActionType
    @State private var camPulse  = false
    @State private var dashPhase: CGFloat = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.hrSurface)

            HStack(spacing: 0) {
                // Camera
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.hrBlue.opacity(camPulse ? 0.0 : 0.28), lineWidth: 1.5)
                            .frame(width: camPulse ? 72 : 50, height: camPulse ? 72 : 50)
                            .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: camPulse)
                        Circle()
                            .stroke(Color.hrBlue.opacity(camPulse ? 0.0 : 0.18), lineWidth: 1)
                            .frame(width: camPulse ? 58 : 44, height: camPulse ? 58 : 44)
                            .animation(.easeOut(duration: 1.5).delay(0.4).repeatForever(autoreverses: false), value: camPulse)
                        Circle()
                            .fill(Color.hrBlue.opacity(0.18)).frame(width: 44, height: 44)
                        Image(systemName: "video.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.hrBlue)
                    }
                    Text("CAMERA")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.primary.opacity(0.40)).tracking(1.2)
                }
                .frame(width: 80)

                // Scan zone
                ZStack {
                    HRScanCone().fill(Color.hrBlue.opacity(0.05))
                    GeometryReader { geo in
                        Path { p in
                            p.move(to: .init(x: 0, y: geo.size.height / 2))
                            p.addLine(to: .init(x: geo.size.width, y: geo.size.height / 2))
                        }
                        .stroke(Color.hrBlue.opacity(0.35),
                                style: StrokeStyle(lineWidth: 1.5, dash: [7, 5], dashPhase: dashPhase))
                    }
                    VStack {
                        Spacer()
                        Text("Side view · 3–5 m · Waist height")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.40)).tracking(0.3)
                    }
                    .padding(.bottom, 4)
                }
                .frame(maxWidth: .infinity)

                // Player
                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.hrSurface).frame(width: 44, height: 44)
                        Image(systemName: actionType.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(.primary.opacity(0.65))
                    }
                    Text("PLAYER")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.primary.opacity(0.40)).tracking(1.2)
                }
                .frame(width: 80)
            }
            .padding(.horizontal, 8).padding(.vertical, 14)
        }
        .frame(height: 100)
        .onAppear {
            camPulse = true
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                dashPhase = -24
            }
        }
    }
}

struct HRScanCone: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cy = rect.midY
        p.move(to: CGPoint(x: rect.minX, y: cy - 8))
        p.addLine(to: CGPoint(x: rect.maxX, y: cy - 28))
        p.addLine(to: CGPoint(x: rect.maxX, y: cy + 28))
        p.addLine(to: CGPoint(x: rect.minX, y: cy + 8))
        p.closeSubpath()
        return p
    }
}

// MARK: - Quality error sheet

struct QualityErrorSheet: View {
    let qualityError: QualityError
    let onDismiss: () -> Void
    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()
                List {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.hrOrange).font(.title3)
                            Text("Video quality check failed. Please re-record and try again.")
                                .font(.subheadline).foregroundStyle(.primary.opacity(0.75))
                        }
                        .listRowBackground(Color.hrCard)
                    }
                    Section("Issues Found") {
                        ForEach(qualityError.issues) { issue in
                            Label(issue.message,
                                  systemImage: issue.severity == "error"
                                  ? "xmark.circle.fill"
                                  : "exclamationmark.triangle.fill")
                                .foregroundStyle(issue.severity == "error" ? Color.hrRed : Color.hrOrange)
                                .font(.subheadline)
                                .listRowBackground(Color.hrCard)
                        }
                    }
                    if let rate = qualityError.visibilityRate {
                        Section("Visibility Rate") {
                            Text("\(Int(rate * 100))% of frames had detectable pose")
                                .font(.subheadline).foregroundStyle(.primary.opacity(0.60))
                                .listRowBackground(Color.hrCard)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Video Quality").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Try Again", action: onDismiss).foregroundStyle(Color.hrBlue)
                }
            }
        }
    }
}

