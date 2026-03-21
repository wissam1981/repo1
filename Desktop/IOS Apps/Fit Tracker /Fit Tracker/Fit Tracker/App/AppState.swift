import SwiftUI
import Observation

// MARK: - Auth Phase

enum AuthPhase: Equatable {
    case splash
    case unauthenticated
    case onboarding
    case main
}

// MARK: - AI Action

enum AIAction {
    case budgetAdvisor
    case weeklyDigest
}

// MARK: - App State
// Single source of truth for authentication phase and current user.
// @Observable drives automatic RootView re-renders on phase changes.

@Observable
final class AppState {
    var authPhase: AuthPhase = .splash
    var currentUser: UserProfile?
    var isLoading: Bool = false
    var errorMessage: String?
    // MARK: - AI Navigation
    var pendingAIAction: AIAction?
    var showAICoach: Bool = false

    // MARK: - Auth State Handler
    // Called by FirebaseAuthService's auth state listener (Sprint 2).

    func handleAuthStateChange(user: UserProfile?) {
        if let user {
            currentUser = user
            authPhase = user.isOnboardingComplete ? .main : .onboarding
        } else {
            currentUser = nil
            authPhase = .unauthenticated
        }
        isLoading = false
    }

    // MARK: - Convenience

    func showError(_ message: String) {
        errorMessage = message
    }

    func clearError() {
        errorMessage = nil
    }

    func signOut() {
        currentUser = nil
        authPhase = .unauthenticated
    }
}
