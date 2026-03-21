import SwiftUI

// MARK: - Premium Card Button Style

private struct PremiumCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Home View (Dashboard)
// Main dashboard showing calorie ring, macro progress, weight snapshot, and workout card.

struct HomeView: View {
    let sharedNutritionVM: NutritionViewModel?

    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(DependencyContainer.self) private var container
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: HomeViewModel?
    @State private var progressVM: ProgressViewModel?
    @State private var fastingVM: FastingViewModel?
    @State private var dailyChallengeVM: DailyChallengeViewModel?
    @State private var workoutVM: WorkoutViewModel?
    @State private var nutritionVM: NutritionViewModel?

    init(sharedNutritionVM: NutritionViewModel? = nil) {
        self.sharedNutritionVM = sharedNutritionVM
    }
    @State private var showEditProfile = false
    @State private var showPaywall = false
    @State private var showWeeklyReport = false
    @State private var showBudgetSheet = false

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.homePath) {
            ZStack {
                ThemeColors.backgroundDark
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    if let vm = viewModel {
                        dashboardContent(vm)
                    } else {
                        ProgressView()
                            .tint(ThemeColors.primary)
                            .frame(maxWidth: .infinity, minHeight: 300)
                    }
                }
                .navigationDestination(for: HomeDestination.self) { destination in
                    switch destination {
                    case .instructions:
                        InstructionsView()
                    }
                }
                .refreshable {
                    viewModel?.refresh()
                    await progressVM?.syncFromHealthKit()
                    progressVM?.loadEntries()
                    if let newWeight = progressVM?.latestWeight {
                        viewModel?.updateWeight(newWeight)
                    }
                }
            }
            // Hide standard nav bar, we use a custom one
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                initViewModelIfNeeded()
                viewModel?.refresh()
                dailyChallengeVM?.loadChallenges()
                Task {
                    await progressVM?.syncFromHealthKit()
                    progressVM?.loadEntries()
                    if let newWeight = progressVM?.latestWeight {
                        viewModel?.updateWeight(newWeight)
                    }
                }
                // Trigger weekly digest generation on app launch (Sun-Tue)
                if WeeklyDigestService.isDigestWindow, !WeeklyDigestService.hasDigestThisWeek {
                    weeklyDigestCoachVM?.generateWeeklyDigest()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel?.refresh()
                    dailyChallengeVM?.loadChallenges()
                    Task {
                        await progressVM?.syncFromHealthKit()
                        progressVM?.loadEntries()
                        if let newWeight = progressVM?.latestWeight {
                            viewModel?.updateWeight(newWeight)
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                if let user = appState.currentUser {
                    EditProfileView(user: user) { updatedUser in
                        appState.currentUser = updatedUser
                        Task {
                            await container.coreDataService.saveUserProfile(updatedUser)
                            try? await container.firestoreService.saveUserProfile(updatedUser)
                            viewModel?.refresh()
                        }
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showWeeklyReport) {
                if let vm = viewModel {
                    WeeklyReportSheet(report: vm.weeklyReport)
                }
            }
            .sheet(isPresented: $showBudgetSheet) {
                if let vm = viewModel {
                    CalorieBudgetSheet(
                        consumed: vm.caloriesConsumed,
                        target: vm.targetCalories,
                        proteinConsumed: vm.proteinConsumed,
                        proteinTarget: vm.targetProteinG,
                        carbsConsumed: vm.carbsConsumed,
                        carbsTarget: vm.targetCarbsG,
                        fatConsumed: vm.fatConsumed,
                        fatTarget: vm.targetFatG,
                        onGetAISuggestions: {
                            appState.pendingAIAction = .budgetAdvisor
                            appState.showAICoach = true
                        }
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
                }
            }
            .onChange(of: appState.showAICoach) { _, newValue in
                if newValue {
                    showCoach = true
                    appState.showAICoach = false
                }
            }
        }
    }

    // MARK: - Trial Banner

    @ViewBuilder
    private var trialBanner: some View {
        if !subscriptionManager.isSubscribed {
            Button { showPaywall = true } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: subscriptionManager.isTrialActive
                                        ? [.cyan, .cyan.opacity(0.6)]
                                        : [.orange, .orange.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .shadow(color: (subscriptionManager.isTrialActive ? Color.cyan : .orange).opacity(0.3), radius: 6, x: 0, y: 3)

                        Image(systemName: subscriptionManager.isTrialActive ? "clock.fill" : "crown.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        if subscriptionManager.isTrialActive {
                            let days = subscriptionManager.trialDaysRemaining
                            Text("Free Trial · \(days) day\(days == 1 ? "" : "s") left")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("Trial Ended · Upgrade Now")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Text("AI Coach · Analytics · AI Plans")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    Text("See Plans")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .glassStyle(cornerRadius: 18, color: .white.opacity(0.15))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Init ViewModel

    private func initViewModelIfNeeded() {
        guard let user = appState.currentUser else { return }
        if viewModel == nil {
            viewModel = container.makeHomeViewModel(user: user)
        }
        if progressVM == nil {
            progressVM = ProgressViewModel(
                user: user,
                coreDataService: container.coreDataService,
                healthKitService: container.healthKitService,
                firestoreService: container.firestoreService
            )
        }
        if fastingVM == nil {
            fastingVM = FastingViewModel(coreDataService: container.coreDataService)
        }
        if dailyChallengeVM == nil {
            dailyChallengeVM = DailyChallengeViewModel(coreDataService: container.coreDataService)
        }
        if workoutVM == nil {
            workoutVM = container.makeWorkoutViewModel(appState: appState)
            Task {
                await workoutVM?.loadPlans()
            }
        }
        if nutritionVM == nil {
            if let shared = sharedNutritionVM {
                nutritionVM = shared
            } else if let user = appState.currentUser {
                nutritionVM = NutritionViewModel(
                    user: user,
                    nutritionService: container.nutritionService
                )
            }
        }
        if weeklyDigestCoachVM == nil, let user = appState.currentUser {
            weeklyDigestCoachVM = AICoachViewModel(user: user)
        }
    }

    // MARK: - Dashboard Content

    @State private var nutritionPage = 0
    @State private var workoutPage = 0
    private func dashboardContent(_ vm: HomeViewModel) -> some View {
        VStack(spacing: 16) {
            // 1. Header
            CustomHeader(
                name: vm.user.displayName,
                streak: vm.loggingStreak,
                onProfileTap: { router.switchTo(tab: .profile) }
            )
            .padding(.horizontal, 20)

            // Trial banner
            trialBanner

            // Weekly AI Digest Card (Sunday through Tuesday)
            if WeeklyDigestService.isDigestWindow, WeeklyDigestService.hasDigestThisWeek {
                Button {
                    appState.pendingAIAction = .weeklyDigest
                    appState.showAICoach = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [ThemeColors.primary, ThemeColors.primary.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Your Weekly Report is Ready")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Tap to see your AI analysis")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(ThemeColors.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }

            // Meal Suggestion Card
            if let nvm = nutritionVM,
               let pattern = nvm.mealPatterns[nvm.currentMealType],
               nvm.entries(for: nvm.currentMealType).isEmpty {
                mealSuggestionCard(pattern: pattern, nutritionVM: nvm)
                    .padding(.horizontal, 20)
            }

            // Date Navigator
            DateNavigator(selectedDate: Binding(
                get: { vm.selectedDate },
                set: { newDate in
                    vm.changeDate(to: newDate)
                    dailyChallengeVM?.changeDate(to: newDate)
                    nutritionVM?.selectedDate = newDate
                }
            ))
            .padding(.horizontal, 20)

            // ── Redesigned Nutrition Carousel ──
            TabView(selection: $nutritionPage) {
                // Slide 1: Main Calorie Progress
                CalorieMainCard(
                    consumed: vm.caloriesConsumed,
                    target: vm.targetCalories,
                    progress: vm.targetCalories > 0 ? Double(vm.caloriesConsumed) / Double(vm.targetCalories) : 0,
                    remaining: max(0, vm.targetCalories - vm.caloriesConsumed),
                    fitnessGoal: vm.fitnessGoal
                )
                .onTapGesture { showBudgetSheet = true }
                .padding(.horizontal, 20)
                .tag(0)
                // Slide 2: Macro Breakdown
                MacroBreakdownCard(
                    proteinConsumed: vm.proteinConsumed,
                    proteinTarget: vm.targetProteinG,
                    carbsConsumed: vm.carbsConsumed,
                    carbsTarget: vm.targetCarbsG,
                    fatConsumed: vm.fatConsumed,
                    fatTarget: vm.targetFatG
                )
                .padding(.horizontal, 20)
                .tag(1)
                // Slide 3: Meal Breakdown
                MealBreakdownCard(
                    breakfast: vm.breakfastCalories,
                    lunch: vm.lunchCalories,
                    dinner: vm.dinnerCalories,
                    snacks: vm.snackCalories,
                    target: vm.targetCalories
                )
                .padding(.horizontal, 20)
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 440)
            
            CalorieDeficitCard(
                consumed: vm.caloriesConsumed,
                burned: vm.totalBurnedToday,
                deficit: vm.actualDeficit,
                fitnessGoal: vm.fitnessGoal
            )
            .padding(.horizontal, 20)

            // ── AI Coach & Analytics (premium features, visible first) ──
            HStack(spacing: 12) {
                aiCoachTile
                analyticsTile
            }
            .padding(.horizontal, 20)

            // Weight Progress (right below daily intake)
            if let pvm = progressVM {
                progressSection(pvm)
                    .padding(.horizontal, 20)
            }

            // ── Side-by-side tiles ──
            VStack(spacing: 12) {
                // Steps | Active Cals
                healthStatsWidget(vm)

                // Fasting Widget
                if let fvm = fastingVM {
                    FastingWidgetView(viewModel: fvm)
                }
            }
            .padding(.horizontal, 20)

            WeeklyHabitsCard(
                weekData: vm.weeklyHabitDays,
                habits: vm.weeklyHabits
            )
            .padding(.horizontal, 20)

            // ── Workout Carousel ──
            if let wvm = workoutVM {
                workoutCarousel(wvm)
            }

            // ── Bottom Section ──
            VStack(spacing: 12) {
                // Daily Goals
                if let dcVM = dailyChallengeVM {
                    DailyChallengeWidget(viewModel: dcVM)
                }

                // Weekly Report
                WeeklyReportCard(report: vm.weeklyReport) {
                    showWeeklyReport = true
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 100)
    }

    // MARK: - Workout Carousel

    private func workoutCarousel(_ wvm: WorkoutViewModel) -> some View {
        TabView(selection: $workoutPage) {
            // Slide 1: Today's Session
            TodayWorkoutSlide(
                hasWorkout: wvm.activeSession != nil || !wvm.customPlans.isEmpty,
                workoutName: wvm.activeSession?.planName ?? wvm.customPlans.first?.name,
                duration: wvm.activeSession?.durationSeconds != nil ? wvm.activeSession!.durationSeconds / 60 : 45,
                calories: 320, // Mock for now
                onTap: {
                    router.switchTo(tab: .workout)
                }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
            .tag(0)

            // Slide 2: Consistency
            WorkoutConsistencySlide(
                completedDays: Set(wvm.recentSessions.compactMap { session in
                    let calendar = Calendar.current
                    if calendar.isDate(session.completedAt ?? session.startedAt, equalTo: Date(), toGranularity: .weekOfYear) {
                        return calendar.component(.weekday, from: session.completedAt ?? session.startedAt) - 1
                    }
                    return nil
                }.map { ($0 + 5) % 7 }),
                currentStreak: 4 // Mock for now
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
            .tag(1)

            // Slide 3: Plans
            WorkoutPlansSlide(
                activePlanName: wvm.customPlans.first?.name,
                totalPlans: wvm.customPlans.count,
                onNavigate: {
                    router.switchTo(tab: .workout)
                }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 400)
    }


    // MARK: - AI Coach Tile

    @State private var showCoach = false
    @State private var showCoachPaywall = false
    @State private var weeklyDigestCoachVM: AICoachViewModel?
    @State private var showAnalytics = false
    @State private var showAnalyticsPaywall = false

    private var aiCoachTile: some View {
        Button {
            if subscriptionManager.isSubscribed {
                showCoach = true
            } else {
                showCoachPaywall = true
            }
        } label: {
            premiumFeatureCard(
                icon: "brain.head.profile.fill",
                title: "AI Coach",
                subtitle: "Get personalized advice",
                gradientColors: [ThemeColors.primary, ThemeColors.primary.opacity(0.6)],
                accentColor: ThemeColors.primary
            )
        }
        .buttonStyle(PremiumCardButtonStyle())
        .fullScreenCover(isPresented: $showCoach) {
            if let vm = weeklyDigestCoachVM {
                AICoachView(viewModel: vm)
            } else if let user = appState.currentUser {
                AICoachView(viewModel: AICoachViewModel(user: user))
            }
        }
        .sheet(isPresented: $showCoachPaywall) {
            PaywallView()
        }
    }

    // MARK: - Analytics Tile

    private var analyticsTile: some View {
        Button {
            if subscriptionManager.isSubscribed {
                showAnalytics = true
            } else {
                showAnalyticsPaywall = true
            }
        } label: {
            premiumFeatureCard(
                icon: "chart.xyaxis.line",
                title: "Analytics",
                subtitle: "Track your trends",
                gradientColors: [.cyan, .cyan.opacity(0.6)],
                accentColor: .cyan
            )
        }
        .buttonStyle(PremiumCardButtonStyle())
        .navigationDestination(isPresented: $showAnalytics) {
            AdvancedAnalyticsView()
        }
        .sheet(isPresented: $showAnalyticsPaywall) {
            PaywallView()
        }
    }

    // MARK: - Premium Feature Card (Redesigned - Eye-catching)

    private func premiumFeatureCard(
        icon: String,
        title: String,
        subtitle: String,
        gradientColors: [Color],
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Icon + PRO badge row
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: accentColor.opacity(0.4), radius: 8, x: 0, y: 4)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Spacer()

                // PRO badge - glowing
                Text("PRO")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: accentColor.opacity(0.5), radius: 6, x: 0, y: 2)
                    )
            }

            // Title + Subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Arrow indicator
            HStack {
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(accentColor.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassStyle(cornerRadius: 18, color: .white.opacity(0.1))
    }

    // MARK: - Health Stats Widget

    private func healthStatsWidget(_ vm: HomeViewModel) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Steps
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(ThemeColors.primary.opacity(0.12))
                            .frame(width: 46, height: 46)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(ThemeColors.primary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(vm.stepsToday)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Steps Today")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(16)
                .glassStyle(cornerRadius: 18, color: .white.opacity(0.08))

                // Active Calories
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(ThemeColors.error.opacity(0.12))
                            .frame(width: 46, height: 46)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(ThemeColors.error)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(vm.activeCaloriesBurned)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Active Cals")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(ThemeColors.surfaceColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
            }

            if let errorMsg = vm.healthMessage {
                Text(errorMsg)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeColors.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            } else if vm.stepsToday == 0 && vm.activeCaloriesBurned == 0 {
                Text("Stats remaining 0? Check iOS Settings > Health > Data Access > BiteBrain")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Embedded Progress Section
    private func progressSection(_ pvm: ProgressViewModel) -> some View {
        VStack(spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ThemeColors.info, ThemeColors.info.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(color: ThemeColors.info.opacity(0.3), radius: 6, x: 0, y: 3)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("Weight Progress")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            // Weight overview
            weightOverviewCard(pvm)

            // Stats row
            HStack(spacing: 10) {
                miniStat(label: "Low", value: pvm.lowestWeight.map { String(format: "%.1f", $0) } ?? "-")
                miniStat(label: "Avg", value: pvm.averageWeight.map { String(format: "%.1f", $0) } ?? "-")
                miniStat(label: "High", value: pvm.highestWeight.map { String(format: "%.1f", $0) } ?? "-")
            }

            // Goal Progress
            if let user = viewModel?.user {
                GoalProgressCard(
                    currentWeightKg: pvm.latestWeight ?? pvm.startWeight,
                    startWeightKg: pvm.startWeight,
                    goalWeightKg: user.goalWeightKg,
                    goalTargetDate: user.goalTargetDate,
                    goalSpeedKgPerWeek: user.goalSpeedKgPerWeek,
                    fitnessGoal: user.goal,
                    onEditTarget: {
                        showEditProfile = true
                    }
                )
            }

            // Trend Chart
            WeightGraphView(
                entries: pvm.filteredEntries,
                targetWeight: nil
            )
            .frame(height: 260)
        }
        .padding(16)
        .glassStyle(cornerRadius: 16, color: .white.opacity(0.08))
        .sheet(isPresented: Binding(
            get: { pvm.showAddWeight },
            set: { pvm.showAddWeight = $0 }
        ), onDismiss: {
            // NOTE: Do NOT call pvm.loadEntries() here — it would overwrite the optimistic
            // update that addWeight() already inserted into entries before closing the sheet.
            // Just sync the updated weight into HomeViewModel to refresh targets & calorie ring.
            if let newWeight = pvm.latestWeight {
                viewModel?.updateWeight(newWeight)
            }
        }) {
            WeightEntrySheet(viewModel: pvm)
                .presentationDetents([.medium])
        }
    }

    private func weightOverviewCard(_ pvm: ProgressViewModel) -> some View {
        VStack(spacing: 0) {
            // Update button at the top of the card
            Button {
                pvm.showAddWeight = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Update Weight")
                            .font(.system(size: 17, weight: .bold))
                        Text("Consistency is key")
                            .font(.system(size: 13, weight: .medium))
                            .opacity(0.7)
                    }
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
                .foregroundColor(.white)
                .padding(16)
                .background(ThemeColors.primaryGradient)
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("LATEST LOG")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.white.opacity(0.45))
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", pvm.latestWeight ?? pvm.startWeight))
                                 .font(.system(size: 38, weight: .bold, design: .rounded))
                                 .foregroundStyle(.white)
                            Text("kg")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 5) {
                        Text("CHANGE")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.white.opacity(0.45))
                        Text(pvm.weightChangeText)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(progressChangeColor(pvm))
                    }
                }
                
                if pvm.latestNote != nil || pvm.nextLogDateText != nil {
                    Divider()
                        .background(Color.white.opacity(0.05))
                    
                    VStack(alignment: .leading, spacing: 10) {
                        if let note = pvm.latestNote {
                            Label {
                                Text(note)
                                    .font(.system(size: 12, weight: .medium))
                            } icon: {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption2)
                            }
                            .foregroundStyle(ThemeColors.info.opacity(0.8))
                        }
                        
                        if let nextLog = pvm.nextLogDateText {
                            Label {
                                Text(nextLog)
                                    .font(.system(size: 12, weight: .medium))
                            } icon: {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.03))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("kg")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }


    private func progressChangeColor(_ pvm: ProgressViewModel) -> Color {
        guard let change = pvm.weightChange else { return .secondary }
        if change == 0 { return .secondary }
        return change < 0 ? .green : .orange
    }

    // MARK: - Meal Suggestion Card

    private func mealSuggestionCard(pattern: MealPattern, nutritionVM: NutritionViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ThemeColors.primary)
                Text("Your usual \(pattern.mealType.displayName)?")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(pattern.totalCalories)) kcal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Text(pattern.entries.map(\.foodName).joined(separator: ", "))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(2)

            Button {
                Task { await nutritionVM.logMealPattern(pattern) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15))
                    Text("Log All")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(ThemeColors.primary)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(ThemeColors.primary.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Custom Header
struct CustomHeader: View {
    let name: String
    var streak: Int = 0
    var onProfileTap: () -> Void = {}

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
                Text(name)
                    .font(.system(.title, design: .rounded).weight(.black))
                    .foregroundColor(.white)
            }

            Spacer()

            HStack(spacing: 12) {
                // Streak flame badge
                if streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(streakGradient)
                        Text("\(streak)")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08), in: Capsule())
                    .overlay(Capsule().stroke(streakBorderColor, lineWidth: 1))
                }

                // Profile avatar — tap to go to Profile tab
                Button(action: onProfileTap) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ThemeColors.primary, ThemeColors.primary.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .overlay(
                            Text(String(name.prefix(1)).uppercased())
                                .font(.system(.headline, design: .rounded).bold())
                                .foregroundColor(.white)
                        )
                        .shadow(color: ThemeColors.primary.opacity(0.35), radius: 6, x: 0, y: 3)
                }
            }
        }
        .padding(.top, 16)
    }

    private var streakGradient: LinearGradient {
        LinearGradient(
            colors: streak >= 7 ? [.red, .orange] : [.orange, .yellow],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private var streakBorderColor: Color {
        streak >= 7 ? .orange.opacity(0.4) : .white.opacity(0.1)
    }
}

// MARK: - Date Navigator
private struct DateNavigator: View {
    @Binding var selectedDate: Date

    var body: some View {
        HStack {
            Button {
                withAnimation {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(ThemeColors.primary.opacity(0.8))
            }

            Spacer()

            DatePicker(
                "Select Date",
                selection: Binding(
                    get: { selectedDate },
                    set: { newDate in
                        withAnimation { selectedDate = newDate }
                    }
                ),
                in: ...Date(), // Restrict dates to past and present
                displayedComponents: .date
            )
            .colorScheme(.dark)
            .labelsHidden()

            Spacer()

            Button {
                withAnimation {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Calendar.current.isDateInToday(selectedDate) ? Color.gray.opacity(0.3) : ThemeColors.primary.opacity(0.8))
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
        .padding(.horizontal, 4)
    }
}
