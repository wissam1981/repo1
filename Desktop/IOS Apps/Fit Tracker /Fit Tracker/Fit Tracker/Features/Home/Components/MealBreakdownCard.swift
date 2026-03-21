import SwiftUI

// MARK: - Meal Breakdown Card (Carousel Slide 3)
// Dynamic list showing calorie contribution from different meals.

struct MealBreakdownCard: View {
    let breakfast: Int
    let lunch: Int
    let dinner: Int
    let snacks: Int
    let target: Int

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Daily Meals")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(ThemeColors.textPrimary)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(ThemeColors.secondary.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "calendar.day.timeline.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ThemeColors.secondary)
                }
            }

            VStack(spacing: 12) {
                mealItem(title: "Breakfast", calories: breakfast, icon: "sun.horizon.fill", color: .orange)
                mealItem(title: "Lunch", calories: lunch, icon: "sun.max.fill", color: .yellow)
                mealItem(title: "Dinner", calories: dinner, icon: "moon.fill", color: ThemeColors.info)
                mealItem(title: "Snacks", calories: snacks, icon: "fork.knife", color: ThemeColors.primary)
            }

            Spacer()
        }
        .padding(22)
        .background(ThemeColors.surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [ThemeColors.surfaceBorder, ThemeColors.surfaceBorder],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func mealItem(title: String, calories: Int, icon: String, color: Color) -> some View {
        let progress = target > 0 ? min(Double(calories) / Double(target), 1.0) : 0.0

        return HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(ThemeColors.textPrimary)
                    Spacer()
                    Text("\(calories)")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(ThemeColors.textPrimary)
                    Text("kcal")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ThemeColors.textSecondary)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(ThemeColors.surfaceColor)
                            .frame(height: 6)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(3, geo.size.width * CGFloat(progress)), height: 6)
                            .shadow(color: color.opacity(0.3), radius: 4)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ThemeColors.surfaceColor)
        )
    }
}

#Preview {
    ZStack {
        ThemeColors.backgroundDark.ignoresSafeArea()
        MealBreakdownCard(
            breakfast: 450,
            lunch: 700,
            dinner: 600,
            snacks: 200,
            target: 2000
        )
        .padding()
        .frame(height: 320)
    }
}
