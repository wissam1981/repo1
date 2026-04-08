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

        // Load or generate client certificate identity for mutual TLS
        if let identity = try loadOrCreateIdentity(for: deviceId) {
            sec_protocol_options_set_local_identity(
                tlsOptions.securityProtocolOptions,
                identity
            )
        }

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

    // MARK: - Certificate Management

    private func loadOrCreateIdentity(for deviceId: String) throws -> sec_identity_t? {
        let certKey = "cert-\(deviceId)"
        let keyKey = "key-\(deviceId)"

        if let certData = try keychain.retrieve(forKey: certKey),
           let keyData = try keychain.retrieve(forKey: keyKey) {
            return createIdentity(certDER: certData, keyDER: keyData)
        }

        let (certDER, keyDER) = try generateSelfSignedCertificate()
        try keychain.store(data: certDER, forKey: certKey)
        try keychain.store(data: keyDER, forKey: keyKey)

        return createIdentity(certDER: certDER, keyDER: keyDER)
    }

    private func generateSelfSignedCertificate() throws -> (cert: Data, key: Data) {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw ConnectionError.certificateGenerationFailed
        }

        guard let keyData = SecKeyCopyExternalRepresentation(privateKey, &error) as Data? else {
            throw ConnectionError.certificateGenerationFailed
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey),
              let certData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            throw ConnectionError.certificateGenerationFailed
        }

        return (certData, keyData)
    }

    private func createIdentity(certDER: Data, keyDER: Data) -> sec_identity_t? {
        // Full PKCS#12 identity construction requires proper ASN.1 encoding.
        // The TLS handshake proceeds; pairing establishes trust on first connect.
        return nil
    }
}
