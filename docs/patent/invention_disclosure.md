# Invention Disclosure Document

## Title
**Multi-Modal Sensor Fusion System for Baseball Swing Analysis Using Wearable IMU and Video Pose Estimation**

## Inventor(s)
- AIHomeRun Development Team

## Date of First Conception
March 2026

## Date of First Reduction to Practice
March 2026 (implemented in AIHomeRun iOS application v1.x)

---

## 1. Abstract

A system and method for analyzing baseball swing mechanics by combining inertial measurement unit (IMU) data from a wrist-worn wearable device (Apple Watch) with computer vision-based body pose estimation extracted from video recordings. The system performs temporal alignment of the two data streams, calibrates bat speed measurements using video-derived limb segment proportions, computes a multi-dimensional biomechanical efficiency metric, and produces age-normalized composite scores. The fusion of these complementary data modalities yields significantly more accurate and comprehensive analysis than either modality alone.

---

## 2. Background of the Invention

### 2.1 Field of the Invention
This invention relates to sports analytics, specifically to methods and systems for analyzing baseball batting mechanics using multi-modal sensor fusion.

### 2.2 Description of Related Art

Existing baseball swing analysis solutions fall into several categories:

1. **Dedicated bat sensors** (e.g., Blast Motion, Diamond Kinetics): Attach an IMU sensor to the bat handle. Advantages: direct bat measurement. Disadvantages: requires purchasing separate hardware ($100-$150), only measures bat motion (not body mechanics), must be attached/detached for each session.

2. **Radar-based systems** (e.g., Rapsodo, HitTrax): Use radar or camera arrays to track ball flight. Advantages: accurate ball metrics. Disadvantages: expensive ($2,000-$15,000), fixed installation, measures ball trajectory but not swing mechanics.

3. **Video-only analysis** (e.g., various mobile apps): Use smartphone cameras to record swings and apply pose estimation. Advantages: accessible, measures full body mechanics. Disadvantages: limited temporal resolution (30fps), cannot measure forces or accelerations, sensitive to camera angle and distance.

4. **Wearable-only analysis** (general fitness trackers): Use wrist-worn accelerometers for basic activity detection. Advantages: convenient. Disadvantages: no visual context of body position, limited to wrist-local measurements.

### 2.3 Problems with Prior Art

No existing solution combines wrist-worn IMU data with video-based body pose estimation to produce a unified analysis. This represents a significant gap because:

- IMU sensors excel at measuring **acceleration, rotation, and timing** at very high sample rates (100-800 Hz) but cannot observe body position or form
- Video pose estimation excels at measuring **joint angles, body alignment, and spatial relationships** but is limited to camera frame rate (30-60 fps) and cannot measure forces
- The combination of both modalities enables **cross-calibration** that improves the accuracy of each individual measurement

---

## 3. Summary of the Invention

The present invention provides a multi-modal sensor fusion system comprising:

### 3.1 Data Acquisition Layer
- **Wearable IMU Module** (Apple Watch): Collects tri-axial accelerometer data at 100-800 Hz, tri-axial gyroscope data at 100-200 Hz, and heart rate data. An on-device swing detection algorithm identifies individual swing events in real-time and computes per-swing metrics including hand speed, peak acceleration, rotation rate, attack angle, swing duration, and impact detection.
- **Video Analysis Module** (iPhone): Records video at 30-240 fps and extracts 2D body pose (19 joints) and optionally 3D body pose (16 joints with depth) using the Apple Vision framework. Body mechanics metrics are computed including joint angles (elbow, shoulder, hip, knee), hip-shoulder separation, balance score, follow-through detection, and bat plane efficiency.

### 3.2 Sensor Fusion Engine
The core innovation is the **FusionAnalysisService** which:

1. **Temporally aligns** IMU events with video frames using swing detection events as anchor points
2. **Calibrates bat speed** by scaling wrist-mounted IMU velocity measurements using video-derived arm segment lengths (shoulder-to-wrist distance from pose estimation)
3. **Computes composite metrics** that require data from both modalities:
   - **Power Index**: Weighted combination of IMU acceleration, video hip-shoulder separation, follow-through detection, and IMU rotational acceleration
   - **Biomechanical Efficiency**: Video body mechanics score (balance, joint conformity, plane efficiency) combined with IMU rotational efficiency (rotation rate / acceleration ratio)
   - **Timing Score**: Correlation between IMU impact detection timestamp and video peak wrist velocity frame
   - **Consistency Index**: Statistical analysis of swing-to-swing variation across multiple IMU-measured swings

### 3.3 Age-Normalized Scoring
All metrics are normalized against age-appropriate reference ranges derived from the Long-Term Athlete Development (LTAD) framework, producing fair and developmentally appropriate scores for players aged 5-18+.

### 3.4 Graceful Degradation
The system operates in three modes with decreasing confidence:
- **Full Fusion** (video + watch): 95% confidence, all metrics available
- **Video Only**: 65% confidence, estimated metrics for acceleration-dependent values
- **Watch Only**: 70% confidence, no body mechanics data

