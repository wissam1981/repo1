import Foundation
import Network
import Security

actor AndroidTVConnection {
    enum ConnectionError: Error, LocalizedError {
        case connectionFailed(String)
        case notConnected
        case sendFailed
        case certificateGenerationFailed

        var errorDescription: String? {
            switch self {
            case .connectionFailed(let reason): return "Connection failed: \(reason)"
            case .notConnected: return "Not connected to TV"
            case .sendFailed: return "Failed to send data"
            case .certificateGenerationFailed: return "Failed to generate TLS certificate"
            }
        }
    }

    private var connection: NWConnection?
    private var receiveBuffer = Data()
    private var messageHandler: (@Sendable (Data) -> Void)?
    private let keychain = KeychainService()

    var isConnected: Bool {
        connection?.state == .ready
    }

    func connect(host: String, port: UInt16, deviceId: String) async throws {
        let tlsOptions = NWProtocolTLS.Options()

        sec_protocol_options_set_verify_block(
            tlsOptions.securityProtocolOptions,
            { _, _, completionHandler in
                completionHandler(true)
            },
            DispatchQueue(label: "com.zapper.tls-verify")
        )

        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveInterval = 30

        let parameters = NWParameters(tls: tlsOptions, tcp: tcpOptions)
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )

        let connection = NWConnection(to: endpoint, using: parameters)
        self.connection = connection

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    continuation.resume()
                case .failed(let error):
                    continuation.resume(throwing: ConnectionError.connectionFailed(error.localizedDescription))
                case .cancelled:
                    continuation.resume(throwing: ConnectionError.connectionFailed("Cancelled"))
                default:
                    break
                }
            }
            connection.start(queue: DispatchQueue(label: "com.zapper.connection"))
        }
    }

    func send(_ data: Data) async throws {
        guard let connection, isConnected else {
            throw ConnectionError.notConnected
        }
        let framed = MessageFramer.frame(data)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(content: framed, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }

    func startReceiving(handler: @escaping @Sendable (Data) -> Void) {
        self.messageHandler = handler
        receiveLoop()
    }

    private func receiveLoop() {
        guard let connection else { return }
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self else { return }
            Task {
                if let content {
                    await self.handleReceivedData(content)
                }
                if !isComplete && error == nil {
                    await self.receiveLoop()
                }
            }
        }
    }

    private func handleReceivedData(_ data: Data) {
        receiveBuffer.append(data)
        while let (message, consumed) = MessageFramer.deframe(receiveBuffer) {
            receiveBuffer = receiveBuffer.subdata(in: consumed..<receiveBuffer.count)
            messageHandler?(message)
        }
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
        receiveBuffer = Data()
    }
}
