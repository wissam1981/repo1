import SwiftUI

struct AppRouter: View {
    @State private var container = DependencyContainer.shared

    var body: some View {
        Group {
            switch container.appState.currentScreen {
            case .discovery:
                DiscoveryView(
                    viewModel: DiscoveryViewModel(
                        discoveryService: container.discoveryService,
                        connectionManager: container.connectionManager
                    )
                )
            case .remote:
                RemoteView(
                    viewModel: RemoteViewModel(container: container)
                )
            }
        }
        .onChange(of: container.connectionManager.connectionStatus) { _, newStatus in
            switch newStatus {
            case .connected:
                container.appState.currentScreen = .remote
            case .disconnected:
                container.appState.currentScreen = .discovery
            default:
                break
            }
        }
        .onAppear {
            container.connectionManager.attemptAutoReconnect()
        }
        .preferredColorScheme(.dark)
    }
}
