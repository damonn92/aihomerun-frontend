import SwiftUI

@main
struct AIHomeRunWatchApp: App {
    @StateObject private var viewModel = SessionViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Group {
                    switch viewModel.state {
                    case .idle:
                        StartView()
                    case .starting:
                        ProgressView("Starting...")
                            .tint(.green)
                    case .active:
                        LiveSessionView()
                    case .ending:
                        ProgressView("Saving...")
                            .tint(.green)
                    case .completed:
                        SessionCompleteView()
                    }
                }
                .environmentObject(viewModel)
            }
        }
    }
}
