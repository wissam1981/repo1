@preconcurrency import Foundation
import FirebaseFunctions

// MARK: - Meal Plan Service
// Generates a full day's meal plan hitting specific macro targets using AI.

actor MealPlanService {

    static let shared = MealPlanService()

    private let functions = Functions.functions()

    private init() {}

    func generateDayPlan(targetCalories: Int, targetProtein: Int, targetCarbs: Int, targetFat: Int) async throws -> [GeneratedMeal] {
        let systemPrompt = """
        You are an expert fitness nutritionist. Generate a 1-day meal plan that hits these exact daily totals (±50 kcal, ±5g macros):
        TARGET: \(targetCalories) kcal, \(targetProtein)g Protein, \(targetCarbs)g Carbs, \(targetFat)g Fat.
        
        The plan MUST include exactly four meals: Breakfast, Lunch, Snack, and Dinner.
        Each meal must contain a list of 'items'. Each item is a distinct, real-world ingredient with realistic serving sizes.

        Return ONLY a JSON array, wrapped in ```json and ``` markers.
        The JSON must be an array of exactly 4 meal objects.
        Structure:
        [
          {
            "meal_type": "breakfast",
            "items": [
              {
                "name": "Oatmeal",
                "serving_size_g": 60,
                "calories": 230,
                "protein_g": 8,
                "carbs_g": 40,
                "fat_g": 4
              }
            ]
          }
        ]
        
        Ensure the sum of all items across all meals equals the targets precisely. Use whole foods.
        """
        
        let languageDirective = await MainActor.run {
            LanguageManager.shared.isArabic
                ? "\nIMPORTANT: Write all meal names and descriptions in Arabic (العربية)."
                : ""
        }

        let userPrompt = "Generate my meal plan for today."

        let messagesPayload: [[String: String]] = [
            ["role": "system", "content": systemPrompt + languageDirective],
            ["role": "user", "content": userPrompt]
        ]
        
        let result = try await functions.httpsCallable("openaiChat").call([
             "messages": messagesPayload,
             "model": "gpt-4o-mini"
         ])

        guard let data = result.data as? [String: Any],
              let content = data["content"] as? String else {
            throw MealPlanError.parsingError
        }

        // Extract JSON
        let cleaned: String
        if let jsonStart = content.range(of: "```json\n") {
            let afterStart = content[jsonStart.upperBound...]
            if let jsonEnd = afterStart.range(of: "```") {
                cleaned = String(afterStart[..<jsonEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                cleaned = String(afterStart).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            cleaned = content
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                 .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let planData = cleaned.data(using: .utf8) else {
            throw MealPlanError.parsingError
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let meals = try decoder.decode([GeneratedMeal].self, from: planData)
        return meals
    }
}

// MARK: - Models

struct GeneratedMeal: Codable, Identifiable, Sendable {
    var id: String { mealType }
    let mealType: String
    let items: [GeneratedMealItem]
    
    var appMealType: MealType {
        MealType(rawValue: mealType.lowercased()) ?? .snack
    }
    
    var totalCalories: Int { items.reduce(0) { $0 + Int($1.calories) } }
    var totalProtein: Int { items.reduce(0) { $0 + Int($1.proteinG) } }
    var totalCarbs: Int { items.reduce(0) { $0 + Int($1.carbsG) } }
    var totalFat: Int { items.reduce(0) { $0 + Int($1.fatG) } }
}

struct GeneratedMealItem: Codable, Identifiable, Sendable {
    var id: String { name + String(calories) }
    let name: String
    let servingSizeG: Double
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    
    func toFoodItem() -> FoodItem {
         FoodItem(
             id: "plan_\(UUID().uuidString.prefix(8))",
             name: name,
             brandName: "AI Plan",
             barcode: nil,
             fdcId: nil,
             servingSizeG: servingSizeG,
             servingUnit: "g",
             calories: calories,
             proteinG: proteinG,
             carbsG: carbsG,
             fatG: fatG,
             fiberG: 0,
             sugarG: nil,
             sodiumMg: nil,
             isVerified: false,
             isCustom: true,
             source: .custom
         )
     }
}

// MARK: - Errors

enum MealPlanError: LocalizedError {
    case networkError(String)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return "Network error: \(msg)"
        case .parsingError: return "Could not interpret the generated plan."
        }
    }
}
