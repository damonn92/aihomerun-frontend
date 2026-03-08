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

    func signInWithApple() async {
        error = nil
        let nonce = randomNonceString()
        let hashedNonce = sha256(nonce)

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate()

        do {
            let credential = try await delegate.signIn(controller: controller)
            guard let idTokenString = String(data: credential.identityToken!, encoding: .utf8) else {
                self.error = "Apple Sign In: missing identity token"
                return
            }
            try await supabase.signInWithApple(idToken: idTokenString, nonce: nonce)
        } catch {
            self.error = error.localizedDescription
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
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        precondition(errorCode == errSecSuccess, "Unable to generate nonce")
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple Sign In Delegate Helper

@MainActor
private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    func signIn(controller: ASAuthorizationController) async throws -> ASAuthorizationAppleIDCredential {
        controller.delegate = self
        controller.presentationContextProvider = self
        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        continuation?.resume(returning: credential)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first ?? ASPresentationAnchor()
    }
}
