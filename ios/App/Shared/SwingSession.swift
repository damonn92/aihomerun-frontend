import Foundation

// MARK: - Shared data models between iPhone and Apple Watch

/// A single detected swing event with IMU-derived metrics
struct SwingEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let handSpeedMPH: Double          // Estimated hand speed in mph
    let peakAccelerationG: Double     // Peak acceleration in g-force
    let timeToContactMS: Double?      // Time from swing start to impact (ms)
    let attackAngleDegrees: Double?   // Attack angle at impact
    let swingDurationMS: Double       // Total swing duration
    let impactDetected: Bool          // Whether bat-ball impact was detected
    let rotationRateDPS: Double       // Peak rotation rate (degrees/sec)
    let rotationalAcceleration: Double? // Rotational acceleration (rad/s²) — how quickly bat accelerates into swing plane
    let swingScore: Int?              // Composite swing quality score (0–100)

    // Advanced metrics
    let barrelSpeedMPH: Double?           // Estimated barrel speed using centripetal acceleration (mph)
    let swingPlaneAngle: Double?          // Angle of swing plane relative to horizontal (degrees)
    let powerTransferEfficiency: Double?  // How well energy transfers to bat at contact (0–100)
    let loadTimeMS: Double?              // Weight transfer phase before swing starts (ms)
    let snapScore: Double?               // Wrist snap quality around impact (0–100)
    let kineticChainScore: Double?        // Sequential acceleration buildup quality (0–100)
    let connectionScore: Double?          // Hands-to-body connection quality (0–100)

    init(
        timestamp: Date = Date(),
        handSpeedMPH: Double,
        peakAccelerationG: Double,
        timeToContactMS: Double? = nil,
        attackAngleDegrees: Double? = nil,
        swingDurationMS: Double,
        impactDetected: Bool,
        rotationRateDPS: Double,
        rotationalAcceleration: Double? = nil,
        swingScore: Int? = nil,
        barrelSpeedMPH: Double? = nil,
        swingPlaneAngle: Double? = nil,
        powerTransferEfficiency: Double? = nil,
        loadTimeMS: Double? = nil,
        snapScore: Double? = nil,
        kineticChainScore: Double? = nil,
        connectionScore: Double? = nil
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.handSpeedMPH = handSpeedMPH
        self.peakAccelerationG = peakAccelerationG
        self.timeToContactMS = timeToContactMS
        self.attackAngleDegrees = attackAngleDegrees
        self.swingDurationMS = swingDurationMS
        self.impactDetected = impactDetected
        self.rotationRateDPS = rotationRateDPS
        self.rotationalAcceleration = rotationalAcceleration
        self.swingScore = swingScore
        self.barrelSpeedMPH = barrelSpeedMPH
        self.swingPlaneAngle = swingPlaneAngle
        self.powerTransferEfficiency = powerTransferEfficiency
        self.loadTimeMS = loadTimeMS
        self.snapScore = snapScore
        self.kineticChainScore = kineticChainScore
        self.connectionScore = connectionScore
    }
}

/// Practice mode — affects swing detection thresholds
enum PracticeMode: String, Codable, CaseIterable {
    case standard = "Standard"   // Normal — requires ball impact
    case airSwing = "Air Swing"  // No ball needed — lower thresholds

    var icon: String {
        switch self {
        case .standard: return "baseball"
        case .airSwing: return "wind"
        }
    }
}

