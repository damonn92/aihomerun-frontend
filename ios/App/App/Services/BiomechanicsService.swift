import Foundation

// MARK: - Biomechanics Reference Data Service

final class BiomechanicsService {
    static let shared = BiomechanicsService()

    private var db: CoachReferenceDB?
    private var rawJSON: [String: Any]?

    private init() { loadIfNeeded() }

    // MARK: - Loading

    private func loadIfNeeded() {
        guard db == nil else { return }
        guard let url = Bundle.main.url(forResource: "ai_coach_reference_db", withExtension: "json") else {
            print("[BiomechanicsService] ⚠️ Reference JSON not found in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            db = try JSONDecoder().decode(CoachReferenceDB.self, from: data)
            rawJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            print("[BiomechanicsService] ⚠️ Failed to decode reference data: \(error)")
        }
    }

    // MARK: - Age Group Resolution

    func ageGroup(for age: Int) -> String {
        switch age {
        case ...8:    return "7-8"
        case 9...10:  return "9-10"
        case 11...12: return "11-12"
        case 13...14: return "13-14"
        case 15...16: return "15-16"
        case 17...18: return "17-18"
        case 19...22: return "19-22"
        default:      return "23+"
        }
    }

    func ageFromDateOfBirth(_ dob: String) -> Int? {
        // Try ISO8601 full format first, then date-only
        let iso = ISO8601DateFormatter()
        let dateOnly = DateFormatter()
        dateOnly.dateFormat = "yyyy-MM-dd"

        let date = iso.date(from: dob) ?? dateOnly.date(from: dob)
        guard let birthDate = date else { return nil }
        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }

    // MARK: - Pitch Count

    func dailyPitchLimit(forAge age: Int) -> Int {
        let group = ageGroup(for: age)
        return db?.pitchCountLimits.dailyMax[group] ?? 75
    }

    func restDaysRequired(forAge age: Int, pitchCount: Int) -> Int {
        guard let restDays = db?.pitchCountLimits.restDays else { return 0 }

        let key: String
        if age <= 14 { key = "14_and_under" }
        else if age <= 16 { key = "15-16" }
        else { key = "17-18" }

        guard let rules = restDays[key] else { return 0 }

        // Rules are like "1-20": 0, "21-35": 1, etc. Find matching range
        var maxRest = 0
        for (range, days) in rules {
            let parts = range.replacingOccurrences(of: "+", with: "-999").split(separator: "-")
            if parts.count >= 2,
               let low = Int(parts[0]),
               let high = Int(parts[1]) {
                if pitchCount >= low && pitchCount <= high {
                    return days
                }
                if pitchCount >= low { maxRest = max(maxRest, days) }
            }
        }
        return maxRest
    }

    // MARK: - Pitch Types

    func allowedPitchTypes(forAge age: Int) -> [(name: String, minAge: Int, allowed: Bool)] {
        guard let guidelines = db?.pitchTypeAgeGuidelines else { return [] }
        return guidelines.map { (name, guide) in
            (name: name.capitalized, minAge: guide.minAge, allowed: age >= guide.minAge)
        }.sorted { $0.minAge < $1.minAge }
    }

    // MARK: - Coaching Priorities

    func pitchingCoachingPriorities(forAge age: Int) -> [String] {
        let group = ageGroup(for: age)
        return db?.pitching.youthBiomechanics.coachingPrioritiesByAge?[group] ?? []
    }

    func hittingCoachingPriorities(forAge age: Int) -> [String] {
        let group = ageGroup(for: age)
        return db?.hitting.youthGuidelines.coachingPrioritiesByAge?[group] ?? []
    }

    // MARK: - Fatigue Warning Signs

    func fatigueWarningSigns() -> [String] {
        db?.injuryPrevention.fatigueWarningSigns ?? []
    }

    func asmiKeyRules() -> [String] {
        db?.injuryPrevention.asmiKeyRules ?? []
    }

    // MARK: - Assessment Framework

    func assessmentConfig(forAge age: Int) -> AssessmentConfig? {
        let group = ageGroup(for: age)
        return db?.aiCoachLogic.assessmentFramework?[group]
    }

    // MARK: - System Prompt Builder (Critical)

    func buildSystemContext(forAge age: Int, position: String? = nil) -> String {
        let group = ageGroup(for: age)
        var lines: [String] = []

        // Age group info
        if let info = db?.ageGroups[group] {
            lines.append("PLAYER PROFILE: Age \(age), Group: \(group) (\(info.label))")
            lines.append("DEVELOPMENT STAGE: \(info.ltadStage)")
            lines.append("FOCUS AREA: \(info.focus)")
        }

        // Pitch count limits
        let limit = dailyPitchLimit(forAge: age)
        lines.append("\nPITCH COUNT LIMITS: Daily max = \(limit) pitches")
        if let weekly = db?.pitchCountLimits.weeklyMax?[group] {
            lines.append("  Weekly max = \(weekly) pitches")
        }

        // Rest days
        lines.append("REST DAY RULES:")
        if age <= 14 {
            lines.append("  1-20 pitches: 0 rest days, 21-35: 1 day, 36-50: 2 days, 51-65: 3 days, 66+: 4 days")
        } else if age <= 16 {
            lines.append("  1-30 pitches: 0 rest days, 31-45: 1 day, 46-60: 2 days, 61-75: 3 days, 76+: 4 days")
        }

        // Pitch types
        let types = allowedPitchTypes(forAge: age)
        let allowed = types.filter(\.allowed).map(\.name).joined(separator: ", ")
        let notAllowed = types.filter { !$0.allowed }.map { "\($0.name) (min age \($0.minAge))" }.joined(separator: ", ")
        lines.append("\nALLOWED PITCH TYPES: \(allowed)")
        if !notAllowed.isEmpty {
            lines.append("NOT YET RECOMMENDED: \(notAllowed)")
        }

        // Coaching priorities
        let pitchPriorities = pitchingCoachingPriorities(forAge: age)
        if !pitchPriorities.isEmpty {
            lines.append("\nPITCHING COACHING PRIORITIES:")
            for (i, p) in pitchPriorities.enumerated() {
                lines.append("  \(i+1). \(p)")
            }
        }

        let hitPriorities = hittingCoachingPriorities(forAge: age)
        if !hitPriorities.isEmpty {
            lines.append("\nHITTING COACHING PRIORITIES:")
            for (i, p) in hitPriorities.enumerated() {
                lines.append("  \(i+1). \(p)")
            }
        }

        // Ball velocity reference
        if age <= 16 {
            let velGroup = ageGroup(for: age)
            if let velData = db?.pitching.youthBiomechanics.ballVelocityByAge,
               let ageVel = velData[velGroup]?.value as? [String: Any] {
                let low = ageVel["average_low"] ?? "?"
                let high = ageVel["average_high"] ?? "?"
                let elite = ageVel["elite"] ?? "?"
                lines.append("\nBALL VELOCITY REFERENCE (age \(group)):")
                lines.append("  Average: \(low)-\(high) mph, Elite: \(elite) mph")
            }
        }

        // Injury prevention key rules
        lines.append("\nINJURY PREVENTION (ASMI KEY RULES):")
        for rule in asmiKeyRules().prefix(4) {
            lines.append("  • \(rule)")
        }

        // Fatigue signs
        lines.append("\nFATIGUE WARNING SIGNS TO WATCH:")
        for sign in fatigueWarningSigns().prefix(4) {
            lines.append("  • \(sign)")
        }

        // Assessment style
        if let config = assessmentConfig(forAge: age) {
            lines.append("\nFEEDBACK STYLE: \(config.feedbackStyle ?? "instructional")")
            lines.append("LANGUAGE LEVEL: \(config.languageLevel ?? "moderate")")
            lines.append("COMPARISON: \(config.comparisonTarget ?? "self-improvement")")
        }

        // Position-specific note
        if let pos = position, !pos.isEmpty {
            lines.append("\nPOSITION: \(pos)")
            if pos == "Pitcher" {
                lines.append("  Focus coaching on pitching mechanics, arm care, and pitch development.")
            } else if pos == "Catcher" {
                lines.append("  Note: ASMI recommends catchers should NOT also pitch on the same day if they catch 4+ innings.")
            }
        }

        return lines.joined(separator: "\n")
    }
}
