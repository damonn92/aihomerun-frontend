import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @AppStorage("appTheme") private var appTheme: String = AppTheme.dark.rawValue

    private var resolvedScheme: ColorScheme? {
        AppTheme(rawValue: appTheme)?.colorScheme
    }

    var body: some View {
        Group {
            if authVM.isLoading {
                SplashView()
            } else if authVM.user == nil {
                AuthView()
            } else {
                MainTabView()
            }
        }
        .preferredColorScheme(resolvedScheme)
        .animation(.easeInOut(duration: 0.4), value: authVM.isLoading)
        .animation(.easeInOut(duration: 0.4), value: authVM.user == nil)
    }
}

// MARK: - Splash

struct SplashView: View {
    @State private var glowing = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.hrBg.ignoresSafeArea()

            RadialGradient(
                colors: [Color.hrBlue.opacity(0.28), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 260
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    // Glow ring
                    Circle()
                        .fill(Color.hrBlue.opacity(0.18))
                        .frame(width: 130, height: 130)
                        .blur(radius: glowing ? 28 : 14)
                        .animation(
                            .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                            value: glowing
                        )

                    Image("AppIcon")
                        .resizable()
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: Color.hrBlue.opacity(0.6), radius: 20)
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.6, bounce: 0.4), value: appeared)
                }

                VStack(spacing: 6) {
                    Text("AIHomeRun")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(duration: 0.5).delay(0.15), value: appeared)

                    Text("AI Baseball Coaching")
                        .font(.subheadline)
                        .foregroundStyle(.primary.opacity(0.55))
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: appeared)
                }
            }
        }
        .onAppear {
            glowing = true
            appeared = true
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            UploadView()
                .tabItem {
                    Label("Analyze", systemImage: "video.fill")
                }
                .tag(0)

            TrainingView()
                .tabItem {
                    Label("Watch", systemImage: "applewatch")
                }
                .tag(1)

            RankingsView()
                .tabItem {
                    Label("Rankings", systemImage: "trophy.fill")
                }
                .tag(2)

            AICoachView()
                .tabItem {
                    Label("AI Coach", systemImage: "sparkles")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(4)
        }
        .tint(.hrBlue)
    }
}
