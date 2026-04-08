import Foundation

struct MediaInfo: Equatable, Sendable {
    var title: String
    var subtitle: String?
    var artworkURL: URL?
    var duration: TimeInterval?
    var position: TimeInterval?
}
