import Foundation
import CryptoKit

// MARK: - Analysis Result Cache

/// Thread-safe disk cache for `AnalysisResult`, ensuring the same video
/// always returns a consistent analysis.
///
/// Cache files live in `Application Support/analysis_cache/`
/// and are keyed by SHA-256 of the **video file content** + actionType + age.
actor AnalysisResultCache {
    static let shared = AnalysisResultCache()

    private let cacheDir: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory,
                                                   in: .userDomainMask).first!
        cacheDir = appSupport.appendingPathComponent("analysis_cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir,
                                                  withIntermediateDirectories: true)
    }

    // MARK: - Public API

    /// Return cached analysis result for a given video + parameters, or nil if not cached.
    func cached(for fileURL: URL, actionType: String, age: Int) -> AnalysisResult? {
        guard let file = cacheFile(for: fileURL, actionType: actionType, age: age) else { return nil }
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        do {
            let data = try Data(contentsOf: file)
            return try decoder.decode(AnalysisResult.self, from: data)
        } catch {
            // Corrupt cache — remove
            try? FileManager.default.removeItem(at: file)
            return nil
        }
    }

    /// Store analysis result for a video + parameters.
    func store(_ result: AnalysisResult, for fileURL: URL, actionType: String, age: Int) {
        guard let file = cacheFile(for: fileURL, actionType: actionType, age: age) else { return }
        do {
            let data = try encoder.encode(result)
            try data.write(to: file, options: .atomic)
        } catch {
            print("[AnalysisResultCache] Failed to write cache: \(error)")
        }
    }

    /// Remove cached result for a specific video + parameters.
    func remove(for fileURL: URL, actionType: String, age: Int) {
        guard let file = cacheFile(for: fileURL, actionType: actionType, age: age) else { return }
        try? FileManager.default.removeItem(at: file)
    }

    /// Clear the entire cache.
    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir,
                                                  withIntermediateDirectories: true)
    }

    // MARK: - Stats

    /// Total size of cache in bytes.
    func cacheSize() -> Int {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        return files.reduce(0) { sum, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return sum + size
        }
    }

    /// Number of cached analyses.
    func cacheCount() -> Int {
        let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDir, includingPropertiesForKeys: nil)
        return files?.filter { $0.pathExtension == "json" }.count ?? 0
    }

    // MARK: - Private

    /// Build a cache file URL by hashing the video **file content** + actionType + age.
    /// Returns nil if the file can't be read (e.g. deleted/moved).
    private func cacheFile(for fileURL: URL, actionType: String, age: Int) -> URL? {
        guard let fileData = try? Data(contentsOf: fileURL) else { return nil }
        // Combine file content hash with parameters for a unique key
        var hasher = SHA256()
        hasher.update(data: fileData)
        hasher.update(data: Data(actionType.utf8))
        hasher.update(data: Data("\(age)".utf8))
        let digest = hasher.finalize()
        let hex = digest.compactMap { String(format: "%02x", $0) }.joined()
        return cacheDir.appendingPathComponent("\(hex).json")
    }
}
