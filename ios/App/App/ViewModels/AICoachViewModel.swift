import Foundation
import SwiftUI

// MARK: - AI Coach ViewModel

@MainActor
class AICoachViewModel: ObservableObject {

    // MARK: - Types

    struct Message: Identifiable {
        let id = UUID()
        let text: String
        let isCoach: Bool
        let date = Date()
        let messageType: MessageType

        enum MessageType {
            case normal
            case safetyAlert
            case pitchCount
        }

        var timeString: String {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f.string(from: date)
        }

        init(text: String, isCoach: Bool, messageType: MessageType = .normal) {
            self.text = text
            self.isCoach = isCoach
            self.messageType = messageType
        }
    }

    struct PromptCard {
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
    }

    // MARK: - Published State

    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var isTyping = false
    @Published var sessionCount = 0
    @Published var isDemoMode = true
    @Published var errorMessage: String?
    @Published var selectedChild: Child?
    @Published var playerAge: Int = 12
    @Published var todayPitchCount: Int = 0
    @Published var showPitchCount = false

    var hasConversation: Bool { !messages.isEmpty }

    // MARK: - Dependencies

    private let biomechanics = BiomechanicsService.shared
    private let claudeAPI = ClaudeAPIService.shared
    private var conversationHistory: [ClaudeAPIService.Message] = []

    // MARK: - Prompt Cards

    let initialPrompts: [PromptCard] = [
        PromptCard(title: "Improve my swing", subtitle: "Bat path & contact tips",
                   icon: "figure.baseball", color: .hrBlue),
        PromptCard(title: "Fix my stance", subtitle: "Balance & weight transfer",
                   icon: "person.fill", color: .hrGold),
        PromptCard(title: "Pitching mechanics", subtitle: "Velocity & accuracy drills",
                   icon: "figure.softball", color: .hrGreen),
        PromptCard(title: "Pitch count check", subtitle: "Today's limits & rest days",
                   icon: "number.circle.fill", color: .hrOrange),
    ]

    var quickPrompts: [String] {
        ["Follow-up drill", "Show me an example", "What should I avoid?", "How often to practice?"]
    }

    // MARK: - Demo Mode Fallback

    private let coachResponses: [String: [String]] = [
        "Improve my swing": [
            "Great focus area! For a stronger swing, start with your hip rotation. Fire your hips before your hands — this generates power from your lower body first.",
            "Keep your back elbow down at contact. A high back elbow causes the bat to loop. Try the 'palm up, palm down' drill at contact position.",
            "Your follow-through should finish high across your opposite shoulder. Film yourself from behind to check if the bat is staying through the zone."
        ],
        "Fix my stance": [
            "A balanced stance is the foundation of everything. Your feet should be shoulder-width apart, weight on the balls of your feet — never on your heels.",
            "Check your load: as the pitcher winds up, shift your weight slightly to your back foot without drifting. Think 'load, stride, fire.'",
            "Keep your hands close to your body in your stance — hands by your back shoulder, not behind your head. It shortens your swing path significantly."
        ],
        "Pitching mechanics": [
            "For pitching velocity, it's all about the kinetic chain: legs → hips → torso → shoulder → elbow → wrist. If any link breaks down, you lose speed.",
            "Focus on your stride length first. Stride at least 80-90% of your height toward the plate. A short stride limits your power dramatically.",
            "After release, your throwing arm should continue down across your body naturally. Stopping short puts stress on your elbow and shoulder."
        ],
        "Warm-up routine": [
            "Here's a solid 10-minute pre-game routine:\n1. Light jog (2 min)\n2. Arm circles, leg swings (2 min)\n3. Band shoulder exercises (2 min)\n4. Soft toss / flip drill (4 min)",
            "Always warm up your shoulder before throwing hard. Start at 30 feet and work back to full distance over 8-10 throws before any max-effort throws.",
            "Include hip flexor stretches — tight hips are one of the main causes of mechanical breakdown in young players."
        ],
    ]

    // MARK: - Configure

