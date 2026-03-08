import Foundation
import SwiftUI

// MARK: - Brand Color System

extension Color {
    /// Deep navy background
    static let hrBg     = Color(red: 0.031, green: 0.059, blue: 0.118)
    /// Card surface
    static let hrCard   = Color(red: 0.067, green: 0.102, blue: 0.165)
    /// Electric blue — primary accent
    static let hrBlue   = Color(red: 0.078, green: 0.494, blue: 1.000)
    /// Gold — grade / highlight accent
    static let hrGold   = Color(red: 0.961, green: 0.651, blue: 0.137)
    /// Success / strengths
    static let hrGreen  = Color(red: 0.188, green: 0.820, blue: 0.345)
    /// Error / improvements
    static let hrRed    = Color(red: 1.000, green: 0.271, blue: 0.227)
    /// Drills / tips
    static let hrOrange = Color(red: 1.000, green: 0.624, blue: 0.039)
    /// Card border stroke
    static let hrStroke = Color.white.opacity(0.09)
}

// MARK: - Shared card modifier

struct HRCard: ViewModifier {
    var padding: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.hrCard)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.hrStroke, lineWidth: 1)
            )
    }
}

extension View {
    func hrCard(padding: CGFloat = 20) -> some View { modifier(HRCard(padding: padding)) }
}

// MARK: - Reusable input container

struct HRInputContainer<Content: View>: View {
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 20)
            content
                .foregroundStyle(.white)
                .tint(.hrBlue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

enum AppConfig {
    private static let dict: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any]
        else {
            fatalError("Config.plist not found. Copy Config.plist.template to Config.plist and fill in values.")
        }
        return dict
    }()

    static var supabaseURL: String {
        dict["SUPABASE_URL"] as? String ?? ""
    }

    static var supabaseAnonKey: String {
        dict["SUPABASE_ANON_KEY"] as? String ?? ""
    }

    static var apiBaseURL: String {
        dict["API_BASE_URL"] as? String ?? ""
    }

    static var googleClientID: String {
        dict["GOOGLE_CLIENT_ID"] as? String ?? ""
    }
}
