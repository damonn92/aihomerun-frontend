import Foundation
import SwiftUI

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

    func analyze(token: String?) async {
        guard let videoURL else { return }
        isLoading = true
        loadStep = 0
        uploadProgress = 0
        error = nil
        qualityError = nil
        result = nil

        do {
            let analysisResult = try await APIClient.shared.analyzeVideo(
                fileURL: videoURL,
                actionType: actionType.rawValue,
                age: age,
                token: token
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.uploadProgress = progress
                    if progress > 0.35 && (self?.loadStep ?? 0) < 1 { self?.loadStep = 1 }
                    if progress > 0.70 && (self?.loadStep ?? 0) < 2 { self?.loadStep = 2 }
                    if progress > 0.90 && (self?.loadStep ?? 0) < 3 { self?.loadStep = 3 }
                }
            }
            self.result = analysisResult
        } catch APIError.qualityGateFailure(let qe) {
            qualityError = qe
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func reset() {
        videoURL = nil
        result = nil
        error = nil
        qualityError = nil
        loadStep = 0
        uploadProgress = 0
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

    private let cacheKey = "hr_last_result_v1"

    init() { loadCache() }

    // MARK: API

    func loadFeed(token: String?) async {
        isLoadingFeed = true
        defer { isLoadingFeed = false }
        do {
            let history = try await APIClient.shared.fetchHistory(token: token)
            sessionHistory = history
        } catch {
            // Silently keep cached data on network error
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
