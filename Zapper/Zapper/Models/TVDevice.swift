import Foundation

enum TVPlatform: String, Codable, Sendable {
    case androidTV
    case roku
    case samsung
    case lgWebOS
    case fireTV
}

enum PairingStatus: String, Codable, Sendable {
    case unpaired
    case pairing
    case paired
}

enum TVCapability: String, Codable, Sendable {
    case dpad
    case mediaControl
    case textInput
    case appLaunch
    case power
    case volume
}

struct TVDevice: Identifiable, Equatable, Codable, Sendable {
    var id: UUID = UUID()
    var name: String
    var ipAddress: String
    var platform: TVPlatform
    var macAddress: String?
    var capabilities: Set<TVCapability> = []
    var pairingStatus: PairingStatus = .unpaired
}
