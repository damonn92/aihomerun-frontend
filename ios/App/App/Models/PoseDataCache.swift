import Foundation
import CryptoKit

// MARK: - Pose Data Cache

/// Thread-safe disk cache for `VideoPoseData`, avoiding repeated
/// pose analysis on previously-processed videos.
///
/// Cache files live in `Application Support/pose_cache/`
/// and are keyed by SHA-256 of the video URL's absolute string.
actor PoseDataCache {
    static let shared = PoseDataCache()

    private let cacheDir: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory,
                                                   in: .userDomainMask).first!
        cacheDir = appSupport.appendingPathComponent("pose_cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir,
                                                  withIntermediateDirectories: true)
    }

    // MARK: - Public API

    /// Return cached pose data for a given video URL, or nil if not cached.
    func cached(for videoURL: URL) -> VideoPoseData? {
        let file = cacheFile(for: videoURL)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        do {
            let data = try Data(contentsOf: file)
            return try decoder.decode(VideoPoseData.self, from: data)
        } catch {
            // Corrupt cache — remove
            try? FileManager.default.removeItem(at: file)
            return nil
        }
    }

    /// Store pose data for a video URL.
    func store(_ poseData: VideoPoseData, for videoURL: URL) {
        let file = cacheFile(for: videoURL)
        do {
            let data = try encoder.encode(poseData)
            try data.write(to: file, options: .atomic)
        } catch {
            print("[PoseDataCache] Failed to write cache: \(error)")
        }
    }

    /// Remove cached data for a specific video.
    func remove(for videoURL: URL) {
        let file = cacheFile(for: videoURL)
        try? FileManager.default.removeItem(at: file)
    }

    /// Clear the entire cache.
    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir,
                                                  withIntermediateDirectories: true)
    }

    // MARK: - 3D Pose Cache

    /// Return cached 3D pose data for a given video URL, or nil if not cached.
    func cached3D(for videoURL: URL) -> VideoPose3DData? {
        let file = cacheFile3D(for: videoURL)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        do {
            let data = try Data(contentsOf: file)
            return try decoder.decode(VideoPose3DData.self, from: data)
        } catch {
            try? FileManager.default.removeItem(at: file)
            return nil
        }
    }

    /// Store 3D pose data for a video URL.
    func store3D(_ poseData: VideoPose3DData, for videoURL: URL) {
        let file = cacheFile3D(for: videoURL)
        do {
            let data = try encoder.encode(poseData)
            try data.write(to: file, options: .atomic)
        } catch {
            print("[PoseDataCache] Failed to write 3D cache: \(error)")
        }
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

    // MARK: - Private

    private func cacheFile(for videoURL: URL) -> URL {
        let hash = SHA256.hash(data: Data(videoURL.absoluteString.utf8))
        let hex = hash.compactMap { String(format: "%02x", $0) }.joined()
        return cacheDir.appendingPathComponent("\(hex).json")
    }

    private func cacheFile3D(for videoURL: URL) -> URL {
        let hash = SHA256.hash(data: Data(videoURL.absoluteString.utf8))
        let hex = hash.compactMap { String(format: "%02x", $0) }.joined()
        return cacheDir.appendingPathComponent("\(hex)_3d.json")
    }
}
