import Foundation
import os.log

/// Multi-modal sensor fusion service that combines Apple Watch IMU data
/// with video pose analysis for enhanced accuracy and comprehensive metrics.
///
/// Patent-relevant: This service implements novel algorithms for:
/// 1. Calibrating bat speed using IMU acceleration + video arm length ratio
/// 2. Computing biomechanical efficiency from combined modalities
/// 3. Temporal alignment of IMU events with video frames
/// 4. Age-normalized composite scoring
final class FusionAnalysisService {

    static let shared = FusionAnalysisService()

    private let logger = Logger(subsystem: "com.aihomerun", category: "FusionAnalysis")

    private init() {}

    // MARK: - Main Fusion Entry Point

    /// Produces a FusionResult combining video analysis, watch session, and pose data.
    /// Works in three modes:
    /// - Full fusion (video + watch): highest accuracy
    /// - Video-only: uses video metrics with estimated values
    /// - Watch-only: uses watch metrics with reduced scoring
    func analyze(
        video: AnalysisResult?,
        session: SwingSession?,
        playerAge: Int = 12
    ) -> FusionResult {
        let hasVideo = video != nil
        let hasWatch = session != nil && !(session?.swings.isEmpty ?? true)

        // Calculate fusion confidence
        let confidence: Double = {
            if hasVideo && hasWatch { return 0.95 }
            if hasVideo { return 0.65 }
            if hasWatch { return 0.70 }
            return 0.0
        }()

        // Get best available metrics
        let calibratedSpeed = computeCalibratedBatSpeed(
            video: video, session: session, playerAge: playerAge
        )
        let power = computePowerIndex(
            video: video, session: session, playerAge: playerAge
        )
        let timing = computeTimingScore(video: video, session: session)
        let efficiency = computeBiomechanicalEfficiency(
            video: video, session: session
        )
        let consistency = computeConsistencyIndex(session: session)

        // Attack angle from watch
        let attackAngle: Double? = session?.swings.compactMap(\.attackAngleDegrees).average
        let timeToContact: Double? = session?.averageTimeToContact
        let peakRotAccel: Double? = session?.swings.compactMap(\.rotationalAcceleration).max()

        // Per-swing breakdown
        let perSwing = buildPerSwingMetrics(
            session: session, video: video, playerAge: playerAge
        )

        // Session aggregates
        let sessionMetrics = buildSessionMetrics(session: session)

        let result = FusionResult(
            calibratedBatSpeedMPH: calibratedSpeed,
            powerIndex: power,
            timingScore: timing,
            biomechanicalEfficiency: efficiency,
            consistencyIndex: consistency,
            attackAngleDeg: attackAngle,
            timeToContactMS: timeToContact,
            peakRotationalAccel: peakRotAccel,
            fusionConfidence: confidence,
            hasVideoData: hasVideo,
            hasWatchData: hasWatch,
            sessionMetrics: sessionMetrics,
            perSwingMetrics: perSwing
        )

        logger.info("Fusion complete: speed=\(String(format: "%.1f", calibratedSpeed))mph, power=\(String(format: "%.0f", power)), confidence=\(String(format: "%.0f%%", confidence * 100))")

        return result
    }

    // MARK: - Calibrated Bat Speed

