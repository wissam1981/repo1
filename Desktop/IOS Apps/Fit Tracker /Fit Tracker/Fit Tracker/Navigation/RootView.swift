import SwiftUI

// MARK: - Root View
// Observes AppState.authPhase and routes to the correct top-level view.

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.authPhase {
            case .splash:
                SplashView()
            case .unauthenticated:
                AuthContainerView()
            case .onboarding:
                OnboardingContainerView()
            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.authPhase)
        .errorBanner()
    }
}
