import Foundation
import os.log

/// On-device swing detection algorithm
/// Based on Apple WWDC23 CoreMotion demo for baseball bat swings
/// Uses accelerometer peaks for impact detection and rotation rate for swing start
final class SwingDetector: ObservableObject {

    private let logger = Logger(subsystem: "com.aihomerun.watch", category: "SwingDetector")

    // MARK: - Configuration

    struct Config {
        // Impact detection (from 800Hz accelerometer)
        var impactThresholdG: Double = 8.0          // Minimum g-force to count as impact
        var impactPeakWindowSamples: Int = 50       // Samples around peak to analyze

        // Swing start detection (from rotation rate)
        var swingStartThresholdDPS: Double = 100.0  // Min rotation rate to indicate swing start
        var swingStartLookbackMS: Double = 500.0    // How far back to search for swing start

        // Hand speed estimation
        var estimatedWristRadiusM: Double = 0.65    // Average wrist-to-bat-center distance (meters)

        // Cooldown to prevent double-counting
        var swingCooldownMS: Double = 800.0         // Minimum time between detected swings

        // Quality filters
        var minSwingDurationMS: Double = 100.0      // Too short = noise
        var maxSwingDurationMS: Double = 1000.0     // Too long = not a swing
    }

    /// Standard config for normal (ball impact) mode
    static let standardConfig = Config()

    /// Air Swing config — lower thresholds to detect swings without ball contact
    static let airSwingConfig: Config = {
        var c = Config()
        c.impactThresholdG = 3.0              // Much lower — no ball impact needed
        c.swingStartThresholdDPS = 80.0       // Slightly lower rotation threshold
        c.swingCooldownMS = 1000.0            // Longer cooldown to avoid noise
        c.minSwingDurationMS = 120.0          // Slightly more lenient
        return c
    }()

    var config = Config()

    // MARK: - State

    @Published private(set) var totalSwingsDetected: Int = 0
    @Published private(set) var lastSwingEvent: SwingEvent?
    @Published var practiceMode: PracticeMode = .standard {
        didSet {
            applyMode(practiceMode)
        }
    }

    private var lastSwingTimestamp: TimeInterval = 0
    var onSwingDetected: ((SwingEvent) -> Void)?

    // Age-based scoring reference (for composite score normalization)
    var playerAge: Int = 12

    // MARK: - Apply Practice Mode

    private func applyMode(_ mode: PracticeMode) {
        switch mode {
        case .standard:
            config = Self.standardConfig
            logger.info("Switched to Standard mode (impact threshold: \(self.config.impactThresholdG)g)")
        case .airSwing:
            config = Self.airSwingConfig
            logger.info("Switched to Air Swing mode (impact threshold: \(self.config.impactThresholdG)g)")
        }
    }

    // MARK: - Process Batch

