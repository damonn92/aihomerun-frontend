import Foundation
import Supabase
import AuthenticationServices

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: AppConfig.supabaseURL), !AppConfig.supabaseURL.isEmpty else {
            fatalError("Invalid SUPABASE_URL in Config.plist. Check your configuration.")
        }
        client = SupabaseClient(supabaseURL: url, supabaseKey: AppConfig.supabaseAnonKey)
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    func updateEmail(newEmail: String) async throws {
        try await client.auth.update(user: UserAttributes(email: newEmail))
    }

    func updatePassword(newPassword: String) async throws {
        try await client.auth.update(user: UserAttributes(password: newPassword))
    }

    func currentAccessToken() async -> String? {
        try? await client.auth.session.accessToken
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: idToken, accessToken: accessToken)
        )
    }

    /// Delete the current user's account via Supabase Edge Function.
    /// The Edge Function should handle data cleanup and call admin.deleteUser().
    func deleteAccount() async throws {
        guard let accessToken = try? await client.auth.session.accessToken else {
            throw NSError(domain: "SupabaseService", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        // Call a Supabase Edge Function that deletes the user on the server side
        let url = URL(string: AppConfig.supabaseURL + "/functions/v1/delete-account")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "SupabaseService", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to delete account. Please try again later."])
        }
        // Sign out locally after server-side deletion
        try await client.auth.signOut()
    }

    // MARK: - Profile

    func fetchProfile(userId: String) async throws -> UserProfile? {
        let response: [UserProfile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    func upsertProfile(_ profile: UserProfile) async throws {
        try await client
            .from("profiles")
            .upsert(profile)
            .execute()
    }

    // MARK: - Children

    func fetchChildren(parentId: String) async throws -> [Child] {
        let response: [Child] = try await client
            .from("children")
            .select()
            .eq("parent_id", value: parentId)
            .order("created_at")
            .execute()
            .value
        return response
    }

    func insertChild(_ child: Child) async throws {
        try await client.from("children").insert(child).execute()
    }

    func updateChild(_ child: Child) async throws {
        try await client.from("children").update(child).eq("id", value: child.id).execute()
    }

    func deleteChild(id: String) async throws {
        try await client.from("children").delete().eq("id", value: id).execute()
    }

    // MARK: - Leaderboard

    struct LeaderboardRow: Codable, Identifiable {
        let entryId: String
        let initials: String
        let displayName: String
        let score: Int
        let isMe: Bool
        let isRealUser: Bool

        var id: String { entryId }

        enum CodingKeys: String, CodingKey {
            case entryId = "entry_id"
            case initials
            case displayName = "display_name"
            case score
            case isMe = "is_me"
            case isRealUser = "is_real_user"
        }
    }

    struct TrendRow: Codable {
        let sessionNumber: Int
        let overallScore: Int
        let createdAt: String

        enum CodingKeys: String, CodingKey {
            case sessionNumber = "session_number"
            case overallScore = "overall_score"
            case createdAt = "created_at"
        }
    }

    func fetchLeaderboard(ageGroup: String, userId: String?) async throws -> [LeaderboardRow] {
        let params: [String: AnyJSON] = [
            "p_age_group": .string(ageGroup),
            "p_user_id": userId.map { .string($0) } ?? .null
        ]
        let response: [LeaderboardRow] = try await client
            .rpc("get_leaderboard", params: params)
            .execute()
            .value
        return response
    }

    func fetchMyTrend(userId: String, limit: Int = 8) async throws -> [TrendRow] {
        let params: [String: AnyJSON] = [
            "p_user_id": .string(userId),
            "p_limit": .integer(limit)
        ]
        let response: [TrendRow] = try await client
            .rpc("get_my_trend", params: params)
            .execute()
            .value
        return response
    }

    func fetchMyBestScore(userId: String) async throws -> Int? {
        struct ScoreRow: Codable {
            let overallScore: Int?
            enum CodingKeys: String, CodingKey {
                case overallScore = "overall_score"
            }
        }
        let response: [ScoreRow] = try await client
            .from("analyses")
            .select("overall_score")
            .eq("user_id", value: userId)
            .order("overall_score", ascending: false)
            .limit(1)
            .execute()
            .value
        return response.first?.overallScore
    }
}
