import Foundation

// MARK: - Meal Pattern

struct MealPattern {
    let mealType: MealType
    let entries: [NutritionEntry]    // The frequent food entries with original portions
    let totalCalories: Double        // Sum of their calories
    let frequency: Int               // How many of the last 14 days this pattern appeared
}

// MARK: - Meal Pattern Service
/// Analyzes the last 14 days of nutrition logs to find recurring meal patterns.
/// Returns patterns for meals the user eats frequently (3+ times in 14 days).

struct MealPatternService {

    /// Analyze recent logs and return patterns grouped by meal type.
    /// Only returns patterns where the user has eaten the same foods 3+ times.
    static func detectPatterns(from logs: [NutritionLog]) -> [MealType: MealPattern] {
        var result: [MealType: MealPattern] = [:]

        for mealType in MealType.allCases {
            if let pattern = findPattern(for: mealType, in: logs) {
                result[mealType] = pattern
            }
        }

        return result
    }

    /// Find the most common foods for a given meal type.
    private static func findPattern(for mealType: MealType, in logs: [NutritionLog]) -> MealPattern? {
        // Collect all entries for this meal type across all logs
        let allEntries = logs.flatMap { $0.entries.filter { $0.mealType == mealType } }

        guard !allEntries.isEmpty else { return nil }

        // Count frequency of each food (by foodItemId)
        var frequencyByFoodId: [String: Int] = [:]
        var latestEntryByFoodId: [String: NutritionEntry] = [:]

        for entry in allEntries {
            frequencyByFoodId[entry.foodItemId, default: 0] += 1
            // Keep the most recent entry for each food (has latest portion/macros)
            if let existing = latestEntryByFoodId[entry.foodItemId] {
                if entry.loggedAt > existing.loggedAt {
                    latestEntryByFoodId[entry.foodItemId] = entry
                }
            } else {
                latestEntryByFoodId[entry.foodItemId] = entry
            }
        }

        // Filter to foods eaten 3+ times
        let frequentFoodIds = frequencyByFoodId.filter { $0.value >= 3 }.map(\.key)

        guard !frequentFoodIds.isEmpty else { return nil }

        // Get the top 3 most frequent foods
        let topFoodIds = frequentFoodIds
            .sorted { frequencyByFoodId[$0]! > frequencyByFoodId[$1]! }
            .prefix(3)

        let patternEntries = topFoodIds.compactMap { latestEntryByFoodId[$0] }

        guard !patternEntries.isEmpty else { return nil }

        // Count how many unique days this meal type had ANY of these foods
        let daysWithPattern = Set(
            logs.filter { log in
                log.entries.contains { entry in
                    entry.mealType == mealType && frequentFoodIds.contains(entry.foodItemId)
                }
            }.map { Calendar.current.startOfDay(for: $0.date) }
        ).count

        let totalCalories = patternEntries.reduce(0) { $0 + $1.calories }

        return MealPattern(
            mealType: mealType,
            entries: Array(patternEntries),
            totalCalories: totalCalories,
            frequency: daysWithPattern
        )
    }
}
