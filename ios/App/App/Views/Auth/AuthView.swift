import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showForgot = false
    @State private var isSubmitting = false
    @State private var cardAppeared = false
    @Environment(\.colorScheme) private var colorScheme

    enum AuthMode { case signIn, signUp }

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────────
            Color.hrBg.ignoresSafeArea()

            RadialGradient(
                colors: [Color.hrBlue.opacity(0.30), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: 320
            )
            .ignoresSafeArea()

            // ── Content ─────────────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Hero ─────────────────────────────────────────────
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.hrBlue.opacity(0.20))
                                .frame(width: 110, height: 110)
                                .blur(radius: 22)
                            Image("AppIcon")
                                .resizable()
                                .frame(width: 82, height: 82)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color.hrBlue.opacity(0.55), radius: 18)
                        }

                        Text("AIHomeRun")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("AI-Powered Baseball Coaching")
                            .font(.subheadline)
                            .foregroundStyle(.primary.opacity(0.55))
                    }
                    .padding(.top, 56)
                    .padding(.bottom, 36)

                    // ── Form card ────────────────────────────────────────
                    VStack(spacing: 22) {

                        // Mode toggle
                        HStack(spacing: 0) {
                            ForEach([AuthMode.signIn, AuthMode.signUp], id: \.self) { m in
                                Button {
                                    withAnimation(.spring(duration: 0.3)) { mode = m }
                                } label: {
                                    Text(m == .signIn ? "Sign In" : "Sign Up")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(mode == m ? Color.white : Color.primary.opacity(0.50))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            mode == m
                                                ? Color.hrBlue
                                                : Color.clear
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                        }
                        .padding(4)
                        .background(Color.hrDivider)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        // Text fields
                        VStack(spacing: 12) {
                            HRInputContainer(icon: "envelope.fill") {
                                TextField("Email address", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }

                            HRInputContainer(icon: "lock.fill") {
                                SecureField("Password (8+ characters)", text: $password)
                                    .textContentType(mode == .signIn ? .password : .newPassword)
                            }

                            if mode == .signUp {
                                HRInputContainer(icon: "lock.fill") {
                                    SecureField("Confirm password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }

                        // Error
                        if let error = authVM.error {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                Text(error)
                                    .font(.footnote)
                            }
                            .foregroundStyle(Color.hrRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Primary CTA
                        Button {
                            Task { await submit() }
                        } label: {
                            ZStack {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(mode == .signIn ? "Sign In" : "Create Account")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                formValid
                                    ? LinearGradient(
                                        colors: [Color.hrBlue, Color(red: 0.04, green: 0.36, blue: 0.80)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                                    : LinearGradient(
                                        colors: [Color.hrStroke, Color.hrDivider],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: formValid ? Color.hrBlue.opacity(0.45) : .clear, radius: 12, y: 4)
                        }
                        .disabled(isSubmitting || !formValid)

                        if mode == .signIn {
                            Button("Forgot password?") { showForgot = true }
                                .font(.footnote)
                                .foregroundStyle(.primary.opacity(0.50))
                        }

                        // Divider
                        HStack(spacing: 12) {
                            Rectangle().frame(height: 0.5).foregroundStyle(Color.hrStroke)
                            Text("OR")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.primary.opacity(0.40))
                                .tracking(1)
                            Rectangle().frame(height: 0.5).foregroundStyle(Color.hrStroke)
                        }

                        // Social auth
                        VStack(spacing: 12) {
                            // Sign in with Apple
                            SignInWithAppleButton(
                                mode == .signIn ? .signIn : .signUp
                            ) { request in
                                authVM.configureAppleRequest(request)
                            } onCompletion: { result in
                                authVM.handleAppleSignInCompletion(result)
                            }
                            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                            .frame(height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            // Google
                            Button {
                                Task { await authVM.signInWithGoogle() }
                            } label: {
                                HStack(spacing: 10) {
                                    Image("GoogleLogo")
                                        .resizable()
                                        .renderingMode(.original)
                                        .frame(width: 22, height: 22)
                                    Text("Continue with Google")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.hrSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.hrStroke, lineWidth: 1)
                                )
                            }
                        }

                        Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                            .font(.caption2)
                            .foregroundStyle(.primary.opacity(0.35))
                            .multilineTextAlignment(.center)
                    }
                    .padding(22)
                    .background(.ultraThinMaterial.opacity(0.25))
                    .background(Color.hrSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.hrStroke, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                    .opacity(cardAppeared ? 1 : 0)
                    .offset(y: cardAppeared ? 0 : 24)
                    .animation(.spring(duration: 0.55, bounce: 0.2).delay(0.1), value: cardAppeared)
                }
            }
        }
        .onAppear { cardAppeared = true }
        .sheet(isPresented: $showForgot) {
            ForgotPasswordView()
                .environmentObject(authVM)
                .presentationDetents([.medium])
        }
    }

    private var formValid: Bool {
        !email.isEmpty && password.count >= 8 &&
        (mode == .signIn || password == confirmPassword)
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        if mode == .signIn {
            await authVM.signIn(email: email, password: password)
        } else {
            await authVM.signUp(email: email, password: password)
        }
    }
}

// MARK: - Forgot Password

struct ForgotPasswordView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var sent = false
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                VStack(spacing: 28) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.hrBlue)
                        .padding(.top, 16)

                    if sent {
                        VStack(spacing: 14) {
                            Text("Check your inbox")
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                            Text("We sent a reset link to \(email)")
                                .font(.subheadline)
                                .foregroundStyle(.primary.opacity(0.60))
                                .multilineTextAlignment(.center)
                            Button("Done") { dismiss() }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.hrBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    } else {
                        VStack(spacing: 20) {
                            VStack(spacing: 6) {
                                Text("Reset Password")
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)
                                Text("Enter your email to receive a reset link")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary.opacity(0.55))
                            }

                            HRInputContainer(icon: "envelope.fill") {
                                TextField("Email address", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }

                            Button {
                                Task {
                                    isSending = true
                                    await authVM.resetPassword(email: email)
                                    sent = true
                                    isSending = false
                                }
                            } label: {
                                ZStack {
                                    if isSending {
                                        ProgressView().tint(email.isEmpty ? Color.primary : Color.white)
                                    } else {
                                        Text("Send Reset Email")
                                            .font(.headline)
                                            .foregroundStyle(email.isEmpty ? Color.primary.opacity(0.40) : Color.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(email.isEmpty ? Color.hrSurface : Color.hrBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .disabled(email.isEmpty || isSending)
                        }
                    }
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.primary.opacity(0.6))
                }
            }
        }
    }
}

