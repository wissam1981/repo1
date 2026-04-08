import Foundation

struct TVApp: Identifiable, Equatable, Codable, Sendable {
    var id: String  // package name, e.g. "com.netflix.ninja"
    var name: String
    var isFavorite: Bool = false
}
