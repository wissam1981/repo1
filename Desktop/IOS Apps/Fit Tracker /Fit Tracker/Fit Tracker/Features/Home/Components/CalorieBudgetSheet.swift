import SwiftUI

// MARK: - Calorie Budget Sheet
/// Bottom sheet showing remaining calories and macros with an AI suggestion button.

struct CalorieBudgetSheet: View {
    let consumed: Int
    let target: Int
    let proteinConsumed: Int
    let proteinTarget: Int
    let carbsConsumed: Int
    let carbsTarget: Int
    let fatConsumed: Int
    let fatTarget: Int

    let onGetAISuggestions: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var remaining: Int { max(0, target - consumed) }
    private var proteinRemaining: Int { max(0, proteinTarget - proteinConsumed) }
    private var carbsRemaining: Int { max(0, carbsTarget - carbsConsumed) }
    private var fatRemaining: Int { max(0, fatTarget - fatConsumed) }

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(ThemeColors.textSecondary)
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            Text("Today's Budget")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(ThemeColors.textPrimary)

            VStack(spacing: 4) {
                Text("\(remaining)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(ThemeColors.primary)
                Text("kcal remaining")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
            }

            VStack(spacing: 16) {
                macroRow("Protein", consumed: proteinConsumed, target: proteinTarget, remaining: proteinRemaining, color: .blue)
                macroRow("Carbs", consumed: carbsConsumed, target: carbsTarget, remaining: carbsRemaining, color: .orange)
                macroRow("Fat", consumed: fatConsumed, target: fatTarget, remaining: fatRemaining, color: .red)
            }
            .padding(.horizontal, 20)

            Button {
                dismiss()
                onGetAISuggestions()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                    Text("Get AI Suggestions")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(ThemeColors.primary)
                        .shadow(color: ThemeColors.primary.opacity(0.3), radius: 10, y: 5)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.top, 8)
        .background(ThemeColors.backgroundDark.ignoresSafeArea())
    }

    private func macroRow(_ label: String, consumed: Int, target: Int, remaining: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ThemeColors.textPrimary)
                Spacer()
                Text("\(consumed)g / \(target)g")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
                Text("(\(remaining)g left)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ThemeColors.surfaceColor)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * min(1.0, target > 0 ? Double(consumed) / Double(target) : 0), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
