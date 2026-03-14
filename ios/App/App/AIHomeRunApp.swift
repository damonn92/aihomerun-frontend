import SwiftUI
import GoogleSignIn

// Observable object to broadcast deep-link stats route across the app
final class DeepLinkRouter: ObservableObject {
    @Published var statsRoute: String?
}

@main
struct AIHomeRunApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var deepLink = DeepLinkRouter()
    @StateObject private var watchManager = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
                .environmentObject(deepLink)
                .environmentObject(watchManager)
                .onOpenURL { url in
                    if url.scheme == "aihomerun" && url.host == "stats" {
                        deepLink.statsRoute = url.lastPathComponent
                    } else {
                        GIDSignIn.sharedInstance.handle(url)
                    }
                }
                .onAppear {
                    // Initialize Watch connectivity
                    WatchConnectivityService.shared.activate()
                }
        }
    }
}
