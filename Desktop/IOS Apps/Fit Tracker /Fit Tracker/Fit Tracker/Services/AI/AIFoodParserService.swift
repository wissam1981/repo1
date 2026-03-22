import Foundation

// MARK: - Parsed Food Item
/// Intermediate model representing a single food item parsed by AI.
/// Contains per-100g nutrition data and an optional database match.

struct ParsedFoodItem: Identifiable {
    let id: String
    var name: String
    var nameAr: String?
    var quantity: Int
    var servingSizeG: Double
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var fiberPer100g: Double

    var databaseMatch: FoodItem?

    /// User-editable weight override in grams. When set, overrides the AI quantity * servingSizeG.
    var customGrams: Double?

    var isAIEstimated: Bool { databaseMatch == nil }

    /// Default total serving in grams (quantity * single serving)
    var defaultServingG: Double { Double(quantity) * servingSizeG }

    /// Effective total grams — uses customGrams if user edited, otherwise default
    var effectiveGrams: Double { customGrams ?? defaultServingG }

    /// Computed calories based on effective grams
    var effectiveCalories: Double {
        if let match = databaseMatch {
            guard match.servingSizeG > 0 else { return match.calories }
            return match.calories * (effectiveGrams / match.servingSizeG)
        }
        return caloriesPer100g * effectiveGrams / 100
    }

    /// Computed protein based on effective grams
    var effectiveProtein: Double {
        if let match = databaseMatch {
            guard match.servingSizeG > 0 else { return match.proteinG }
            return match.proteinG * (effectiveGrams / match.servingSizeG)
        }
        return proteinPer100g * effectiveGrams / 100
    }

    /// Computed carbs based on effective grams
    var effectiveCarbs: Double {
        if let match = databaseMatch {
            guard match.servingSizeG > 0 else { return match.carbsG }
            return match.carbsG * (effectiveGrams / match.servingSizeG)
        }
        return carbsPer100g * effectiveGrams / 100
    }

    /// Computed fat based on effective grams
    var effectiveFat: Double {
        if let match = databaseMatch {
            guard match.servingSizeG > 0 else { return match.fatG }
            return match.fatG * (effectiveGrams / match.servingSizeG)
        }
        return fatPer100g * effectiveGrams / 100
    }

    /// Convert to FoodItem for logging.
    /// Uses effectiveGrams for the serving size.
    func toFoodItem() -> FoodItem {
        if let match = databaseMatch {
            var adjusted = match
            adjusted.servingSizeG = effectiveGrams
            adjusted.calories = effectiveCalories
            adjusted.proteinG = effectiveProtein
            adjusted.carbsG = effectiveCarbs
            adjusted.fatG = effectiveFat
            if match.servingSizeG > 0 {
                adjusted.fiberG = match.fiberG * (effectiveGrams / match.servingSizeG)
            }
            return adjusted
        }
        return FoodItem(
            id: UUID().uuidString,
            name: name,
            nameAr: nameAr,
            servingSizeG: effectiveGrams,
            servingUnit: "g",
            calories: caloriesPer100g * effectiveGrams / 100,
            proteinG: proteinPer100g * effectiveGrams / 100,
            carbsG: carbsPer100g * effectiveGrams / 100,
            fatG: fatPer100g * effectiveGrams / 100,
            fiberG: fiberPer100g * effectiveGrams / 100,
            sugarG: nil,
            sodiumMg: nil,
            isVerified: false,
            isCustom: false,
            source: .custom
        )
    }

    /// Quantity for logging — returns grams. addEntry() expects grams.
    var loggingQuantity: Double {
        return effectiveGrams
    }
}

// MARK: - AI JSON Response Model (private)

private struct AIFoodParseResponse: Decodable {
    let items: [AIFoodItem]

    struct AIFoodItem: Decodable {
        let name: String
        let nameAr: String?
        let quantity: Int
        let servingSizeG: Double
        let caloriesPer100g: Double
        let proteinPer100g: Double
        let carbsPer100g: Double
        let fatPer100g: Double
        let fiberPer100g: Double
    }
}

