import SwiftUI

// MARK: - Food Log Row View
// Single entry row inside a meal section with colored macro indicators.

struct FoodLogRowView: View {
    let entry: NutritionEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.foodName)
                    .font(.subheadline)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Text(servingText)
                        .foregroundStyle(.tertiary)

                    macroChip(value: Int(entry.proteinG), label: "P", color: .orange)
                    macroChip(value: Int(entry.carbsG), label: "C", color: .green)
                    macroChip(value: Int(entry.fatG), label: "F", color: .purple)
                }
                .font(.caption2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(Int(entry.calories))")
                    .font(.subheadline.bold().monospacedDigit())
                Text("kcal")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func macroChip(value: Int, label: String, color: Color) -> some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text("\(label) \(value)g")
                .foregroundStyle(.secondary)
        }
    }

    private var servingText: String {
        let qty = entry.servingQuantity
        if qty == floor(qty) {
            return "\(Int(qty)) \(entry.servingUnit)"
        }
        return String(format: "%.1f %@", qty, entry.servingUnit)
    }
}
