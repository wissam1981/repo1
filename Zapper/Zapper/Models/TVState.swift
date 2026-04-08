import Foundation

enum ConnectionStatus: String, Sendable {
    case disconnected
    case connecting
    case connected
}

enum PowerState: String, Sendable {
    case on
    case off
    case unknown
}

enum PlaybackState: String, Sendable {
    case idle
    case playing
    case paused
    case buffering
}

enum RemoteMode: String, Sendable, Hashable {
    case navigation
    case media
    case keyboard
    case appLauncher
}

struct TVState: Equatable, Sendable {
    var connectionStatus: ConnectionStatus = .disconnected
    var powerState: PowerState = .unknown
    var currentApp: TVApp? = nil
    var playbackState: PlaybackState = .idle
    var mediaInfo: MediaInfo? = nil
    var volume: Float = 0.5
    var isMuted: Bool = false
    var isTextInputFocused: Bool = false

    var suggestedMode: RemoteMode {
        if isTextInputFocused { return .keyboard }
        if playbackState != .idle { return .media }
        return .navigation
    }
}
