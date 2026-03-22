import SwiftUI

// MARK: - Workout Dashboard View (Redesigned)

struct WorkoutDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(DependencyContainer.self) private var container
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var viewModel: WorkoutViewModel?
    @State private var showActiveWorkout = false
    @State private var selectedPlan: WorkoutPlan?
    @State private var showAddExercise = false
    @State private var pendingExercise: PlanExercise?
    @State private var showDayPicker = false
    @State private var showPaywall = false

    var body: some View {
        Group {
            if let vm = viewModel {
                workoutContent(vm)
            } else {
                ProgressView()
                    .tint(ThemeColors.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(ThemeColors.backgroundDark.ignoresSafeArea())
        .onAppear {
            initViewModelIfNeeded()
            viewModel?.checkStaleSession()
        }
        .fullScreenCover(isPresented: $showActiveWorkout) {
            if let vm = viewModel {
                ActiveWorkoutView(viewModel: vm)
            }
        }
    }

    private func initViewModelIfNeeded() {
        guard viewModel == nil, appState.currentUser != nil else { return }
        viewModel = container.makeWorkoutViewModel(appState: appState)
        Task { await viewModel?.loadPlans() }
    }

    // MARK: - Content

    private func workoutContent(_ vm: WorkoutViewModel) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // 1. Clean Header
                headerSection(vm)

                // 2. Weekly Activity Rings
                weeklyActivitySection(vm)

                // 3. Active Session Banner (if exists)
                if vm.activeSession != nil {
                    activeSessionBanner(vm)
                }

                // 4. Quick Stats
                statsGrid(vm)

                // 5. My Plans
                myRoutinesSection(vm)

                // 6. AI Generate Card
                aiGeneratorSection(vm)

                // 7. Muscle Group Explorer
                muscleGroupExplorer(vm)

                // 8. Recent Workouts
                recentWorkoutsSection(vm)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
        .sheet(item: $selectedPlan) { plan in
            WorkoutDaySelectionSheet(plan: plan, onSelectDay: { plan, day in
                vm.startWorkout(plan: plan, day: day)
                showActiveWorkout = true
            })
        }
        .sheet(isPresented: Binding(get: { vm.showCreatePlan }, set: { vm.showCreatePlan = $0 })) {
            CreateWorkoutView(existingPlan: vm.planToEdit, onSave: { plan in
                vm.savePlan(plan)
                vm.planToEdit = nil
            })
        }
        .sheet(isPresented: Binding(get: { vm.showAIGenerate }, set: { vm.showAIGenerate = $0 })) {
            AIGenerateWorkoutSheet(viewModel: vm)
        }
        .sheet(isPresented: $showAddExercise) {
            exerciseSelectionSheet(vm)
        }
        .sheet(isPresented: $showDayPicker) {
            dayPickerSheet(vm)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - 1. Header

    private func headerSection(_ vm: WorkoutViewModel) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)

                Text("Workouts")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
            }
            Spacer()

            // Streak badge
            if currentStreak(vm) > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.orange)
                    Text("\(currentStreak(vm))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ThemeColors.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                        .overlay(Capsule().stroke(Color.orange.opacity(0.3), lineWidth: 1))
                )
            }
        }
    }

    // MARK: - 2. Weekly Activity Rings

    private func weeklyActivitySection(_ vm: WorkoutViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
                Spacer()
                Text(String(localized: "\(workoutsThisWeek(vm)) workouts"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
            }

            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = weekDate(offset: dayOffset)
                    let hasWorkout = didWorkout(on: date, vm: vm)
                    let isToday = Calendar.current.isDateInToday(date)

                    VStack(spacing: 10) {
                        Text(dayLabel(for: date))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(isToday ? ThemeColors.textPrimary : ThemeColors.textSecondary)

                        ZStack {
                            Circle()
                                .fill(hasWorkout ? ThemeColors.primary : ThemeColors.surfaceColor)
                                .frame(width: 38, height: 38)

                            if hasWorkout {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            } else if isToday {
                                Circle()
                                    .stroke(ThemeColors.primary.opacity(0.5), lineWidth: 2)
                                    .frame(width: 38, height: 38)
                            }
                        }

                        Text(dayNumber(for: date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(ThemeColors.surfaceColor)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(ThemeColors.surfaceBorder, lineWidth: 1))
            )
        }
    }

    // MARK: - 3. Active Session Banner

    private func activeSessionBanner(_ vm: WorkoutViewModel) -> some View {
        Button { showActiveWorkout = true } label: {
            HStack(spacing: 16) {
                // Animated pulse circle
                ZStack {
                    Circle()
                        .fill(ThemeColors.primary.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Circle()
                        .stroke(ThemeColors.primary.opacity(0.3), lineWidth: 3)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(ThemeColors.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "figure.run")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ThemeColors.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout in Progress")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(ThemeColors.textPrimary)
                    Text(vm.formattedTimer)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(ThemeColors.primary)
                }
                Spacer()

                Text("Continue")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(ThemeColors.primary))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(ThemeColors.primary.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(ThemeColors.primary.opacity(0.3), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Stats Grid

    private func statsGrid(_ vm: WorkoutViewModel) -> some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(vm.recentSessions.count)",
                label: "Sessions",
                icon: "flame.fill",
                color: .orange
            )
            statCard(
                value: totalVolume(vm),
                label: "Volume",
                icon: "scalemass.fill",
                color: ThemeColors.primary
            )
            statCard(
                value: avgDuration(vm),
                label: "Avg Time",
                icon: "clock.fill",
                color: .cyan
            )
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color.opacity(0.12))
                )

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(ThemeColors.textPrimary)

            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ThemeColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(ThemeColors.surfaceColor)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(ThemeColors.surfaceBorder, lineWidth: 1))
        )
    }

    // MARK: - 5. My Routines

    private func myRoutinesSection(_ vm: WorkoutViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Plans")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)

                Spacer()

                Button {
                    vm.planToEdit = nil
                    vm.showCreatePlan = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("New")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(ThemeColors.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(ThemeColors.primary.opacity(0.12))
                    )
                }
            }

            if vm.customPlans.isEmpty {
                emptyRoutinesPlaceholder(vm)
            } else {
                VStack(spacing: 16) {
                    ForEach(vm.customPlans) { plan in
                        routineCard(plan, vm: vm)
                    }
                }
            }
        }
    }

    private func routineCard(_ plan: WorkoutPlan, vm: WorkoutViewModel) -> some View {
        Button { selectedPlan = plan } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Top: Name + Difficulty
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(plan.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(ThemeColors.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 16) {
                            HStack(spacing: 5) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12))
                                Text(String(localized: "\(plan.days.count) days/week"))
                                    .font(.system(size: 13, weight: .medium))
                            }
                            HStack(spacing: 5) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text(String(localized: "~\(plan.estimatedDurationMin) min"))
                                    .font(.system(size: 13, weight: .medium))
                            }
                        }
                        .foregroundStyle(ThemeColors.textSecondary)
                    }
                    Spacer()
                    difficultyBadge(plan.difficulty)
                }

                // Muscle group tags
                let muscles = Array(Set(plan.days.flatMap(\.muscleGroups)))
                if !muscles.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(muscles.prefix(5), id: \.self) { muscle in
                                Text(muscle.displayName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(ThemeColors.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule().fill(ThemeColors.surfaceColor)
                                    )
                            }
                        }
                    }
                }

                // Start button
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                        Text("Start Workout")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(
                        Capsule()
                            .fill(ThemeColors.primary)
                            .shadow(color: ThemeColors.primary.opacity(0.3), radius: 8, y: 4)
                    )
                    Spacer()
                }
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(ThemeColors.surfaceColor)
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(ThemeColors.surfaceBorder, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                vm.planToEdit = plan
                vm.showCreatePlan = true
            } label: { Label("Edit Plan", systemImage: "pencil") }

            Button(role: .destructive) { vm.deletePlan(id: plan.id) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private func emptyRoutinesPlaceholder(_ vm: WorkoutViewModel) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(ThemeColors.primary.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(ThemeColors.primary.opacity(0.4))
            }

            VStack(spacing: 8) {
                Text("No Plans Yet")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ThemeColors.textSecondary)
                Text("Create your first workout plan\nor let AI generate one for you")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button { vm.showCreatePlan = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Create Plan")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Capsule().fill(ThemeColors.primary))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(ThemeColors.surfaceColor)
                .overlay(RoundedRectangle(cornerRadius: 26).stroke(ThemeColors.surfaceBorder, lineWidth: 1))
        )
    }

    // MARK: - 6. AI Generator

    private func aiGeneratorSection(_ vm: WorkoutViewModel) -> some View {
        Button {
            if subscriptionManager.isSubscribed {
                vm.generateError = nil
                vm.showAIGenerate = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 16) {
                // Left: Sparkle icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ThemeColors.primary, ThemeColors.primary.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Plan Generator")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(ThemeColors.textPrimary)
                    Text("Custom plan for your goals")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ThemeColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ThemeColors.textSecondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.primary.opacity(0.15), ThemeColors.primary.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(ThemeColors.primary.opacity(0.25), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 7. Muscle Group Explorer

    private func muscleGroupExplorer(_ vm: WorkoutViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Exercise Library")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
                Spacer()
                Button { showAddExercise = true } label: {
                    Text("See All")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ThemeColors.primary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(muscleGroups, id: \.name) { group in
                        Button { showAddExercise = true } label: {
                            VStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(group.color.opacity(0.12))
                                        .frame(width: 64, height: 64)
                                    Image(systemName: group.icon)
                                        .font(.system(size: 24))
                                        .foregroundStyle(group.color)
                                }
                                Text(group.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(ThemeColors.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - 8. Recent Workouts

    private func recentWorkoutsSection(_ vm: WorkoutViewModel) -> some View {
        Group {
            if !vm.recentSessions.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Workouts")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(ThemeColors.textPrimary)

                    VStack(spacing: 12) {
                        ForEach(vm.recentSessions.prefix(3)) { session in
                            recentSessionRow(session)
                        }
                    }
                }
            }
        }
    }

    private func recentSessionRow(_ session: WorkoutSession) -> some View {
        HStack(spacing: 14) {
            // Date circle
            VStack(spacing: 2) {
                Text(sessionDayLabel(session))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ThemeColors.textSecondary)
                Text(sessionDayNumber(session))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
            }
            .frame(width: 48, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(ThemeColors.surfaceColor)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(session.planName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
                    .lineLimit(1)
                Text(session.dayLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.formattedDuration)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(ThemeColors.textPrimary)
                Text(String(localized: "\(session.totalSets) sets"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ThemeColors.surfaceColor)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(ThemeColors.surfaceBorder, lineWidth: 1))
        )
    }

    // MARK: - Sheets & Helpers

    private func exerciseSelectionSheet(_ vm: WorkoutViewModel) -> some View {
        ExerciseSelectionView(onExerciseSelected: { exercise in
            pendingExercise = exercise
            showAddExercise = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                handleExerciseAdd(vm, exercise: exercise)
            }
        })
    }

    private func handleExerciseAdd(_ vm: WorkoutViewModel, exercise: PlanExercise) {
        if vm.customPlans.count == 1, let plan = vm.customPlans.first, plan.days.count == 1 {
            vm.addExerciseToPlan(planId: plan.id, dayIndex: 0, exercise: exercise)
            pendingExercise = nil
        } else if vm.customPlans.isEmpty {
            let day = WorkoutDay(id: UUID().uuidString, dayNumber: 1, label: "Day 1", muscleGroups: [exercise.muscleGroup], exercises: [exercise])
            let plan = WorkoutPlan(id: UUID().uuidString, name: "Custom Workout", description: "", difficulty: .intermediate, daysPerWeek: 1, isPremium: false, category: .fullBody, estimatedDurationMin: 45, days: [day], createdAt: Date())
            vm.savePlan(plan)
            pendingExercise = nil
        } else {
            showDayPicker = true
        }
    }

    private func dayPickerSheet(_ vm: WorkoutViewModel) -> some View {
        Group {
            if let exercise = pendingExercise {
                AddExerciseDayPickerSheet(
                    plans: vm.customPlans,
                    exercise: exercise,
                    onSelect: { planId, dayIndex in
                        vm.addExerciseToPlan(planId: planId, dayIndex: dayIndex, exercise: exercise)
                        pendingExercise = nil
                        showDayPicker = false
                    },
                    onCancel: {
                        pendingExercise = nil
                        showDayPicker = false
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }

    private func difficultyBadge(_ difficulty: WorkoutPlan.Difficulty) -> some View {
        Text(difficulty.displayName)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(difficultyColor(difficulty))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(difficultyColor(difficulty).opacity(0.12))
            )
    }

    private func difficultyColor(_ difficulty: WorkoutPlan.Difficulty) -> Color {
        switch difficulty {
        case .beginner: return ThemeColors.success
        case .intermediate: return .orange
        case .advanced: return ThemeColors.error
        }
    }

    // MARK: - Computed Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return String(localized: "Good Morning") }
        else if hour < 17 { return String(localized: "Good Afternoon") }
        else { return String(localized: "Good Evening") }
    }

    private func currentStreak(_ vm: WorkoutViewModel) -> Int {
        guard !vm.recentSessions.isEmpty else { return 0 }
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())

        while true {
            let dayHasWorkout = vm.recentSessions.contains { session in
                Calendar.current.isDate(session.startedAt, inSameDayAs: checkDate)
            }
            if dayHasWorkout {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            } else if streak == 0 {
                // Check yesterday too (streak might start from yesterday)
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
                let yesterdayWorkout = vm.recentSessions.contains { session in
                    Calendar.current.isDate(session.startedAt, inSameDayAs: checkDate)
                }
                if yesterdayWorkout {
                    streak += 1
                    checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
                } else {
                    break
                }
            } else {
                break
            }
        }
        return streak
    }

    private func workoutsThisWeek(_ vm: WorkoutViewModel) -> Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return vm.recentSessions.filter { $0.startedAt >= startOfWeek }.count
    }

    private func weekDate(offset: Int) -> Date {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }

    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func didWorkout(on date: Date, vm: WorkoutViewModel) -> Bool {
        vm.recentSessions.contains { Calendar.current.isDate($0.startedAt, inSameDayAs: date) }
    }

    private func sessionDayLabel(_ session: WorkoutSession) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: session.startedAt).uppercased()
    }

    private func sessionDayNumber(_ session: WorkoutSession) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: session.startedAt)
    }

    private func totalVolume(_ vm: WorkoutViewModel) -> String {
        let total = vm.recentSessions.reduce(0.0) { $0 + $1.totalVolume }
        if total >= 1000 { return String(format: "%.1fk", total / 1000) }
        return "\(Int(total))"
    }

    private func avgDuration(_ vm: WorkoutViewModel) -> String {
        guard !vm.recentSessions.isEmpty else { return "0m" }
        let avg = vm.recentSessions.reduce(0) { $0 + $1.durationSeconds } / vm.recentSessions.count
        return "\(avg / 60)m"
    }

    // MARK: - Muscle Group Data

    private var muscleGroups: [(name: String, icon: String, color: Color)] {
        [
            ("Chest", "figure.arms.open", ThemeColors.primary),
            ("Back", "figure.rowing", .cyan),
            ("Legs", "figure.walk", .green),
            ("Shoulders", "figure.boxing", .orange),
            ("Arms", "figure.strengthtraining.traditional", .purple),
            ("Core", "figure.core.training", .yellow),
        ]
    }
}

// MARK: - Add Exercise Day Picker Sheet

private struct AddExerciseDayPickerSheet: View {
    let plans: [WorkoutPlan]
    let exercise: PlanExercise
    let onSelect: (String, Int) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Add to Routine")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
                Spacer()
                Button { onCancel() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
            }

            // Exercise being added
            HStack(spacing: 12) {
                ExerciseGifThumbnail(
                    gifUrl: exercise.gifUrl,
                    muscleGroup: exercise.muscleGroup,
                    exerciseName: exercise.exerciseName,
                    instructions: exercise.instructions,
                    size: 44
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.exerciseName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(ThemeColors.textPrimary)
                        .lineLimit(1)
                    Text(exercise.muscleGroup.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(ThemeColors.surfaceColor)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(ThemeColors.surfaceBorder, lineWidth: 1))
            )

            // Plan + Day list
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(plans) { plan in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(plan.name.uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(ThemeColors.primary)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 10)

                            ForEach(Array(plan.days.enumerated()), id: \.element.id) { dayIndex, day in
                                Button {
                                    onSelect(plan.id, dayIndex)
                                } label: {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(ThemeColors.primary.opacity(0.1))
                                                .frame(width: 40, height: 40)
                                            Text("\(day.dayNumber)")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundStyle(ThemeColors.primary)
                                        }

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(day.label)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundStyle(ThemeColors.textPrimary)
                                            Text(String(localized: "\(day.exercises.count) exercises"))
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(ThemeColors.textSecondary)
                                        }

                                        Spacer()

                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(ThemeColors.primary)
                                    }
                                    .padding(16)
                                }
                                .buttonStyle(.plain)

                                if dayIndex < plan.days.count - 1 {
                                    Divider().background(ThemeColors.surfaceBorder).padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(ThemeColors.surfaceColor)
                                .overlay(RoundedRectangle(cornerRadius: 22).stroke(ThemeColors.surfaceBorder, lineWidth: 1))
                        )
                    }
                }
            }
        }
        .padding(24)
        .background(ThemeColors.backgroundDark.ignoresSafeArea())
    }
}