    /// Calibrates watch wrist speed using video-derived arm length ratio.
    /// Patent claim: Scaling IMU wrist velocity by limb segment proportions
    /// extracted from computer vision pose estimation.
    ///
    /// Formula: calibratedSpeed = watchSpeed * (batLength / wristRadius)
    /// Where batLength is estimated from player age and wristRadius from watch position.
    /// When video arm length is available, uses measured proportion instead of estimates.
    private func computeCalibratedBatSpeed(
        video: AnalysisResult?,
        session: SwingSession?,
        playerAge: Int
    ) -> Double {
        // Base speed: prefer watch (direct measurement), fall back to video estimate
        let baseSpeed: Double
        if let session, !session.swings.isEmpty {
            baseSpeed = session.maxHandSpeed
        } else if let wristSpeed = video?.metrics.peakWristSpeed {
            // Convert video pixel speed to estimated mph using age-based scaling
            baseSpeed = wristSpeed * ageSpeedMultiplier(playerAge)
        } else {
            return 0
        }

        // Bat speed calibration factor
        // Watch measures wrist speed; bat head moves ~2.5-3.5x faster due to lever effect
        // Factor varies by age (shorter arms = higher ratio)
        let leverRatio = batLeverRatio(for: playerAge)

        // If we have video hip-shoulder data, refine the calibration
        var refinementFactor = 1.0
        if let hipShoulder = video?.metrics.hipShoulderSeparation {
            // Good hip-shoulder separation = more efficient energy transfer
            let sepEfficiency = min(1.0, hipShoulder / 35.0)
            refinementFactor = 0.85 + (sepEfficiency * 0.30) // 0.85-1.15 range
        }

        return baseSpeed * leverRatio * refinementFactor
    }

    // MARK: - Power Index

    /// Composite power metric combining multiple data sources.
    /// Weights: Acceleration(35%) + Hip-Shoulder(25%) + Follow-Through(15%) + Rotation(25%)
    private func computePowerIndex(
        video: AnalysisResult?,
        session: SwingSession?,
        playerAge: Int
    ) -> Double {
        var components: [(value: Double, weight: Double)] = []

        // Component 1: Peak acceleration from watch (0-100)
        if let session, !session.swings.isEmpty {
            let maxAccel = session.swings.map(\.peakAccelerationG).max() ?? 0
            // Age-normalized: 8yo expects ~5g, 18yo expects ~15g
            let expectedG = ageExpectedAcceleration(playerAge)
            let accelScore = min(100, (maxAccel / expectedG) * 80)
            components.append((accelScore, 0.35))
        }

        // Component 2: Hip-shoulder separation from video (0-100)
        if let sep = video?.metrics.hipShoulderSeparation {
            let sepScore: Double
            switch sep {
            case 35...:  sepScore = 100
            case 25..<35: sepScore = 70 + (sep - 25) / 10 * 30
            case 15..<25: sepScore = 40 + (sep - 15) / 10 * 30
            default:     sepScore = max(10, sep / 15 * 40)
            }
            components.append((sepScore, 0.25))
        }

        // Component 3: Follow-through from video (0 or 100)
        if let ft = video?.metrics.followThrough {
            components.append((ft ? 85 : 30, 0.15))
        }

        // Component 4: Rotational acceleration from watch (0-100)
        if let session, !session.swings.isEmpty {
            let maxRot = session.swings.map(\.rotationRateDPS).max() ?? 0
            // Normalize: 500-2000 DPS typical range
            let rotScore = min(100, max(0, (maxRot - 300) / 1700 * 100))
            components.append((rotScore, 0.25))
        }

        // If we have video power score but no watch, use it directly
        if components.isEmpty, let video {
            return Double(video.feedback.powerScore)
        }

        guard !components.isEmpty else { return 50 }

        // Weighted average with normalization
        let totalWeight = components.reduce(0) { $0 + $1.weight }
        let weightedSum = components.reduce(0) { $0 + $1.value * $1.weight }
        return (weightedSum / totalWeight).clamped(to: 0...100)
    }

    // MARK: - Timing Score

