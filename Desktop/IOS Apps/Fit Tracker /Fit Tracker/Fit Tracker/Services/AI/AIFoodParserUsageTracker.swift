import Foundation

// MARK: - AI Food Parser Usage Tracker
/// Tracks AI food parse usage during the 7-day trial.
/// Trial users get 3 total AI parses. Premium users are unlimited.
/// Follows the same pattern as BarcodeScanUsageTracker.

struct AIFoodParserUsageTracker {

    static let trialLimit = 3

    private static let countKey = "ai_food_parse_count"

    // MARK: - Public API

    /// Whether the user can perform another AI food parse.
    static func canParse(isPremium: Bool) -> Bool {
        if isPremium { return true }
        return currentCount() < trialLimit
    }

    /// Number of AI parses remaining (for display). Returns nil for premium users.
    static func parsesRemaining(isPremium: Bool) -> Int? {
        if isPremium { return nil }
        return max(0, trialLimit - currentCount())
    }

    /// Record a completed AI food parse.
    static func recordParse() {
        UserDefaults.standard.set(currentCount() + 1, forKey: countKey)
    }

    // MARK: - Internals

    private static func currentCount() -> Int {
        UserDefaults.standard.integer(forKey: countKey)
    }
}
