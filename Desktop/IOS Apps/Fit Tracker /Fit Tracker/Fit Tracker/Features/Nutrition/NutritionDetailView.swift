import SwiftUI

// MARK: - Nutrition Detail View
// Deep-dive nutrition breakdown with Calories, Nutrients, and Macros tabs.
// Similar to MFP's Nutrition screen showing Total / Goal / Left for every nutrient.

struct NutritionDetailView: View {
    @Bindable var viewModel: NutritionViewModel
    @State private var selectedTab: NutrientTab = .calories
    @State private var appeared = false

    enum NutrientTab: String, CaseIterable {
        case calories = "Calories"
        case nutrients = "Nutrients"
        case macros = "Macros"
    }

    var body: some View {
        ZStack {
            ThemeColors.backgroundDark.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Date & day navigation
                    dateHeader

                    // Tab selector
                    tabSelector

                    // Tab content
                    switch selectedTab {
                    case .calories:
                        caloriesTab
                    case .nutrients:
                        nutrientsTab
                    case .macros:
                        macrosTab
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack {
            Button {
                viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.selectedDate) ?? viewModel.selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption.bold())
                    .foregroundStyle(ThemeColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(ThemeColors.surfaceColor))
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Day View")
                    .font(.caption2)
                    .foregroundStyle(ThemeColors.textSecondary)
                Text(viewModel.selectedDate, style: .date)
                    .font(.subheadline.bold())
                    .foregroundStyle(ThemeColors.textPrimary)
            }

            Spacer()

            Button {
                viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.selectedDate) ?? viewModel.selectedDate
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(ThemeColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(ThemeColors.surfaceColor))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(NutrientTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedTab == tab ? ThemeColors.textPrimary : ThemeColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(ThemeColors.primary.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(ThemeColors.primary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                }
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ThemeColors.surfaceColor)
        )
    }

    // MARK: - Calories Tab

    private var caloriesTab: some View {
        VStack(spacing: 12) {
            // Summary card
            calorieEquationCard

            // Meal breakdown
            sectionHeader("By Meal")

            ForEach(MealType.allCases, id: \.self) { meal in
                let entries = viewModel.entries(for: meal)
                let cal = entries.reduce(0.0) { $0 + $1.calories }
                let prot = entries.reduce(0.0) { $0 + $1.proteinG }
                let carbs = entries.reduce(0.0) { $0 + $1.carbsG }
                let fat = entries.reduce(0.0) { $0 + $1.fatG }

                if !entries.isEmpty {
                    mealBreakdownRow(
                        icon: meal.icon,
                        name: meal.rawValue.capitalized,
                        calories: Int(cal),
                        protein: Int(prot),
                        carbs: Int(carbs),
                        fat: Int(fat)
                    )
                }
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private var calorieEquationCard: some View {
        HStack(spacing: 0) {
            equationItem(value: viewModel.targetCalories, label: "Goal", color: ThemeColors.textPrimary)
            equationSymbol("-")
            equationItem(value: viewModel.caloriesConsumed, label: "Food", color: ThemeColors.info)
            equationSymbol("=")
            equationItem(
                value: viewModel.caloriesRemaining,
                label: "Remaining",
                color: viewModel.caloriesRemaining >= 0 ? ThemeColors.success : ThemeColors.error
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ThemeColors.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
                )
        )
    }

    private func equationItem(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(ThemeColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func equationSymbol(_ symbol: String) -> some View {
        Text(symbol)
            .font(.headline)
            .foregroundStyle(ThemeColors.textSecondary)
    }

    private func mealBreakdownRow(icon: String, name: String, calories: Int, protein: Int, carbs: Int, fat: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(ThemeColors.primary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(ThemeColors.primary.opacity(0.1)))

            Text(name)
                .font(.subheadline.bold())
                .foregroundStyle(ThemeColors.textPrimary)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(localized: "\(calories) cal"))
                    .font(.subheadline.bold())
                    .foregroundStyle(ThemeColors.textPrimary)
                Text("P:\(protein) C:\(carbs) F:\(fat)")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(ThemeColors.textSecondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ThemeColors.surfaceColor)
        )
    }

    // MARK: - Nutrients Tab

    private var nutrientsTab: some View {
        let log = viewModel.todayLog
        let rows: [(String, Double, Double?, Color)] = [
            ("Calories", log.totalCalories, Double(viewModel.targetCalories), ThemeColors.info),
            ("Protein", log.totalProteinG, Double(viewModel.targetProteinG), .orange),
            ("Carbohydrates", log.totalCarbsG, Double(viewModel.targetCarbsG), ThemeColors.success),
            ("Fiber", log.totalFiberG, 38, ThemeColors.info),
            ("Fat", log.totalFatG, Double(viewModel.targetFatG), .purple),
        ]

        return VStack(spacing: 0) {
            // Table header
            nutrientTableHeader

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                nutrientRow(
                    name: row.0,
                    total: row.1,
                    goal: row.2,
                    color: row.3,
                    showDivider: index < rows.count - 1
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ThemeColors.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
    }

    private var nutrientTableHeader: some View {
        HStack {
            Text("")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Total")
                .frame(width: 55, alignment: .trailing)
            Text("Goal")
                .frame(width: 55, alignment: .trailing)
            Text("Left")
                .frame(width: 55, alignment: .trailing)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(ThemeColors.textSecondary)
        .padding(.bottom, 8)
        .overlay(
            Rectangle()
                .fill(ThemeColors.surfaceBorder)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private func nutrientRow(name: String, total: Double, goal: Double?, color: Color, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 3, height: 16)

                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ThemeColors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(Int(total))")
                    .frame(width: 55, alignment: .trailing)
                    .foregroundStyle(ThemeColors.textPrimary)

                if let goal {
                    Text("\(Int(goal))")
                        .frame(width: 55, alignment: .trailing)
                        .foregroundStyle(ThemeColors.textSecondary)

                    let left = max(0, Int(goal) - Int(total))
                    Text("\(left)")
                        .frame(width: 55, alignment: .trailing)
                        .foregroundStyle(left > 0 ? ThemeColors.textSecondary : ThemeColors.error)
                } else {
                    Text("–")
                        .frame(width: 55, alignment: .trailing)
                        .foregroundStyle(ThemeColors.textSecondary)
                    Text("–")
                        .frame(width: 55, alignment: .trailing)
                        .foregroundStyle(ThemeColors.textSecondary)
                }
            }
            .font(.system(size: 13, design: .rounded))
            .padding(.vertical, 10)

            if showDivider {
                Rectangle()
                    .fill(ThemeColors.surfaceBorder)
                    .frame(height: 1)
            }
        }
    }

    // MARK: - Macros Tab

    private var macrosTab: some View {
        let log = viewModel.todayLog
        let proteinCal = log.totalProteinG * 4
        let carbsCal = log.totalCarbsG * 4
        let fatCal = log.totalFatG * 9
        let totalMacroCal = max(proteinCal + carbsCal + fatCal, 1)
        let proteinFraction = proteinCal / totalMacroCal
        let carbsFraction = carbsCal / totalMacroCal
        let fatFraction = fatCal / totalMacroCal

        return VStack(spacing: 16) {
            // Donut chart
            ZStack {
                Circle()
                    .stroke(ThemeColors.surfaceBorder, lineWidth: 20)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: proteinFraction)
                    .stroke(.orange, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: proteinFraction, to: proteinFraction + carbsFraction)
                    .stroke(ThemeColors.success, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: proteinFraction + carbsFraction, to: proteinFraction + carbsFraction + fatFraction)
                    .stroke(.purple, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(log.totalCalories))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(ThemeColors.textPrimary)
                    Text("kcal")
                        .font(.caption2)
                        .foregroundStyle(ThemeColors.textSecondary)
                }
            }
            .frame(height: 200)

            // Macro detail cards
            HStack(spacing: 12) {
                macroDetailCard(
                    name: "Protein",
                    grams: Int(log.totalProteinG),
                    target: viewModel.targetProteinG,
                    percentage: Int(proteinFraction * 100),
                    color: .orange
                )
                macroDetailCard(
                    name: "Carbs",
                    grams: Int(log.totalCarbsG),
                    target: viewModel.targetCarbsG,
                    percentage: Int(carbsFraction * 100),
                    color: ThemeColors.success
                )
                macroDetailCard(
                    name: "Fat",
                    grams: Int(log.totalFatG),
                    target: viewModel.targetFatG,
                    percentage: Int(fatFraction * 100),
                    color: .purple
                )
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private func macroDetailCard(name: String, grams: Int, target: Int, percentage: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            Text("\(percentage)%")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ThemeColors.textSecondary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ThemeColors.surfaceBorder)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * min(Double(grams) / max(Double(target), 1), 1.0))
                }
            }
            .frame(height: 4)

            Text(String(localized: "\(grams)/\(target)g"))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ThemeColors.textSecondary)

            Text(String(localized: "\(max(0, target - grams))g left"))
                .font(.system(size: 9))
                .foregroundStyle(ThemeColors.textSecondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(color.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.bold())
            .foregroundStyle(ThemeColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