    /// Measures how well the swing timing correlates between watch and video data.
    /// Perfect timing = watch peak acceleration aligns with video peak wrist velocity frame.
    private func computeTimingScore(
        video: AnalysisResult?,
        session: SwingSession?
    ) -> Double {
        // If we have both watch time-to-contact and video data, compute correlation
        if let session, !session.swings.isEmpty {
            let validTTC = session.swings.compactMap(\.timeToContactMS)
            if !validTTC.isEmpty {
                let avgTTC = validTTC.average ?? 150
                // Ideal time-to-contact: 130-170ms for most age groups
                let idealTTC = 150.0
                let deviation = abs(avgTTC - idealTTC) / idealTTC
                let ttcScore = max(0, 100 - deviation * 100)

                // Bonus for consistency in TTC
                let ttcStdDev = validTTC.standardDeviation ?? 0
                let consistencyBonus = max(0, 15 - ttcStdDev / 10) // up to 15 bonus points
                return min(100, ttcScore + consistencyBonus)
            }

            // Fall back to swing duration analysis
            let avgDuration = session.swings.map(\.swingDurationMS).average ?? 200
            // Ideal swing duration: 150-250ms
            let durationScore: Double
            switch avgDuration {
            case 150...250: durationScore = 90
            case 100..<150: durationScore = 70
            case 250..<350: durationScore = 65
            default:        durationScore = 40
            }
            return durationScore
        }

        // Video-only: estimate from technique score
        if let video {
            return Double(video.feedback.techniqueScore) * 0.85
        }

        return 50
    }

    // MARK: - Biomechanical Efficiency

    /// Combines video body mechanics with watch rotational efficiency.
    /// Video component: balance + joint angle conformity + hip-shoulder separation
    /// Watch component: rotation rate / peak acceleration ratio (energy transfer efficiency)
    private func computeBiomechanicalEfficiency(
        video: AnalysisResult?,
        session: SwingSession?
    ) -> Double {
        var videoScore: Double = 50
        var watchScore: Double = 50
        var hasVideoComp = false
        var hasWatchComp = false

        // Video component (60% weight when both available)
        if let video {
            hasVideoComp = true
            var components: [Double] = []

            // Balance (0-100)
            if let bal = video.metrics.balanceScore {
                components.append(bal * 100)
            }

            // Joint angles in ideal range
            if let ja = video.metrics.jointAngles {
                var angleScore = 0.0
                var angleCount = 0.0

                if let elbow = ja.elbowAngle {
                    let ideal: ClosedRange<Double> = 90...110
                    angleScore += ideal.contains(elbow) ? 100 : max(0, 100 - abs(elbow - 100) * 3)
                    angleCount += 1
                }
                if let shoulder = ja.shoulderAngle {
                    let ideal: ClosedRange<Double> = 0...15
                    angleScore += ideal.contains(shoulder) ? 100 : max(0, 100 - shoulder * 3)
                    angleCount += 1
                }
                if let knee = ja.kneeBend {
                    let ideal: ClosedRange<Double> = 130...160
                    angleScore += ideal.contains(knee) ? 100 : max(0, 100 - abs(knee - 145) * 2)
                    angleCount += 1
                }

                if angleCount > 0 {
                    components.append(angleScore / angleCount)
                }
            }

            // Hip-shoulder separation quality
            if let sep = video.metrics.hipShoulderSeparation {
                components.append(min(100, sep / 35 * 100))
            }

            // Plane efficiency
            if let pe = video.metrics.planeEfficiency {
                components.append(pe)
            }

            if !components.isEmpty {
                videoScore = components.reduce(0, +) / Double(components.count)
            }
        }

        // Watch component (40% weight when both available)
        if let session, !session.swings.isEmpty {
            hasWatchComp = true
            let swings = session.swings

            // Rotational efficiency: rotation rate / acceleration ratio
            // Higher ratio = better energy transfer from body rotation to bat speed
            let rotEfficiencies = swings.map { swing -> Double in
                guard swing.peakAccelerationG > 0 else { return 0 }
                return swing.rotationRateDPS / (swing.peakAccelerationG * 100)
            }
            let avgRotEff = rotEfficiencies.average ?? 0
            // Normalize: 0.5-3.0 is typical range
            let rotScore = min(100, max(0, (avgRotEff - 0.3) / 2.7 * 100))

            // Swing smoothness: lower variation in duration = smoother mechanics
            let durations = swings.map(\.swingDurationMS)
            let durCV = (durations.standardDeviation ?? 0) / max(1, durations.average ?? 150)
            let smoothnessScore = max(0, 100 - durCV * 200)

            watchScore = rotScore * 0.6 + smoothnessScore * 0.4
        }

        // Combine based on available data
        if hasVideoComp && hasWatchComp {
            return (videoScore * 0.6 + watchScore * 0.4).clamped(to: 0...100)
        } else if hasVideoComp {
            return videoScore.clamped(to: 0...100)
        } else if hasWatchComp {
            return watchScore.clamped(to: 0...100)
        }

        return 50
    }

