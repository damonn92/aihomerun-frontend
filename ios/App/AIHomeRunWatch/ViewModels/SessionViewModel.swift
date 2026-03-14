import Foundation
import Combine
import os.log

#if os(watchOS)
import WatchKit
#endif

/// Main ViewModel for the Watch app — orchestrates workout, motion, and swing detection
@MainActor
final class SessionViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.aihomerun.watch", category: "SessionViewModel")

    // MARK: - Services
    let motionService = MotionService()
    let swingDetector = SwingDetector()
    let workoutService = WorkoutService()
    let connectivityService = WatchConnectivityService.shared

    // MARK: - Session State
    enum SessionState {
        case idle
        case starting
        case active
        case ending
        case completed
    }

    @Published var state: SessionState = .idle
    @Published var currentSession: SwingSession?
    @Published var recentSessions: [SessionSummaryWatch] = []

    // MARK: - Player Config
    @Published var playerName: String = "Player"
    @Published var playerAge: Int = 12
    @Published var battingHand: BattingHand = .right
    @Published var practiceMode: PracticeMode = .standard
    @Published var syncedPlayers: [SyncedPlayer] = []
    @Published var selectedPlayerId: String?

    // MARK: - Live Metrics
    @Published var swingCount: Int = 0
    @Published var lastSwingSpeed: Double = 0
    @Published var bestSwingSpeed: Double = 0
    @Published var averageSpeed: Double = 0
    @Published var heartRate: Double = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var lastSwingScore: Int = 0
    @Published var bestSwingScore: Int = 0
    @Published var lastRotAccel: Double = 0

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        setupBindings()
        loadRecentSessions()
        loadPlayerConfig()
        connectivityService.activate()

        // Pre-request HealthKit authorization so the dialog
        // appears on launch rather than blocking "Start Practice"
        Task {
            _ = await workoutService.requestAuthorization()
        }
    }

    // MARK: - Setup

    private func setupBindings() {
        // Swing detector → session updates
        swingDetector.onSwingDetected = { [weak self] event in
            Task { @MainActor in
                self?.handleSwingDetected(event)
            }
        }

        // Motion service → swing detector
        motionService.onBatchReady = { [weak self] accelBatch, motionBatch in
            self?.swingDetector.processBatch(accelData: accelBatch, motionData: motionBatch)
        }

        // Workout service → UI updates
        workoutService.$heartRate
            .receive(on: DispatchQueue.main)
            .assign(to: &$heartRate)

        workoutService.$elapsedTime
            .receive(on: DispatchQueue.main)
            .assign(to: &$elapsedTime)
    }

    // MARK: - Start Session

    func startSession() async {
        guard state == .idle || state == .completed else { return }
        state = .starting

        // HealthKit authorization is pre-requested on init,
        // but ensure it's done (no-op if already authorized)
        _ = await workoutService.requestAuthorization()

        // Create new session
        #if os(watchOS)
        let model = WKInterfaceDevice.current().model
        #else
        let model = "iPhone"
        #endif

        currentSession = SwingSession(
            playerName: playerName,
            playerAge: playerAge,
            battingHand: battingHand,
            practiceMode: practiceMode,
            watchModel: model,
            sensorRate: motionService.sensorRate
        )

        // Reset metrics
        swingCount = 0
        lastSwingSpeed = 0
        bestSwingSpeed = 0
        averageSpeed = 0
        lastSwingScore = 0
        bestSwingScore = 0
        lastRotAccel = 0
        swingDetector.reset()
        swingDetector.practiceMode = practiceMode
        swingDetector.playerAge = playerAge

        // Start workout (best-effort — required for CMBatchedSensorManager on real device)
        do {
            try await workoutService.startWorkout()
        } catch {
            logger.warning("Workout unavailable: \(error.localizedDescription) — continuing without it")
        }

        // Start motion collection
        motionService.startCollection()

        state = .active

        // Haptic feedback
        #if os(watchOS)
        WKInterfaceDevice.current().play(.start)
        #endif

        logger.info("Session started for \(self.playerName)")
    }

    // MARK: - End Session

    func endSession() async {
        guard state == .active else { return }
        state = .ending

        // Stop motion collection
        motionService.stopCollection()

        // Process any remaining buffered data
        let remaining = motionService.flushBuffers()
        if !remaining.accel.isEmpty || !remaining.motion.isEmpty {
            swingDetector.processBatch(accelData: remaining.accel, motionData: remaining.motion)
        }

        // End workout and get health stats
        let healthStats = await workoutService.endWorkout()

        // Finalize session
        currentSession?.endTime = Date()
        currentSession?.averageHeartRate = healthStats?.avgHeartRate
        currentSession?.peakHeartRate = healthStats?.peakHeartRate
        currentSession?.caloriesBurned = healthStats?.calories

        // Haptic feedback
        #if os(watchOS)
        WKInterfaceDevice.current().play(.stop)
        #endif

        state = .completed

        // Save and send to iPhone
        if let session = currentSession {
            saveSession(session)
            connectivityService.sendSessionToPhone(session)
            logger.info("Session completed: \(session.swingCount) swings, best: \(String(format: "%.1f", session.maxHandSpeed)) mph")
        }
    }

    // MARK: - Handle Swing

    private func handleSwingDetected(_ event: SwingEvent) {
        currentSession?.swings.append(event)
        swingCount = currentSession?.swingCount ?? 0
        lastSwingSpeed = event.handSpeedMPH
        bestSwingSpeed = max(bestSwingSpeed, event.handSpeedMPH)
        averageSpeed = currentSession?.averageHandSpeed ?? 0

        // New metrics
        if let score = event.swingScore {
            lastSwingScore = score
            bestSwingScore = max(bestSwingScore, score)
        }
        if let rotAccel = event.rotationalAcceleration {
            lastRotAccel = rotAccel
        }

        // Haptic feedback on each swing
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif

        // Send real-time update to iPhone
        connectivityService.sendSwingUpdate(event)
    }

    // MARK: - Persistence

    private func saveSession(_ session: SwingSession) {
        let summary = SessionSummaryWatch(from: session)
        recentSessions.insert(summary, at: 0)

        // Keep only last 20 sessions
        if recentSessions.count > 20 {
            recentSessions = Array(recentSessions.prefix(20))
        }

        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(recentSessions) {
            UserDefaults.standard.set(data, forKey: "recentSessions")
        }

        // Save full session to file for later transfer
        let fileURL = sessionFileURL(for: session.id)
        if let data = try? JSONEncoder().encode(session) {
            try? data.write(to: fileURL)
        }
    }

    private func loadRecentSessions() {
        guard let data = UserDefaults.standard.data(forKey: "recentSessions"),
              let sessions = try? JSONDecoder().decode([SessionSummaryWatch].self, from: data) else {
            return
        }
        recentSessions = sessions
    }

    private func sessionFileURL(for id: UUID) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("session_\(id.uuidString).json")
    }

    // MARK: - Format Helpers

    var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedHeartRate: String {
        heartRate > 0 ? "\(Int(heartRate))" : "--"
    }

    // MARK: - Player Management

    func selectPlayer(_ player: SyncedPlayer) {
        playerName = player.name
        playerAge = player.age
        selectedPlayerId = player.id
        savePlayerConfig()
    }

    private func savePlayerConfig() {
        UserDefaults.standard.set(playerName, forKey: "playerName")
        UserDefaults.standard.set(playerAge, forKey: "playerAge")
        UserDefaults.standard.set(battingHand.rawValue, forKey: "battingHand")
        if let id = selectedPlayerId {
            UserDefaults.standard.set(id, forKey: "selectedPlayerId")
        }
    }

    private func loadPlayerConfig() {
        if let name = UserDefaults.standard.string(forKey: "playerName"), !name.isEmpty {
            playerName = name
        }
        let age = UserDefaults.standard.integer(forKey: "playerAge")
        if age > 0 {
            playerAge = age
        }
        if let handRaw = UserDefaults.standard.string(forKey: "battingHand"),
           let hand = BattingHand(rawValue: handRaw) {
            battingHand = hand
        }
        selectedPlayerId = UserDefaults.standard.string(forKey: "selectedPlayerId")

        // Load synced players
        if let data = UserDefaults.standard.data(forKey: "syncedPlayers"),
           let players = try? JSONDecoder().decode([SyncedPlayer].self, from: data) {
            syncedPlayers = players
        }
    }

    /// Called when iPhone sends updated player list
    func updateSyncedPlayers(_ players: [SyncedPlayer]) {
        syncedPlayers = players
        if let data = try? JSONEncoder().encode(players) {
            UserDefaults.standard.set(data, forKey: "syncedPlayers")
        }
        // Auto-select first player if none selected
        if selectedPlayerId == nil, let first = players.first {
            selectPlayer(first)
        }
    }
}

// MARK: - Synced Player Model

struct SyncedPlayer: Codable, Identifiable {
    let id: String
    let name: String
    let age: Int
    let position: String?
}
