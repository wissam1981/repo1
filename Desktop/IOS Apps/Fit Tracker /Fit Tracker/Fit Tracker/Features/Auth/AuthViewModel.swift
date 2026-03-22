import Observation
import SwiftUI
import AuthenticationServices
import CryptoKit
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

// MARK: - Auth View Model

@Observable
final class AuthViewModel {

    var email = ""
    var password = ""
    var displayName = ""
    var confirmPassword = ""

    var isLoading = false
    var errorMessage: String?
    var showForgotPassword = false
    var resetEmailSent = false

    private let authService: AuthServiceProtocol

    /// Unhashed nonce for Apple Sign-In verification
    private var currentNonce: String?

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    // MARK: - Validation

    var isLoginValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= 6
    }

    var isSignUpValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }

    // MARK: - Sign In

    func signIn() async {
        guard isLoginValid else {
            errorMessage = "Please enter a valid email and password (6+ characters)."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await authService.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign Up

    func signUp() async {
        guard isSignUpValid else {
            if password != confirmPassword {
                errorMessage = "Passwords don't match."
            } else {
                errorMessage = "Please fill in all fields."
            }
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await authService.signUp(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                displayName: displayName.trimmingCharacters(in: .whitespaces)
            )
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign in with Google

    @MainActor
    func signInWithGoogle() async {
        let rootVC = await MainActor.run {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil as UIViewController? }
            return windowScene.windows.first?.rootViewController
        }

        guard let rootViewController = rootVC else {
            errorMessage = "Could not find root view controller to present Google Login."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        #if canImport(GoogleSignIn)
        do {
            guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                  let plistDict = NSDictionary(contentsOfFile: plistPath),
                  let clientID = plistDict["CLIENT_ID"] as? String else {
                errorMessage = "Could not find CLIENT_ID in GoogleService-Info.plist."
                return
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google authentication failed. Missing ID Token."
                return
            }

            let accessToken = result.user.accessToken.tokenString
            _ = try await authService.signInWithGoogle(idToken: idToken, accessToken: accessToken)

        } catch {
            if (error as NSError).code != GIDSignInError.canceled.rawValue {
                errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
            }
        }
        #else
        errorMessage = "Google Sign-In integration requires installing the GoogleSignIn Swift Package."
        #endif
    }

    // MARK: - Sign in with Apple

    /// Generate a nonce and return an ASAuthorizationAppleIDRequest ready for use.
    func prepareAppleSignInRequest() -> String {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        return Self.sha256(nonce)
    }

    /// Handle the completed Apple Sign-In authorization.
    @MainActor
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Apple Sign-In failed: could not retrieve token."
                return
            }

            guard let nonce = currentNonce else {
                errorMessage = "Apple Sign-In failed: invalid state (missing nonce)."
                return
            }

            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            do {
                _ = try await authService.signInWithApple(
                    idToken: idTokenString,
                    nonce: nonce,
                    fullName: appleIDCredential.fullName
                )
            } catch let error as AuthError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
            }

        case .failure(let error):
            // User cancelled is code 1001
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Forgot Password

    func sendPasswordReset() async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Enter your email first."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.sendPasswordReset(email: email.trimmingCharacters(in: .whitespaces))
            resetEmailSent = true
        } catch {
            errorMessage = "Failed to send reset email."
        }
    }

    // MARK: - Clear

    func clearFields() {
        email = ""
        password = ""
        displayName = ""
        confirmPassword = ""
        errorMessage = nil
    }

    // MARK: - Apple Sign-In Helpers

    /// Generate a random nonce string for Apple Sign-In
    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    /// SHA256 hash of input string
    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
