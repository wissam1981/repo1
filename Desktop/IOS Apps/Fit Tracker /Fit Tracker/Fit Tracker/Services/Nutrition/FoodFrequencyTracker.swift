import Foundation

// MARK: - Food Frequency Tracker
/// Tracks how often each food is logged to enable smart search ranking.
/// Data stored in UserDefaults, capped at 200 entries.

struct FoodFrequency: Codable {
    var count: Int
    var lastLogged: Date
}

@MainActor
struct FoodFrequencyTracker {

    private static let storageKey = "food_frequency_map"
    private static let maxEntries = 200

    // MARK: - Read

    static func frequencyMap() -> [String: FoodFrequency] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let map = try? JSONDecoder().decode([String: FoodFrequency].self, from: data) else {
            return [:]
        }
        return map
    }

    static func isFrequent(_ name: String) -> Bool {
        let key = name.lowercased()
        guard let entry = frequencyMap()[key] else { return false }
        return entry.count >= 3
    }

    // MARK: - Write

    static func recordFood(_ name: String) {
        var map = frequencyMap()
        let key = name.lowercased()

        if var existing = map[key] {
            existing.count += 1
            existing.lastLogged = Date()
            map[key] = existing
        } else {
            map[key] = FoodFrequency(count: 1, lastLogged: Date())
        }

        // Prune if over limit — remove the least frequent entry (excluding the one just recorded)
        if map.count > maxEntries {
            if let leastFrequent = map
                .filter({ $0.key != key })
                .min(by: { $0.value.count < $1.value.count || ($0.value.count == $1.value.count && $0.value.lastLogged < $1.value.lastLogged) })?
                .key {
                map.removeValue(forKey: leastFrequent)
            }
        }

        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
