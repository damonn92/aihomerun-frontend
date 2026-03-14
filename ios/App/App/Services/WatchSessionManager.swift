import Foundation
import Combine
import WatchConnectivity
import os.log

/// iPhone-side manager for receiving and storing Apple Watch session data
@MainActor
final class WatchSessionManager: ObservableObject {

    static let shared = WatchSessionManager()

    private let logger = Logger(subsystem: "com.aihomerun", category: "WatchSessionManager")

    // MARK: - Published State
    @Published var sessions: [SwingSession] = []
    @Published var latestSession: SwingSession?
    @Published var isWatchConnected = false
    @Published var isWatchReachable = false
    @Published var isWatchSessionActive = false

    // Live updates from active watch session
    @Published var liveSwingCount: Int = 0
    @Published var liveLastSpeed: Double = 0
    @Published var liveBestSpeed: Double = 0
    @Published var liveHeartRate: Double = 0

    private let connectivity = WatchConnectivityService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupConnectivity()
        loadSessions()
    }

    // MARK: - Setup

    private func setupConnectivity() {
        connectivity.onSessionReceived = { [weak self] session in
            Task { @MainActor in
                self?.handleReceivedSession(session)
            }
        }

        connectivity.onSwingDetected = { [weak self] event in
            Task { @MainActor in
                self?.handleLiveSwing(event)
            }
        }

        connectivity.onPlayerInfoRequested = { [weak self] in
            // Return active player info from profile
            // TODO: integrate with ProfileViewModel
            return (name: "Player", age: 12, hand: .right)
        }

        // Observe connectivity state changes to update isWatchConnected
        connectivity.$isPaired
            .combineLatest(connectivity.$isWatchAppInstalled)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] paired, installed in
                self?.isWatchConnected = paired && installed
                self?.logger.info("Watch connection updated: paired=\(paired), installed=\(installed)")
            }
            .store(in: &cancellables)

        connectivity.$isReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reachable in
                self?.isWatchReachable = reachable
            }
            .store(in: &cancellables)

        connectivity.activate()

        // Also check immediately after activation (WCSession state may already be available)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshConnectionStatus()
        }
    }

    /// Manually refresh connection status from WCSession
    func refreshConnectionStatus() {
        guard WCSession.isSupported() else {
            isWatchConnected = false
            return
        }
        let session = WCSession.default
        #if os(iOS)
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        isWatchConnected = paired && installed
        isWatchReachable = session.isReachable
        logger.info("Manual refresh: paired=\(paired), installed=\(installed), reachable=\(session.isReachable)")
        #endif
    }

    // MARK: - Handle Received Session

    private func handleReceivedSession(_ session: SwingSession) {
        latestSession = session
        sessions.insert(session, at: 0)

        // Keep max 50 sessions
        if sessions.count > 50 {
            sessions = Array(sessions.prefix(50))
        }

        saveSessions()
        isWatchSessionActive = false

        // Reset live metrics
        liveSwingCount = 0
        liveLastSpeed = 0
        liveBestSpeed = 0
        liveHeartRate = 0

        logger.info("Received watch session: \(session.swingCount) swings, best: \(String(format: "%.1f", session.maxHandSpeed)) mph")
    }

    // MARK: - Handle Live Swing

    private func handleLiveSwing(_ event: SwingEvent) {
        isWatchSessionActive = true
        liveSwingCount += 1
        liveLastSpeed = event.handSpeedMPH
        liveBestSpeed = max(liveBestSpeed, event.handSpeedMPH)
    }

    // MARK: - Remote Control

    func startWatchSession(playerName: String, playerAge: Int, battingHand: BattingHand) {
        connectivity.sendStartSession(playerName: playerName, playerAge: playerAge, battingHand: battingHand)
        isWatchSessionActive = true
        liveSwingCount = 0
        liveLastSpeed = 0
        liveBestSpeed = 0
    }

    func stopWatchSession() {
        connectivity.sendStopSession()
    }

    // MARK: - Persistence

    private let sessionsKey = "watchSwingSessions"

    private func saveSessions() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: sessionsKey)
    }

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let loaded = try? JSONDecoder().decode([SwingSession].self, from: data) else {
            return
        }
        sessions = loaded
    }

    // MARK: - Delete Session

    func deleteSession(_ session: SwingSession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
    }

    func deleteAllSessions() {
        sessions.removeAll()
        saveSessions()
    }

    // MARK: - Get Session for Fusion Upload

    /// Returns session data as JSON for uploading alongside video analysis
    func sessionDataForUpload(_ sessionId: UUID) -> Data? {
        guard let session = sessions.first(where: { $0.id == sessionId }) else { return nil }
        return try? JSONEncoder().encode(session)
    }

    // MARK: - Find Matching Session for Fusion

    /// Finds a watch session whose time window overlaps with a given date.
    /// Used by FusionAnalysisService to automatically pair watch data with video analysis.
    func findMatchingSession(near date: Date, tolerance: TimeInterval = 600) -> SwingSession? {
        let searchRange = date.addingTimeInterval(-tolerance)...date.addingTimeInterval(tolerance)
        return sessions.first { session in
            let sessionEnd = session.endTime ?? session.startTime.addingTimeInterval(session.duration)
            let sessionRange = session.startTime...sessionEnd
            return sessionRange.overlaps(searchRange)
        }
    }

    /// Returns the most recent session (useful for fusion when no specific time match is needed)
    func mostRecentSession(maxAge: TimeInterval = 3600) -> SwingSession? {
        guard let latest = sessions.first,
              Date().timeIntervalSince(latest.startTime) < maxAge else { return nil }
        return latest
    }
}
