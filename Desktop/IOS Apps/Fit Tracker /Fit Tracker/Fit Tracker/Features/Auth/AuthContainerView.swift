import SwiftUI

// MARK: - Auth Container View

struct AuthContainerView: View {
    @Environment(DependencyContainer.self) private var container
    @Environment(AppState.self) private var appState
    @State private var viewModel: AuthViewModel?
    @State private var showLogin = false

    var body: some View {
        ZStack {
            if let viewModel {
                if !showLogin {
                    WelcomeView {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showLogin = true
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                } else {
                    LoginView(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AuthViewModel(authService: container.authService)
            }
        }
    }
}
