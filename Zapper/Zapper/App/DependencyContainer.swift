import Foundation

@Observable
final class DependencyContainer: @unchecked Sendable {
    let discoveryService = DiscoveryService()
    let connectionManager = ConnectionManager()
    let appState = AppState()
    let haptics = HapticEngine()

    static let shared = DependencyContainer()
    private init() {}
}