/// A complete practice session recorded on Apple Watch
struct SwingSession: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    let playerName: String
    let playerAge: Int
    let battingHand: BattingHand
    let practiceMode: PracticeMode
    var swings: [SwingEvent]
    var averageHeartRate: Double?
    var peakHeartRate: Double?
    var caloriesBurned: Double?
    let watchModel: String
    let sensorRate: SensorRate

    var duration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }

    var swingCount: Int { swings.count }

    var averageHandSpeed: Double {
        guard !swings.isEmpty else { return 0 }
        return swings.map(\.handSpeedMPH).reduce(0, +) / Double(swings.count)
    }

    var maxHandSpeed: Double {
        swings.map(\.handSpeedMPH).max() ?? 0
    }

    var averageTimeToContact: Double? {
        let valid = swings.compactMap(\.timeToContactMS)
        guard !valid.isEmpty else { return nil }
        return valid.reduce(0, +) / Double(valid.count)
    }

    var hitsCount: Int {
        swings.filter(\.impactDetected).count
    }

    var averageRotationalAcceleration: Double? {
        let valid = swings.compactMap(\.rotationalAcceleration)
        guard !valid.isEmpty else { return nil }
        return valid.reduce(0, +) / Double(valid.count)
    }

    var averageSwingScore: Double? {
        let valid = swings.compactMap(\.swingScore)
        guard !valid.isEmpty else { return nil }
        return Double(valid.reduce(0, +)) / Double(valid.count)
    }

    var bestSwingScore: Int? {
        swings.compactMap(\.swingScore).max()
    }

    var averageBarrelSpeed: Double? {
        let valid = swings.compactMap(\.barrelSpeedMPH)
        guard !valid.isEmpty else { return nil }
        return valid.reduce(0, +) / Double(valid.count)
    }

    var averageSwingPlane: Double? {
        let valid = swings.compactMap(\.swingPlaneAngle)
        guard !valid.isEmpty else { return nil }
        return valid.reduce(0, +) / Double(valid.count)
    }

    var averagePowerTransfer: Double? {
        let valid = swings.compactMap(\.powerTransferEfficiency)
        guard !valid.isEmpty else { return nil }
        return valid.reduce(0, +) / Double(valid.count)
    }

    var averageSnapScore: Double? {
        let valid = swings.compactMap(\.snapScore)
        guard !valid.isEmpty else { return nil }
        return valid.reduce(0, +) / Double(valid.count)
    }

    var averageKineticChainScore: Double? {
        let valid = swings.compactMap(\.kineticChainScore)
        guard !valid.isEmpty else { return nil }
        return valid.reduce(0, +) / Double(valid.count)
    }

    var averageConnectionScore: Double? {
        let valid = swings.compactMap(\.connectionScore)
        guard !valid.isEmpty else { return nil }
        return valid.reduce(0, +) / Double(valid.count)
    }

    init(
        playerName: String,
        playerAge: Int,
        battingHand: BattingHand,
        practiceMode: PracticeMode = .standard,
        watchModel: String = "",
        sensorRate: SensorRate = .standard
    ) {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.playerName = playerName
        self.playerAge = playerAge
        self.battingHand = battingHand
        self.practiceMode = practiceMode
        self.swings = []
        self.watchModel = watchModel
        self.sensorRate = sensorRate
    }
}

// MARK: - Supporting Types

enum BattingHand: String, Codable, CaseIterable {
    case left = "Left"
    case right = "Right"
    case both = "Switch"

    var abbreviation: String {
        switch self {
        case .left: return "L"
        case .right: return "R"
        case .both: return "S"
        }
    }
}

enum SensorRate: String, Codable {
    case standard = "100Hz"       // CMMotionManager (Series 4-7)
    case highFrequency = "800Hz"  // CMBatchedSensorManager (Series 8+)
}

// MARK: - WatchConnectivity Message Keys

enum WatchMessageKey {
    static let sessionData = "sessionData"
    static let sessionComplete = "sessionComplete"
    static let startSession = "startSession"
    static let stopSession = "stopSession"
    static let swingDetected = "swingDetected"
    static let heartRateUpdate = "heartRateUpdate"
    static let playerName = "playerName"
    static let playerAge = "playerAge"
    static let battingHand = "battingHand"
    static let requestActivePlayer = "requestActivePlayer"
    static let activePlayerResponse = "activePlayerResponse"
}

// MARK: - Session Summary (lightweight, for Watch display)

struct SessionSummaryWatch: Codable, Identifiable {
    let id: UUID
    let date: Date
    let swingCount: Int
    let avgHandSpeed: Double
    let maxHandSpeed: Double
    let duration: TimeInterval
    let hitsCount: Int

    init(from session: SwingSession) {
        self.id = session.id
        self.date = session.startTime
        self.swingCount = session.swingCount
        self.avgHandSpeed = session.averageHandSpeed
        self.maxHandSpeed = session.maxHandSpeed
        self.duration = session.duration
        self.hitsCount = session.hitsCount
    }
}
