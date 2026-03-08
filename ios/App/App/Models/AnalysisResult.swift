import Foundation

// MARK: - API Response Models

struct AnalysisResult: Codable {
    let videoId: String?
    let actionType: String
    let metrics: Metrics
    let feedback: Feedback
    let processingTimeSeconds: Double?
    let quality: Quality?
    let previousSession: SessionSummary?
    let history: [SessionSummary]?

    enum CodingKeys: String, CodingKey {
        case videoId = "video_id"
        case actionType = "action_type"
        case metrics, feedback
        case processingTimeSeconds = "processing_time_seconds"
        case quality
        case previousSession = "previous_session"
        case history
    }
}

struct Metrics: Codable {
    let peakWristSpeed: Double?
    let hipShoulderSeparation: Double?
    let balanceScore: Double?
    let followThrough: Bool?
    let jointAngles: JointAngles?
    let framesAnalyzed: Int?

    enum CodingKeys: String, CodingKey {
        case peakWristSpeed = "peak_wrist_speed"
        case hipShoulderSeparation = "hip_shoulder_separation"
        case balanceScore = "balance_score"
        case followThrough = "follow_through"
        case jointAngles = "joint_angles"
        case framesAnalyzed = "frames_analyzed"
    }
}

struct JointAngles: Codable {
    let elbowAngle: Double?
    let shoulderAngle: Double?
    let hipRotation: Double?
    let kneeBend: Double?

    enum CodingKeys: String, CodingKey {
        case elbowAngle = "elbow_angle"
        case shoulderAngle = "shoulder_angle"
        case hipRotation = "hip_rotation"
        case kneeBend = "knee_bend"
    }
}

struct Feedback: Codable {
    let overallScore: Int
    let techniqueScore: Int
    let powerScore: Int
    let balanceScore: Int
    let plainSummary: String
    let encouragement: String?
    let strengths: [String]
    let improvements: [String]
    let drill: DrillInfo?
    let parentTip: String?

    enum CodingKeys: String, CodingKey {
        case overallScore = "overall_score"
        case techniqueScore = "technique_score"
        case powerScore = "power_score"
        case balanceScore = "balance_score"
        case plainSummary = "plain_summary"
        case encouragement
        case strengths, improvements
        case drill
        case parentTip = "parent_tip"
    }

    // Custom decoder: backend may send drill as a plain String or as a DrillInfo object.
    // When it's a String, we wrap it so the rest of the app still gets a DrillInfo.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        overallScore   = try c.decode(Int.self,     forKey: .overallScore)
        techniqueScore = try c.decode(Int.self,     forKey: .techniqueScore)
        powerScore     = try c.decode(Int.self,     forKey: .powerScore)
        balanceScore   = try c.decode(Int.self,     forKey: .balanceScore)
        plainSummary   = (try? c.decode(String.self,   forKey: .plainSummary)) ?? ""
        encouragement  = try? c.decode(String.self,   forKey: .encouragement)
        strengths      = (try? c.decode([String].self, forKey: .strengths)) ?? []
        improvements   = (try? c.decode([String].self, forKey: .improvements)) ?? []
        parentTip      = try? c.decode(String.self,   forKey: .parentTip)

        // Try structured object first, fall back to plain string
        if let obj = try? c.decode(DrillInfo.self, forKey: .drill) {
            drill = obj
        } else if let str = try? c.decode(String.self, forKey: .drill), !str.isEmpty {
            drill = DrillInfo(name: "Today's Drill", description: str, reps: nil)
        } else {
            drill = nil
        }
    }

    var grade: String {
        switch overallScore {
        case 90...100: return "A+"
        case 80..<90:  return "A"
        case 70..<80:  return "B"
        case 60..<70:  return "C"
        default:       return "D"
        }
    }
}

struct DrillInfo: Codable {
    let name: String
    let description: String
    let reps: String?
}

struct Quality: Codable {
    let visibilityRate: Double?
    let passed: Bool?

    enum CodingKeys: String, CodingKey {
        case visibilityRate = "visibility_rate"
        case passed
    }
}

struct SessionSummary: Codable, Identifiable {
    var id: String { videoId ?? UUID().uuidString }
    let videoId: String?
    let actionType: String?
    let overallScore: Int?
    let techniqueScore: Int?
    let powerScore: Int?
    let balanceScore: Int?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case videoId = "video_id"
        case actionType = "action_type"
        case overallScore = "overall_score"
        case techniqueScore = "technique_score"
        case powerScore = "power_score"
        case balanceScore = "balance_score"
        case createdAt = "created_at"
    }
}

/// One per-check result returned by the backend quality gate.
struct QualityIssue: Codable, Identifiable {
    var id: String { check }
    let check: String       // machine-readable key, e.g. "low_fps"
    let message: String     // human-readable explanation
    let severity: String    // "error" | "warning"
}

struct QualityError: Codable {
    let error: String
    let issues: [QualityIssue]
    let visibilityRate: Double?

    enum CodingKeys: String, CodingKey {
        case error, issues
        case visibilityRate = "visibility_rate"
    }

    // Memberwise init used by APIClient when unwrapping FastAPI's {"detail":…} envelope.
    init(error: String, issues: [QualityIssue], visibilityRate: Double?) {
        self.error = error
        self.issues = issues
        self.visibilityRate = visibilityRate
    }
}
