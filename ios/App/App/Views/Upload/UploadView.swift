import SwiftUI
import PhotosUI
import Charts

// MARK: - UploadView (Training Dashboard Home)

struct UploadView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm   = UploadViewModel()
    @StateObject private var feed = HomeFeedViewModel()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    LoadingView(step: vm.loadStep, progress: vm.uploadProgress)
                } else if let result = vm.result {
                    ResultView(result: result) {
                        feed.saveLastResult(result)
                        vm.reset()
                    }
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("AIHomeRun")
            .navigationBarTitleDisplayMode(.large)
            .alert("Analysis Error", isPresented: .constant(vm.error != nil)) {
                Button("OK") { vm.error = nil }
            } message: { Text(vm.error ?? "") }
            .sheet(isPresented: .constant(vm.qualityError != nil)) {
                QualityErrorSheet(qualityError: vm.qualityError!) { vm.qualityError = nil }
                    .presentationDetents([.medium])
            }
        }
        .task {
            let token = await authVM.accessToken()
            await feed.loadFeed(token: token)
        }
        .onChange(of: selectedItem) { item in
            Task {
                guard let item,
                      let data = try? await item.loadTransferable(type: Data.self) else { return }
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("mov")
                try? data.write(to: url)
                vm.videoURL = url
            }
        }
    }

    // MARK: - Dashboard

    private var dashboardContent: some View {
        ZStack {
            Color.hrBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    greetingHeader
                    quickRecordCard
                    if let cached = feed.lastResult {
                        lastAnalysisCard(cached)
                    } else {
                        emptyLastAnalysisCard
                    }
                    todaysDrillCard
                    if feed.sessionHistory.count >= 2 { progressTrendCard }
                    ageRankingCard
                    filmingGuideCard
                    if vm.videoURL != nil { analyzeButton }
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - 1. Greeting

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.40))
                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.25))
            }
            Spacer()
            if feed.isLoadingFeed {
                ProgressView().scaleEffect(0.7).tint(.white.opacity(0.3))
            }
        }
    }

    // MARK: - 2. Quick Record

    private var quickRecordCard: some View {
        VStack(spacing: 12) {
            // Hero tap area
            PhotosPicker(selection: $selectedItem, matching: .videos) {
                ZStack {
                    LinearGradient(
                        colors: [Color.hrBlue.opacity(0.28), Color.hrCard],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    HStack(spacing: 18) {
                        ZStack {
                            Circle().fill(Color.hrBlue.opacity(0.20)).frame(width: 64, height: 64)
                            Circle().fill(Color.hrBlue.opacity(0.28)).frame(width: 52, height: 52)
                            Image(systemName: vm.videoURL == nil ? "video.badge.plus" : "video.fill.badge.checkmark")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            Text(vm.videoURL == nil ? "Analyze Your Swing" : "Video Ready")
                                .font(.title3.bold()).foregroundStyle(.white)
                            Text(vm.videoURL == nil
                                 ? "Choose a video to get your AI coaching report"
                                 : "Tap Analyze below — or tap here to change video")
                                .font(.footnote).foregroundStyle(.white.opacity(0.52))
                                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                            if vm.videoURL != nil {
                                Label("Selected ✓", systemImage: "checkmark.circle.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.hrGreen)
                                    .padding(.top, 2)
                            }
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.28))
                    }
                    .padding(20)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.hrBlue.opacity(0.32), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

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
                            .foregroundStyle(vm.actionType == type ? .white : .white.opacity(0.35))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(vm.actionType == type ? Color.hrBlue : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                Spacer()

                // Age stepper
                HStack(spacing: 0) {
                    Button {
                        if vm.age > 6 { withAnimation(.spring(duration: 0.2)) { vm.age -= 1 } }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(vm.age > 6 ? .white : .white.opacity(0.20))
                            .frame(width: 36, height: 36)
                    }
                    Text("Age \(vm.age)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 54)
                        .contentTransition(.numericText())
                    Button {
                        if vm.age < 18 { withAnimation(.spring(duration: 0.2)) { vm.age += 1 } }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(vm.age < 18 ? .white : .white.opacity(0.20))
                            .frame(width: 36, height: 36)
                    }
                }
                .background(Color.white.opacity(0.07))
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
                        .font(.caption).foregroundStyle(.white.opacity(0.35))
                    HStack(spacing: 6) {
                        scorePill("Tech", fb.techniqueScore, .hrBlue)
                        scorePill("Pwr",  fb.powerScore,     .hrOrange)
                        scorePill("Bal",  fb.balanceScore,   .hrGreen)
                    }
                    Text(fb.plainSummary)
                        .font(.footnote).foregroundStyle(.white.opacity(0.55))
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
                .foregroundStyle(.white.opacity(0.18))
            VStack(alignment: .leading, spacing: 4) {
                Text("No analysis yet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.42))
                Text("Record your first video to see your AI coaching report")
                    .font(.caption).foregroundStyle(.white.opacity(0.26))
            }
            Spacer()
        }
        .hrCard()
    }

    // MARK: - 4. Today's Drill

    private var todaysDrillCard: some View {
        let drill = feed.todaysDrill
        return VStack(alignment: .leading, spacing: 14) {
            feedSectionHeader(icon: "figure.baseball", title: "Today's Drill",
                              subtitle: dayOfWeekString)
            VStack(alignment: .leading, spacing: 8) {
                Text(drill.name)
                    .font(.headline).foregroundStyle(.white)
                Text(drill.description)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.60))
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
                    .foregroundStyle(.white).symbolSize(22)
            }
            .chartYScale(domain: 0...100)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.07))
                    AxisValueLabel {
                        Text("\(v.as(Int.self) ?? 0)")
                            .font(.system(size: 9)).foregroundStyle(.white.opacity(0.25))
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
                        Text("Top").font(.subheadline).foregroundStyle(.white.opacity(0.50))
                        Text("\(p)%")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(Color.hrGold)
                        Text("in your age group")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.42))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.07)).frame(height: 8)
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
                        .font(.system(size: 10)).foregroundStyle(.white.opacity(0.22))
                }
            } else {
                Text("Analyze a video to see how you rank against players your age")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.36))
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
                HStack {
                    feedSectionHeader(icon: "camera.viewfinder", title: "Filming Guide",
                                      subtitle: "How to position the camera")
                    Spacer()
                    Image(systemName: showFullGuide ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.30))
                }
            }
            .buttonStyle(.plain)

            FilmingDiagramView(actionType: vm.actionType)

            if showFullGuide {
                VStack(alignment: .leading, spacing: 14) {
                    Divider().background(Color.white.opacity(0.08))
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
                    Circle().fill(Color.white.opacity(0.20))
                        .frame(width: 4, height: 4).padding(.top, 6)
                    Text(item).font(.footnote).foregroundStyle(.white.opacity(0.52))
                }
            }
        }
    }

    // MARK: - 8. Analyze Button

    private var analyzeButton: some View {
        Button {
            Task {
                let token = await authVM.accessToken()
                await vm.analyze(token: token)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "waveform.and.magnifyingglass")
                    .font(.system(size: 17, weight: .semibold))
                Text("Analyze Video").font(.headline)
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
                    .foregroundStyle(.white.opacity(0.52))
                    .textCase(.uppercase).tracking(0.6)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.26))
            }
        }
    }

    private func scorePill(_ label: String, _ value: Int, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(color.opacity(0.80))
            Text("\(value)").font(.system(size: 11, weight: .bold).monospacedDigit()).foregroundStyle(.white)
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
                .fill(Color.white.opacity(0.03))

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
                        .foregroundStyle(.white.opacity(0.26)).tracking(1.2)
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
                            .foregroundStyle(.white.opacity(0.25)).tracking(0.3)
                    }
                    .padding(.bottom, 4)
                }
                .frame(maxWidth: .infinity)

                // Player
                VStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.07)).frame(width: 44, height: 44)
                        Image(systemName: actionType.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    Text("PLAYER")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.26)).tracking(1.2)
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
                                .font(.subheadline).foregroundStyle(.white.opacity(0.75))
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
                                .font(.subheadline).foregroundStyle(.white.opacity(0.5))
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
        .preferredColorScheme(.dark)
    }
}