    func configure(child: Child?) {
        if let child = child {
            selectedChild = child
            if let dob = child.dateOfBirth,
               let age = biomechanics.ageFromDateOfBirth(dob) {
                playerAge = max(7, min(18, age))
            }
        }

        isDemoMode = AppConfig.claudeAPIKey.isEmpty
        loadPitchCount()
    }

    // MARK: - Welcome

    func loadWelcome() {
        let name = selectedChild?.fullName.split(separator: " ").first.map(String.init) ?? "there"
        let ageNote = selectedChild != nil ? " I see you're \(playerAge) years old, so I'll tailor my advice just for you." : ""
        let modeNote = isDemoMode ? " (Demo Mode)" : ""

        let welcome = Message(
            text: "Hi \(name)!\(modeNote) I'm your AI baseball coach.\(ageNote) What would you like to work on today?",
            isCoach: true
        )
        messages = [welcome]
    }

    // MARK: - Send

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        messages.append(Message(text: trimmed, isCoach: false))
        inputText = ""
        isTyping = true

        // Handle pitch count queries locally
        if trimmed.localizedCaseInsensitiveContains("pitch count") ||
           trimmed.localizedCaseInsensitiveContains("how many pitches") {
            handlePitchCountQuery()
            return
        }

        if isDemoMode {
            sendDemoResponse(for: trimmed)
        } else {
            sendClaudeResponse(for: trimmed)
        }
    }

    // MARK: - Claude API Response

    private func sendClaudeResponse(for text: String) {
        Task {
            conversationHistory.append(
                ClaudeAPIService.Message(role: "user", content: text)
            )

            do {
                let systemPrompt = buildSystemPrompt()
                let response = try await claudeAPI.sendMessage(
                    systemPrompt: systemPrompt,
                    messages: conversationHistory
                )

                conversationHistory.append(
                    ClaudeAPIService.Message(role: "assistant", content: response)
                )

                // Keep history manageable (last 20 exchanges)
                if conversationHistory.count > 40 {
                    conversationHistory = Array(conversationHistory.suffix(40))
                }

                isTyping = false

                let msgType = detectMessageType(userText: text)
                messages.append(Message(text: response, isCoach: true, messageType: msgType))
                sessionCount += 1

            } catch {
                isTyping = false
                print("[AICoach] API error: \(error.localizedDescription)")

                // Graceful degradation
                let fallback = "I'm having trouble connecting right now. Here's a quick tip: " +
                    "focus on your fundamentals — consistent practice of basic mechanics " +
                    "beats trying advanced techniques. Try again in a moment for personalized coaching!"
                messages.append(Message(text: fallback, isCoach: true))
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Demo Response

    private func sendDemoResponse(for text: String) {
        let matchedKey = coachResponses.keys.first { text.localizedCaseInsensitiveContains($0) }
        let responses = matchedKey.flatMap { coachResponses[$0] } ?? defaultDemoResponses()
        let delay = Double.random(in: 1.2...2.2)
        let idx = Int.random(in: 0..<responses.count)

        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            isTyping = false
            messages.append(Message(text: responses[idx], isCoach: true))
            sessionCount += 1
        }
    }

    private func defaultDemoResponses() -> [String] {
        [
            "That's a great question! Based on common patterns for your age group, I'd focus on fundamentals first. Quality repetition beats volume every time.",
            "Let's break that down. The key is consistency — 300 quality reps a week will create muscle memory faster than 1,000 careless swings.",
            "I'd recommend filming yourself and uploading a video for AI analysis. We can then make targeted adjustments based on real data.",
            "Great thinking! Set a 20-minute daily practice goal focused on one mechanic at a time rather than trying to fix everything at once.",
        ]
    }

    // MARK: - System Prompt

    private func buildSystemPrompt() -> String {
        let childName = selectedChild?.fullName ?? "the player"
        let position = selectedChild?.position ?? "unspecified"
        let referenceContext = biomechanics.buildSystemContext(forAge: playerAge, position: position)

        return """
        You are Coach AI, a youth baseball coaching assistant for the AIHomeRun app. \
        You are coaching \(childName), age \(playerAge), who plays \(position).

        CRITICAL RULES:
        - Always use age-appropriate language and concepts for a \(playerAge)-year-old
        - Never recommend techniques beyond the player's age group
        - If asked about advanced pitches not appropriate for age \(playerAge), \
          explain why they should wait and what to focus on instead
        - Emphasize safety and injury prevention at all times
        - Keep responses concise (2-3 short paragraphs max)
        - Use encouraging, supportive language suitable for a young athlete
        - Suggest one specific actionable drill per response when applicable
        - Reference specific numbers and angles from the data below when relevant
        - If discussing pitch counts, always reference the age-specific limits
        - Respond in the same language the user writes in

        REFERENCE DATA FOR THIS PLAYER:
        \(referenceContext)
        """
    }

    // MARK: - Message Type Detection

    private func detectMessageType(userText: String) -> Message.MessageType {
        let lower = userText.lowercased()

        // Safety: young player asking about advanced pitches
        if playerAge < 14 {
            let advancedPitches = ["slider", "cutter", "splitter", "knuckle"]
            if advancedPitches.contains(where: { lower.contains($0) }) {
                return .safetyAlert
            }
        }
        if playerAge < 14 && lower.contains("curveball") {
            return .safetyAlert
        }

        if lower.contains("pitch count") || lower.contains("how many pitch") {
            return .pitchCount
        }

        return .normal
    }

    // MARK: - Pitch Count

    private func handlePitchCountQuery() {
        let limit = biomechanics.dailyPitchLimit(forAge: playerAge)
        let rest = biomechanics.restDaysRequired(forAge: playerAge, pitchCount: todayPitchCount)

        let text: String
        if todayPitchCount == 0 {
            text = "No pitches logged today. The daily limit for age \(playerAge) is \(limit) pitches. " +
                   "Use the pitch counter to track your throws during practice or games!"
        } else if todayPitchCount >= limit {
            text = "PITCH LIMIT REACHED! You've thrown \(todayPitchCount) pitches today " +
                   "(limit: \(limit) for age \(playerAge)). You need \(rest) rest day(s) before your next pitching appearance. " +
                   "It's important to stop now to protect your arm."
        } else {
            let remaining = limit - todayPitchCount
            text = "You've thrown \(todayPitchCount) of \(limit) pitches today (\(remaining) remaining). " +
                   "Based on your current count, you'll need \(rest) rest day(s) before pitching again. " +
                   "Remember to watch for signs of fatigue — decreased velocity or accuracy means it's time to stop."
        }

        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            isTyping = false
            messages.append(Message(text: text, isCoach: true, messageType: .pitchCount))
        }
    }

    func incrementPitchCount(by amount: Int = 1) {
        todayPitchCount += amount
        savePitchCount()

        let limit = biomechanics.dailyPitchLimit(forAge: playerAge)
        if todayPitchCount >= limit && todayPitchCount - amount < limit {
            // Just crossed the limit
            let alert = Message(
                text: "⚠️ PITCH LIMIT REACHED: \(todayPitchCount)/\(limit) pitches for age \(playerAge). " +
                      "Time to rest! Pitching while fatigued increases injury risk by 36x according to ASMI research.",
                isCoach: true,
                messageType: .safetyAlert
            )
            messages.append(alert)
        }
    }

    func resetPitchCount() {
        todayPitchCount = 0
        savePitchCount()
    }

    private func savePitchCount() {
        let key = pitchCountKey()
        UserDefaults.standard.set(todayPitchCount, forKey: key)
    }

    private func loadPitchCount() {
        let key = pitchCountKey()
        todayPitchCount = UserDefaults.standard.integer(forKey: key)
    }

    private func pitchCountKey() -> String {
        let dayStart = Calendar.current.startOfDay(for: Date())
        return "hr_pitch_count_\(Int(dayStart.timeIntervalSince1970))"
    }

    // MARK: - Reset

    func reset() {
        messages = []
        inputText = ""
        isTyping = false
        conversationHistory = []
        errorMessage = nil
        sessionCount = 0
        loadWelcome()
    }
}
