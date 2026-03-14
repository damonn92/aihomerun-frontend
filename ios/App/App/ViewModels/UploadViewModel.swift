import Foundation
import SwiftUI
import PhotosUI

// MARK: - Action Type

enum ActionType: String, CaseIterable {
    case swing = "swing"
    case pitch = "pitch"
    var label: String { rawValue.capitalized }
    var icon: String { self == .swing ? "figure.baseball" : "figure.softball" }
}

// MARK: - Upload / Analyze ViewModel

@MainActor
class UploadViewModel: ObservableObject {
    @Published var videoURL: URL?
    @Published var actionType: ActionType = .swing
    @Published var age: Int = 12
    @Published var isLoading = false
    @Published var loadStep: Int = 0
    @Published var uploadProgress: Double = 0
    @Published var result: AnalysisResult?
    @Published var error: String?
    @Published var qualityError: QualityError?
    @Published var isPreparing = false
    @Published var prepareProgress: Double = 0
    @Published var usedCache = false

    // MARK: - Auto-Detect State

    @Published var isDetecting = false
    @Published var detectProgress: Double = 0
    @Published var detectionResult: ActionDetectionService.DetectionResult?
    @Published var showTrimPreview = false
    @Published var trimmedVideoURL: URL?
    @Published var isTrimming = false

    private let detectionService = ActionDetectionService()

    func analyze(token: String?, forceRefresh: Bool = false) async {
        // Use trimmed video if available, otherwise original
        let effectiveURL = trimmedVideoURL ?? videoURL
        guard let videoURL = effectiveURL else { return }
        isLoading = true
        loadStep = 0
        uploadProgress = 0
        error = nil
        qualityError = nil
        result = nil
        usedCache = false

        // Check cache first (unless force-refreshing)
        if !forceRefresh {
            let cache = AnalysisResultCache.shared
            if let cached = await cache.cached(for: videoURL, actionType: actionType.rawValue, age: age) {
                self.result = cached
                self.usedCache = true
                self.uploadProgress = 1.0
                self.isLoading = false
                // Store video URL mapping for comparison lookups
                if let videoId = cached.videoId {
                    VideoURLStore.shared.store(videoId: videoId, url: videoURL)
                }
                return
            }
        }

        // Simulated progress task: advances the bar during the AI processing phase
        // (after upload completes, the real callback stops at ~0.40)
        let simTask = Task { [weak self] in
            // Wait until real upload has started (progress > 0.36)
            var wait = 0
            while (self?.uploadProgress ?? 1.0) < 0.36, wait < 120, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                wait += 1
            }
            // Slowly creep from current progress up to 0.95
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 700_000_000)
                guard let self, !Task.isCancelled else { break }
                let cur = self.uploadProgress
                guard cur < 0.95 else { break }
                self.uploadProgress = min(0.95, cur + Double.random(in: 0.007...0.018))
                let p = self.uploadProgress
                if p > 0.52 && self.loadStep < 2 { self.loadStep = 2 }
                if p > 0.78 && self.loadStep < 3 { self.loadStep = 3 }
            }
        }

        do {
            let analysisResult = try await APIClient.shared.analyzeVideo(
                fileURL: videoURL,
                actionType: actionType.rawValue,
                age: age,
                token: token
            ) { [weak self] progress in
                Task { @MainActor in
                    guard let self else { return }
                    // Only advance, never retreat
                    if progress > self.uploadProgress { self.uploadProgress = progress }
                    if progress > 0.35 && self.loadStep < 1 { self.loadStep = 1 }
                }
            }
            simTask.cancel()
            uploadProgress = 1.0
            self.result = analysisResult

            // Cache the result for future lookups
            await AnalysisResultCache.shared.store(analysisResult, for: videoURL, actionType: actionType.rawValue, age: age)

            // Store video URL mapping for future comparison lookups
            if let videoId = analysisResult.videoId {
                VideoURLStore.shared.store(videoId: videoId, url: videoURL)
            }
        } catch APIError.qualityGateFailure(let qe) {
            simTask.cancel()
            qualityError = qe
        } catch {
            simTask.cancel()
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    /// Force re-analyze the current video, bypassing cache.
    func reanalyze(token: String?) async {
        let effectiveURL = trimmedVideoURL ?? videoURL
        guard let url = effectiveURL else { return }
        // Remove cached entry first
        await AnalysisResultCache.shared.remove(for: url, actionType: actionType.rawValue, age: age)
        await analyze(token: token, forceRefresh: true)
    }

    /// Load the selected video file, animate a "preparing" progress bar, then run auto-detect.
    func prepareVideo(from item: PhotosPickerItem) async {
        isPreparing = true
        prepareProgress = 0
        videoURL = nil
        detectionResult = nil
        showTrimPreview = false
        trimmedVideoURL = nil

        // Animate progress while loading
        let simTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 120_000_000)
                guard let self, !Task.isCancelled else { break }
                let cur = self.prepareProgress
                guard cur < 0.90 else { break }
                self.prepareProgress = min(0.90, cur + Double.random(in: 0.03...0.08))
            }
        }

        if let movie = try? await item.loadTransferable(type: MovieTransferable.self) {
            videoURL = movie.url
        }

        simTask.cancel()
        withAnimation(.easeOut(duration: 0.3)) {
            prepareProgress = 1.0
        }
        // Brief pause at 100% so user sees completion
        try? await Task.sleep(nanoseconds: 400_000_000)
        isPreparing = false

        // Auto-detect action after video is ready
        if videoURL != nil {
            await runAutoDetect()
        }
    }

    // MARK: - Auto-Detect

    /// Scan the video for the peak action moment.
    func runAutoDetect() async {
        guard let url = videoURL else { return }

        isDetecting = true
        detectProgress = 0
        detectionResult = nil

        do {
            let result = try await detectionService.detectAction(videoURL: url) { [weak self] progress in
                Task { @MainActor in
                    self?.detectProgress = progress
                }
            }

            detectionResult = result
            if result != nil {
                withAnimation(.spring(duration: 0.3)) {
                    showTrimPreview = true
                }
            }
        } catch {
            print("[AIHomeRun] Auto-detect error: \(error.localizedDescription)")
        }

        isDetecting = false
    }

    /// Apply the user-confirmed trim range and export the trimmed video.
    func applyTrim(range: ClosedRange<Double>) async {
        guard let url = videoURL else { return }

        isTrimming = true
        do {
            let trimmedURL = try await detectionService.trimVideo(sourceURL: url, range: range)
            trimmedVideoURL = trimmedURL
            withAnimation(.spring(duration: 0.25)) {
                showTrimPreview = false
            }
        } catch {
            print("[AIHomeRun] Trim error: \(error.localizedDescription)")
        }
        isTrimming = false
    }

    /// Skip trimming and use the full original video.
    func skipTrim() {
        trimmedVideoURL = nil
        withAnimation(.spring(duration: 0.25)) {
            showTrimPreview = false
        }
    }

    func reset() {
        videoURL = nil
        result = nil
        error = nil
        qualityError = nil
        loadStep = 0
        uploadProgress = 0
        isPreparing = false
        prepareProgress = 0
        usedCache = false
        // Auto-detect state
        isDetecting = false
        detectProgress = 0
        detectionResult = nil
        showTrimPreview = false
        trimmedVideoURL = nil
        isTrimming = false
    }
}

