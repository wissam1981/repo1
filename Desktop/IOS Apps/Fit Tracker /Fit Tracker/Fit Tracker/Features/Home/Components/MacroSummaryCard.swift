import SwiftUI

// MARK: - Macro Summary Card
// Horizontal card showing protein, carbs, fat progress.

struct MacroSummaryCard: View {
    let proteinConsumed: Int
    let proteinTarget: Int
    let proteinProgress: Double

    let carbsConsumed: Int
    let carbsTarget: Int
    let carbsProgress: Double

    let fatConsumed: Int
    let fatTarget: Int
    let fatProgress: Double

    var body: some View {
        HStack(spacing: 12) {
            macroPill(
                name: "Protein",
                consumed: proteinConsumed,
                target: proteinTarget,
                progress: proteinProgress,
                color: ThemeColors.primary
            )

            macroPill(
                name: "Carbs",
                consumed: carbsConsumed,
                target: carbsTarget,
                progress: carbsProgress,
                color: ThemeColors.success
            )

            macroPill(
                name: "Fat",
                consumed: fatConsumed,
                target: fatTarget,
                progress: fatProgress,
                color: ThemeColors.secondary
            )
        }
    }

    private func macroPill(
        name: String,
        consumed: Int,
        target: Int,
        progress: Double,
        color: Color
    ) -> some View {
        VStack(spacing: 12) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 5)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(progress > 0 ? 0.5 : 0), radius: 5, x: 0, y: 0)
                    .animation(.spring(response: 0.6), value: progress)

                Text("\(consumed)")
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
            }

            VStack(spacing: 2) {
                Text(name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("\(target)g goal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}
