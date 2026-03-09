import SwiftUI

// MARK: - AI Coach View

struct AICoachView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = AICoachViewModel()
    @FocusState private var inputFocused: Bool
    @State private var appeared = false
    @Namespace private var scrollAnchor

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Coach header banner — rich AI tech design
                    CoachHeroBanner(sessionCount: vm.sessionCount)

                    // Quick prompts (if at top)
                    if !vm.hasConversation {
                        quickPromptsSection
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Chat messages
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 14) {
                                ForEach(vm.messages) { msg in
                                    ChatBubble(message: msg)
                                        .id(msg.id)
                                }
                                if vm.isTyping {
                                    TypingIndicator()
                                        .id("typing")
                                }
                                Color.clear.frame(height: 1).id("bottom")
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        }
                        .onChange(of: vm.messages.count) { _ in
                            withAnimation(.spring(duration: 0.4)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: vm.isTyping) { _ in
                            withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                        }
                    }

                    // Quick prompts (inline, when conversation started)
                    if vm.hasConversation && !vm.quickPrompts.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(vm.quickPrompts, id: \.self) { prompt in
                                    Button {
                                        vm.send(prompt)
                                        inputFocused = false
                                    } label: {
                                        Text(prompt)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.white.opacity(0.70))
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(Color.white.opacity(0.07))
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .background(Color.hrBg)
                    }

                    // Input bar
                    chatInputBar
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.hrBg.opacity(0.95), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(duration: 0.35)) { vm.reset() }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
        }
        .onAppear {
            appeared = true
            if !vm.hasConversation { vm.loadWelcome() }
        }
    }

    // MARK: - Coach Banner

    private var coachBanner: some View {
        HStack(spacing: 14) {
            // Coach avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.hrBlue.opacity(0.50), Color.hrBlue.opacity(0.20)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 48, height: 48)
                Image("AICoachIcon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Coach AI")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Circle()
                        .fill(Color.hrGreen)
                        .frame(width: 7, height: 7)
                }
                Text("Demo Mode · Responses are pre-written")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

            // Session count badge
            VStack(spacing: 1) {
                Text("\(vm.sessionCount)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Color.hrBlue)
                Text("sessions")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.white.opacity(0.30))
                    .tracking(0.3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.hrCard.opacity(0.80))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.white.opacity(0.07)),
            alignment: .bottom
        )
    }

    // MARK: - Quick Prompts (initial state)

    private var quickPromptsSection: some View {
        VStack(spacing: 14) {
            Text("What would you like to work on?")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(vm.initialPrompts, id: \.title) { item in
                    Button {
                        vm.send(item.title)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: item.icon)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(item.color)
                            Text(item.title)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            Text(item.subtitle)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.35))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(Color.hrCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(item.color.opacity(0.25), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Chat Input

    private var chatInputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask your coach...", text: $vm.inputText, axis: .vertical)
                .font(.subheadline)
                .foregroundStyle(.white)
                .tint(.hrBlue)
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(inputFocused ? Color.hrBlue.opacity(0.50) : Color.white.opacity(0.10), lineWidth: 1)
                )

            Button {
                guard !vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                vm.send(vm.inputText)
                inputFocused = false
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                     ? Color.white.opacity(0.15)
                                     : Color.hrBlue)
            }
            .disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            .animation(.spring(duration: 0.25), value: vm.inputText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.5))
        .background(Color.hrBg.opacity(0.90))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color.white.opacity(0.08)),
            alignment: .top
        )
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: AICoachViewModel.Message

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isCoach {
                // Coach avatar
                ZStack {
                    Circle().fill(Color.hrBlue.opacity(0.20)).frame(width: 28, height: 28)
                    Image("AICoachIcon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(Color.hrBlue)
                }
            } else {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isCoach ? .leading : .trailing, spacing: 4) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isCoach
                                ? Color.hrCard
                                : Color.hrBlue.opacity(0.85))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(message.isCoach
                                    ? Color.white.opacity(0.08)
                                    : Color.hrBlue.opacity(0.40),
                                    lineWidth: 0.5)
                    )

                Text(message.timeString)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.25))
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 280, alignment: message.isCoach ? .leading : .trailing)

            if !message.isCoach {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isCoach ? .leading : .trailing)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(Color.hrBlue.opacity(0.20)).frame(width: 28, height: 28)
                Image("AICoachIcon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(Color.hrBlue)
            }

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.3 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.45).repeatForever().delay(Double(i) * 0.15),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.hrCard)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
            )

            Spacer()
        }
        .onAppear { phase = 1 }
    }
}

// MARK: - AI Coach ViewModel

@MainActor
class AICoachViewModel: ObservableObject {
    struct Message: Identifiable {
        let id = UUID()
        let text: String
        let isCoach: Bool
        let date = Date()

        var timeString: String {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f.string(from: date)
        }
    }

    struct PromptCard {
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
    }

    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var isTyping = false
    @Published var sessionCount = 4

    var hasConversation: Bool { !messages.isEmpty }

    let initialPrompts: [PromptCard] = [
        PromptCard(title: "Improve my swing", subtitle: "Bat path & contact tips",
                   icon: "figure.baseball", color: .hrBlue),
        PromptCard(title: "Fix my stance", subtitle: "Balance & weight transfer",
                   icon: "person.fill", color: .hrGold),
        PromptCard(title: "Pitching mechanics", subtitle: "Velocity & accuracy drills",
                   icon: "figure.softball", color: .hrGreen),
        PromptCard(title: "Warm-up routine", subtitle: "Pre-game preparation",
                   icon: "flame.fill", color: .hrOrange),
    ]

    var quickPrompts: [String] {
        ["Follow-up drill", "Show me an example", "Any video tips?", "How often to practice?"]
    }

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

    func loadWelcome() {
        let welcome = Message(
            text: "Hi! I'm your AI baseball coach. I'm here to help you improve your swing mechanics, pitching form, and overall game. What would you like to work on today?",
            isCoach: true
        )
        messages = [welcome]
    }

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Add user message
        messages.append(Message(text: trimmed, isCoach: false))
        inputText = ""
        isTyping = true

        // Find best matching response
        let matchedKey = coachResponses.keys.first { trimmed.localizedCaseInsensitiveContains($0) }
        let responses = matchedKey.flatMap { coachResponses[$0] } ?? defaultResponses(for: trimmed)

        // Simulate typing delay
        let delay = Double.random(in: 1.2...2.2)
        let idx = Int.random(in: 0..<responses.count)

        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            isTyping = false
            messages.append(Message(text: responses[idx], isCoach: true))
            sessionCount += 1
        }
    }

    private func defaultResponses(for text: String) -> [String] {
        [
            "That's a great question! Based on your recent analysis, I'd focus on your hip rotation timing. Early hip rotation is one of the most common issues I see in players.",
            "Let's break that down. The key thing to remember is that baseball skills take repetition — 300 quality reps a week will create muscle memory faster than 1,000 careless swings.",
            "I'd recommend filming yourself from the side and tagging the video in this app. The AI analysis will give us concrete numbers to work with. Then we can make targeted adjustments.",
            "Good thinking! Consistency beats perfection. Set a 20-minute daily practice goal focused on one mechanic at a time rather than trying to fix everything at once.",
        ]
    }

    func reset() {
        messages = []
        inputText = ""
        isTyping = false
        loadWelcome()
    }
}