---

## 4. Detailed Description of the Invention

### 4.1 System Architecture

```
                    ┌─────────────┐
                    │ Apple Watch  │
                    │ (watchOS)    │
                    ├─────────────┤
                    │ IMU Sensors  │
                    │ • Accel 800Hz│
                    │ • Gyro 200Hz │
                    │ • Heart Rate │
                    ├─────────────┤
                    │ On-Device    │
                    │ Processing:  │
                    │ • Swing Det. │
                    │ • Impact Det.│
                    │ • Metric Calc│
                    └──────┬──────┘
                           │ WatchConnectivity
                           │ (real-time + file transfer)
                           ▼
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│ iPhone      │    │ Fusion       │    │ Cloud AI    │
│ Camera      │───▶│ Analysis     │◀───│ Backend     │
│ (30-240fps) │    │ Service      │    │ (Claude AI) │
├─────────────┤    ├──────────────┤    ├─────────────┤
│ On-Device   │    │ • Temporal   │    │ • Advanced  │
│ Processing: │    │   Alignment  │    │   Analysis  │
│ • Vision    │    │ • Speed Cal. │    │ • Coaching  │
│   Pose Est. │    │ • Power Idx  │    │ • Feedback  │
│ • Action    │    │ • Biomech.   │    │ • Drills    │
│   Detection │    │   Efficiency │    │             │
│ • 3D Pose   │    │ • Consistency│    │             │
└─────────────┘    │ • Age Norm.  │    └─────────────┘
                    └──────┬──────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ Result       │
                    │ Presentation │
                    │ • ProMetrics │
                    │ • Speed Dist.│
                    │ • Timeline   │
                    │ • Radar 6-ax │
                    └──────────────┘
```

### 4.2 Bat Speed Calibration Algorithm

The bat speed calibration is a key novel contribution. The algorithm works as follows:

**Problem**: A wrist-worn accelerometer measures wrist velocity, not bat head velocity. The relationship between the two depends on the player's arm length and bat length, which vary significantly by age and size.

**Solution**: Use video pose estimation to measure arm segment proportions, then apply a lever-arm correction factor.

```
Step 1: Measure wrist speed from IMU
    watchWristSpeed = max(handSpeedMPH across session swings)

Step 2: Estimate arm length from video pose
    armLength = euclidean_distance(shoulder_joint, wrist_joint)
    bodyHeight = euclidean_distance(ankle_joint, head_joint)
    normalizedArmLength = armLength / bodyHeight

Step 3: Compute lever ratio
    leverRatio = lookup_age_table(playerAge)
    // Typical ratios: 2.2 (age 7) to 3.4 (age 18+)
    // Bat head moves faster than wrist due to lever effect

Step 4: Refine with body mechanics
    hipShoulderEfficiency = min(1.0, hipShoulderSeparation / 35.0)
    refinementFactor = 0.85 + (hipShoulderEfficiency * 0.30)
    // Better hip-shoulder separation = more efficient energy transfer

Step 5: Final calibration
    calibratedBatSpeed = watchWristSpeed × leverRatio × refinementFactor
```

### 4.3 Biomechanical Efficiency Calculation

This metric is unique because it combines two fundamentally different measurement modalities:

**Video Component (60% weight)**:
- Balance score: Center-of-gravity stability measured from ankle position variance across frames
- Joint angle conformity: How closely observed angles match biomechanically ideal ranges
- Hip-shoulder separation: Kinematic chain efficiency indicator
- Bat plane efficiency: Path straightness through the strike zone

**Watch Component (40% weight)**:
- Rotational efficiency: Ratio of peak rotation rate to peak linear acceleration. Higher ratio indicates better energy transfer from body rotation to bat speed.
- Swing smoothness: Inverse of coefficient of variation in swing duration across the session. Consistent timing indicates refined motor patterns.

```
videoScore = weighted_avg(balance, jointAngles, hipShoulder, planeEfficiency)
watchRotationalEff = rotationRateDPS / (peakAccelG × 100)
watchSmoothnessScore = 100 - (duration_CV × 200)
watchScore = rotationalEff × 0.6 + smoothnessScore × 0.4

biomechanicalEfficiency = videoScore × 0.6 + watchScore × 0.4
```

### 4.4 Real-Time Swing Detection with Impact Classification

The Apple Watch runs an on-device swing detection algorithm:

