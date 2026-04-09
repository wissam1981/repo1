import Foundation
import UIKit

actor AndroidTVPairing {
    enum PairingError: Error, LocalizedError {
        case invalidPIN
        case pairingRejected
        case timeout
        case protocolError(String)

        var errorDescription: String? {
            switch self {
            case .invalidPIN: return "Invalid PIN code"
            case .pairingRejected: return "TV rejected the pairing request"
            case .timeout: return "Pairing timed out"
            case .protocolError(let msg): return "Protocol error: \(msg)"
            }
        }
    }

    enum PairingState: Sendable {
        case idle
        case waitingForPIN
        case verifying
        case paired
        case failed(PairingError)
    }

    private let connection: AndroidTVConnection
    private(set) var state: PairingState = .idle

    init(connection: AndroidTVConnection) {
        self.connection = connection
    }

    func startPairing() async throws {
        state = .waitingForPIN

        var pairingRequest = Data()
        let serviceName = "Zapper".data(using: .utf8)!
        let deviceNameString = await MainActor.run { UIDevice.current.name }
        let deviceName = deviceNameString.data(using: .utf8) ?? "iPhone".data(using: .utf8)!

        pairingRequest.append(0x0a)
        pairingRequest.append(UInt8(serviceName.count))
        pairingRequest.append(serviceName)

        pairingRequest.append(0x12)
        pairingRequest.append(UInt8(deviceName.count))
        pairingRequest.append(deviceName)

        try await connection.send(pairingRequest)
    }

    func submitPIN(_ pin: String) async throws {
        guard pin.count >= 4, pin.allSatisfy(\.isNumber) else {
            throw PairingError.invalidPIN
        }

        state = .verifying

        let pinData = pin.data(using: .utf8)!
        var pinMessage = Data()
        pinMessage.append(0x0a)
        pinMessage.append(UInt8(pinData.count))
        pinMessage.append(pinData)

        try await connection.send(pinMessage)
    }

    func pairingSucceeded() {
        state = .paired
    }

    func pairingFailed(_ error: PairingError) {
        state = .failed(error)
    }
}