// MARK: - AI Food Parser Service
/// Parses natural language meal descriptions into structured food items using AI.

struct AIFoodParserService {

    private let aiCoachService = AICoachService()

    /// Parse a meal description into individual food items.
    /// Attempts to match each item against the local food database.
    func parseMeal(description: String, nutritionService: NutritionService) async throws -> [ParsedFoodItem] {
        // 1. Send to AI
        let systemPrompt = """
        You are a food nutrition parser. Given a natural language description of a meal (in English or Arabic), parse it into individual food items with estimated nutrition data.

        Respond with ONLY valid JSON, no markdown, no explanation, no code fences.

        The JSON must match this structure:
        {
          "items": [
            {
              "name": "English name",
              "nameAr": "Arabic name or null",
              "quantity": 1,
              "servingSizeG": 100,
              "caloriesPer100g": 0,
              "proteinPer100g": 0,
              "carbsPer100g": 0,
              "fatPer100g": 0,
              "fiberPer100g": 0
            }
          ]
        }

        Rules:
        1. Parse each distinct food item separately.
        2. quantity is the count (e.g., 2 eggs = quantity 2).
        3. servingSizeG is grams per single unit (1 egg = 46g).
        4. All nutrition values are per 100 grams.
        5. Use common nutritional data. Be accurate.
        6. If input is Arabic, still provide English name. Provide nameAr for all items.
        7. If quantity is not specified, assume 1.
        """

        let languageDirective = await MainActor.run {
            LanguageManager.shared.isArabic
                ? "\nIMPORTANT: Provide food names in Arabic and use Arabic for any descriptive text."
                : ""
        }

        let userPrompt = "Parse this meal: \(description)"

        let rawResponse = try await aiCoachService.generateJSON(
            systemPrompt: systemPrompt + languageDirective,
            userPrompt: userPrompt
        )

        // 2. Clean and decode JSON
        let cleaned = rawResponse
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw AIFoodParserError.invalidResponse
        }

        let parsed: AIFoodParseResponse
        do {
            parsed = try JSONDecoder().decode(AIFoodParseResponse.self, from: jsonData)
        } catch {
            throw AIFoodParserError.decodingFailed(error.localizedDescription)
        }

        guard !parsed.items.isEmpty else {
            throw AIFoodParserError.noItemsParsed
        }

        // 3. Convert to ParsedFoodItem and attempt database matching
        var results: [ParsedFoodItem] = []

        for aiItem in parsed.items {
            var parsedItem = ParsedFoodItem(
                id: UUID().uuidString,
                name: aiItem.name,
                nameAr: aiItem.nameAr,
                quantity: aiItem.quantity,
                servingSizeG: aiItem.servingSizeG,
                caloriesPer100g: aiItem.caloriesPer100g,
                proteinPer100g: aiItem.proteinPer100g,
                carbsPer100g: aiItem.carbsPer100g,
                fatPer100g: aiItem.fatPer100g,
                fiberPer100g: aiItem.fiberPer100g
            )

            // 4. Try to match against local database (silently skip on error)
            if let dbMatch = try? await nutritionService.searchFoods(query: aiItem.name).first {
                let dbNameLower = dbMatch.name.lowercased()
                let aiNameLower = aiItem.name.lowercased()
                if dbNameLower.contains(aiNameLower) || aiNameLower.contains(dbNameLower) {
                    parsedItem.databaseMatch = dbMatch
                }
            }

            results.append(parsedItem)
        }

        return results
    }
}

// MARK: - Errors

enum AIFoodParserError: LocalizedError {
    case invalidResponse
    case decodingFailed(String)
    case noItemsParsed

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Could not understand the meal. Try describing it differently."
        case .decodingFailed:
            return "Could not understand the meal. Try describing it differently."
        case .noItemsParsed:
            return "No food items found in your description."
        }
    }
}
