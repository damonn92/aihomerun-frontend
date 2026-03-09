import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel

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
        .preferredColorScheme(.dark)
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
                        .foregroundStyle(.white)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(duration: 0.5).delay(0.15), value: appeared)

                    Text("AI Baseball Coaching")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
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

            RankingsView()
                .tabItem {
                    Label("Rankings", systemImage: "trophy.fill")
                }
                .tag(1)

            AICoachView()
                .tabItem {
                    Label {
                        Text("AI Coach")
                    } icon: {
                        Image("AICoachIcon")
                            .renderingMode(.template)
                    }
                }
                .tag(2)

            FieldBookingView()
                .tabItem {
                    Label("Fields", systemImage: "mappin.and.ellipse")
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
