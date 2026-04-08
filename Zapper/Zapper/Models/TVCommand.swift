import Foundation

enum Direction: String, Sendable {
    case up, down, left, right
}

enum TVCommand: Equatable, Sendable {
    case dpad(Direction)
    case select
    case back
    case home
    case menu
    case playPause
    case play
    case pause
    case stop
    case skipForward
    case skipBackward
    case seekForward(seconds: Int)
    case seekBackward(seconds: Int)
    case volumeUp
    case volumeDown
    case mute
    case power
}
