import UIKit
import AuthenticationServices
import CryptoKit

/// Handles Sign in with Apple authentication flow
class SignInWithAppleService: NSObject {
    static let shared = SignInWithAppleService()

    // MARK: - Properties
    private var currentNonce: String?
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?

    // MARK: - Public Methods

    /// Initiate Sign in with Apple flow
    /// - Parameter presentingViewController: The view controller to present the Apple sign in sheet from
    /// - Returns: AppleSignInResult containing ID token and nonce
    func signIn(from presentingViewController: UIViewController) async throws -> AppleSignInResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            // Generate a random nonce for security
            let nonce = randomNonceString()
            currentNonce = nonce

            // Create Apple ID authorization request
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

            // Create authorization controller
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self

            // Perform request
            authorizationController.performRequests()
        }
    }

    /// Check credential state for a given user
    /// - Parameter userID: The Apple user identifier
    /// - Returns: Authorization credential state
    func checkCredentialState(for userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        return await withCheckedContinuation { continuation in
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: userID) { state, error in
                if let error = error {
                    print("❌ Error checking credential state: \(error.localizedDescription)")
                }
                continuation.resume(returning: state)
            }
        }
    }

    // MARK: - Helper Methods

    /// Generate a random nonce string
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    // Fallback to arc4random if SecRandomCopyBytes fails (very rare)
                    print("⚠️ SecRandomCopyBytes failed with OSStatus \(errorCode), using fallback")
                    return UInt8(arc4random_uniform(UInt32(UInt8.max)))
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    /// Hash a string using SHA256
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension SignInWithAppleService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: SignInWithAppleError.invalidCredential)
            continuation = nil
            return
        }

        guard let nonce = currentNonce else {
            continuation?.resume(throwing: SignInWithAppleError.missingNonce)
            continuation = nil
            return
        }

        guard let appleIDToken = appleIDCredential.identityToken else {
            continuation?.resume(throwing: SignInWithAppleError.missingIdentityToken)
            continuation = nil
            return
        }

        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            continuation?.resume(throwing: SignInWithAppleError.invalidIdentityToken)
            continuation = nil
            return
        }

        print("✅ Sign in with Apple successful")
        print("   User ID: \(appleIDCredential.user)")
        print("   Email: \(appleIDCredential.email ?? "not provided")")
        print("   Full Name: \(appleIDCredential.fullName?.givenName ?? "") \(appleIDCredential.fullName?.familyName ?? "")")

        let result = AppleSignInResult(
            idToken: idTokenString,
            nonce: nonce,
            userID: appleIDCredential.user,
            email: appleIDCredential.email,
            fullName: appleIDCredential.fullName
        )

        continuation?.resume(returning: result)
        continuation = nil
        currentNonce = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Sign in with Apple failed: \(error.localizedDescription)")

        // Check if user cancelled
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                continuation?.resume(throwing: SignInWithAppleError.userCancelled)
            case .failed:
                continuation?.resume(throwing: SignInWithAppleError.authorizationFailed(authError))
            case .invalidResponse:
                continuation?.resume(throwing: SignInWithAppleError.invalidResponse)
            case .notHandled:
                continuation?.resume(throwing: SignInWithAppleError.notHandled)
            case .unknown:
                continuation?.resume(throwing: SignInWithAppleError.unknown(authError))
            @unknown default:
                continuation?.resume(throwing: SignInWithAppleError.unknown(authError))
            }
        } else {
            continuation?.resume(throwing: error)
        }

        continuation = nil
        currentNonce = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension SignInWithAppleService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Try to find the key window
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            return window
        }

        // Fallback: return any window
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first {
            print("⚠️ No key window found, using first available window")
            return window
        }

        // Last resort: create a new window (shouldn't happen in practice)
        print("❌ No windows found, creating fallback window")
        let fallbackWindow = UIWindow(frame: UIScreen.main.bounds)
        fallbackWindow.makeKeyAndVisible()
        return fallbackWindow
    }
}

// MARK: - Result Model

struct AppleSignInResult {
    let idToken: String
    let nonce: String
    let userID: String
    let email: String?
    let fullName: PersonNameComponents?
}

// MARK: - Error Types

enum SignInWithAppleError: LocalizedError {
    case invalidCredential
    case missingNonce
    case missingIdentityToken
    case invalidIdentityToken
    case userCancelled
    case authorizationFailed(Error)
    case invalidResponse
    case notHandled
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple ID credential received"
        case .missingNonce:
            return "Security nonce is missing"
        case .missingIdentityToken:
            return "Apple ID token is missing"
        case .invalidIdentityToken:
            return "Unable to decode Apple ID token"
        case .userCancelled:
            return "Sign in with Apple was cancelled"
        case .authorizationFailed(let error):
            return "Authorization failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from Apple"
        case .notHandled:
            return "Authorization request not handled"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
