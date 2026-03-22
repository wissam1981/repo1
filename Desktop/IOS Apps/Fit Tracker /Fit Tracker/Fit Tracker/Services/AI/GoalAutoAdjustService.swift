import Foundation

// MARK: - Goal Auto-Adjust Service
// Analyzes 14 days of nutrition + weight trends and suggests calorie/macro adjustments.

struct GoalAutoAdjustService {

    // MARK: - Suggestion Model

    struct GoalAdjustmentSuggestion: Identifiable {
        let id = UUID()
        let newCalories: Int
        let newProteinG: Int
        let newCarbsG: Int
        let newFatG: Int
        let reason: String
        let icon: String
        let severity: Severity

        enum Severity {
            case info, warning
        }
    }

    // MARK: - Analyze Trends

    /// Analyzes 14 days of nutrition data and returns a suggestion if adjustment is needed
    static func analyze(
        user: UserProfile,
        coreDataService: CoreDataService
    ) -> GoalAdjustmentSuggestion? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Fetch last 14 days of nutrition logs
        var dailyIntakes: [(calories: Int, protein: Int, carbs: Int, fat: Int)] = []

        for dayOffset in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            if let log = coreDataService.fetchNutritionLogDomain(for: date) {
                let cals = Int(log.totalCalories)
                // Only count days with actual food logged
                if cals > 200 {
                    dailyIntakes.append((
                        calories: cals,
                        protein: Int(log.totalProteinG),
                        carbs: Int(log.totalCarbsG),
                        fat: Int(log.totalFatG)
                    ))
                }
            }
        }

        // Need at least 7 days of data to make a suggestion
        guard dailyIntakes.count >= 7 else { return nil }

        let avgCalories = dailyIntakes.map(\.calories).reduce(0, +) / dailyIntakes.count
        let avgProtein = dailyIntakes.map(\.protein).reduce(0, +) / dailyIntakes.count

        let targetCalories = user.targetCalories
        let calorieDeviation = Double(avgCalories - targetCalories) / Double(targetCalories)

        // Check for consistent under-eating (>15% below target for 7+ days)
        if calorieDeviation < -0.15 {
            let daysUnder = dailyIntakes.filter { $0.calories < Int(Double(targetCalories) * 0.85) }.count
            if daysUnder >= 7 {
                let suggestedCalories = max(1200, targetCalories - 200)
                let ratio = Double(suggestedCalories) / Double(targetCalories)

                return GoalAdjustmentSuggestion(
                    newCalories: suggestedCalories,
                    newProteinG: max(user.targetProteinG, Int(Double(user.targetProteinG) * ratio)),
                    newCarbsG: Int(Double(user.targetCarbsG) * ratio),
                    newFatG: Int(Double(user.targetFatG) * ratio),
                    reason: "You've been eating ~\(avgCalories) cal/day (target: \(targetCalories)). Consider lowering your target to make it more achievable.",
                    icon: "arrow.down.circle.fill",
                    severity: .info
                )
            }
        }

        // Check for consistent over-eating (>15% above target)
        if calorieDeviation > 0.15 {
            let daysOver = dailyIntakes.filter { $0.calories > Int(Double(targetCalories) * 1.15) }.count
            if daysOver >= 7 {
                let suggestedCalories = targetCalories + 200

                return GoalAdjustmentSuggestion(
                    newCalories: suggestedCalories,
                    newProteinG: user.targetProteinG,
                    newCarbsG: Int(Double(user.targetCarbsG) * Double(suggestedCalories) / Double(targetCalories)),
                    newFatG: Int(Double(user.targetFatG) * Double(suggestedCalories) / Double(targetCalories)),
                    reason: "You're averaging ~\(avgCalories) cal/day (target: \(targetCalories)). Your target may be too restrictive.",
                    icon: "arrow.up.circle.fill",
                    severity: .warning
                )
            }
        }

        // Check for low protein (consistently >20% below target)
        let proteinDeviation = Double(avgProtein - user.targetProteinG) / Double(user.targetProteinG)
        if proteinDeviation < -0.2 {
            let daysLowProtein = dailyIntakes.filter { $0.protein < Int(Double(user.targetProteinG) * 0.8) }.count
            if daysLowProtein >= 7 {
                return GoalAdjustmentSuggestion(
                    newCalories: targetCalories,
                    newProteinG: max(50, user.targetProteinG - 15),
                    newCarbsG: user.targetCarbsG,
                    newFatG: user.targetFatG,
                    reason: "You're averaging \(avgProtein)g protein/day (target: \(user.targetProteinG)g). Let's set a more realistic protein goal.",
                    icon: "exclamationmark.triangle.fill",
                    severity: .warning
                )
            }
        }

        return nil
    }
}
