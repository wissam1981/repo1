import Foundation

struct AndroidTVMessageHandler: Sendable {
    enum MessageType: UInt8, Sendable {
        case pairingResponse = 1
        case keyResponse = 2
        case volumeInfo = 3
        case currentApp = 4
        case imeStatus = 5
        case deviceInfo = 6
        case error = 255
    }

    enum StateUpdate: Sendable {
        case volume(level: Float, isMuted: Bool)
        case currentApp(packageName: String, appName: String)
        case textInputFocused(Bool)
        case pairingResult(success: Bool)
        case playbackState(PlaybackState)
        case unknown
    }

    func parseMessage(type: MessageType, data: Data) -> StateUpdate {
        switch type {
        case .volumeInfo:
            return parseVolumeInfo(data)
        case .currentApp:
            return parseCurrentApp(data)
        case .imeStatus:
            return parseIMEStatus(data)
        case .pairingResponse:
            return parsePairingResponse(data)
        default:
            return .unknown
        }
    }

    func identifyMessage(_ data: Data) -> (type: MessageType, payload: Data)? {
        guard !data.isEmpty else { return nil }
        guard let type = MessageType(rawValue: data[0]) else { return nil }
        let payload = data.count > 1 ? data.subdata(in: 1..<data.count) : Data()
        return (type, payload)
    }

    private func parseVolumeInfo(_ data: Data) -> StateUpdate {
        var currentVolume: Int = 0
        var maxVolume: Int = 1
        var isMuted: Bool = false
        var offset = 0

        while offset < data.count {
            let byte = data[offset]
            let fieldNumber = (byte >> 3)
            let wireType = byte & 0x07
            offset += 1

            if wireType == 0 {
                var value: Int = 0
                var shift = 0
                while offset < data.count {
                    if shift > 35 { break }
                    let b = data[offset]
                    value |= Int(b & 0x7F) << shift
                    offset += 1
                    if b & 0x80 == 0 { break }
                    shift += 7
                }
                switch fieldNumber {
                case 1: currentVolume = value
                case 2: maxVolume = max(value, 1)
                case 3: isMuted = value != 0
                default: break
                }
            }
        }

        let level = Float(currentVolume) / Float(maxVolume)
        return .volume(level: level, isMuted: isMuted)
    }

    private func parseCurrentApp(_ data: Data) -> StateUpdate {
        var packageName = ""
        var appName = ""
        var offset = 0

        while offset < data.count {
            let byte = data[offset]
            let fieldNumber = (byte >> 3)
            let wireType = byte & 0x07
            offset += 1

            if wireType == 2 {
                guard offset < data.count else { break }
                var length = 0
                var shift = 0
                while offset < data.count {
                    if shift > 35 { break }
                    let b = data[offset]
                    length |= Int(b & 0x7F) << shift
                    offset += 1
                    if b & 0x80 == 0 { break }
                    shift += 7
                }
                guard offset + length <= data.count else { break }
                let stringData = data.subdata(in: offset..<(offset + length))
                let string = String(data: stringData, encoding: .utf8) ?? ""
                offset += length
                switch fieldNumber {
                case 1: packageName = string
                case 2: appName = string
                default: break
                }
            }
        }

        return .currentApp(packageName: packageName, appName: appName)
    }

    private func parseIMEStatus(_ data: Data) -> StateUpdate {
        guard data.count >= 2 else { return .textInputFocused(false) }
        return .textInputFocused(data[1] != 0)
    }

    private func parsePairingResponse(_ data: Data) -> StateUpdate {
        guard data.count >= 2 else { return .pairingResult(success: false) }
        return .pairingResult(success: data[1] != 0)
    }
}
