import Foundation

/// Android TV key codes
enum AndroidKeyCode: Int, Sendable {
    case up = 19
    case down = 20
    case left = 21
    case right = 22
    case select = 23
    case back = 4
    case home = 3
    case menu = 82
    case playPause = 85
    case play = 126
    case pause = 127
    case stop = 86
    case next = 87
    case previous = 88
    case volumeUp = 24
    case volumeDown = 25
    case mute = 164
    case power = 26
}

enum KeyAction: UInt8, Sendable {
    case down = 0
    case up = 1
    case press = 2
}

extension TVCommand {
    var androidKeyCode: AndroidKeyCode? {
        switch self {
        case .dpad(.up): return .up
        case .dpad(.down): return .down
        case .dpad(.left): return .left
        case .dpad(.right): return .right
        case .select: return .select
        case .back: return .back
        case .home: return .home
        case .menu: return .menu
        case .playPause: return .playPause
        case .play: return .play
        case .pause: return .pause
        case .stop: return .stop
        case .skipForward: return .next
        case .skipBackward: return .previous
        case .volumeUp: return .volumeUp
        case .volumeDown: return .volumeDown
        case .mute: return .mute
        case .power: return .power
        case .seekForward, .seekBackward: return nil
        }
    }
}

enum MessageFramer {
    static func frame(_ data: Data) -> Data {
        var result = Data()
        var length = UInt64(data.count)
        while length > 127 {
            result.append(UInt8(length & 0x7F) | 0x80)
            length >>= 7
        }
        result.append(UInt8(length))
        result.append(data)
        return result
    }

    static func deframe(_ buffer: Data) -> (message: Data, consumed: Int)? {
        var offset = 0
        var length: UInt64 = 0
        var shift: UInt64 = 0

        while offset < buffer.count {
            let byte = buffer[offset]
            length |= UInt64(byte & 0x7F) << shift
            offset += 1
            if byte & 0x80 == 0 { break }
            shift += 7
            if shift > 35 { return nil }
        }

        let totalLength = offset + Int(length)
        guard buffer.count >= totalLength else { return nil }

        let message = buffer.subdata(in: offset..<totalLength)
        return (message, totalLength)
    }
}
