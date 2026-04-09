import Foundation

@Observable
@MainActor
final class RemoteViewModel {
    private(set) var activeMode: RemoteMode = .navigation
    private(set) var tvState = TVState()
    private(set) var installedApps: [TVApp] = []
    var isManualOverride = false

    private let container: DependencyContainer
    private var statePollingTask: Task<Void, Never>?

    init(container: DependencyContainer) {
        self.container = container
    }

    func setManualMode(_ mode: RemoteMode) {
        isManualOverride = true
        activeMode = mode
        container.haptics.play(.selection)
    }

    func enableAutoMode() {
        isManualOverride = false
        activeMode = tvState.suggestedMode
    }

    func handleStateUpdate(_ state: TVState) {
        tvState = state
        if !isManualOverride {
            let newMode = state.suggestedMode
            if newMode != activeMode {
                activeMode = newMode
                container.haptics.play(.selection)
            }
        }
    }

    func sendCommand(_ command: TVCommand) {
        Task {
            try? await container.connectionManager.sendCommand(command)
            switch command {
            case .dpad:
                container.haptics.play(.light)
            case .select:
                container.haptics.play(.medium)
            case .power:
                container.haptics.play(.heavy)
            default:
                container.haptics.play(.light)
            }
        }
    }

    func sendText(_ text: String) {
        Task {
            try? await container.connectionManager.sendText(text)
        }
    }

    func launchApp(_ app: TVApp) {
        Task {
            try? await container.connectionManager.launchApp(app)
            container.haptics.play(.medium)
        }
    }

    func startStatePolling() {
        statePollingTask = Task {
            while !Task.isCancelled {
                let state = await container.connectionManager.getTVState()
                await MainActor.run { handleStateUpdate(state) }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    func stopStatePolling() {
        statePollingTask?.cancel()
        statePollingTask = nil
    }

    func loadInstalledApps() {
        Task {
            installedApps = (try? await container.connectionManager.getInstalledApps()) ?? []
        }
    }
}
