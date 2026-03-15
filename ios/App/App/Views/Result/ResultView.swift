import SwiftUI

struct ResultView: View {
    let result: AnalysisResult
    var videoURL: URL? = nil
    var usedCache: Bool = false
    var onReanalyze: (() -> Void)? = nil
    let onReset: () -> Void

    @State private var parentMode = false
    @State private var appeared = false
    @State private var showSessionPicker = false
    @State private var comparisonVM: ComparisonViewModel?
    @State private var pendingComparisonSession: ComparisonSession?
    @State private var fusionResult: FusionResult?
    @State private var watchSession: SwingSession?

    private var feedback: Feedback { result.feedback }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {

                        if usedCache {
                            cacheBanner
                                .staggered(appeared, delay: 0.01)
                        }

                        if let videoURL {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader("Video Replay", icon: "play.rectangle.fill", accent: Color.hrBlue)
                                VideoReplayView(videoURL: videoURL)
                            }
                            .hrCard(padding: 12)
                            .staggered(appeared, delay: 0.02)
                        }

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

                        // Compare Swings button
                        compareSwingsButton
                            .staggered(appeared, delay: 0.20)

                        // Export Report button
                        exportReportSection
                            .staggered(appeared, delay: 0.21)

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
                            // Bat Plane Analysis gauge (swing only)
                            if result.actionType == "swing",
                               let pe = result.metrics.planeEfficiency {
                                PlaneEfficiencyGaugeView(
                                    efficiency: pe,
                                    consistency: result.metrics.batPathConsistency
                                )
                                .staggered(appeared, delay: 0.36)
                            }

                            // Swing Metrics Dashboard
                            SwingMetricsDashboard(
                                metrics: result.metrics,
                                actionType: result.actionType
                            )
                            .staggered(appeared, delay: 0.40)

                            // Fusion Metrics (when Watch data available)
                            if let fusion = fusionResult {
                                ProMetricsCard(fusion: fusion)
                                    .staggered(appeared, delay: 0.44)

                                // Speed Distribution (5+ swings)
                                if let session = fusion.sessionMetrics,
                                   session.speedDistribution.count >= 5 {
                                    SpeedDistributionChart(
                                        speeds: session.speedDistribution,
                                        meanSpeed: session.speedMean,
                                        stdDev: session.speedStdDev
                                    )
                                    .staggered(appeared, delay: 0.48)
                                }

                                // Swing Timeline (multiple swings)
                                if fusion.perSwingMetrics.count >= 2 {
                                    SwingTimelineView(swings: fusion.perSwingMetrics)
                                        .staggered(appeared, delay: 0.52)
                                }
                            }

                            // Watch Metrics Card (when watch session available)
                            if let ws = watchSession {
                                WatchMetricsCard(session: ws)
                                    .staggered(appeared, delay: 0.56)
                            }

                            // Swing Detail Card (when multiple swings)
                            if let ws = watchSession, ws.swings.count >= 2 {
                                SwingDetailCard(swings: ws.swings)
                                    .staggered(appeared, delay: 0.60)
                            }

                            // Heat Map (when 3+ swings with attack angle data)
                            if let ws = watchSession,
                               ws.swings.filter({ $0.attackAngleDegrees != nil }).count >= 3 {
                                HeatMapView(swings: ws.swings)
                                    .staggered(appeared, delay: 0.64)
                            }

