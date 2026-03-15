import Foundation
import CoreGraphics

// MARK: - Comparison Session

/// Represents one side of a comparison — wraps a session's metadata, video, and pose data.
struct ComparisonSession: Identifiable {
    let id: String                       // matches SessionSummary.videoId
    var videoURL: URL?                   // nil when the original video is unavailable
    let sessionSummary: SessionSummary
    let analysisResult: AnalysisResult?  // present for the "current" session, nil for historical
    var poseData: VideoPoseData?         // populated after local re-analysis or from cache
    var syncPointTime: Double?           // user-set sync moment (seconds from video start)

    /// True if video is playable — either a local file or a remote URL
    var videoAvailable: Bool {
        guard let url = videoURL else { return false }
        if url.scheme == "https" || url.scheme == "http" {
            return true  // Remote URL — AVPlayer can stream it
        }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// True if this is a remote (cloud) video URL
    var isRemoteVideo: Bool {
        guard let url = videoURL else { return false }
        return url.scheme == "https" || url.scheme == "http"
    }

    /// Short display label: date + time for easy identification
    var displayLabel: String {
        if let dateStr = sessionSummary.createdAt {
            return ComparisonSession.formatDateTime(dateStr)
        }
        return analysisResult != nil ? "Current" : "Previous"
    }

    /// Overall score, if available
    var overallScore: Int? {
        analysisResult?.feedback.overallScore ?? sessionSummary.overallScore
    }

    // MARK: - Date Formatting

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private static let displayDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d h:mm a"
        return f
    }()

    private static func formatDate(_ iso: String) -> String {
        if let date = isoFormatter.date(from: iso) {
            return displayFormatter.string(from: date)
        }
        let alt = ISO8601DateFormatter()
        if let date = alt.date(from: iso) {
            return displayFormatter.string(from: date)
        }
        return String(iso.prefix(10))
    }

    private static func formatDateTime(_ iso: String) -> String {
        if let date = isoFormatter.date(from: iso) {
            return displayDateTimeFormatter.string(from: date)
        }
        let alt = ISO8601DateFormatter()
        if let date = alt.date(from: iso) {
            return displayDateTimeFormatter.string(from: date)
        }
        return String(iso.prefix(16))
    }
}

// MARK: - Comparison Mode

enum ComparisonMode: String, CaseIterable {
    case sideBySide
    case ghostOverlay

    var label: String {
        switch self {
        case .sideBySide:   return "Side by Side"
        case .ghostOverlay: return "Ghost Overlay"
        }
    }

    var icon: String {
        switch self {
        case .sideBySide:   return "rectangle.split.2x1"
        case .ghostOverlay: return "square.on.square"
        }
    }
}

// MARK: - Angle Delta (real-time comparison)

/// Difference in a computed angle between left and right sessions at the current frame.
struct AngleDelta: Identifiable {
    let id = UUID()
    let name: String
    let jointName: JointName
    let leftDegrees: Double
    let rightDegrees: Double
    let position: CGPoint   // normalized, for potential label rendering

    var delta: Double { rightDegrees - leftDegrees }
}

// MARK: - Sync Side

enum SyncSide {
    case left, right
}

// MARK: - Video URL Store

/// Lightweight persistence for videoId → local file URL mapping.
/// Allows the comparison feature to locate previously analyzed videos.
final class VideoURLStore {
    static let shared = VideoURLStore()

    private let key = "com.aihomerun.videoURLMap"

    private init() {}

    /// Save a mapping from videoId to local file URL
    func store(videoId: String, url: URL) {
        var map = loadMap()
        map[videoId] = url.path
        UserDefaults.standard.set(map, forKey: key)
    }

    /// Look up a local file URL for a given videoId
    func url(for videoId: String) -> URL? {
        let map = loadMap()
        guard var str = map[videoId] else { return nil }
        // Migrate legacy entries that stored absoluteString (file:///...) instead of path
        if str.hasPrefix("file://") {
            if let legacyURL = URL(string: str) {
                str = legacyURL.path
                // Fix the stored value
                var updated = map
                updated[videoId] = str
                UserDefaults.standard.set(updated, forKey: key)
            }
        }
        let url = URL(fileURLWithPath: str)
        // Only return if file still exists
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Remove a stale entry
    func remove(videoId: String) {
        var map = loadMap()
        map.removeValue(forKey: videoId)
        UserDefaults.standard.set(map, forKey: key)
    }

    private func loadMap() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
    }
}
