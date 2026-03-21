import SwiftUI

// MARK: - Calorie Ring View
// Canvas-drawn circular progress ring showing daily calorie consumption
// with macro breakdown, goal context, BMR/TDEE, and meal breakdown.

struct CalorieRingView: View {
    let consumed: Int
    let target: Int
    let progress: Double

    // Macros
    let proteinConsumed: Int
    let proteinTarget: Int
    let carbsConsumed: Int
    let carbsTarget: Int
    let fatConsumed: Int
    let fatTarget: Int

    // Goal context
    let fitnessGoal: FitnessGoal
    let activityLevel: ActivityLevel
    let bmr: Int
    let tdee: Int
    let dailyDeficit: Int

    // Meal breakdown
    let breakfastCal: Int
    let lunchCal: Int
    let dinnerCal: Int
    let snackCal: Int

    @Environment(AppRouter.self) private var router

    private let lineWidth: CGFloat = 20
    private let ringSize: CGFloat = 180

    var body: some View {
        VStack(spacing: 20) {
            // Header with goal badge
            headerSection

            // Ring
            ringSection

            // Remaining footer
            remainingFooter

            // Divider
            thinDivider

            // Macro breakdown
            macroSection

            // Divider
            thinDivider

            // Goal context info
            goalContextSection

            // Divider
            thinDivider

            // Meal breakdown
            mealBreakdownSection
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [ThemeColors.primaryDark.opacity(0.8), Color(red: 0.1, green: 0.0, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
        .animation(.spring(response: 0.5), value: consumed)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Text("Daily Calorie Goal")
                    .font(.headline)
                    .foregroundStyle(ThemeColors.textPrimary)

                Button {
                    router.pushHome(HomeDestination.instructions)
                } label: {
                    Image(systemName: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(ThemeColors.textSecondary)
                }
            }
            Spacer()
            // Goal type badge
            HStack(spacing: 4) {
                Image(systemName: fitnessGoal.icon)
                    .font(.caption2)
                Text(fitnessGoal.displayName)
                    .font(.caption2.bold())
            }
            .foregroundStyle(goalBadgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(goalBadgeColor.opacity(0.15))
            .clipShape(Capsule())
        }
    }

    private var goalBadgeColor: Color {
        switch fitnessGoal {
        case .lose:     return ThemeColors.info
        case .maintain: return ThemeColors.primary
        case .gain:     return ThemeColors.secondary
        }
    }

    // MARK: - Ring

    private var ringSection: some View {
        ZStack {
            Circle()
                .stroke(ThemeColors.surfaceBorder, lineWidth: lineWidth)
                .frame(width: ringSize, height: ringSize)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [ThemeColors.info, ThemeColors.primary, ThemeColors.secondary, ThemeColors.info]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .shadow(color: ThemeColors.primary.opacity(progress > 0 ? 0.6 : 0), radius: 10, x: 0, y: 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)

            VStack(spacing: 2) {
                Text("\(consumed)")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(ThemeColors.textPrimary)
                    .contentTransition(.numericText())

                Text("of \(target)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeColors.textSecondary)

                Text("kcal")
                    .font(.caption2.bold())
                    .foregroundStyle(ThemeColors.textSecondary)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Remaining Footer

    private var remainingFooter: some View {
        let remaining = max(0, target - consumed)
        return HStack {
            Spacer()
            Text("\(remaining) kcal remaining")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ThemeColors.textSecondary)
            Spacer()
        }
        .padding(.vertical, 8)
        .background(ThemeColors.surfaceColor)
        .clipShape(Capsule())
    }

    // MARK: - Macro Breakdown

    private var macroSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Macros")
                    .font(.subheadline.bold())
                    .foregroundStyle(ThemeColors.textPrimary)
                Spacer()
            }

            HStack(spacing: 12) {
                macroBar(label: "Protein", consumed: proteinConsumed, target: proteinTarget, color: ThemeColors.primary, unit: "g")
                macroBar(label: "Carbs", consumed: carbsConsumed, target: carbsTarget, color: ThemeColors.success, unit: "g")
                macroBar(label: "Fat", consumed: fatConsumed, target: fatTarget, color: ThemeColors.secondary, unit: "g")
            }
        }
    }

    private func macroBar(label: String, consumed: Int, target: Int, color: Color, unit: String) -> some View {
        let prog = target > 0 ? min(Double(consumed) / Double(target), 1.0) : 0.0
        return VStack(spacing: 6) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(ThemeColors.textSecondary)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(ThemeColors.surfaceColor)
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: max(0, CGFloat(prog) * 80), height: 6)
                    .animation(.spring(response: 0.6), value: consumed)
            }
            .frame(width: 80)

            Text("\(consumed)/\(target)\(unit)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Goal Context

    private var goalContextSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Your Plan")
                    .font(.subheadline.bold())
                    .foregroundStyle(ThemeColors.textPrimary)
                Spacer()
            }

            HStack(spacing: 0) {
                infoTile(
                    icon: "bolt.heart.fill",
                    label: "BMR",
                    value: "\(bmr)",
                    color: ThemeColors.info
                )
                infoTile(
                    icon: "flame.fill",
                    label: "TDEE",
                    value: "\(tdee)",
                    color: ThemeColors.primary
                )
                infoTile(
                    icon: dailyDeficit < 0 ? "arrow.down.right" : (dailyDeficit > 0 ? "arrow.up.right" : "equal"),
                    label: dailyDeficit < 0 ? "Deficit" : (dailyDeficit > 0 ? "Surplus" : "Balance"),
                    value: "\(abs(dailyDeficit))",
                    color: dailyDeficit < 0 ? ThemeColors.info : (dailyDeficit > 0 ? ThemeColors.success : ThemeColors.primary)
                )
            }

            // Activity level row
            HStack(spacing: 6) {
                Image(systemName: activityLevel.icon)
                    .font(.caption2)
                    .foregroundStyle(ThemeColors.primary.opacity(0.8))
                Text(activityLevel.displayName)
                    .font(.caption2)
                    .foregroundStyle(ThemeColors.textSecondary)
                Spacer()
                if fitnessGoal != .maintain {
                    Text("\(String(format: "%.2f", abs(goalSpeedKgPerWeek))) kg/week")
                        .font(.caption2)
                        .foregroundStyle(ThemeColors.textSecondary)
                }
            }
            .padding(.top, 2)
        }
    }

