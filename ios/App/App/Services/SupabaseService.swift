import Foundation

/// Lightweight user representation replacing Supabase.User.
struct AuthUser: Equatable {
    let id: String
    let email: String?
}

/// Backend API service — replaces SupabaseService.
/// All auth & data operations now go through our own REST API.
@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    // MARK: - Token / user state

    private(set) var accessToken: String? {
        didSet {
            if let t = accessToken {
                KeychainService.save(key: "access_token", value: t)
            } else {
                KeychainService.delete(key: "access_token")
            }
        }
    }

    private(set) var currentUser: AuthUser? {
        didSet {
            if let u = currentUser {
                UserDefaults.standard.set(u.id, forKey: "auth_user_id")
                UserDefaults.standard.set(u.email, forKey: "auth_user_email")
            } else {
                UserDefaults.standard.removeObject(forKey: "auth_user_id")
                UserDefaults.standard.removeObject(forKey: "auth_user_email")
            }
        }
    }

    private let baseURL: String

    private init() {
        baseURL = AppConfig.apiBaseURL
        // Restore persisted session
        if let token = KeychainService.load(key: "access_token"),
           let uid = UserDefaults.standard.string(forKey: "auth_user_id") {
            self.accessToken = token
            let email = UserDefaults.standard.string(forKey: "auth_user_email")
            self.currentUser = AuthUser(id: uid, email: email)
        }
    }

    // MARK: - Auth response

    private struct AuthResponse: Decodable {
        let access_token: String
        let user_id: String
        let email: String?
    }

    // MARK: - Email Auth

    func signIn(email: String, password: String) async throws {
        let body: [String: Any] = ["email": email, "password": password]
        let resp: AuthResponse = try await post("/auth/email/signin", body: body, authenticated: false)
        setSession(token: resp.access_token, userId: resp.user_id, email: resp.email ?? email)
    }

    func signUp(email: String, password: String) async throws {
        let body: [String: Any] = ["email": email, "password": password]
        let resp: AuthResponse = try await post("/auth/email/signup", body: body, authenticated: false)
        setSession(token: resp.access_token, userId: resp.user_id, email: resp.email ?? email)
    }

    func signOut() async throws {
        accessToken = nil
        currentUser = nil
    }

    func resetPassword(email: String) async throws {
        // Server-side password reset not yet implemented — no-op for now
        // In future, call POST /auth/email/reset-password
    }

    func updateEmail(newEmail: String) async throws {
        // Not supported in self-hosted auth — email changes require re-registration
        throw NSError(domain: "AuthService", code: 501,
                      userInfo: [NSLocalizedDescriptionKey: "Email changes are not currently supported."])
    }

    func updatePassword(newPassword: String) async throws {
        // Not yet implemented on backend
        throw NSError(domain: "AuthService", code: 501,
                      userInfo: [NSLocalizedDescriptionKey: "Password changes are not currently supported."])
    }

    func currentAccessToken() async -> String? {
        accessToken
    }

    // MARK: - Apple Sign In

    func signInWithApple(idToken: String, nonce: String) async throws {
        let body: [String: Any] = ["id_token": idToken, "nonce": nonce]
        let resp: AuthResponse = try await post("/auth/apple", body: body, authenticated: false)
        setSession(token: resp.access_token, userId: resp.user_id, email: resp.email)
    }

    // MARK: - Google Sign In

    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        let body: [String: Any] = ["id_token": idToken]
        let resp: AuthResponse = try await post("/auth/google", body: body, authenticated: false)
        setSession(token: resp.access_token, userId: resp.user_id, email: resp.email)
    }

    // MARK: - Account Deletion

    func deleteAccount() async throws {
        try await delete("/account")
        accessToken = nil
        currentUser = nil
    }

    // MARK: - Profile

    func fetchProfile(userId: String) async throws -> UserProfile? {
        struct ProfileResponse: Decodable {
            let id: String
            let display_name: String?
            let full_name: String?
        }
        let resp: ProfileResponse = try await get("/profile")
        return UserProfile(id: resp.id, fullName: resp.display_name ?? resp.full_name)
    }

    func upsertProfile(_ profile: UserProfile) async throws {
        let body: [String: Any] = ["display_name": profile.fullName ?? ""]
        let _: [String: String] = try await put("/profile", body: body)
    }

    // MARK: - Children

    func fetchChildren(parentId: String) async throws -> [Child] {
        struct ChildResponse: Decodable {
            let id: String
            let parent_id: String
            let full_name: String
            let date_of_birth: String?
            let gender: String?
            let position: String?
            let notes: String?
            let created_at: String?
        }
        let rows: [ChildResponse] = try await get("/children")
        return rows.map { r in
            Child(id: r.id, parentId: r.parent_id, fullName: r.full_name,
                  dateOfBirth: r.date_of_birth, gender: r.gender,
                  position: r.position, notes: r.notes, createdAt: r.created_at)
        }
    }

    func insertChild(_ child: Child) async throws {
        let body: [String: Any] = childBody(child)
        let _: [String: String] = try await post("/children", body: body)
    }

    func updateChild(_ child: Child) async throws {
        let body: [String: Any] = childBody(child)
        let _: [String: String] = try await put("/children/\(child.id)", body: body)
    }

    func deleteChild(id: String) async throws {
        try await delete("/children/\(id)")
    }

    private func childBody(_ child: Child) -> [String: Any] {
        var body: [String: Any] = ["full_name": child.fullName]
        if let v = child.dateOfBirth { body["date_of_birth"] = v }
        if let v = child.gender { body["gender"] = v }
        if let v = child.position { body["position"] = v }
        if let v = child.notes { body["notes"] = v }
        return body
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
        var path = "/leaderboard?age_group=\(ageGroup.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ageGroup)"
        if let uid = userId { path += "&user_id=\(uid)" }
        return try await get(path)
    }

    func fetchMyTrend(userId: String, limit: Int = 8) async throws -> [TrendRow] {
        try await get("/trend?limit=\(limit)")
    }

    func fetchMyBestScore(userId: String) async throws -> Int? {
        struct BestScoreResponse: Decodable { let best_score: Int? }
        let resp: BestScoreResponse = try await get("/best-score")
        return resp.best_score
    }

    // MARK: - Session helpers

    private func setSession(token: String, userId: String, email: String?) {
        accessToken = token
        currentUser = AuthUser(id: userId, email: email)
    }

    // MARK: - HTTP helpers

    private func get<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuth(&request)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkHTTP(response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post<T: Decodable>(_ path: String, body: [String: Any], authenticated: Bool = true) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated { applyAuth(&request) }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkHTTP(response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func put<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyAuth(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkHTTP(response, data: data)
        return try JSONDecoder().decode(T.self, from: data)
    }

    @discardableResult
    private func delete(_ path: String) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        applyAuth(&request)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkHTTP(response, data: data)
        return data
    }

    private func applyAuth(_ request: inout URLRequest) {
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func checkHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        guard (200..<300).contains(http.statusCode) else {
            // Try to extract detail message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = json["detail"] as? String {
                throw NSError(domain: "APIClient", code: http.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: detail])
            }
            throw NSError(domain: "APIClient", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Server error (\(http.statusCode))"])
        }
    }
}