    /// Called with each batch of sensor data (typically every ~1 second)
    func processBatch(
        accelData: [(timestamp: TimeInterval, x: Double, y: Double, z: Double)],
        motionData: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double,
                      gravX: Double, gravY: Double, gravZ: Double,
                      userAccX: Double, userAccY: Double, userAccZ: Double)]
    ) {
        // Step 1: Find impact peaks in accelerometer data
        let impacts = findImpactPeaks(in: accelData)

        for impact in impacts {
            // Cooldown check
            guard impact.timestamp - lastSwingTimestamp > config.swingCooldownMS / 1000.0 else {
                continue
            }

            // Step 2: Find swing start by looking back in rotation rate data
            let swingStart = findSwingStart(before: impact.timestamp, in: motionData)

            // Step 3: Calculate metrics
            let swingDurationMS: Double
            if let swingStart {
                swingDurationMS = (impact.timestamp - swingStart.timestamp) * 1000.0
            } else {
                swingDurationMS = 200.0  // Default estimate
            }

            // Filter unrealistic durations
            guard swingDurationMS >= config.minSwingDurationMS &&
                  swingDurationMS <= config.maxSwingDurationMS else {
                continue
            }

            // Step 4: Estimate hand speed from peak rotation rate
            let peakRotation = findPeakRotationRate(
                around: impact.timestamp,
                in: motionData,
                windowMS: swingDurationMS
            )

            let handSpeedMS = peakRotation.magnitude * config.estimatedWristRadiusM
            let handSpeedMPH = handSpeedMS * 2.23694  // m/s to mph

            // Step 5: Estimate attack angle from acceleration vector at impact
            let attackAngle = estimateAttackAngle(at: impact, motionData: motionData)

            // Step 6: Calculate time to contact
            let timeToContact: Double? = swingStart != nil ?
                (impact.timestamp - swingStart!.timestamp) * 1000.0 : nil

            // Step 7: Calculate rotational acceleration
            let rotAccel = calculateRotationalAcceleration(
                around: impact.timestamp,
                in: motionData,
                swingStartTimestamp: swingStart?.timestamp
            )

            // Step 8: Calculate advanced metrics
            let barrelSpeed = calculateBarrelSpeed(
                peakAccelerationG: impact.magnitude,
                peakRotationRadS: peakRotation.magnitude
            )

            let swingPlane = calculateSwingPlaneAngle(
                at: impact.timestamp,
                in: motionData
            )

            let powerTransfer = calculatePowerTransferEfficiency(
                peakAccelerationG: impact.magnitude,
                around: impact.timestamp,
                swingStartTimestamp: swingStart?.timestamp,
                in: motionData
            )

            let loadTime = calculateLoadTime(
                impactTimestamp: impact.timestamp,
                swingStartTimestamp: swingStart?.timestamp,
                in: motionData
            )

            let snap = calculateSnapScore(
                around: impact.timestamp,
                in: motionData
            )

            let kineticChain = calculateKineticChainScore(
                around: impact.timestamp,
                swingStartTimestamp: swingStart?.timestamp,
                in: motionData
            )

            let connection = calculateConnectionScore(
                around: impact.timestamp,
                swingStartTimestamp: swingStart?.timestamp,
                in: motionData
            )

            // Step 9: Calculate composite swing score
            let score = calculateSwingScore(
                handSpeedMPH: handSpeedMPH,
                barrelSpeedMPH: barrelSpeed,
                attackAngle: attackAngle,
                timeToContactMS: timeToContact,
                rotationalAcceleration: rotAccel,
                peakAccelerationG: impact.magnitude,
                swingDurationMS: swingDurationMS,
                impactDetected: impact.magnitude > config.impactThresholdG * 2,
                powerTransferEfficiency: powerTransfer,
                kineticChainScore: kineticChain,
                snapScore: snap
            )

            // Step 10: Create swing event
            let event = SwingEvent(
                timestamp: Date(),
                handSpeedMPH: handSpeedMPH,
                peakAccelerationG: impact.magnitude,
                timeToContactMS: timeToContact,
                attackAngleDegrees: attackAngle,
                swingDurationMS: swingDurationMS,
                impactDetected: practiceMode == .airSwing ? true : impact.magnitude > config.impactThresholdG * 2,
                rotationRateDPS: peakRotation.magnitude * 180.0 / .pi,  // rad/s to deg/s
                rotationalAcceleration: rotAccel,
                swingScore: score,
                barrelSpeedMPH: barrelSpeed,
                swingPlaneAngle: swingPlane,
                powerTransferEfficiency: powerTransfer,
                loadTimeMS: loadTime,
                snapScore: snap,
                kineticChainScore: kineticChain,
                connectionScore: connection
            )

            lastSwingTimestamp = impact.timestamp
            totalSwingsDetected += 1
            lastSwingEvent = event
            onSwingDetected?(event)

            logger.info("Swing #\(self.totalSwingsDetected): hand \(String(format: "%.1f", handSpeedMPH)) mph, barrel \(String(format: "%.1f", barrelSpeed)) mph, score: \(score ?? 0), snap: \(String(format: "%.0f", snap ?? 0)), chain: \(String(format: "%.0f", kineticChain ?? 0))")
        }
    }

    // MARK: - Impact Detection

    private struct AccelPeak {
        let timestamp: TimeInterval
        let magnitude: Double
        let x: Double, y: Double, z: Double
    }

    private func findImpactPeaks(
        in data: [(timestamp: TimeInterval, x: Double, y: Double, z: Double)]
    ) -> [AccelPeak] {
        guard data.count > 2 else { return [] }

        var peaks: [AccelPeak] = []

        for i in 1..<(data.count - 1) {
            let mag = sqrt(data[i].x * data[i].x + data[i].y * data[i].y + data[i].z * data[i].z)

            // Check if this is a local maximum above threshold
            if mag > config.impactThresholdG {
                let prevMag = sqrt(data[i-1].x * data[i-1].x + data[i-1].y * data[i-1].y + data[i-1].z * data[i-1].z)
                let nextMag = sqrt(data[i+1].x * data[i+1].x + data[i+1].y * data[i+1].y + data[i+1].z * data[i+1].z)

                if mag >= prevMag && mag >= nextMag {
                    peaks.append(AccelPeak(
                        timestamp: data[i].timestamp,
                        magnitude: mag,
                        x: data[i].x, y: data[i].y, z: data[i].z
                    ))
                }
            }
        }

        // De-duplicate peaks that are too close together (keep the highest)
        var filtered: [AccelPeak] = []
        for peak in peaks {
            if let last = filtered.last,
               abs(peak.timestamp - last.timestamp) < 0.05 {
                // Within 50ms — keep the bigger one
                if peak.magnitude > last.magnitude {
                    filtered[filtered.count - 1] = peak
                }
            } else {
                filtered.append(peak)
            }
        }

        return filtered
    }

    // MARK: - Swing Start Detection

    private struct RotationPoint {
        let timestamp: TimeInterval
        let magnitude: Double
    }

    private func findSwingStart(
        before impactTime: TimeInterval,
        in motionData: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double,
                         gravX: Double, gravY: Double, gravZ: Double,
                         userAccX: Double, userAccY: Double, userAccZ: Double)]
    ) -> RotationPoint? {
        let lookbackSeconds = config.swingStartLookbackMS / 1000.0
        let earliestTime = impactTime - lookbackSeconds

        // Find samples in the lookback window, reversed (working backwards from impact)
        let relevantSamples = motionData.filter {
            $0.timestamp >= earliestTime && $0.timestamp <= impactTime
        }.reversed()

        let thresholdRadS = config.swingStartThresholdDPS * .pi / 180.0

        // Walk backwards from impact, find where rotation rate drops below threshold
        for sample in relevantSamples {
            let rotMag = sqrt(sample.rotX * sample.rotX + sample.rotY * sample.rotY + sample.rotZ * sample.rotZ)
            if rotMag < thresholdRadS {
                return RotationPoint(timestamp: sample.timestamp, magnitude: rotMag)
            }
        }

        return nil
    }

    // MARK: - Peak Rotation Rate

    private func findPeakRotationRate(
        around timestamp: TimeInterval,
        in motionData: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double,
                         gravX: Double, gravY: Double, gravZ: Double,
                         userAccX: Double, userAccY: Double, userAccZ: Double)],
        windowMS: Double
    ) -> (magnitude: Double, x: Double, y: Double, z: Double) {
        let windowSec = windowMS / 1000.0
        let start = timestamp - windowSec
        let end = timestamp

        var peakMag = 0.0
        var peakRot = (x: 0.0, y: 0.0, z: 0.0)

        for sample in motionData where sample.timestamp >= start && sample.timestamp <= end {
            let mag = sqrt(sample.rotX * sample.rotX + sample.rotY * sample.rotY + sample.rotZ * sample.rotZ)
            if mag > peakMag {
                peakMag = mag
                peakRot = (sample.rotX, sample.rotY, sample.rotZ)
            }
        }

        return (magnitude: peakMag, x: peakRot.x, y: peakRot.y, z: peakRot.z)
    }

    // MARK: - Attack Angle Estimation

    private func estimateAttackAngle(
        at impact: AccelPeak,
        motionData: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double,
                      gravX: Double, gravY: Double, gravZ: Double,
                      userAccX: Double, userAccY: Double, userAccZ: Double)]
    ) -> Double? {
        // Find the closest motion sample to the impact
        guard let closestMotion = motionData.min(by: {
            abs($0.timestamp - impact.timestamp) < abs($1.timestamp - impact.timestamp)
        }) else { return nil }

        // Attack angle: angle of user acceleration relative to gravity plane
        let userAccMag = sqrt(
            closestMotion.userAccX * closestMotion.userAccX +
            closestMotion.userAccY * closestMotion.userAccY +
            closestMotion.userAccZ * closestMotion.userAccZ
        )

        guard userAccMag > 0.1 else { return nil }

        // Dot product of user acceleration with gravity gives the vertical component
        let dotProduct = closestMotion.userAccX * closestMotion.gravX +
                         closestMotion.userAccY * closestMotion.gravY +
                         closestMotion.userAccZ * closestMotion.gravZ

        let gravMag = sqrt(
            closestMotion.gravX * closestMotion.gravX +
            closestMotion.gravY * closestMotion.gravY +
            closestMotion.gravZ * closestMotion.gravZ
        )

        guard gravMag > 0.1 else { return nil }

        // Angle between acceleration and gravity = attack angle approximation
        let cosAngle = dotProduct / (userAccMag * gravMag)
        let clamped = max(-1.0, min(1.0, cosAngle))
        let angle = acos(clamped) * 180.0 / .pi

        // Convert to swing attack angle (-90 to +90 range)
        return angle - 90.0
    }

    // MARK: - Rotational Acceleration (NEW)

    /// Calculates the rate of change of rotation rate (angular acceleration) during the early swing phase.
    /// This measures how quickly the bat accelerates into the swing plane — a key indicator of
    /// proper sequencing (hip → torso → arms) vs. "muscling" the bat with hands.
    ///
    /// Similar to Blast Motion's "Rotational Acceleration" metric.
    private func calculateRotationalAcceleration(
        around impactTimestamp: TimeInterval,
        in motionData: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double,
                         gravX: Double, gravY: Double, gravZ: Double,
                         userAccX: Double, userAccY: Double, userAccZ: Double)],
        swingStartTimestamp: TimeInterval?
    ) -> Double? {
        // We want the early phase of the swing (first 40% of swing duration)
        let swingStart = swingStartTimestamp ?? (impactTimestamp - 0.2) // fallback 200ms before impact
        let earlyPhaseEnd = swingStart + (impactTimestamp - swingStart) * 0.4

        // Get rotation rate samples in the early swing window
        let earlySamples = motionData.filter {
            $0.timestamp >= swingStart && $0.timestamp <= earlyPhaseEnd
        }.sorted { $0.timestamp < $1.timestamp }

        guard earlySamples.count >= 3 else { return nil }

        // Calculate rotation rate magnitudes
        let rotMagnitudes: [(timestamp: TimeInterval, mag: Double)] = earlySamples.map { sample in
            let mag = sqrt(sample.rotX * sample.rotX + sample.rotY * sample.rotY + sample.rotZ * sample.rotZ)
            return (timestamp: sample.timestamp, mag: mag)
        }

        // Compute finite differences (angular acceleration = d(omega)/dt)
        var accelerations: [Double] = []
        for i in 1..<rotMagnitudes.count {
            let dt = rotMagnitudes[i].timestamp - rotMagnitudes[i-1].timestamp
            guard dt > 0.001 else { continue } // avoid division by near-zero
            let dOmega = rotMagnitudes[i].mag - rotMagnitudes[i-1].mag
            accelerations.append(dOmega / dt)
        }

        guard !accelerations.isEmpty else { return nil }

        // Return peak angular acceleration (rad/s²)
        // We want the maximum positive acceleration (the buildup phase)
        let peakAccel = accelerations.max() ?? 0
        return peakAccel > 0 ? peakAccel : nil
    }

    // MARK: - Composite Swing Score (NEW)

    /// Calculates a 0–100 composite swing quality score based on available metrics.
    /// Inspired by Blast's "Blast Factor" but adapted for wrist IMU data.
    ///
    /// Weights:
    /// - Barrel Speed:             25% (primary performance indicator)
    /// - Attack Angle:             10% (ideal range: 6–12° upward)
    /// - Rotational Acceleration:  15% (sequencing quality)
    /// - Time to Contact:          10% (bat quickness)
    /// - Impact Quality:           15% (peak g-force indicates clean contact)
    /// - Power Transfer:           10% (explosive contact efficiency)
    /// - Kinetic Chain:            10% (sequential acceleration buildup)
    /// - Snap Score:                5% (wrist snap quality)
    private func calculateSwingScore(
        handSpeedMPH: Double,
        barrelSpeedMPH: Double?,
        attackAngle: Double?,
        timeToContactMS: Double?,
        rotationalAcceleration: Double?,
        peakAccelerationG: Double,
        swingDurationMS: Double,
        impactDetected: Bool,
        powerTransferEfficiency: Double?,
        kineticChainScore: Double?,
        snapScore: Double?
    ) -> Int? {
        var totalScore: Double = 0
        var totalWeight: Double = 0

        // --- Barrel Speed Score (25%) ---
        // Use barrel speed if available, fall back to hand speed
        let speedForScoring = barrelSpeedMPH ?? handSpeedMPH
        let speedRef = referenceBarrelSpeed(for: playerAge)
        let speedScore = min(100.0, (speedForScoring / speedRef.excellent) * 100.0)
        totalScore += speedScore * 0.25
        totalWeight += 0.25

        // --- Attack Angle Score (10%) ---
        if let angle = attackAngle {
            // Ideal attack angle is 6–12° upward
            // Perfect = 9°, penalty increases as you deviate
            let idealAngle = 9.0
            let deviation = abs(angle - idealAngle)
            let angleScore: Double
            if deviation <= 3.0 {
                angleScore = 100.0 - (deviation * 5.0) // 85–100 for within 3° of ideal
            } else if deviation <= 10.0 {
                angleScore = 85.0 - ((deviation - 3.0) * 8.0) // 29–85
            } else {
                angleScore = max(0, 29.0 - (deviation - 10.0) * 3.0)
            }
            totalScore += angleScore * 0.10
            totalWeight += 0.10
        }

        // --- Rotational Acceleration Score (15%) ---
        if let rotAccel = rotationalAcceleration {
            // Higher is better — indicates good kinetic chain sequencing
            let rotRef = referenceRotAccel(for: playerAge)
            let rotScore = min(100.0, (rotAccel / rotRef.excellent) * 100.0)
            totalScore += rotScore * 0.15
            totalWeight += 0.15
        }

        // --- Time to Contact Score (10%) ---
        if let ttc = timeToContactMS {
            // Faster is better, but too fast may indicate a choppy swing
            let ttcRef = referenceTTC(for: playerAge)
            let ttcScore: Double
            if ttc < ttcRef.tooFast {
                ttcScore = 70.0 // Penalize unnaturally fast swings
            } else if ttc <= ttcRef.excellent {
                ttcScore = 100.0
            } else if ttc <= ttcRef.average {
                let range = ttcRef.average - ttcRef.excellent
                ttcScore = 100.0 - ((ttc - ttcRef.excellent) / range * 40.0)
            } else {
                ttcScore = max(0, 60.0 - ((ttc - ttcRef.average) / 50.0 * 30.0))
            }
            totalScore += ttcScore * 0.10
            totalWeight += 0.10
        }

        // --- Impact Quality Score (15%) ---
        // Higher peak g-force with impact = cleaner contact
        let impactScore: Double
        if impactDetected {
            let impactRef = referenceImpact(for: playerAge)
            impactScore = min(100.0, (peakAccelerationG / impactRef.excellent) * 100.0)
        } else {
            impactScore = practiceMode == .airSwing ? 50.0 : 20.0 // Miss penalty (reduced for air swing)
        }
        totalScore += impactScore * 0.15
        totalWeight += 0.15

        // --- Power Transfer Efficiency Score (10%) ---
        if let pte = powerTransferEfficiency {
            totalScore += pte * 0.10
            totalWeight += 0.10
        }

        // --- Kinetic Chain Score (10%) ---
        if let kcs = kineticChainScore {
            totalScore += kcs * 0.10
            totalWeight += 0.10
        }

        // --- Snap Score (5%) ---
        if let ss = snapScore {
            totalScore += ss * 0.05
            totalWeight += 0.05
        }

        // Normalize if some metrics were missing
        guard totalWeight > 0 else { return nil }
        let normalizedScore = totalScore / totalWeight

        return max(0, min(100, Int(normalizedScore.rounded())))
    }

    /// Barrel speed reference values by age (mph) — higher than hand speed due to lever effect
    private func referenceBarrelSpeed(for age: Int) -> SpeedReference {
        switch age {
        case ...8:   return SpeedReference(average: 30, excellent: 45)
        case 9...10: return SpeedReference(average: 40, excellent: 55)
        case 11...12: return SpeedReference(average: 50, excellent: 65)
        case 13...14: return SpeedReference(average: 55, excellent: 72)
        case 15...17: return SpeedReference(average: 62, excellent: 78)
        default:      return SpeedReference(average: 68, excellent: 85) // 18+ / college+
        }
    }

    // MARK: - Age-Based Reference Values

    private struct SpeedReference {
        let average: Double   // Average for age group (mph)
        let excellent: Double // Top-tier for age group (mph)
    }

    private func referenceSpeed(for age: Int) -> SpeedReference {
        switch age {
        case ...8:   return SpeedReference(average: 20, excellent: 30)
        case 9...10: return SpeedReference(average: 28, excellent: 40)
        case 11...12: return SpeedReference(average: 35, excellent: 50)
        case 13...14: return SpeedReference(average: 42, excellent: 58)
        case 15...17: return SpeedReference(average: 50, excellent: 65)
        default:      return SpeedReference(average: 55, excellent: 75) // 18+ / college+
        }
    }

    private func referenceRotAccel(for age: Int) -> (average: Double, excellent: Double) {
        // Rotational acceleration in rad/s² — higher is better
        switch age {
        case ...10:  return (average: 80, excellent: 150)
        case 11...14: return (average: 120, excellent: 220)
        case 15...17: return (average: 160, excellent: 300)
        default:      return (average: 200, excellent: 380)
        }
    }

    private func referenceTTC(for age: Int) -> (tooFast: Double, excellent: Double, average: Double) {
        // Time to contact in ms — lower is better (within reason)
        switch age {
        case ...10:  return (tooFast: 100, excellent: 160, average: 220)
        case 11...14: return (tooFast: 90, excellent: 140, average: 200)
        case 15...17: return (tooFast: 80, excellent: 120, average: 180)
        default:      return (tooFast: 70, excellent: 110, average: 160)
        }
    }

    private func referenceImpact(for age: Int) -> (average: Double, excellent: Double) {
        // Peak acceleration g-force at impact
        switch age {
        case ...10:  return (average: 10, excellent: 18)
        case 11...14: return (average: 14, excellent: 24)
        case 15...17: return (average: 18, excellent: 30)
        default:      return (average: 22, excellent: 36)
        }
    }

    // MARK: - Barrel Speed

    /// Estimates barrel speed using centripetal acceleration and rotation rate.
    /// Takes the higher of two estimates: centripetal-based and rotation-based.
    private func calculateBarrelSpeed(
        peakAccelerationG: Double,
        peakRotationRadS: Double
    ) -> Double {
        let batLength = referenceBatLength(for: playerAge)

        // Method 1: From centripetal acceleration — a = v² / r → v = sqrt(a * r)
        let accelMPS2 = peakAccelerationG * 9.81
        let barrelV1 = sqrt(accelMPS2 * batLength)

        // Method 2: From rotation rate — v = ω * r
        let barrelV2 = peakRotationRadS * batLength

        // Take the higher estimate (both are approximations)
        let barrelMPS = max(barrelV1, barrelV2)
        return barrelMPS * 2.23694 // m/s to mph
    }

    /// Returns estimated bat length (meters) based on player age
    private func referenceBatLength(for age: Int) -> Double {
        switch age {
        case ...7:   return 0.610  // 24 inches
        case 8:      return 0.660  // 26 inches
        case 9...10: return 0.737  // 29 inches
        case 11...12: return 0.787 // 31 inches
        case 13...14: return 0.826 // 32.5 inches
        case 15...17: return 0.851 // 33.5 inches
        default:      return 0.864 // 34 inches (adult)
        }
    }

    // MARK: - Swing Plane Angle

    /// Calculates the angle of the swing plane relative to horizontal.
    /// Positive = uppercut, negative = downswing, ~0 = level.
    private func calculateSwingPlaneAngle(
        at impactTimestamp: TimeInterval,
        in motionData: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double,
                         gravX: Double, gravY: Double, gravZ: Double,
                         userAccX: Double, userAccY: Double, userAccZ: Double)]
    ) -> Double? {
        guard let closest = motionData.min(by: {
            abs($0.timestamp - impactTimestamp) < abs($1.timestamp - impactTimestamp)
        }) else { return nil }

        let gravMag = sqrt(closest.gravX * closest.gravX + closest.gravY * closest.gravY + closest.gravZ * closest.gravZ)
        guard gravMag > 0.1 else { return nil }

        let userAccMag = sqrt(closest.userAccX * closest.userAccX + closest.userAccY * closest.userAccY + closest.userAccZ * closest.userAccZ)
        guard userAccMag > 0.1 else { return nil }

        // Dot product of user acceleration with gravity → vertical component
        let dotProduct = closest.userAccX * closest.gravX +
                         closest.userAccY * closest.gravY +
                         closest.userAccZ * closest.gravZ

        let verticalComponent = dotProduct / gravMag
        // Horizontal component: magnitude of projection onto plane perpendicular to gravity
        let verticalSquared = (dotProduct * dotProduct) / (gravMag * gravMag)
        let horizontalMag = sqrt(max(0, userAccMag * userAccMag - verticalSquared))

        guard horizontalMag > 0.01 else { return nil }

        let planeAngle = atan2(verticalComponent, horizontalMag) * 180.0 / .pi
        return planeAngle
    }

    // MARK: - Power Transfer Efficiency

    /// Measures how explosive contact is relative to the average swing acceleration.
    /// Higher ratio = energy concentrates at impact point = better power transfer.
    private func calculatePowerTransferEfficiency(
        peakAccelerationG: Double,
        around impactTimestamp: TimeInterval,
        swingStartTimestamp: TimeInterval?,
        in motionData: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double,
                         gravX: Double, gravY: Double, gravZ: Double,
                         userAccX: Double, userAccY: Double, userAccZ: Double)]
    ) -> Double? {
        let swingStart = swingStartTimestamp ?? (impactTimestamp - 0.2)

        let swingSamples = motionData.filter {
            $0.timestamp >= swingStart && $0.timestamp <= impactTimestamp
        }

        guard swingSamples.count >= 3 else { return nil }

        let accelMagnitudes = swingSamples.map { sample in
            sqrt(sample.userAccX * sample.userAccX + sample.userAccY * sample.userAccY + sample.userAccZ * sample.userAccZ)
        }

        // Average acceleration during swing (in g, using userAcceleration which is already in g)
        let avgAccelG = accelMagnitudes.reduce(0, +) / Double(accelMagnitudes.count)
        guard avgAccelG > 0.01 else { return nil }

        let peakRatio = peakAccelerationG / avgAccelG
        // A ratio of 5.0+ earns a perfect 100
        let efficiency = min(100.0, peakRatio / 5.0 * 100.0)
        return max(0, efficiency)
    }

    // MARK: - Load Time

    /// Detects the weight transfer / load phase before the swing starts.
    /// Searches up to 1000ms before impact for the onset of body motion (acceleration > 1.1g equivalent).
    private func calculateLoadTime(
        impactTimestamp: TimeInterval,
        swingStartTimestamp: TimeInterval?,
        in motionData: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double,
                         gravX: Double, gravY: Double, gravZ: Double,
                         userAccX: Double, userAccY: Double, userAccZ: Double)]
    ) -> Double? {
        guard let swingStart = swingStartTimestamp else { return nil }

        // Search up to 1000ms before impact for first motion onset
        let searchStart = impactTimestamp - 1.0
        let preSamples = motionData.filter {
            $0.timestamp >= searchStart && $0.timestamp < swingStart
        }.sorted { $0.timestamp < $1.timestamp }

        guard !preSamples.isEmpty else { return nil }

        // Find first sample where user acceleration exceeds rest threshold (0.1g in user accel space)
        let motionThreshold = 0.1 // g — user acceleration above rest
        var motionOnset: TimeInterval?

        for sample in preSamples {
            let accelMag = sqrt(sample.userAccX * sample.userAccX + sample.userAccY * sample.userAccY + sample.userAccZ * sample.userAccZ)
            if accelMag > motionThreshold {
                motionOnset = sample.timestamp
                break
            }
        }

        guard let onset = motionOnset else { return nil }

        let loadTimeMS = (swingStart - onset) * 1000.0
        // Filter unrealistic values
        guard loadTimeMS > 10.0 && loadTimeMS < 800.0 else { return nil }
        return loadTimeMS
    }

    // MARK: - Snap Score

    /// Measures wrist snap quality: how sharply rotation rate changes around impact.
    /// A sharp deceleration of rotation after impact = good wrist snap / bat whip.
    private func calculateSnapScore(
        around impactTimestamp: TimeInterval,
        in motionData: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double,
                         gravX: Double, gravY: Double, gravZ: Double,
                         userAccX: Double, userAccY: Double, userAccZ: Double)]
    ) -> Double? {
        // Get samples in a narrow window around impact (±50ms)
        let windowSec = 0.05
        let nearImpact = motionData.filter {
            $0.timestamp >= (impactTimestamp - windowSec) && $0.timestamp <= (impactTimestamp + windowSec)
        }.sorted { $0.timestamp < $1.timestamp }

        guard nearImpact.count >= 3 else { return nil }

        // Calculate rotation rate magnitudes
        let rotMags: [(timestamp: TimeInterval, mag: Double)] = nearImpact.map { sample in
            let mag = sqrt(sample.rotX * sample.rotX + sample.rotY * sample.rotY + sample.rotZ * sample.rotZ)
            return (timestamp: sample.timestamp, mag: mag)
        }

        // Find the rate of change of rotation rate (angular jerk) at the point closest to impact
        var maxSnapRate = 0.0
        for i in 1..<rotMags.count {
            let dt = rotMags[i].timestamp - rotMags[i-1].timestamp
            guard dt > 0.001 else { continue }
            let dRot = abs(rotMags[i].mag - rotMags[i-1].mag)
            let snapRate = dRot / dt
            maxSnapRate = max(maxSnapRate, snapRate)
        }

        guard maxSnapRate > 0 else { return nil }

        // Normalize by age-based reference
        let refSnap = referenceSnapRate(for: playerAge)
        let score = min(100.0, maxSnapRate / refSnap * 100.0)
        return max(0, score)
    }

    private func referenceSnapRate(for age: Int) -> Double {
        // Reference snap rate (rad/s² — rate of change of rotation rate at impact)
        switch age {
        case ...10:  return 300.0
        case 11...14: return 500.0
        case 15...17: return 700.0
        default:      return 900.0
        }
    }

    // MARK: - Kinetic Chain Score

    /// Measures if acceleration builds progressively through the swing phases
    /// (hip → torso → arms). Divides swing into 3 phases and checks if peak
    /// acceleration magnitude increases: early < mid < late = proper sequencing.
    private func calculateKineticChainScore(
        around impactTimestamp: TimeInterval,
        swingStartTimestamp: TimeInterval?,
        in motionData: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double,
                         gravX: Double, gravY: Double, gravZ: Double,
                         userAccX: Double, userAccY: Double, userAccZ: Double)]
    ) -> Double? {
        let swingStart = swingStartTimestamp ?? (impactTimestamp - 0.2)
        let swingDuration = impactTimestamp - swingStart
        guard swingDuration > 0.05 else { return nil }

        let phase1End = swingStart + swingDuration * 0.33
        let phase2End = swingStart + swingDuration * 0.66

        let swingSamples = motionData.filter {
            $0.timestamp >= swingStart && $0.timestamp <= impactTimestamp
        }

        // Compute peak user acceleration magnitude in each phase
        func peakAccel(from start: TimeInterval, to end: TimeInterval) -> Double? {
            let phaseSamples = swingSamples.filter { $0.timestamp >= start && $0.timestamp <= end }
            guard !phaseSamples.isEmpty else { return nil }
            return phaseSamples.map { sample in
                sqrt(sample.userAccX * sample.userAccX + sample.userAccY * sample.userAccY + sample.userAccZ * sample.userAccZ)
            }.max()
        }

        guard let earlyPeak = peakAccel(from: swingStart, to: phase1End),
              let midPeak = peakAccel(from: phase1End, to: phase2End),
              let latePeak = peakAccel(from: phase2End, to: impactTimestamp) else {
            return nil
        }

        // Score based on progressive acceleration buildup
        if earlyPeak < midPeak && midPeak < latePeak {
            return 100.0 // Perfect kinetic chain
        } else if earlyPeak < latePeak && midPeak < latePeak {
            return 85.0  // Late peak is highest but mid dipped
        } else if earlyPeak < latePeak {
            return 70.0  // General buildup but mid out of order
        } else if midPeak < latePeak {
            return 55.0  // Late phase is strong but early was high too
        } else {
            return 40.0  // No clear progressive buildup
        }
    }

    // MARK: - Connection Score

    /// Measures how well hands work with body rotation throughout the swing.
    /// Low coefficient of variation in the ratio of rotation rate to acceleration = better connection.
    private func calculateConnectionScore(
        around impactTimestamp: TimeInterval,
        swingStartTimestamp: TimeInterval?,
        in motionData: [(timestamp: TimeInterval, rotX: Double, rotY: Double, rotZ: Double,
                         gravX: Double, gravY: Double, gravZ: Double,
                         userAccX: Double, userAccY: Double, userAccZ: Double)]
    ) -> Double? {
        let swingStart = swingStartTimestamp ?? (impactTimestamp - 0.2)

        let swingSamples = motionData.filter {
            $0.timestamp >= swingStart && $0.timestamp <= impactTimestamp
        }

        guard swingSamples.count >= 5 else { return nil }

        // Calculate the ratio of rotation rate magnitude to acceleration magnitude for each sample
        var ratios: [Double] = []
        for sample in swingSamples {
            let rotMag = sqrt(sample.rotX * sample.rotX + sample.rotY * sample.rotY + sample.rotZ * sample.rotZ)
            let accelMag = sqrt(sample.userAccX * sample.userAccX + sample.userAccY * sample.userAccY + sample.userAccZ * sample.userAccZ)
            guard accelMag > 0.05 else { continue } // skip near-zero acceleration
            ratios.append(rotMag / accelMag)
        }

        guard ratios.count >= 3 else { return nil }

        // Coefficient of variation = stdDev / mean
        let mean = ratios.reduce(0, +) / Double(ratios.count)
        guard mean > 0.001 else { return nil }

        let variance = ratios.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(ratios.count)
        let stdDev = sqrt(variance)
        let cv = stdDev / mean

        // Lower CV = more consistent ratio = better connection
        // CV of 0 → 100, CV of 0.5+ → 0
        let score = max(0, 100.0 - cv * 200.0)
        return score
    }

    // MARK: - Reset

    func reset() {
        totalSwingsDetected = 0
        lastSwingEvent = nil
        lastSwingTimestamp = 0
    }
}
