import SwiftUI
import Charts

// MARK: - Advanced Analytics View (Premium)
// Detailed progress charts for calories, macros, and workout volume.
// Stylish dark-themed design with gradient accents.

struct AdvancedAnalyticsView: View {
    @Environment(AppState.self) private var appState
    @Environment(DependencyContainer.self) private var container
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var selectedTab = 0
    @State private var selectedRange: AnalyticsRange = .week
    @State private var nutritionData: [DailyNutritionPoint] = []
    @State private var workoutData: [WorkoutDataPoint] = []
    @State private var showPaywall = false
    @Namespace private var tabAnimation

    enum AnalyticsRange: String, CaseIterable {
        case week = "7D"
        case twoWeeks = "14D"
        case month = "30D"
        case threeMonths = "90D"
    }

    private let tabs = [
        (icon: "flame.fill", label: "Calories"),
        (icon: "chart.bar.fill", label: "Macros"),
        (icon: "dumbbell.fill", label: "Workouts")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                analyticsHeader

                // Range pills
                rangePills

                // Tab selector
                tabSelector

                // Charts
                switch selectedTab {
                case 0:  calorieChart
                case 1:  macroChart
                case 2:  workoutChart
                default: EmptyView()
                }

                // Summary cards
                summaryCards

                // Insights section
                insightsSection
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .background(ThemeColors.backgroundDark.ignoresSafeArea())
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ThemeColors.backgroundDark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { loadData() }
        .onChange(of: selectedRange) { _, _ in loadData() }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Header

    private var analyticsHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.primary.opacity(0.3), ThemeColors.primary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(ThemeColors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Advanced Analytics")
                        .font(.title3.bold())
                        .foregroundStyle(ThemeColors.textPrimary)

                    Text("PRO")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [ThemeColors.primary, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }

                Text("Track your fitness journey in detail")
                    .font(.caption)
                    .foregroundStyle(ThemeColors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Range Pills

    private var rangePills: some View {
        HStack(spacing: 6) {
            ForEach(AnalyticsRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedRange == range ? .white : ThemeColors.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if selectedRange == range {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [ThemeColors.primary, .cyan.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                } else {
                                    Capsule()
                                        .fill(ThemeColors.surfaceColor)
                                        .overlay(
                                            Capsule()
                                                .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
                                        )
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = index
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12))
                        Text(tab.label)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(selectedTab == index ? ThemeColors.textPrimary : ThemeColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if selectedTab == index {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(ThemeColors.surfaceColor)
                                    .matchedGeometryEffect(id: "activeTab", in: tabAnimation)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ThemeColors.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Calorie Chart

    private var calorieChart: some View {
        chartCard(title: "Daily Calories", icon: "flame.fill", color: .cyan) {
            if nutritionData.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(nutritionData) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Calories", point.calories)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ThemeColors.primary, .cyan.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)

                    if let target = appState.currentUser?.targetCalories {
                        RuleMark(y: .value("Target", target))
                            .foregroundStyle(.orange.opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Target \(target) kcal")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.orange.opacity(0.9))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule().fill(.orange.opacity(0.15))
                                    )
                            }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(ThemeColors.surfaceBorder)
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text("\(intVal)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(ThemeColors.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                }
                .chartPlotStyle { area in
                    area.frame(height: 200)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Macro Chart

    private var macroChart: some View {
        chartCard(title: "Macronutrients", icon: "chart.bar.fill", color: .blue) {
            if nutritionData.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart {
                    ForEach(nutritionData) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Grams", point.proteinG),
                            series: .value("Macro", "Protein")
                        )
                        .foregroundStyle(.blue)
                        .symbol {
                            Circle()
                                .fill(.blue)
                                .frame(width: 6, height: 6)
                        }
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        AreaMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Grams", point.proteinG),
                            series: .value("Macro", "Protein")
                        )
                        .foregroundStyle(.blue.opacity(0.08))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Grams", point.carbsG),
                            series: .value("Macro", "Carbs")
                        )
                        .foregroundStyle(.green)
                        .symbol {
                            Circle()
                                .strokeBorder(.green, lineWidth: 1.5)
                                .frame(width: 6, height: 6)
                        }
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Grams", point.fatG),
                            series: .value("Macro", "Fat")
                        )
                        .foregroundStyle(.orange)
                        .symbol {
                            Circle()
                                .fill(.orange)
                                .frame(width: 5, height: 5)
                        }
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                .chartForegroundStyleScale([
                    "Protein": .blue,
                    "Carbs": .green,
                    "Fat": .orange
                ])
                .chartLegend(position: .bottom, spacing: 16) {
                    HStack(spacing: 16) {
                        macroLegendItem(color: .blue, label: "Protein")
                        macroLegendItem(color: .green, label: "Carbs")
                        macroLegendItem(color: .orange, label: "Fat")
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(ThemeColors.surfaceBorder)
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text("\(intVal)g")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(ThemeColors.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                }
                .chartPlotStyle { area in
                    area.frame(height: 200)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Workout Chart

    private var workoutChart: some View {
        chartCard(title: "Workout Volume", icon: "dumbbell.fill", color: .purple) {
            if workoutData.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(workoutData) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Volume", point.totalVolume)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(ThemeColors.surfaceBorder)
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text("\(intVal) kg")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(ThemeColors.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                }
                .chartPlotStyle { area in
                    area.frame(height: 200)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Chart Card Container

    private func chartCard<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title row
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)

                Spacer()

                // Data point count
                let count = selectedTab == 2 ? workoutData.count : nutritionData.count
                if count > 0 {
                    Text("\(count) days")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(ThemeColors.surfaceColor))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ThemeColors.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(ThemeColors.primary)
                Text("Summary")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
            }
            .padding(.horizontal, 20)

            if selectedTab == 0 || selectedTab == 1 {
                // Nutrition averages
                let avgCalories = nutritionData.isEmpty ? 0 : nutritionData.reduce(0) { $0 + $1.calories } / Double(nutritionData.count)
                let avgProtein = nutritionData.isEmpty ? 0 : nutritionData.reduce(0) { $0 + $1.proteinG } / Double(nutritionData.count)
                let avgCarbs = nutritionData.isEmpty ? 0 : nutritionData.reduce(0) { $0 + $1.carbsG } / Double(nutritionData.count)
                let avgFat = nutritionData.isEmpty ? 0 : nutritionData.reduce(0) { $0 + $1.fatG } / Double(nutritionData.count)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    summaryCard(title: "Avg Calories", value: String(format: "%.0f", avgCalories), unit: "kcal", icon: "flame.fill", color: .cyan)
                    summaryCard(title: "Avg Protein", value: String(format: "%.0f", avgProtein), unit: "g", icon: "bolt.fill", color: .blue)
                    summaryCard(title: "Avg Carbs", value: String(format: "%.0f", avgCarbs), unit: "g", icon: "leaf.fill", color: .green)
                    summaryCard(title: "Avg Fat", value: String(format: "%.0f", avgFat), unit: "g", icon: "drop.fill", color: .orange)
                }
                .padding(.horizontal, 20)
            } else {
                // Workout stats
                let totalWorkouts = workoutData.count
                let totalVolume = workoutData.reduce(0) { $0 + $1.totalVolume }
                let avgDuration = workoutData.isEmpty ? 0 : workoutData.reduce(0) { $0 + $1.durationMinutes } / Double(workoutData.count)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    summaryCard(title: "Workouts", value: "\(totalWorkouts)", unit: "sessions", icon: "dumbbell.fill", color: .purple)
                    summaryCard(title: "Total Volume", value: String(format: "%.0f", totalVolume), unit: "kg", icon: "scalemass.fill", color: .indigo)
                    summaryCard(title: "Avg Duration", value: String(format: "%.0f", avgDuration), unit: "min", icon: "clock.fill", color: .blue)
                    summaryCard(title: "Avg Volume", value: totalWorkouts > 0 ? String(format: "%.0f", totalVolume / Double(totalWorkouts)) : "0", unit: "kg/session", icon: "chart.line.uptrend.xyaxis", color: .teal)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func summaryCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(ThemeColors.textPrimary)
                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ThemeColors.textSecondary)
                }

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(ThemeColors.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.yellow)
                Text("Insights")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 8) {
                if selectedTab == 0 || selectedTab == 1 {
                    if !nutritionData.isEmpty {
                        let avgCalories = nutritionData.reduce(0) { $0 + $1.calories } / Double(nutritionData.count)
                        let target = Double(appState.currentUser?.targetCalories ?? 2000)
                        let diff = avgCalories - target
                        let diffPercent = abs(diff / target * 100)

                        if diff > 100 {
                            insightRow(
                                icon: "exclamationmark.triangle.fill",
                                color: .orange,
                                text: "You're averaging \(Int(diffPercent))% over your calorie target. Try cutting down on snacks."
                            )
                        } else if diff < -200 {
                            insightRow(
                                icon: "arrow.down.circle.fill",
                                color: .yellow,
                                text: "You're eating \(Int(diffPercent))% below target. Make sure you're fueling properly."
                            )
                        } else {
                            insightRow(
                                icon: "checkmark.circle.fill",
                                color: .green,
                                text: "Great job! Your calorie intake is close to target."
                            )
                        }

                        let avgProtein = nutritionData.reduce(0) { $0 + $1.proteinG } / Double(nutritionData.count)
                        let protTarget = Double(appState.currentUser?.targetProteinG ?? 150)
                        if avgProtein < protTarget * 0.8 {
                            insightRow(
                                icon: "bolt.fill",
                                color: .blue,
                                text: "Protein is below target. Add eggs, chicken, or a shake."
                            )
                        }
                    } else {
                        insightRow(
                            icon: "tray.fill",
                            color: .white.opacity(0.3),
                            text: "Log your meals to unlock nutrition insights."
                        )
                    }
                } else {
                    if !workoutData.isEmpty {
                        let sessionsPerWeek = Double(workoutData.count) / max(Double(rangeDays) / 7.0, 1.0)
                        if sessionsPerWeek >= 4 {
                            insightRow(
                                icon: "star.fill",
                                color: .yellow,
                                text: "Amazing consistency! \(String(format: "%.1f", sessionsPerWeek)) sessions/week."
                            )
                        } else if sessionsPerWeek >= 2 {
                            insightRow(
                                icon: "checkmark.circle.fill",
                                color: .green,
                                text: "Good pace at \(String(format: "%.1f", sessionsPerWeek)) sessions/week. Push for 4+!"
                            )
                        } else {
                            insightRow(
                                icon: "exclamationmark.triangle.fill",
                                color: .orange,
                                text: "Only \(String(format: "%.1f", sessionsPerWeek)) sessions/week. Try to be more consistent."
                            )
                        }
                    } else {
                        insightRow(
                            icon: "tray.fill",
                            color: .white.opacity(0.3),
                            text: "Complete workouts to unlock training insights."
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func insightRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(ThemeColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ThemeColors.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    private func macroLegendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ThemeColors.textSecondary)
        }
    }

    private var emptyChartPlaceholder: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(ThemeColors.surfaceColor)
                    .frame(width: 56, height: 56)
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 24))
                    .foregroundStyle(ThemeColors.textSecondary)
            }
            Text("No data for this period")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ThemeColors.textSecondary)
            Text("Start logging to see your trends")
                .font(.system(size: 12))
                .foregroundStyle(ThemeColors.textSecondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    private var rangeDays: Int {
        switch selectedRange {
        case .week: return 7
        case .twoWeeks: return 14
        case .month: return 30
        case .threeMonths: return 90
        }
    }

    // MARK: - Data Loading

    private func loadData() {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -rangeDays, to: endDate)!

        nutritionData = container.coreDataService.fetchNutritionLogs(from: startDate, to: endDate).map { log in
            DailyNutritionPoint(date: log.date, calories: log.totalCalories, proteinG: log.totalProteinG, carbsG: log.totalCarbsG, fatG: log.totalFatG)
        }

        workoutData = container.coreDataService.fetchWorkoutSessions(from: startDate, to: endDate).map { session in
            WorkoutDataPoint(date: session.startedAt, totalVolume: session.totalVolume, durationMinutes: Double(session.durationSeconds) / 60.0, totalSets: session.totalSets)
        }
    }
}

// MARK: - Data Models

struct DailyNutritionPoint: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
}

struct WorkoutDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let totalVolume: Double
    let durationMinutes: Double
    let totalSets: Int
}
