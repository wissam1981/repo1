import Foundation

final class AndroidTVDriver: TVProtocol, @unchecked Sendable {
    private let connection = AndroidTVConnection()
    private let messageHandler = AndroidTVMessageHandler()
    private var pairing: AndroidTVPairing?
    private var _state = TVState()
    private let stateLock = NSLock()

    private static let defaultPort: UInt16 = 6466

    var state: TVState {
        get async {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _state
        }
    }

    private func updateState(_ update: (inout TVState) -> Void) {
        stateLock.lock()
        update(&_state)
        stateLock.unlock()
    }

    func connect(to device: TVDevice) async throws {
        updateState { $0.connectionStatus = .connecting }
        try await connection.connect(
            host: device.ipAddress,
            port: Self.defaultPort,
            deviceId: device.id.uuidString
        )
        updateState { $0.connectionStatus = .connected }
        await connection.startReceiving { [weak self] data in
            self?.handleIncomingMessage(data)
        }
    }

    func disconnect() async {
        await connection.disconnect()
        updateState { state in
            state.connectionStatus = .disconnected
            state.playbackState = .idle
            state.currentApp = nil
        }
    }

    func sendCommand(_ command: TVCommand) async throws {
        guard let keyCode = command.androidKeyCode else {
            switch command {
            case .seekForward(let seconds):
                for _ in 0..<(seconds / 10) {
                    let data = Self.encodeKeyPress(keyCode: .next, action: .press)
                    try await connection.send(data)
                }
            case .seekBackward(let seconds):
                for _ in 0..<(seconds / 10) {
                    let data = Self.encodeKeyPress(keyCode: .previous, action: .press)
                    try await connection.send(data)
                }
            default:
                break
            }
            return
        }
        let data = Self.encodeKeyPress(keyCode: keyCode, action: .press)
        try await connection.send(data)
    }

    func sendText(_ text: String) async throws {
        guard let textData = text.data(using: .utf8) else { return }
        var message = Data()
        message.append(0x0a)
        message.append(UInt8(min(textData.count, 255)))
        message.append(textData)
        try await connection.send(message)
    }

    func getInstalledApps() async throws -> [TVApp] {
        return [
            TVApp(id: "com.netflix.ninja", name: "Netflix"),
            TVApp(id: "com.google.android.youtube.tv", name: "YouTube"),
            TVApp(id: "com.spotify.tv.android", name: "Spotify"),
            TVApp(id: "com.disney.disneyplus", name: "Disney+"),
            TVApp(id: "com.amazon.amazonvideo.livingroom", name: "Prime Video"),
            TVApp(id: "com.hbo.hbonow", name: "HBO Max"),
        ]
    }

    func launchApp(_ app: TVApp) async throws {
        guard let appData = app.id.data(using: .utf8) else { return }
        var message = Data()
        message.append(0x0a)
        message.append(UInt8(min(appData.count, 255)))
        message.append(appData)
        try await connection.send(message)
    }

    func startPairing() async throws -> AndroidTVPairing {
        let pairing = AndroidTVPairing(connection: connection)
        self.pairing = pairing
        try await pairing.startPairing()
        return pairing
    }

    static func encodeKeyPress(keyCode: AndroidKeyCode, action: KeyAction) -> Data {
        var data = Data()
        data.append(0x08)
        var code = keyCode.rawValue
        while code > 127 {
            data.append(UInt8(code & 0x7F) | 0x80)
            code >>= 7
        }
        data.append(UInt8(code))
        data.append(0x10)
        data.append(action.rawValue)
        return data
    }

    private func handleIncomingMessage(_ data: Data) {
        guard let (type, payload) = messageHandler.identifyMessage(data) else { return }
        let update = messageHandler.parseMessage(type: type, data: payload)
        switch update {
        case .volume(let level, let isMuted):
            updateState { $0.volume = level; $0.isMuted = isMuted }
        case .currentApp(let packageName, let appName):
            updateState { $0.currentApp = TVApp(id: packageName, name: appName) }
        case .textInputFocused(let focused):
            updateState { $0.isTextInputFocused = focused }
        case .pairingResult(let success):
            Task {
                if success { await pairing?.pairingSucceeded() }
                else { await pairing?.pairingFailed(.pairingRejected) }
            }
        case .playbackState(let playback):
            updateState { $0.playbackState = playback }
        case .unknown:
            break
        }
    }
}
