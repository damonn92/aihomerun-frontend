import Foundation
import Supabase
import AuthenticationServices

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: AppConfig.supabaseURL)!,
            supabaseKey: AppConfig.supabaseAnonKey
        )
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
}
