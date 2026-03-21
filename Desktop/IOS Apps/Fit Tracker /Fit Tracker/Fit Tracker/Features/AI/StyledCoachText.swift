import SwiftUI

// MARK: - Styled Coach Text
// Parses AI coach responses and highlights nutrition/fitness keywords with semantic colors.
// Protein → Green, Carbs → Cyan, Fat → Orange, Calories → Rose, Water → Blue.
// Numbers with units are bolded for emphasis.

struct StyledCoachText: View {
    let text: String

    var body: some View {
        styledText()
            .font(.system(size: 17, weight: .regular))
            .lineSpacing(6)
    }

    // MARK: - Build Attributed Text

    private func styledText() -> Text {
        let words = tokenize(text)
        var result = Text("")

        for token in words {
            result = result + styledToken(token)
        }
        return result
    }

    // MARK: - Tokenizer

    /// Splits text into tokens preserving whitespace and punctuation
    private func tokenize(_ input: String) -> [String] {
        var tokens: [String] = []
        var current = ""

        for char in input {
            if char == " " || char == "\n" {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                tokens.append(String(char))
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            tokens.append(current)
        }
        return tokens
    }

    // MARK: - Style Each Token

    private func styledToken(_ token: String) -> Text {
        let stripped = token.lowercased().trimmingCharacters(in: .punctuationCharacters)

        // Whitespace passthrough
        if token == " " || token == "\n" {
            return Text(token)
        }

        // Markdown bold: **word**
        if token.hasPrefix("**") && token.hasSuffix("**") && token.count > 4 {
            let inner = String(token.dropFirst(2).dropLast(2))
            return Text(inner)
                .bold()
                .foregroundColor(ThemeColors.textPrimary)
        }

        // Numbers with units (e.g. "150g", "2000kcal", "85%", "2500ml")
        if isNumberWithUnit(stripped) {
            let color = colorForUnit(stripped)
            return Text(token)
                .bold()
                .foregroundColor(color)
        }

        // Standalone numbers (like "150" before "g")
        if isStandaloneNumber(stripped) {
            return Text(token)
                .bold()
                .foregroundColor(ThemeColors.textPrimary)
        }

        // Protein keywords
        if proteinKeywords.contains(stripped) {
            return Text(token)
                .bold()
                .foregroundColor(NutrientColor.protein)
        }

        // Carbs keywords
        if carbsKeywords.contains(stripped) {
            return Text(token)
                .bold()
                .foregroundColor(NutrientColor.carbs)
        }

        // Fat keywords
        if fatKeywords.contains(stripped) {
            return Text(token)
                .bold()
                .foregroundColor(NutrientColor.fat)
        }

        // Calories keywords
        if calorieKeywords.contains(stripped) {
            return Text(token)
                .bold()
                .foregroundColor(NutrientColor.calories)
        }

        // Water keywords
        if waterKeywords.contains(stripped) {
            return Text(token)
                .bold()
                .foregroundColor(NutrientColor.water)
        }

        // Fitness keywords
        if fitnessKeywords.contains(stripped) {
            return Text(token)
                .bold()
                .foregroundColor(NutrientColor.fitness)
        }

        // Default
        return Text(token)
            .foregroundColor(ThemeColors.textPrimary)
    }

    // MARK: - Number Detection

    private func isNumberWithUnit(_ s: String) -> Bool {
        let pattern = #"^\d+\.?\d*(g|kg|kcal|cal|ml|l|lbs|oz|%|mg|iu)$"#
        return s.range(of: pattern, options: .regularExpression) != nil
    }

    private func isStandaloneNumber(_ s: String) -> Bool {
        let pattern = #"^\d+\.?\d*$"#
        return s.range(of: pattern, options: .regularExpression) != nil
    }

    private func colorForUnit(_ s: String) -> Color {
        if s.hasSuffix("kcal") || s.hasSuffix("cal") { return NutrientColor.calories }
        if s.hasSuffix("ml") || s.hasSuffix("l") { return NutrientColor.water }
        // g could be protein, carbs, or fat — default to textPrimary bold
        return ThemeColors.textPrimary
    }

    // MARK: - Keyword Sets

    private let proteinKeywords: Set<String> = [
        "protein", "proteins", "whey", "casein", "bcaa", "amino",
        "leucine", "chicken", "turkey", "salmon", "tuna", "eggs",
        "greek yogurt", "cottage cheese"
    ]

    private let carbsKeywords: Set<String> = [
        "carbs", "carbohydrates", "carb", "fiber", "fibre",
        "glycogen", "glucose", "sugar", "sugars", "starch",
        "oats", "rice", "quinoa", "pasta"
    ]

    private let fatKeywords: Set<String> = [
        "fat", "fats", "lipids", "omega-3", "omega-6",
        "saturated", "unsaturated", "monounsaturated",
        "polyunsaturated", "trans", "avocado", "nuts", "olive"
    ]

    private let calorieKeywords: Set<String> = [
        "calories", "calorie", "kcal", "cal", "tdee", "bmr",
        "deficit", "surplus", "maintenance", "intake"
    ]

    private let waterKeywords: Set<String> = [
        "water", "hydration", "hydrate", "hydrated",
        "dehydrated", "dehydration", "fluid", "fluids"
    ]

    private let fitnessKeywords: Set<String> = [
        "workout", "exercise", "training", "rest", "recovery",
        "reps", "sets", "volume", "progressive", "overload",
        "bench", "squat", "deadlift", "push-ups", "pull-ups",
        "hiit", "cardio", "strength", "muscle", "muscles",
        "gains", "pr", "personal record"
    ]
}

// MARK: - Nutrient Colors

struct NutrientColor {
    static let protein = Color(hex: "#34d399")     // Emerald green
    static let carbs = Color(hex: "#22d3ee")       // Cyan
    static let fat = Color(hex: "#fb923c")         // Orange
    static let calories = Color(hex: "#f87171")    // Rose / Red
    static let water = Color(hex: "#38bdf8")       // Sky blue
    static let fitness = Color(hex: "#a78bfa")     // Purple / Violet
}