    private var goalSpeedKgPerWeek: Double {
        Double(abs(dailyDeficit)) * 7.0 / 7700.0
    }

    private func infoTile(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(ThemeColors.textPrimary)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(ThemeColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(ThemeColors.surfaceColor))
    }

    // MARK: - Meal Breakdown

    private var mealBreakdownSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Meals")
                    .font(.subheadline.bold())
                    .foregroundStyle(ThemeColors.textPrimary)
                Spacer()
            }

            VStack(spacing: 6) {
                mealRow(icon: "sun.horizon.fill", label: "Breakfast", calories: breakfastCal, color: .orange)
                mealRow(icon: "sun.max.fill", label: "Lunch", calories: lunchCal, color: .yellow)
                mealRow(icon: "moon.fill", label: "Dinner", calories: dinnerCal, color: ThemeColors.info)
                mealRow(icon: "fork.knife", label: "Snacks", calories: snackCal, color: ThemeColors.primary)
            }
        }
    }

    private func mealRow(icon: String, label: String, calories: Int, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 20)

            Text(label)
                .font(.caption)
                .foregroundStyle(ThemeColors.textSecondary)

            Spacer()

            // Mini bar
            let barProg = target > 0 ? min(CGFloat(calories) / CGFloat(target), 1.0) : 0.0
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(ThemeColors.surfaceColor)
                    .frame(width: 60, height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.8))
                    .frame(width: max(0, barProg * 60), height: 4)
            }

            Text("\(calories)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(ThemeColors.textSecondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(ThemeColors.surfaceColor))
    }

    // MARK: - Divider

    private var thinDivider: some View {
        Rectangle()
            .fill(ThemeColors.surfaceBorder)
            .frame(height: 1)
    }
}
