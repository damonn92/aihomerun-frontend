import Foundation

// MARK: - Sensor Fusion Result

/// Combined analysis result merging Apple Watch IMU data with video pose analysis.
/// When both data sources are available, fusion produces more accurate and comprehensive metrics.
struct FusionResult: Codable, Identifiable {
    let id: UUID
    let timestamp: Date

    // MARK: - Core Fusion Metrics

    /// Bat speed calibrated using Watch wrist acceleration + video arm length estimation (mph)
    let calibratedBatSpeedMPH: Double

    /// Composite power index (0-100) combining acceleration, hip-shoulder separation, follow-through
    let powerIndex: Double

    /// Timing score (0-100) — correlation between watch impact detection and video peak wrist frame
    let timingScore: Double

    /// Biomechanical efficiency (0-100) — video body mechanics x watch rotational efficiency
    let biomechanicalEfficiency: Double

    /// Consistency index (0-100) — inverse of coefficient of variation across session swings
    let consistencyIndex: Double

    /// Attack angle from Watch gyroscope (degrees)
    let attackAngleDeg: Double?

    /// Time to contact from swing initiation to impact (milliseconds)
    let timeToContactMS: Double?

    /// Peak rotational acceleration (rad/s^2) — correlates with bat head speed
    let peakRotationalAccel: Double?

    /// Fusion confidence (0.0-1.0) — how much data overlap exists between video and watch
    let fusionConfidence: Double

    /// Data source flags
    let hasVideoData: Bool
    let hasWatchData: Bool

    // MARK: - Session Aggregate Metrics (multi-swing)

    let sessionMetrics: SessionFusionMetrics?

    // MARK: - Per-Swing Breakdown

    let perSwingMetrics: [SwingFusionMetric]

    init(
        calibratedBatSpeedMPH: Double,
        powerIndex: Double,
        timingScore: Double,
        biomechanicalEfficiency: Double,
        consistencyIndex: Double,
        attackAngleDeg: Double? = nil,
        timeToContactMS: Double? = nil,
        peakRotationalAccel: Double? = nil,
        fusionConfidence: Double,
        hasVideoData: Bool,
        hasWatchData: Bool,
        sessionMetrics: SessionFusionMetrics? = nil,
        perSwingMetrics: [SwingFusionMetric] = []
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.calibratedBatSpeedMPH = calibratedBatSpeedMPH
        self.powerIndex = powerIndex
        self.timingScore = timingScore
        self.biomechanicalEfficiency = biomechanicalEfficiency
        self.consistencyIndex = consistencyIndex
        self.attackAngleDeg = attackAngleDeg
        self.timeToContactMS = timeToContactMS
        self.peakRotationalAccel = peakRotationalAccel
        self.fusionConfidence = fusionConfidence
        self.hasVideoData = hasVideoData
        self.hasWatchData = hasWatchData
        self.sessionMetrics = sessionMetrics
        self.perSwingMetrics = perSwingMetrics
    }
}

// MARK: - Session-Level Aggregated Fusion Metrics

struct SessionFusionMetrics: Codable {
    /// All swing speeds for distribution chart
    let speedDistribution: [Double]
    let speedMean: Double
    let speedStdDev: Double
    let speedMin: Double
    let speedMax: Double

    /// All attack angles for distribution
    let angleDistribution: [Double]
    let angleMean: Double
    let angleStdDev: Double

    /// Session-level consistency (0-100)
    let sessionConsistencyScore: Double

    /// Speed improvement trend: positive = improving over session
    let improvementTrend: Double

    /// Hit rate: impacts / total swings (0-1)
    let hitRate: Double

    /// Total session stats
    let totalSwings: Int
    let totalHits: Int
    let sessionDurationSeconds: Double

    /// Heart rate zones (if available)
    let averageHeartRate: Double?
    let peakHeartRate: Double?
    let caloriesBurned: Double?

    /// Speed zones for histogram coloring
    var speedZones: SpeedZones {
        SpeedZones(speeds: speedDistribution, mean: speedMean, stdDev: speedStdDev)
    }
}

// MARK: - Speed Zone Classification

struct SpeedZones: Codable {
    let elite: Int       // > mean + 1.5 stddev
    let aboveAvg: Int    // mean + 0.5 to mean + 1.5
    let average: Int     // mean - 0.5 to mean + 0.5
    let belowAvg: Int    // < mean - 0.5

    init(speeds: [Double], mean: Double, stdDev: Double) {
        let safeDev = max(stdDev, 0.5)
        var e = 0, a = 0, avg = 0, b = 0
        for s in speeds {
            let z = (s - mean) / safeDev
            if z > 1.5 { e += 1 }
            else if z > 0.5 { a += 1 }
            else if z > -0.5 { avg += 1 }
            else { b += 1 }
        }
        elite = e; aboveAvg = a; average = avg; belowAvg = b
    }
}

// MARK: - Per-Swing Fusion Metric

struct SwingFusionMetric: Codable, Identifiable {
    let id: UUID
    let swingIndex: Int
    let timestamp: Date

    /// Calibrated bat speed for this specific swing (mph)
    let calibratedSpeed: Double

    /// Power index for this swing (0-100)
    let powerIndex: Double

    /// Timing quality for this swing (0-100)
    let timingScore: Double

    /// Biomechanical efficiency for this swing (0-100)
    let efficiency: Double

    /// Attack angle for this swing (degrees)
    let attackAngle: Double?

    /// Whether ball contact was detected
    let impactDetected: Bool

    /// Raw watch hand speed before calibration
    let rawHandSpeedMPH: Double

    /// Swing duration in ms
    let swingDurationMS: Double

    /// Composite swing score (0-100)
    var compositeScore: Double {
        (powerIndex * 0.3 + timingScore * 0.25 + efficiency * 0.25 + (calibratedSpeed / 80.0 * 100.0).clamped(to: 0...100) * 0.2)
    }
}

// MARK: - Fusion Data Source

enum FusionDataSource: String, Codable {
    case videoOnly = "Video Only"
    case watchOnly = "Watch Only"
    case fused = "Video + Watch"

    var icon: String {
        switch self {
        case .videoOnly: return "video.fill"
        case .watchOnly: return "applewatch"
        case .fused:     return "wand.and.stars"
        }
    }

    var color: String {
        switch self {
        case .videoOnly: return "hrBlue"
        case .watchOnly: return "hrOrange"
        case .fused:     return "hrGreen"
        }
    }
}

// MARK: - Helpers

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
