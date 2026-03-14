import Foundation
import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light  = "Light"
    case dark   = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// MARK: - Brand Color System

extension Color {
    /// Adaptive background (light: #F4F5F8, dark: deep navy)
    static let hrBg      = Color("hrBg")
    /// Adaptive card surface (light: white, dark: dark navy)
    static let hrCard    = Color("hrCard")
    /// Adaptive card border stroke
    static let hrStroke  = Color("hrStroke")
    /// Subtle surface tint for inputs / secondary backgrounds
    static let hrSurface = Color("hrSurface")
    /// Divider / separator color
    static let hrDivider = Color("hrDivider")

    /// Electric blue — primary accent (same in both modes)
    static let hrBlue   = Color(red: 0.078, green: 0.494, blue: 1.000)
    /// Gold — grade / highlight accent
    static let hrGold   = Color(red: 0.961, green: 0.651, blue: 0.137)
    /// Success / strengths
    static let hrGreen  = Color(red: 0.188, green: 0.820, blue: 0.345)
    /// Error / improvements
    static let hrRed    = Color(red: 1.000, green: 0.271, blue: 0.227)
    /// Drills / tips
    static let hrOrange = Color(red: 1.000, green: 0.624, blue: 0.039)
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
                .foregroundStyle(.primary.opacity(0.55))
                .frame(width: 20)
            content
                .foregroundStyle(.primary)
                .tint(.hrBlue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.hrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.hrStroke, lineWidth: 1)
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

    static var googlePlacesAPIKey: String {
        dict["GOOGLE_PLACES_API_KEY"] as? String ?? ""
    }

    // MARK: - Secrets (from Secrets.plist, gitignored)

    private static let secrets: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let dict = NSDictionary(contentsOf: url) as? [String: Any]
        else {
            print("⚠️ Secrets.plist not found. Copy Secrets.plist.example → Secrets.plist and fill in values.")
            return [:]
        }
        return dict
    }()

    static var claudeAPIKey: String {
        secrets["CLAUDE_API_KEY"] as? String ?? ""
    }
}