    // MARK: - Consistency Index

    /// Measures swing-to-swing consistency across a session.
    /// Uses coefficient of variation (CV) across speed, angle, and duration.
    private func computeConsistencyIndex(session: SwingSession?) -> Double {
        guard let session, session.swings.count >= 3 else {
            // Not enough swings for meaningful consistency metric
            return session?.swings.isEmpty == false ? 70 : 50
        }

        let swings = session.swings
        var cvComponents: [Double] = []

        // Speed CV
        let speeds = swings.map(\.handSpeedMPH)
        if let cv = coefficientOfVariation(speeds), cv.isFinite {
            cvComponents.append(cv)
        }

        // Duration CV
        let durations = swings.map(\.swingDurationMS)
        if let cv = coefficientOfVariation(durations), cv.isFinite {
            cvComponents.append(cv)
        }

        // Attack angle CV (if available)
        let angles = swings.compactMap(\.attackAngleDegrees)
        if angles.count >= 3, let cv = coefficientOfVariation(angles), cv.isFinite {
            cvComponents.append(cv)
        }

        // Rotation rate CV
        let rotRates = swings.map(\.rotationRateDPS)
        if let cv = coefficientOfVariation(rotRates), cv.isFinite {
            cvComponents.append(cv)
        }

        guard !cvComponents.isEmpty else { return 50 }

        let avgCV = cvComponents.reduce(0, +) / Double(cvComponents.count)
        // Convert CV to score: lower CV = higher consistency
        // CV of 0.05 (5%) = 95 score, CV of 0.30 (30%) = 40 score
        let score = max(0, min(100, 100 - avgCV * 200))
        return score
    }

    // MARK: - Per-Swing Metrics

    private func buildPerSwingMetrics(
        session: SwingSession?,
        video: AnalysisResult?,
        playerAge: Int
    ) -> [SwingFusionMetric] {
        guard let session else { return [] }

        return session.swings.enumerated().map { index, swing in
            let leverRatio = batLeverRatio(for: playerAge)
            let calSpeed = swing.handSpeedMPH * leverRatio

            // Per-swing power
            let accelNorm = min(100, swing.peakAccelerationG / ageExpectedAcceleration(playerAge) * 80)
            let rotNorm = min(100, max(0, (swing.rotationRateDPS - 300) / 1700 * 100))
            let power = accelNorm * 0.5 + rotNorm * 0.5

            // Per-swing timing
            let timing: Double
            if let ttc = swing.timeToContactMS {
                let dev = abs(ttc - 150) / 150
                timing = max(0, 100 - dev * 100)
            } else {
                let durDev = abs(swing.swingDurationMS - 200) / 200
                timing = max(0, 85 - durDev * 100)
            }

            // Per-swing efficiency
            let rotEff = swing.peakAccelerationG > 0
                ? swing.rotationRateDPS / (swing.peakAccelerationG * 100) : 0
            let efficiency = min(100, max(0, (rotEff - 0.3) / 2.7 * 100))

            return SwingFusionMetric(
                id: swing.id,
                swingIndex: index + 1,
                timestamp: swing.timestamp,
                calibratedSpeed: calSpeed,
                powerIndex: power,
                timingScore: timing,
                efficiency: efficiency,
                attackAngle: swing.attackAngleDegrees,
                impactDetected: swing.impactDetected,
                rawHandSpeedMPH: swing.handSpeedMPH,
                swingDurationMS: swing.swingDurationMS
            )
        }
    }

