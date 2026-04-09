import Foundation

@Observable
final class DependencyContainer {
    let discoveryService = DiscoveryService()
    let connectionManager = ConnectionManager()
    let appState = AppState()
    let haptics = HapticEngine()

    static let shared = DependencyContainer()
    private init() {}
}
