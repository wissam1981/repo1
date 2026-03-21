import SwiftUI
import Charts

// MARK: - Nutrition Dashboard View
// Main nutrition tracking screen with meal sections and daily summary.

struct NutritionDashboardView: View {
    let sharedViewModel: NutritionViewModel?

    @Environment(AppState.self) private var appState
    @Environment(DependencyContainer.self) private var container
    @State private var viewModel: NutritionViewModel?
    @State private var exerciseCalories: Int = 0

    init(sharedViewModel: NutritionViewModel? = nil) {
        self.sharedViewModel = sharedViewModel
    }

    var body: some View {
        ZStack {
            ThemeColors.backgroundDark.ignoresSafeArea()
            Group {
                if let vm = viewModel {
                    nutritionContent(vm)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            initViewModelIfNeeded()
            viewModel?.refresh()
            Task {
                let cals = try? await container.healthKitService.fetchActiveCaloriesToday()
                await MainActor.run { exerciseCalories = Int(cals ?? 0) }
            }
        }
    }

    // MARK: - Init

    private func initViewModelIfNeeded() {
        guard viewModel == nil else { return }
        if let shared = sharedViewModel {
            viewModel = shared
            return
        }
        guard let user = appState.currentUser else { return }
        viewModel = NutritionViewModel(user: user, nutritionService: container.nutritionService)
    }

    // MARK: - Content

    private func nutritionContent(_ vm: NutritionViewModel) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Title
                HStack {
                    Text("Nutrition")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(ThemeColors.textPrimary)
                    Spacer()
                }

                // Date Navigator
                dateNavigator(vm)

                // Quick Actions
                nutritionActionButtons(vm)

                // Calorie Equation Bar (Goal - Food + Exercise = Remaining)
                calorieEquationBar(vm)

                // Daily summary header with remaining calories
                dailySummary(vm)

                // Mini 7-day calorie sparkline
                weeklySparkline(vm)

                // Nutrition Detail Link
                NavigationLink(destination: NutritionDetailView(viewModel: vm)) {
                    HStack(spacing: 10) {
                        Image(systemName: "list.bullet.rectangle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(ThemeColors.primary)

                        Text("Nutrition Breakdown")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(ThemeColors.textPrimary)

                        Spacer()

                        Text("Total / Goal / Left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ThemeColors.textSecondary)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                    .padding(14)
                    .glassStyle(cornerRadius: 12, color: ThemeColors.surfaceColor)
                }
                .buttonStyle(.plain)

                // Water Tracker (compact)
                WaterTrackerView(viewModel: vm)

                // Meal sections with auto-expand & quick re-log
                ForEach(MealType.allCases, id: \.self) { meal in
                        // Meal pattern suggestion banner
                        if let pattern = vm.mealPatterns[meal],
                           vm.entries(for: meal).isEmpty {
                            Button {
                                Task { await vm.logMealPattern(pattern) }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(ThemeColors.primary)
                                    Text("Log your usual: \(pattern.entries.map(\.foodName).joined(separator: ", "))?")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(ThemeColors.textSecondary)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(ThemeColors.primary)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(ThemeColors.primary.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(ThemeColors.primary.opacity(0.12), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    MealSectionView(
                        mealType: meal,
                        entries: vm.entries(for: meal),
                        totalCalories: vm.mealCalories(for: meal),
                        onAdd: { vm.openAddFood(for: meal) },
                        onEdit: { entry in
                            vm.entryToEdit = entry
                        },
                        onDelete: { entry in
                            Task { await vm.removeEntry(entry) }
                        },
                        recentEntries: vm.recentEntriesForMeal(meal),
                        onQuickRelog: { entry in
                            Task { await vm.quickRelog(entry) }
                        },
                        autoExpand: meal == vm.currentMealType
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .sheet(isPresented: Binding(
            get: { vm.showAddFood },
            set: { vm.showAddFood = $0 }
        )) {
            FoodSearchView(viewModel: vm)
        }
        .sheet(item: Binding(
            get: { vm.entryToEdit },
            set: { vm.entryToEdit = $0 }
        )) { entry in
            EditFoodEntryView(viewModel: vm, entry: entry)
        }
        .sheet(isPresented: Binding(
            get: { vm.showQuickAdd },
            set: { vm.showQuickAdd = $0 }
        )) {
            QuickAddCaloriesSheet(viewModel: vm)
        }
        .sheet(isPresented: Binding(
            get: { vm.showAnalytics },
            set: { vm.showAnalytics = $0 }
        )) {
            NutritionAnalyticsView(viewModel: vm)
        }
        .sheet(isPresented: Binding(
            get: { vm.showGeneratedPlanSheet },
            set: { vm.showGeneratedPlanSheet = $0 }
        )) {
            SmartMealPlanView(meals: vm.generatedPlan) { mealsToLog in
                vm.logGeneratedPlan(mealsToLog)
            }
        }
        .alert("Plan Generation Failed", isPresented: Binding(
            get: { vm.planGenerationError != nil },
            set: { _ in vm.planGenerationError = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.planGenerationError ?? "")
        }
    }

    // MARK: - Date Navigator

    private func dateNavigator(_ vm: NutritionViewModel) -> some View {
        HStack {
            Button {
                vm.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: vm.selectedDate) ?? vm.selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(ThemeColors.info)

            Spacer()

            DatePicker(
                "",
                selection: Binding(
                    get: { vm.selectedDate },
                    set: { vm.selectedDate = $0 }
                ),
                displayedComponents: .date
            )
            .labelsHidden()
            .environment(\.locale, Locale.current)
            .font(.headline)
            .foregroundStyle(.primary)

            Spacer()

            Button {
                vm.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: vm.selectedDate) ?? vm.selectedDate
            } label: {
                Image(systemName: "chevron.right")
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(Calendar.current.isDate(vm.selectedDate, inSameDayAs: .now) ? Color.gray : ThemeColors.info)
            .disabled(Calendar.current.isDate(vm.selectedDate, inSameDayAs: .now))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Nutrition Action Buttons

    private func nutritionActionButtons(_ vm: NutritionViewModel) -> some View {
        HStack(spacing: 16) {
            NavigationLink(destination: RecipeBrowserView()) {
                nutritionActionTile(icon: "book.fill", title: "Recipes", color: .orange)
            }

            Button { vm.showAnalytics = true } label: {
                nutritionActionTile(icon: "chart.bar.xaxis", title: "Analytics", color: .purple)
            }

            Button {
                vm.generateFullDayPlan()
            } label: {
                if vm.isGeneratingPlan {
                    VStack(spacing: 10) {
                        ProgressView()
                            .frame(width: 56, height: 56)
                            .background(ThemeColors.surfaceColor)
                            .clipShape(Circle())
                        Text("Planning...")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .glassStyle(cornerRadius: 18, color: ThemeColors.surfaceColor)
                } else {
                    nutritionActionTile(icon: "wand.and.stars", title: "Auto-Plan", color: ThemeColors.primary)
                }
            }
            .disabled(vm.isGeneratingPlan)
        }
        .padding(.horizontal)
    }

    private func nutritionActionTile(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: color.opacity(0.3), radius: 6, y: 2)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(ThemeColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassStyle(cornerRadius: 18, color: ThemeColors.surfaceColor)
    }

    // MARK: - Daily Summary

    private func dailySummary(_ vm: NutritionViewModel) -> some View {
        VStack(spacing: 14) {
            HStack(alignment: .center) {
                // Calorie ring (larger)
                ZStack {
                    Circle()
                        .stroke(ThemeColors.info.opacity(0.15), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: CGFloat(min(vm.calorieProgress, 1.0)))
                        .stroke(
                            vm.calorieProgress > 1.0 ? ThemeColors.error : ThemeColors.info,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6), value: vm.calorieProgress)

                    VStack(spacing: 0) {
                        Text("\(vm.caloriesRemaining)")
                            .font(.system(size: 26, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(vm.calorieProgress > 1.0 ? ThemeColors.error : .primary)
                        Text("left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 80, height: 80)

                Spacer()

                // Right side: consumed / target
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(vm.caloriesConsumed)")
                            .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                        Text("eaten")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Text("of \(vm.targetCalories) kcal goal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            // Macro bars
            HStack(spacing: 12) {
                miniMacro(label: "Protein", consumed: Int(vm.todayLog.totalProteinG), target: vm.targetProteinG, color: .orange)
                miniMacro(label: "Carbs", consumed: Int(vm.todayLog.totalCarbsG), target: vm.targetCarbsG, color: .green)
                miniMacro(label: "Fat", consumed: Int(vm.todayLog.totalFatG), target: vm.targetFatG, color: .purple)
            }
        }
        .padding(16)
        .glassStyle(cornerRadius: 16, color: ThemeColors.surfaceColor)
    }

    private func miniMacro(label: String, consumed: Int, target: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(" \(label)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Text("\(consumed)/\(target)g")
                .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(color)
            ProgressView(value: min(max(Double(consumed), 0.0), Double(max(target, 1))), total: Double(max(target, 1)))
                .tint(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Calorie Equation Bar

    private func calorieEquationBar(_ vm: NutritionViewModel) -> some View {
        let goal = vm.targetCalories
        let food = vm.caloriesConsumed
        let exercise = exerciseCalories
        let remaining = goal - food + exercise

        return HStack(spacing: 0) {
            equationColumn(value: goal, label: "Goal", color: ThemeColors.textPrimary)
            equationOp("−")
            equationColumn(value: food, label: "Food", color: ThemeColors.info)
            equationOp("+")
            equationColumn(value: exercise, label: "Exercise", color: ThemeColors.success)
            equationOp("=")
            equationColumn(
                value: remaining,
                label: "Remaining",
                color: remaining >= 0 ? ThemeColors.primary : ThemeColors.error
            )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .glassStyle(cornerRadius: 16, color: ThemeColors.surfaceColor)
    }

    private func equationColumn(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ThemeColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func equationOp(_ symbol: String) -> some View {
        Text(symbol)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(ThemeColors.textSecondary)
            .frame(width: 16)
    }

    // MARK: - Weekly Sparkline

    private func weeklySparkline(_ vm: NutritionViewModel) -> some View {
        WeeklyCalorieSparkline(viewModel: vm)
    }
}

// MARK: - Weekly Calorie Sparkline

private struct WeeklyCalorieSparkline: View {
    @Bindable var viewModel: NutritionViewModel
    @State private var logs: [NutritionLog] = []
    @State private var isLoaded = false

    var body: some View {
        Group {
            if isLoaded && !logs.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("This Week")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    Chart {
                        ForEach(logs, id: \.id) { log in
                            BarMark(
                                x: .value("Day", dayLabel(log.date)),
                                y: .value("Calories", log.totalCalories)
                            )
                            .foregroundStyle(
                                Calendar.current.isDate(log.date, inSameDayAs: .now)
                                    ? ThemeColors.info
                                    : ThemeColors.info.opacity(0.4)
                            )
                            .cornerRadius(3)
                        }

                        // Target line
                        RuleMark(y: .value("Target", viewModel.targetCalories))
                            .foregroundStyle(.red.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                    .chartYAxis(.hidden)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel()
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 50)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .glassStyle(cornerRadius: 12, color: ThemeColors.surfaceColor)
            }
        }
        .task {
            guard !isLoaded else { return }
            logs = await viewModel.fetchWeeklyLogs()
            isLoaded = true
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Quick Add Calories Sheet

private struct QuickAddCaloriesSheet: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Meal Type")) {
                    Picker("Meal", selection: $viewModel.selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { meal in
                            Text(meal.displayName).tag(meal)
                        }
                    }
                }

                Section(header: Text("Details")) {
                    TextField("Food Name (Optional)", text: $viewModel.quickAddName)
                    TextField("Total Calories", text: $viewModel.quickAddCalories)
                        .keyboardType(.numberPad)
                    TextField("Total Protein (g)", text: $viewModel.quickAddProtein)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Button {
                        Task {
                            await viewModel.submitQuickAddCalories()
                            dismiss()
                        }
                    } label: {
                        Text("Save Quick Add")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.bold)
                    }
                    .disabled(viewModel.quickAddCalories.isEmpty)
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
