import Foundation
import Supabase
import AuthenticationServices
import GoogleSignIn
import CryptoKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = true
    @Published var error: String?

    private let supabase = SupabaseService.shared

    init() {
        Task { await listenForAuthChanges() }
    }

    // MARK: - Auth State

    private func listenForAuthChanges() async {
        isLoading = true
        for await (event, session) in await supabase.client.auth.authStateChanges {
            switch event {
            case .initialSession, .signedIn:
                user = session?.user
            case .signedOut:
                user = nil
            default:
                break
            }
            isLoading = false
        }
    }

    // MARK: - Email Auth

    func signIn(email: String, password: String) async {
        error = nil
        do {
            try await supabase.signIn(email: email, password: password)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        error = nil
        do {
            try await supabase.signUp(email: email, password: password)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func resetPassword(email: String) async {
        error = nil
        do {
            try await supabase.resetPassword(email: email)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func signOut() async {
        error = nil
        do {
            try await supabase.signOut()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Apple Sign In

    /// Raw nonce kept in memory so we can forward it to Supabase after Apple returns.
    private var currentNonce: String?

    /// Called inside the `SignInWithAppleButton` request closure.
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    /// Called inside the `SignInWithAppleButton` onCompletion closure.
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        Task {
            error = nil
            switch result {
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    self.error = "Apple Sign In: unexpected credential type"
                    return
                }
                guard let tokenData = credential.identityToken,
                      let idTokenString = String(data: tokenData, encoding: .utf8),
                      !idTokenString.isEmpty else {
                    self.error = "Apple Sign In: missing identity token"
                    return
                }
                guard let nonce = currentNonce else {
                    self.error = "Apple Sign In: missing nonce"
                    return
                }
                do {
                    try await supabase.signInWithApple(idToken: idTokenString, nonce: nonce)
                } catch {
                    self.error = error.localizedDescription
                }
            case .failure(let err):
                // User cancelled – don't show an error
                if (err as NSError).code == ASAuthorizationError.canceled.rawValue { return }
                self.error = err.localizedDescription
            }
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        error = nil
        guard let rootVC = await UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController
        else {
            self.error = "Cannot find root view controller"
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                self.error = "Google Sign In: missing ID token"
                return
            }
            let accessToken = result.user.accessToken.tokenString
            try await supabase.signInWithGoogle(idToken: idToken, accessToken: accessToken)
        } catch {
            if (error as NSError).code == GIDSignInError.canceled.rawValue { return }
            self.error = error.localizedDescription
        }
    }

    // MARK: - Token

    func accessToken() async -> String? {
        await supabase.currentAccessToken()
    }

    // MARK: - Helpers

    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            randomBytes = (0..<length).map { _ in UInt8.random(in: 0...255) }
        }
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

