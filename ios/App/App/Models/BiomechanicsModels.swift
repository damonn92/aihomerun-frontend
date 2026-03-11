import Foundation

// MARK: - Coach Reference Database Root

struct CoachReferenceDB: Codable {
    let version: String
    let description: String
    let sources: [DataSource]
    let ageGroups: [String: AgeGroupInfo]
    let pitchCountLimits: PitchCountConfig
    let pitchTypeAgeGuidelines: [String: PitchTypeGuideline]
    let injuryPrevention: InjuryPreventionConfig
    let pitching: PitchingSection
    let hitting: HittingSection
    let aiCoachLogic: AICoachLogic

    enum CodingKeys: String, CodingKey {
        case version, description, sources
        case ageGroups = "age_groups"
        case pitchCountLimits = "pitch_count_limits"
        case pitchTypeAgeGuidelines = "pitch_type_age_guidelines"
        case injuryPrevention = "injury_prevention"
        case pitching, hitting
        case aiCoachLogic = "ai_coach_logic"
    }
}

// MARK: - Source

struct DataSource: Codable {
    let name: String
    let provider: String
    let url: String?
    let coverage: String?
}

// MARK: - Age Group

struct AgeGroupInfo: Codable {
    let label: String
    let ltadStage: String
    let focus: String

    enum CodingKeys: String, CodingKey {
        case label
        case ltadStage = "ltad_stage"
        case focus
    }
}

// MARK: - Pitch Count

struct PitchCountConfig: Codable {
    let description: String?
    let dailyMax: [String: Int]
    let weeklyMax: [String: Int]?
    let seasonMax: [String: Int]?
    let annualMax: [String: Int]?
    let restDays: [String: [String: Int]]?
    let universalRules: [String]?

    enum CodingKeys: String, CodingKey {
        case description
        case dailyMax = "daily_max"
        case weeklyMax = "weekly_max"
        case seasonMax = "season_max"
        case annualMax = "annual_max"
        case restDays = "rest_days"
        case universalRules = "universal_rules"
    }
}

// MARK: - Pitch Type

struct PitchTypeGuideline: Codable {
    let minAge: Int
    let priority: Int
    let note: String

    enum CodingKeys: String, CodingKey {
        case minAge = "min_age"
        case priority, note
    }
}

// MARK: - Injury Prevention

struct InjuryPreventionConfig: Codable {
    let asmiKeyRules: [String]?
    let fatigueWarningSigns: [String]?
    let riskMultipliers: [String: RiskMultiplier]?
    let elbowTorqueThresholdsByAge: [String: AnyCodable]?
    let ballWeightEffect: BallWeightEffect?

    enum CodingKeys: String, CodingKey {
        case asmiKeyRules = "asmi_key_rules"
        case fatigueWarningSigns = "fatigue_warning_signs"
        case riskMultipliers = "risk_multipliers"
        case elbowTorqueThresholdsByAge = "elbow_torque_thresholds_by_age"
        case ballWeightEffect = "ball_weight_effect"
    }
}

struct RiskMultiplier: Codable {
    let multiplier: Double?
    let reduction: Double?
    let outcome: String
    let source: String
}

struct BallWeightEffect: Codable {
    let description: String?
    let torqueIncreasePerOz: Double?
    let unit: String?
    let ageRange: String?

    enum CodingKeys: String, CodingKey {
        case description
        case torqueIncreasePerOz = "torque_increase_per_oz"
        case unit
        case ageRange = "age_range"
    }
}

// MARK: - Pitching Section

struct PitchingSection: Codable {
    let youthBiomechanics: YouthPitchingData
    let adultBiomechanics: AdultPitchingData

    enum CodingKeys: String, CodingKey {
        case youthBiomechanics = "youth_biomechanics"
        case adultBiomechanics = "adult_biomechanics"
    }
}

struct YouthPitchingData: Codable {
    let description: String?
    let source: String?
    let ballVelocityByAge: [String: AnyCodable]?
    let jointKinematics: [String: AnyCodable]?
    let jointKinetics: [String: AnyCodable]?
    let angularVelocities: [String: AnyCodable]?
    let coachingPrioritiesByAge: [String: [String]]?

    enum CodingKeys: String, CodingKey {
        case description, source
        case ballVelocityByAge = "ball_velocity_by_age"
        case jointKinematics = "joint_kinematics"
        case jointKinetics = "joint_kinetics"
        case angularVelocities = "angular_velocities"
        case coachingPrioritiesByAge = "coaching_priorities_by_age"
    }
}

struct AdultPitchingData: Codable {
    let description: String?
    let source: String?
    let sampleSize: Int?
    let metrics: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case description, source
        case sampleSize = "sample_size"
        case metrics
    }
}

// MARK: - Hitting Section

struct HittingSection: Codable {
    let youthGuidelines: YouthHittingData
    let adultBiomechanics: AdultHittingData

    enum CodingKeys: String, CodingKey {
        case youthGuidelines = "youth_guidelines"
        case adultBiomechanics = "adult_biomechanics"
    }
}

struct YouthHittingData: Codable {
    let description: String?
    let coachingPrioritiesByAge: [String: [String]]?

    enum CodingKeys: String, CodingKey {
        case description
        case coachingPrioritiesByAge = "coaching_priorities_by_age"
    }
}

struct AdultHittingData: Codable {
    let description: String?
    let source: String?
    let sampleSize: Int?
    let metrics: [String: AnyCodable]?
    let batSpeedExitVeloCorrelation: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case description, source
        case sampleSize = "sample_size"
        case metrics
        case batSpeedExitVeloCorrelation = "bat_speed_exit_velo_correlation"
    }
}

// MARK: - AI Coach Logic

struct AICoachLogic: Codable {
    let description: String?
    let assessmentFramework: [String: AssessmentConfig]?
    let safetyAlerts: [String: String]?

    enum CodingKeys: String, CodingKey {
        case description
        case assessmentFramework = "assessment_framework"
        case safetyAlerts = "safety_alerts"
    }
}

struct AssessmentConfig: Codable {
    let primaryFocus: String?
    let feedbackStyle: String?
    let metricsToShow: [String]?
    let languageLevel: String?
    let comparisonTarget: String?
    let injuryPriority: String?

    enum CodingKeys: String, CodingKey {
        case primaryFocus = "primary_focus"
        case feedbackStyle = "feedback_style"
        case metricsToShow = "metrics_to_show"
        case languageLevel = "language_level"
        case comparisonTarget = "comparison_target"
        case injuryPriority = "injury_priority"
    }
}

// MARK: - AnyCodable (flexible JSON value)

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let string = try? container.decode(String.self) { value = string }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else if let array = try? container.decode([AnyCodable].self) { value = array.map(\.value) }
        else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else { value = NSNull() }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as Bool: try container.encode(v)
        default: try container.encodeNil()
        }
    }
}