// MARK: - Home Feed ViewModel

@MainActor
class HomeFeedViewModel: ObservableObject {

    struct CachedResult: Codable {
        let result: AnalysisResult
        let date: Date
    }

    @Published var sessionHistory: [SessionSummary] = []
    @Published var lastResult: CachedResult?
    @Published var isLoadingFeed = false
    @Published var feedError: String?

    private let cacheKey = "hr_last_result_v1"

    init() { loadCache() }

    // MARK: API

    func loadFeed(token: String?) async {
        isLoadingFeed = true
        feedError = nil
        defer { isLoadingFeed = false }
        do {
            let history = try await APIClient.shared.fetchHistory(token: token)
            sessionHistory = history
        } catch {
            print("[AIHomeRun] loadFeed error: \(error.localizedDescription)")
            if sessionHistory.isEmpty {
                feedError = "Could not load history. Pull to refresh."
            }
        }
    }

    // MARK: Cache

    func saveLastResult(_ result: AnalysisResult) {
        let cached = CachedResult(result: result, date: Date())
        lastResult = cached
        if let data = try? JSONEncoder().encode(cached) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(CachedResult.self, from: data)
        else { return }
        lastResult = cached
    }

    // MARK: Computed

    /// Today's drill: last-analysis drill if < 2 days old, else a rotating default
    var todaysDrill: DrillInfo {
        if let drill = lastResult?.result.feedback.drill,
           let date = lastResult?.date,
           (Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 99) < 2 {
            return drill
        }
        let idx = ((Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1) - 1)
        return Self.defaultDrills[idx % Self.defaultDrills.count]
    }

    var latestScore: Int? {
        sessionHistory.last?.overallScore ?? lastResult?.result.feedback.overallScore
    }

    /// Local heuristic percentile — real peer API is a future backend feature
    func estimatedPercentile(age: Int) -> Int? {
        guard let score = latestScore else { return nil }
        return max(5, min(92, 105 - score))
    }

    var progressDelta: Int? {
        guard sessionHistory.count >= 2 else {
            return nil
        }
        let first = sessionHistory.first?.overallScore ?? 0
        let last  = sessionHistory.last?.overallScore  ?? 0
        return last - first
    }

    // MARK: Default drills (7-day rotation)

    static let defaultDrills: [DrillInfo] = [
        DrillInfo(name: "Tee Drill",
                  description: "Focus on bat path staying level through the zone. Keep head still and watch the contact point.",
                  reps: "50 swings"),
        DrillInfo(name: "Hip Rotation",
                  description: "Load weight on back foot, drive hips before the hands. Feel the chain: legs → hips → hands.",
                  reps: "3 × 15 reps"),
        DrillInfo(name: "One-Hand Follow-Through",
                  description: "Swing with your top hand only. Hold the finish for 2 seconds to build follow-through muscle memory.",
                  reps: "20 swings"),
        DrillInfo(name: "Balance Stance",
                  description: "Hold your stance on one foot for 10 seconds per side. Build the balance foundation for power.",
                  reps: "3 × 10 sec each"),
        DrillInfo(name: "Soft Toss",
                  description: "Partner tosses from the side. Drive to the opposite field with a short, compact swing.",
                  reps: "30 swings"),
        DrillInfo(name: "Hip–Shoulder Separation",
                  description: "Slow-motion drill: rotate hips while keeping upper body closed as long as possible. Feel the stretch.",
                  reps: "3 × 12 slow reps"),
        DrillInfo(name: "Mirror Drill",
                  description: "Practice in slow motion in front of a mirror. Pause at contact and verify posture and bat angle.",
                  reps: "20 slow swings"),
    ]
}
