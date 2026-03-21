import SwiftUI

struct CalorieDeficitCard: View {
    let consumed: Int
    let burned: Int // total burn: tdee + active
    let deficit: Int
    let fitnessGoal: FitnessGoal

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Energy Balance")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(ThemeColors.textPrimary)
                Spacer()

                statusBadge
            }

            // Main Stats Row
            HStack(spacing: 0) {
                // Eaten
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ThemeColors.secondary)
                        Text("Eaten")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                    Text("\(consumed)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(ThemeColors.textPrimary)
                    Text("kcal")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Deficit Indicator
                VStack(spacing: 5) {
                    Text(deficit >= 0 ? "Deficit" : "Surplus")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(deficitColor.opacity(0.9))

                    Text("\(abs(deficit))")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(deficitColor)

                    Text("kcal")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(deficitColor.opacity(0.6))
                }
                .frame(width: 110)
                .padding(.vertical, 10)
                .background(
                    Circle()
                        .fill(deficitColor.opacity(0.1))
                        .blur(radius: 12)
                )

                // Burned
                VStack(alignment: .trailing, spacing: 5) {
                    HStack(spacing: 6) {
                        Text("Burned")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(ThemeColors.textSecondary)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ThemeColors.error)
                    }
                    Text("\(burned)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(ThemeColors.textPrimary)
                    Text("kcal")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 8)

            // Comparison Bar
            comparisonBar

            // Helpful Insight
            HStack(spacing: 10) {
                Image(systemName: deficit >= 0 ? "sparkles" : "info.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(deficitColor)
                Text(insightText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .lineSpacing(2)
                Spacer()
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(ThemeColors.surfaceColor))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            ZStack {
                ThemeColors.surfaceColor

                // Subtle gradient glow
                RadialGradient(
                    colors: [deficitColor.opacity(0.15), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 150
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [ThemeColors.surfaceBorder, .clear, ThemeColors.surfaceBorder],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var deficitColor: Color {
        if deficit < 0 {
            return ThemeColors.error
        } else if deficit > 0 {
            return ThemeColors.info
        } else {
            return ThemeColors.primary
        }
    }

    private var statusBadge: some View {
        let isGood = (fitnessGoal == .lose && deficit > 0) ||
                    (fitnessGoal == .gain && deficit < 0) ||
                    (fitnessGoal == .maintain && abs(deficit) < 200)

        return HStack(spacing: 5) {
            Image(systemName: isGood ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
            Text(isGood ? "On Track" : "Adjusting")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(isGood ? ThemeColors.success : Color.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isGood ? ThemeColors.success.opacity(0.12) : Color.orange.opacity(0.12))
        .clipShape(Capsule())
    }

    private var comparisonBar: some View {
        GeometryReader { geo in
            let total = Double(max(consumed + burned, 1))
            let consumedWidth = CGFloat(Double(consumed) / total) * geo.size.width
            let burnedWidth = CGFloat(Double(burned) / total) * geo.size.width

            HStack(spacing: 3) {
                // Eaten bar
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.secondary.opacity(0.8), ThemeColors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(3, consumedWidth))

                // Burned bar
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.error, ThemeColors.error.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(3, burnedWidth))
            }
            .clipShape(Capsule())
        }
        .frame(height: 10)
    }

    private var insightText: String {
        if deficit > 0 {
            return "You've burned \(abs(deficit)) more calories than you've eaten today. Great work!"
        } else if deficit < 0 {
            return "Intake is currently higher than burn. Consider some extra activity!"
        } else {
            return "Perfect balance! You're exactly meeting your body's energy needs."
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CalorieDeficitCard(
            consumed: 1800,
            burned: 2400,
            deficit: -600,
            fitnessGoal: .lose
        )
        .padding()
    }
}