                            // Session Summary Card (when session data available)
                            if let ws = watchSession {
                                SessionSummaryCard(
                                    session: ws,
                                    fusionMetrics: fusionResult?.sessionMetrics
                                )
                                .staggered(appeared, delay: 0.68)
                            }
                        }

                        Spacer(minLength: 36)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .contentShape(Rectangle())
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
        .onAppear {
            appeared = true
            // Store current video URL for future comparison lookups
            if let videoURL, let videoId = result.videoId {
                VideoURLStore.shared.store(videoId: videoId, url: videoURL)
            }
            // Run sensor fusion if watch session data is available
            computeFusion()
        }
        .fullScreenCover(item: $comparisonVM) { vm in
            ComparisonView(vm: vm)
        }
        .sheet(isPresented: $showSessionPicker, onDismiss: {
            // Delayed presentation: wait for sheet dismiss animation to finish
            // before presenting the fullScreenCover to avoid SwiftUI conflict.
            if let session = pendingComparisonSession {
                pendingComparisonSession = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    openComparison(with: session)
                }
            }
        }) {
            SessionPickerView(
                sessions: buildHistorySessions(),
                onSelect: { selected in
                    // Store the selection — don't open comparison yet.
                    // The sheet's onDismiss will handle it after dismiss completes.
                    pendingComparisonSession = selected
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Compare Swings Button

    private var compareSwingsButton: some View {
        Button {
            if let prev = result.previousSession, prev.videoId != nil {
                // Direct compare with previous session
                let prevSession = buildComparisonSession(from: prev)
                openComparison(with: prevSession)
            } else {
                // Open session picker
                showSessionPicker = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.split.2x1.fill")
                    .font(.system(size: 14))
                Text("Compare Swings")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.hrBlue, Color.hrBlue.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.hrBlue.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Export Report

    private var exportReportSection: some View {
        ReportShareSheet(
            result: result,
            videoURL: videoURL,
            playerAge: nil  // Could be passed from UploadViewModel if needed
        )
    }

    // MARK: - Comparison Helpers

    private func openComparison(with otherSession: ComparisonSession) {
        let currentSession = buildCurrentSession()
        // Setting comparisonVM to non-nil triggers fullScreenCover(item:) automatically.
        // Dismissing the cover sets it back to nil.
        comparisonVM = ComparisonViewModel(left: otherSession, right: currentSession)
    }

    private func buildCurrentSession() -> ComparisonSession {
        let summary = SessionSummary(
            videoId: result.videoId,
            actionType: result.actionType,
            overallScore: feedback.overallScore,
            techniqueScore: feedback.techniqueScore,
            powerScore: feedback.powerScore,
            balanceScore: feedback.balanceScore,
            createdAt: nil
        )
        return ComparisonSession(
            id: result.videoId ?? UUID().uuidString,
            videoURL: videoURL,
            sessionSummary: summary,
            analysisResult: result,
            poseData: nil,
            syncPointTime: nil
        )
    }

    private func buildComparisonSession(from summary: SessionSummary) -> ComparisonSession {
        let url: URL? = {
            guard let vid = summary.videoId else { return nil }
            return VideoURLStore.shared.url(for: vid)
        }()
        return ComparisonSession(
            id: summary.videoId ?? UUID().uuidString,
            videoURL: url,
            sessionSummary: summary,
            analysisResult: nil,
            poseData: nil,
            syncPointTime: nil
        )
    }

    private func buildHistorySessions() -> [ComparisonSession] {
        guard let history = result.history else { return [] }
        // Exclude the current session from the list
        return history
            .filter { $0.videoId != result.videoId }
            .map { buildComparisonSession(from: $0) }
    }

    // MARK: - Cache Banner

    private var cacheBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.hrBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Loaded from cache")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Same video detected — instant result")
                    .font(.caption2)
                    .foregroundStyle(.primary.opacity(0.55))
            }

            Spacer()

            if let onReanalyze {
                Button {
                    onReanalyze()
                } label: {
                    Text("Re-analyze")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.hrBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.hrBlue.opacity(0.15))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.hrBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.hrBlue.opacity(0.20), lineWidth: 1)
        )
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
                    .foregroundStyle(.primary.opacity(0.65))
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

    // MARK: - Score rings + Radar

    private var radarAxes: [RadarChartView.RadarAxis] {
        [
            .init(label: "Technique", value: Double(feedback.techniqueScore),
                  icon: "figure.baseball", color: .hrBlue),
            .init(label: "Power", value: Double(feedback.powerScore),
                  icon: "bolt.fill", color: .hrOrange),
            .init(label: "Balance", value: Double(feedback.balanceScore),
                  icon: "figure.stand", color: .hrGreen),
        ]
    }

    private var scoreRingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Performance Scores", icon: "chart.bar.fill")
            overallRingSection
            radarSection
            miniRingsSection
        }
        .hrCard()
    }

    private var overallRingSection: some View {
        HStack {
            Spacer()
            ScoreRingView(score: feedback.overallScore, label: "Overall", size: 90, lineWidth: 9)
            Spacer()
        }
    }

    private var radarSection: some View {
        HStack {
            Spacer()
            RadarChartView(axes: radarAxes, size: 200)
            Spacer()
        }
    }

    private var miniRingsSection: some View {
        HStack(spacing: 10) {
            ScoreRingView(score: feedback.techniqueScore, label: "Technique", size: 56, lineWidth: 5)
            ScoreRingView(score: feedback.powerScore,     label: "Power",     size: 56, lineWidth: 5)
            ScoreRingView(score: feedback.balanceScore,   label: "Balance",   size: 56, lineWidth: 5)
        }
        .frame(maxWidth: .infinity)
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
                            .foregroundStyle(.primary.opacity(0.80))
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
                    .foregroundStyle(.primary)

                Text(drill.description)
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.65))

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
                .foregroundStyle(.primary.opacity(0.72))
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

    // MARK: - Fusion

    private func computeFusion() {
        Task { @MainActor in
            let watchManager = WatchSessionManager.shared
            // Try to find a matching watch session (within 10 minutes of now)
            let session = watchManager.mostRecentSession(maxAge: 3600)
                ?? watchManager.findMatchingSession(near: Date())

            // Store watch session for new visualization components
            if let session {
                withAnimation(.spring(duration: 0.4)) {
                    self.watchSession = session
                }
            }

            // Always compute fusion — works with video-only too when no watch data
            let fusion = FusionAnalysisService.shared.analyze(
                video: result,
                session: session,
                playerAge: 12 // TODO: get from profile
            )

            // Only show fusion card if we have watch data OR meaningful video metrics
            if fusion.hasWatchData || fusion.calibratedBatSpeedMPH > 0 {
                withAnimation(.spring(duration: 0.4)) {
                    self.fusionResult = fusion
                }
            }
        }
    }

    // metricsCard replaced by SwingMetricsDashboard + PlaneEfficiencyGaugeView

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String, accent: Color = .primary.opacity(0.55)) -> some View {
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
                    .foregroundStyle(.primary.opacity(0.60))
                Spacer()
                Text(value)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 11)

            if !last {
                Divider().background(Color.hrSurface)
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
