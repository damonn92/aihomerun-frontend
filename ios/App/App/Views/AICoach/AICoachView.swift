import SwiftUI

// MARK: - AI Coach View

struct AICoachView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = AICoachViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    @FocusState private var inputFocused: Bool
    @State private var appeared = false
    @Namespace private var scrollAnchor

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Coach header banner — rich AI tech design
                    CoachHeroBanner(sessionCount: vm.sessionCount,
                                    isDemoMode: vm.isDemoMode)

                    // Pitch count card (toggleable)
                    if vm.showPitchCount {
                        PitchCountCard(vm: vm)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

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
                    HStack(spacing: 14) {
                        // Pitch count toggle
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                vm.showPitchCount.toggle()
                            }
                        } label: {
                            Image(systemName: vm.showPitchCount
                                  ? "number.circle.fill"
                                  : "number.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(vm.showPitchCount
                                                 ? Color.hrOrange
                                                 : .white.opacity(0.45))
                        }
                        // New chat
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
        }
        .task {
            guard let userId = authVM.user?.id.uuidString else {
                vm.configure(child: nil)
                if !vm.hasConversation { vm.loadWelcome() }
                return
            }
            await profileVM.load(userId: userId)
            let firstChild = profileVM.children.first
            vm.configure(child: firstChild)
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

    private var bubbleBackground: Color {
        guard message.isCoach else { return Color.hrBlue.opacity(0.85) }
        switch message.messageType {
        case .safetyAlert: return Color.hrRed.opacity(0.15)
        case .pitchCount:  return Color.hrOrange.opacity(0.12)
        case .normal:      return Color.hrCard
        }
    }

    private var borderColor: Color {
        guard message.isCoach else { return Color.hrBlue.opacity(0.40) }
        switch message.messageType {
        case .safetyAlert: return Color.hrRed.opacity(0.50)
        case .pitchCount:  return Color.hrOrange.opacity(0.40)
        case .normal:      return Color.white.opacity(0.08)
        }
    }

    private var avatarColor: Color {
        switch message.messageType {
        case .safetyAlert: return Color.hrRed
        case .pitchCount:  return Color.hrOrange
        case .normal:      return Color.hrBlue
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isCoach {
                // Coach avatar
                ZStack {
                    Circle().fill(avatarColor.opacity(0.20)).frame(width: 28, height: 28)
                    Image(systemName: message.messageType == .safetyAlert
                          ? "exclamationmark.triangle.fill"
                          : message.messageType == .pitchCount
                          ? "number.circle.fill"
                          : "brain.head.profile")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(avatarColor)
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
                    .background(bubbleBackground)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(borderColor, lineWidth: message.messageType == .safetyAlert ? 1.0 : 0.5)
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

// AICoachViewModel is now in ViewModels/AICoachViewModel.swift
