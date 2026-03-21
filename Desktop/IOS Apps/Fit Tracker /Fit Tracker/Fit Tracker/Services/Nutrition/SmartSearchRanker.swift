import Foundation

// MARK: - Smart Search Ranker
/// Reorders food search results based on user habits and current macro needs.
/// Pure function — no side effects, no dependencies on ViewModels.

struct SmartSearchRanker {

    static func rank(
        _ results: [FoodItem],
        frequencyMap: [String: FoodFrequency],
        remainingCalories: Int,
        remainingProteinG: Int,
        remainingCarbsG: Int,
        remainingFatG: Int,
        query: String
    ) -> [FoodItem] {
        guard !results.isEmpty, !frequencyMap.isEmpty else { return results }

        let queryLower = query.lowercased()

        let scored = results.enumerated().map { index, food -> (food: FoodItem, score: Int, originalIndex: Int) in
            var score = 0
            let nameLower = food.name.lowercased()

            // +50 if frequently logged (3+ times)
            if let freq = frequencyMap[nameLower], freq.count >= 3 {
                score += 50
            }

            // +20 if logged in the last 3 days
            if let freq = frequencyMap[nameLower] {
                let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: .now)!
                if freq.lastLogged > threeDaysAgo {
                    score += 20
                }
            }

            // +10 if food is high in the user's most-needed macro
            let maxRemaining = max(remainingProteinG, remainingCarbsG, remainingFatG)
            if maxRemaining > 0 {
                if remainingProteinG == maxRemaining && food.proteinG > 15 {
                    score += 10
                } else if remainingCarbsG == maxRemaining && food.carbsG > 20 {
                    score += 10
                } else if remainingFatG == maxRemaining && food.fatG > 10 {
                    score += 10
                }
            }

            // +5 for exact name match with query
            if nameLower == queryLower {
                score += 5
            }

            return (food, score, index)
        }

        // Stable sort: items with equal scores keep their original order
        let sorted = scored.sorted { a, b in
            if a.score != b.score { return a.score > b.score }
            return a.originalIndex < b.originalIndex
        }

        return sorted.map(\.food)
    }
}