// MARK: - AI Generate Workout Sheet

private struct AIGenerateWorkoutSheet: View {
    @Bindable var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var daysPerWeek = 3
    @State private var selectedGoal: FitnessGoal = .maintain
    @State private var selectedDifficulty: WorkoutPlan.Difficulty = .intermediate
    @State private var selectedCategory: WorkoutPlan.Category = .fullBody
    @State private var showExercisePicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeColors.backgroundDark.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(ThemeColors.primary.opacity(0.12))
                                    .frame(width: 64, height: 64)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(ThemeColors.primary)
                            }

                            Text("AI Plan Generator")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(ThemeColors.textPrimary)
                            Text("Customized to your body & goals")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(ThemeColors.textSecondary)
                        }
                        .padding(.top, 20)

                        if viewModel.isGenerating {
                            generationLoadingView
                        } else if let error = viewModel.generateError {
                            errorView(error)
                        } else {
                            optionsForm
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExerciseSelectionView(
                    selectedExercises: $viewModel.selectedSeedExercises,
                    isMultiSelect: true
                )
            }
        }
    }

    private var optionsForm: some View {
        VStack(spacing: 28) {
            // Training Frequency
            VStack(alignment: .leading, spacing: 14) {
                Text("Days per Week")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(ThemeColors.textSecondary)

                HStack(spacing: 10) {
                    ForEach(2...6, id: \.self) { num in
                        Button { daysPerWeek = num } label: {
                            Text("\(num)")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(daysPerWeek == num ? ThemeColors.primary : ThemeColors.surfaceColor)
                                )
                                .foregroundStyle(daysPerWeek == num ? .white : ThemeColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Goal, Difficulty, Category
            VStack(spacing: 24) {
                optionSection("Primary Goal") {
                    pickerGrid(FitnessGoal.allCases, selected: $selectedGoal) { goal in
                        Text(goal.displayName)
                            .font(.system(size: 13, weight: .bold))
                    }
                }

                optionSection("Experience Level") {
                    pickerGrid(WorkoutPlan.Difficulty.allCases, selected: $selectedDifficulty) { diff in
                        Text(diff.displayName)
                            .font(.system(size: 13, weight: .bold))
                    }
                }

                optionSection("Category") {
                    pickerGrid(WorkoutPlan.Category.allCases, selected: $selectedCategory) { cat in
                        Text(cat.displayName)
                            .font(.system(size: 13, weight: .bold))
                    }
                }
            }

            // Target Exercises
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Target Exercises")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(ThemeColors.textSecondary)
                    Spacer()
                    if !viewModel.selectedSeedExercises.isEmpty {
                        Text(String(localized: "\(viewModel.selectedSeedExercises.count) selected"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(ThemeColors.primary)
                    }
                }

                Button {
                    showExercisePicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text(viewModel.selectedSeedExercises.isEmpty ? "Select exercises" : "Modify selection")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(ThemeColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ThemeColors.primary.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.primary.opacity(0.2), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)

                if !viewModel.selectedSeedExercises.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.selectedSeedExercises, id: \.id) { ex in
                                ZStack(alignment: .topTrailing) {
                                    ExerciseGifThumbnail(
                                        gifUrl: ex.gifUrl,
                                        muscleGroup: ex.muscleGroup,
                                        exerciseName: ex.name,
                                        instructions: ex.instructions,
                                        size: 52
                                    )
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(ThemeColors.surfaceBorder, lineWidth: 1))

                                    Button {
                                        if let index = viewModel.selectedSeedExercises.firstIndex(where: { $0.id == ex.id }) {
                                            viewModel.selectedSeedExercises.remove(at: index)
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(.red)
                                            .background(Circle().fill(.black))
                                    }
                                    .offset(x: 6, y: -6)
                                }
                            }
                        }
                        .padding(.top, 6)
                        .padding(.trailing, 10)
                    }
                }
            }

            // Generate Button
            Button {
                Task {
                    await viewModel.generateAIPlan(
                        daysPerWeek: daysPerWeek,
                        goal: selectedGoal,
                        difficulty: selectedDifficulty,
                        category: selectedCategory,
                        seedExercises: viewModel.selectedSeedExercises
                    )
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                    Text("Generate Plan")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(ThemeColors.primary)
                        .shadow(color: ThemeColors.primary.opacity(0.3), radius: 10, y: 5)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    private func optionSection<V: View>(_ title: String, @ViewBuilder content: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(ThemeColors.textSecondary)
            content()
        }
    }

    private func pickerGrid<T: Hashable, V: View>(_ items: [T], selected: Binding<T>, @ViewBuilder content: @escaping (T) -> V) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(items, id: \.self) { item in
                Button { selected.wrappedValue = item } label: {
                    content(item)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selected.wrappedValue == item ? ThemeColors.primary : ThemeColors.surfaceColor)
                        )
                        .foregroundStyle(selected.wrappedValue == item ? .white : ThemeColors.textSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selected.wrappedValue == item ? Color.clear : ThemeColors.surfaceBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var generationLoadingView: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 40)

            ZStack {
                Circle()
                    .stroke(ThemeColors.primary.opacity(0.1), lineWidth: 6)
                    .frame(width: 90, height: 90)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(ThemeColors.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(viewModel.isGenerating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: viewModel.isGenerating)
            }

            VStack(spacing: 10) {
                Text("Building Your Plan")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
                Text("Customizing exercises for your goals...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(20)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(ThemeColors.error.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(ThemeColors.error.opacity(0.7))
            }

            VStack(spacing: 8) {
                Text("Generation Failed")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.generateError = nil
            } label: {
                Text("Try Again")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(ThemeColors.primary))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 50)
    }
}