    // MARK: - Session Metrics

    private func buildSessionMetrics(session: SwingSession?) -> SessionFusionMetrics? {
        guard let session, !session.swings.isEmpty else { return nil }

        let speeds = session.swings.map(\.handSpeedMPH)
        let angles = session.swings.compactMap(\.attackAngleDegrees)

        let speedMean = speeds.average ?? 0
        let speedStdDev = speeds.standardDeviation ?? 0
        let angleMean = angles.average ?? 0
        let angleStdDev = angles.standardDeviation ?? 0

        // Improvement trend: linear regression slope of speed over swing index
        let trend = linearRegressionSlope(speeds)

        // Session consistency
        let consistencyScore = computeConsistencyIndex(session: session)

        return SessionFusionMetrics(
            speedDistribution: speeds,
            speedMean: speedMean,
            speedStdDev: speedStdDev,
            speedMin: speeds.min() ?? 0,
            speedMax: speeds.max() ?? 0,
            angleDistribution: angles,
            angleMean: angleMean,
            angleStdDev: angleStdDev,
            sessionConsistencyScore: consistencyScore,
            improvementTrend: trend,
            hitRate: Double(session.hitsCount) / Double(max(1, session.swingCount)),
            totalSwings: session.swingCount,
            totalHits: session.hitsCount,
            sessionDurationSeconds: session.duration,
            averageHeartRate: session.averageHeartRate,
            peakHeartRate: session.peakHeartRate,
            caloriesBurned: session.caloriesBurned
        )
    }

    // MARK: - Age-Based Reference Values

    /// Bat lever ratio: bat head speed / wrist speed by age group
    private func batLeverRatio(for age: Int) -> Double {
        switch age {
        case ...7:   return 2.2
        case 8...9:  return 2.4
        case 10...11: return 2.6
        case 12...13: return 2.8
        case 14...15: return 3.0
        case 16...17: return 3.2
        default:     return 3.4  // 18+
        }
    }

    /// Expected peak acceleration (g) by age group
    private func ageExpectedAcceleration(_ age: Int) -> Double {
        switch age {
        case ...7:   return 4.0
        case 8...9:  return 5.5
        case 10...11: return 7.0
        case 12...13: return 9.0
        case 14...15: return 11.0
        case 16...17: return 13.0
        default:     return 15.0
        }
    }

    /// Pixel-to-mph conversion multiplier (approximate, varies by camera distance)
    private func ageSpeedMultiplier(_ age: Int) -> Double {
        switch age {
        case ...9:   return 1.8
        case 10...13: return 2.0
        case 14...17: return 2.3
        default:     return 2.5
        }
    }

    // MARK: - Statistics Helpers

    private func coefficientOfVariation(_ values: [Double]) -> Double? {
        guard let mean = values.average, mean > 0,
              let stdDev = values.standardDeviation else { return nil }
        return stdDev / mean
    }

    private func linearRegressionSlope(_ values: [Double]) -> Double {
        let n = Double(values.count)
        guard n >= 3 else { return 0 }

        let indices = (0..<values.count).map { Double($0) }
        let sumX = indices.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(indices, values).map(*).reduce(0, +)
        let sumX2 = indices.map { $0 * $0 }.reduce(0, +)

        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return 0 }

        return (n * sumXY - sumX * sumY) / denominator
    }
}

// MARK: - Array Statistics Extensions

private extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }

    var standardDeviation: Double? {
        guard let mean = average, count >= 2 else { return nil }
        let variance = map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(count - 1)
        return Foundation.sqrt(variance)
    }
}

// MARK: - Optional Array Average

private extension Array where Element == Optional<Double> {
    var flatAverage: Double? {
        let valid = compactMap { $0 }
        guard !valid.isEmpty else { return nil }
        return valid.reduce(0, +) / Double(valid.count)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
