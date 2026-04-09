import Foundation

@Observable
final class ConnectionManager: @unchecked Sendable {
    private(set) var currentDevice: TVDevice?
    private(set) var connectionStatus: ConnectionStatus = .disconnected
    private(set) var savedDevices: [TVDevice] = []

    private var driver: (any TVProtocol)?
    private var reconnectTask: Task<Void, Never>?
    private let maxReconnectAttempts = 3
    private let keychain = KeychainService()

    func connect(to device: TVDevice) async throws {
        disconnect()
        connectionStatus = .connecting
        currentDevice = device

        let driver = createDriver(for: device.platform)
        self.driver = driver

        try await driver.connect(to: device)
        connectionStatus = .connected

        addSavedDevice(device)
        saveLastDeviceId(device.id)
    }

    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil

        if let driver {
            Task { await driver.disconnect() }
        }
        driver = nil
        connectionStatus = .disconnected
        currentDevice = nil
    }

    func sendCommand(_ command: TVCommand) async throws {
        guard let driver else { return }
        try await driver.sendCommand(command)
    }

    func sendText(_ text: String) async throws {
        guard let driver else { return }
        try await driver.sendText(text)
    }

    func getInstalledApps() async throws -> [TVApp] {
        guard let driver else { return [] }
        return try await driver.getInstalledApps()
    }

    func launchApp(_ app: TVApp) async throws {
        guard let driver else { return }
        try await driver.launchApp(app)
    }

    func getTVState() async -> TVState {
        guard let driver else { return TVState() }
        return await driver.state
    }

    func addSavedDevice(_ device: TVDevice) {
        if !savedDevices.contains(where: { $0.id == device.id }) {
            savedDevices.append(device)
        }
    }

    func removeSavedDevice(_ device: TVDevice) {
        savedDevices.removeAll { $0.id == device.id }
    }

    func lastDeviceId() -> UUID? {
        guard let string = UserDefaults.standard.string(forKey: "lastDeviceId"),
              let uuid = UUID(uuidString: string) else { return nil }
        return uuid
    }

    private func saveLastDeviceId(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: "lastDeviceId")
    }

    func attemptAutoReconnect() {
        guard let lastId = lastDeviceId(),
              let device = savedDevices.first(where: { $0.id == lastId }) else { return }

        reconnectTask = Task {
            for attempt in 1...maxReconnectAttempts {
                do {
                    try await connect(to: device)
                    return
                } catch {
                    let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
            await MainActor.run { self.connectionStatus = .disconnected }
        }
    }

    private func createDriver(for platform: TVPlatform) -> any TVProtocol {
        switch platform {
        case .androidTV:
            return AndroidTVDriver()
        default:
            fatalError("Platform \(platform) not yet supported")
        }
    }
}
