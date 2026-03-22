import SwiftUI

// MARK: - Flow Layout (wraps child views across lines)

struct CoachFlowLayout: Layout {
    var horizontalSpacing: CGFloat = 0
    var verticalSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private struct ArrangeResult {
        var size: CGSize
        var positions: [CGPoint]
        var sizes: [CGSize]
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ArrangeResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            // Check if this is a line-break view (width >= maxWidth)
            if size.width >= maxWidth {
                if x > 0 {
                    y += rowHeight + verticalSpacing
                }
                positions.append(CGPoint(x: 0, y: y))
                y += verticalSpacing
                x = 0
                rowHeight = 0
                continue
            }

            if x + size.width > maxWidth && x > 0 {
                y += rowHeight + verticalSpacing
                x = 0
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        let totalHeight = y + rowHeight
        return ArrangeResult(
            size: CGSize(width: maxWidth, height: totalHeight),
            positions: positions,
            sizes: sizes
        )
    }
}

// MARK: - Styled Coach Text
// Parses AI coach responses and highlights nutrition/fitness keywords with semantic colors.
// Protein → Green, Carbs → Cyan, Fat → Orange, Calories → Rose, Water → Blue.
// Numbers with units are bolded for emphasis.

struct StyledCoachText: View {
    let text: String

    var body: some View {
        CoachFlowLayout(horizontalSpacing: 0, verticalSpacing: 6) {
            ForEach(Array(tokenize(text).enumerated()), id: \.offset) { _, token in
                tokenView(token)
            }
        }
        .font(.system(size: 17, weight: .regular))
    }

    // MARK: - Token View

    @ViewBuilder
    private func tokenView(_ token: String) -> some View {
        let stripped = token.lowercased().trimmingCharacters(in: .punctuationCharacters)

        if token == " " {
            Text(" ")
        } else if token == "\n" {
            Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
        } else if token.hasPrefix("**") && token.hasSuffix("**") && token.count > 4 {
            let inner = String(token.dropFirst(2).dropLast(2))
            Text(inner)
                .bold()
                .foregroundColor(ThemeColors.textPrimary)
        } else if isNumberWithUnit(stripped) {
            let color = colorForUnit(stripped)
            pillView(token: token, color: color)
        } else if isStandaloneNumber(stripped) {
            Text(token)
                .bold()
                .foregroundColor(ThemeColors.textPrimary)
        } else if let color = keywordColor(for: stripped) {
            pillView(token: token, color: color)
        } else {
            Text(token)
                .foregroundColor(ThemeColors.textPrimary)
        }
    }

    // MARK: - Pill View

    private func pillView(token: String, color: Color) -> some View {
        Text(token)
            .bold()
            .foregroundColor(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }

    // MARK: - Keyword Color Lookup

    private func keywordColor(for stripped: String) -> Color? {
        if proteinKeywords.contains(stripped) { return NutrientColor.protein }
        if carbsKeywords.contains(stripped) { return NutrientColor.carbs }
        if fatKeywords.contains(stripped) { return NutrientColor.fat }
        if calorieKeywords.contains(stripped) { return NutrientColor.calories }
        if waterKeywords.contains(stripped) { return NutrientColor.water }
        if fitnessKeywords.contains(stripped) { return NutrientColor.fitness }
        return nil
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
        "yogurt", "cottage"
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
        "gains", "pr"
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