```
State Machine:
    IDLE → LOADING (angular velocity > threshold)
    LOADING → SWING (acceleration pattern matches swing initiation)
    SWING → IMPACT (acceleration spike > impact_threshold within time window)
    SWING → MISS (deceleration pattern without impact spike)
    IMPACT/MISS → IDLE (cooldown period)

Impact vs. Miss Classification:
    - Impact: Sharp acceleration spike (>8g) followed by rapid deceleration
    - Miss: Gradual deceleration without spike, lower peak forces
    - Foul tip: Moderate spike (4-8g) with partial deceleration

Per-Swing Metrics (computed at transition to IDLE):
    handSpeedMPH = integrate(userAcceleration, dt) × calibration_factor
    peakAccelerationG = max(magnitude(acceleration_samples))
    rotationRateDPS = max(magnitude(gyroscope_samples)) × (180/π)
    attackAngle = atan2(vertical_velocity, horizontal_velocity) at contact point
    swingDuration = timestamp(IDLE) - timestamp(LOADING)
    timeToContact = timestamp(IMPACT) - timestamp(LOADING)
```

### 4.5 Age-Normalized Scoring System

All numeric metrics are scored against age-appropriate reference databases:

| Age Group | Expected Bat Speed (mph) | Expected Peak G | Ideal Swing Duration (ms) |
|-----------|-------------------------|-----------------|--------------------------|
| 5-7       | 25-35                  | 3-5             | 250-350                 |
| 8-9       | 30-40                  | 4-6             | 220-300                 |
| 10-11     | 35-50                  | 5-8             | 200-280                 |
| 12-13     | 40-55                  | 6-10            | 180-260                 |
| 14-15     | 50-65                  | 8-12            | 160-240                 |
| 16-17     | 55-75                  | 10-14           | 150-230                 |
| 18+       | 60-85                  | 12-16           | 140-220                 |

Scoring formula: `score = min(100, (observed / expected_for_age) × 80)`

This ensures that a 9-year-old with a 35 mph bat speed and an 18-year-old with a 70 mph bat speed can both receive similarly high scores if they are performing well for their development level.

---

## 5. Novel Aspects / Points of Distinction

1. **Multi-modal sensor fusion for baseball**: First system to combine consumer wrist-worn IMU (Apple Watch) with smartphone video pose estimation for baseball swing analysis. No additional hardware purchase required.

2. **Bat speed calibration via pose estimation**: Novel method of calibrating wrist-mounted IMU speed measurements using computer vision-derived limb segment proportions. This eliminates the need for a dedicated bat sensor.

3. **Cross-modal biomechanical efficiency**: Unique metric that combines video-based body mechanics analysis with IMU-based rotational efficiency, providing insight that neither modality can produce alone.

4. **Impact classification from wrist IMU**: Algorithm distinguishes between solid contact, foul tips, and misses using only wrist-worn accelerometer patterns, without requiring a bat-mounted sensor.

5. **Age-normalized developmental scoring**: Scoring system based on LTAD principles that produces fair, age-appropriate evaluations rather than absolute measurements.

6. **Graceful multi-modal degradation**: System produces meaningful results with any available data combination (video+watch, video-only, or watch-only) with transparent confidence scoring.

---

## 6. Commercial Significance

- **Market size**: 15+ million youth baseball players in the US alone
- **Competitive advantage**: Replaces $100-$150 dedicated bat sensors with existing Apple Watch hardware
- **Barrier to competition**: Requires deep integration of IMU processing, computer vision, and sports biomechanics domain knowledge
- **Platform lock-in**: Apple Watch ecosystem integration creates strong user retention

---

## 7. Implementation Status

The invention has been fully implemented in the AIHomeRun iOS application:

- **FusionAnalysisService.swift**: Core fusion engine (~350 lines)
- **FusionModels.swift**: Data structures (~180 lines)
- **SwingDetector.swift**: On-device watch swing detection
- **MotionService.swift**: IMU data collection at 100-800 Hz
- **PoseDetectionService.swift**: 2D pose estimation (19 joints)
- **Pose3DDetectionService.swift**: 3D pose estimation (16 joints)
- **ProMetricsCard.swift**: Fusion results UI
- **SpeedDistributionChart.swift**: Speed histogram visualization
- **SwingTimelineView.swift**: Per-swing timeline visualization

---

## 8. Prior Art Search Summary

| Competitor | Modality | Fusion | Age-Normalized | Body Mechanics |
|-----------|----------|--------|---------------|---------------|
| Blast Motion | Bat IMU sensor | No | Limited | No |
| Diamond Kinetics | Bat IMU sensor | No | No | No |
| Rapsodo | Radar + camera | No | No | No |
| HitTrax | Camera array | No | No | Limited |
| **AIHomeRun** | **Watch IMU + Video Pose** | **Yes** | **Yes** | **Yes** |

Key differentiators:
1. No additional hardware required beyond iPhone + Apple Watch
2. Full body mechanics analysis (not just bat/ball)
3. Multi-modal fusion for cross-calibrated accuracy
4. Age-appropriate developmental scoring
5. Real-time feedback during practice sessions

---

## 9. Appendices

### Appendix A: Key Algorithms (Pseudocode)
See Section 4.2-4.5 above.

### Appendix B: Data Flow Diagram
See Section 4.1 system architecture diagram.

### Appendix C: Reference Implementation
Source code files listed in Section 7, available in the AIHomeRun iOS application repository.
