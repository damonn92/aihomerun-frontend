import Foundation
import AuthenticationServices
import GoogleSignIn
import CryptoKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: AuthUser?
    @Published var isLoading = true
    @Published var error: String?

    private let service = SupabaseService.shared

    init() {
        // Restore persisted session synchronously
        if let u = service.currentUser {
            user = u
        }
        isLoading = false
    }

    // MARK: - Email Auth

    func signIn(email: String, password: String) async {
        error = nil
        do {
            try await service.signIn(email: email, password: password)
            user = service.currentUser
        } catch {
            self.error = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        error = nil
        do {
            try await service.signUp(email: email, password: password)
            user = service.currentUser
        } catch {
            self.error = error.localizedDescription
        }
    }

    func resetPassword(email: String) async {
        error = nil
        do {
            try await service.resetPassword(email: email)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func signOut() async {
        error = nil
        do {
            try await service.signOut()
            user = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Apple Sign In

    /// Raw nonce kept in memory so we can forward it to the backend after Apple returns.
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
                    self.error = "Apple Sign In failed. Please try again."
                    return
                }
                guard let tokenData = credential.identityToken,
                      let idTokenString = String(data: tokenData, encoding: .utf8),
                      !idTokenString.isEmpty else {
                    self.error = "Apple Sign In failed. Please try again."
                    return
                }
                guard let nonce = currentNonce else {
                    self.error = "Apple Sign In failed. Please try again."
                    return
                }
                do {
                    try await service.signInWithApple(idToken: idTokenString, nonce: nonce)
                    user = service.currentUser
                } catch {
                    self.error = "Apple Sign In failed: \(error.localizedDescription)"
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

        // Find the key window's root VC — works on both iPhone and iPad multi-scene
        guard let rootVC = await {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes
                .compactMap { $0 as? UIWindowScene }
                .first(where: { $0.activationState == .foregroundActive })
                ?? scenes.compactMap({ $0 as? UIWindowScene }).first
            return windowScene?.windows.first(where: \.isKeyWindow)?.rootViewController
                ?? windowScene?.windows.first?.rootViewController
        }()
        else {
            self.error = "Unable to present Google Sign In. Please try again."
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                self.error = "Google Sign In failed. Please try again."
                return
            }
            let googleAccessToken = result.user.accessToken.tokenString
            try await service.signInWithGoogle(idToken: idToken, accessToken: googleAccessToken)
            user = service.currentUser
        } catch {
            if (error as NSError).code == GIDSignInError.canceled.rawValue { return }
            self.error = "Google Sign In failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Account Deletion

    func deleteAccount() async {
        error = nil
        do {
            try await service.deleteAccount()
            user = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Token

    func accessToken() async -> String? {
        await service.currentAccessToken()
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
