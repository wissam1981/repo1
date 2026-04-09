import Foundation

@Observable
final class AppState {
    enum AppScreen {
        case discovery
        case remote
    }

    var currentScreen: AppScreen = .discovery
    var activeMode: RemoteMode = .navigation
    var isManualModeOverride: Bool = false

    func updateModeFromState(_ tvState: TVState) {
        guard !isManualModeOverride else { return }
        activeMode = tvState.suggestedMode
    }

    func setManualMode(_ mode: RemoteMode) {
        isManualModeOverride = true
        activeMode = mode
    }

    func enableAutoMode() {
        isManualModeOverride = false
    }
}
