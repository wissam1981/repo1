import SwiftUI
import Observation

// MARK: - Home View Model

@Observable
final class HomeViewModel {

    // MARK: - Published State

    var todayLog: NutritionLog
    var selectedDate: Date
    var latestWeight: ProgressEntry?
    var greeting: String = ""
    var activeCaloriesBurned: Int = 0
    var stepsToday: Int = 0
    var healthMessage: String?

    // MARK: - Recovery Advisor

    var isLoadingRecovery: Bool = false
    var recoveryAdvice: RecoveryAdvice?

    // MARK: - Contextual Insight

    var contextualInsight: String = ""

    // MARK: - Goal Suggestion

    var goalSuggestion: GoalSuggestion?

    func dismissGoalSuggestion() {
        goalSuggestion = nil
    }

    func applyGoalSuggestion() {
        guard let suggestion = goalSuggestion else { return }
        user.targetCalories = suggestion.newCalories
        goalSuggestion = nil
    }

    // MARK: - Dependencies

    private let coreDataService: CoreDataService
    private let healthKitService: HealthKitServiceProtocol
    var user: UserProfile
    private var logChangeObserver: Any?

    // MARK: - Init

    init(user: UserProfile, coreDataService: CoreDataService, healthKitService: HealthKitServiceProtocol) {
        self.user = user
        self.coreDataService = coreDataService
        self.healthKitService = healthKitService
        self.selectedDate = .now
        self.todayLog = coreDataService.fetchNutritionLogDomain(for: .now) ?? NutritionLog(date: .now)
        self.latestWeight = coreDataService.fetchLatestProgressEntry()
        self.greeting = Self.makeGreeting(name: user.displayName)

        // Listen for external changes (e.g. food logging from NutritionViewModel)
        logChangeObserver = NotificationCenter.default.addObserver(
            forName: .nutritionLogDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        if let observer = logChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Targets (from user profile)

    var targetCalories: Int { user.targetCalories }
    var targetProteinG: Int { user.targetProteinG }
    var targetCarbsG: Int { user.targetCarbsG }
    var targetFatG: Int { user.targetFatG }

    // MARK: - Goal Context

    var fitnessGoal: FitnessGoal { user.goal }
    var activityLevel: ActivityLevel { user.activityLevel }
    var goalSpeedKgPerWeek: Double { user.goalSpeedKgPerWeek }

    var bmr: Int {
        let result = currentCalculation
        return Int(result.bmr)
    }

    var tdee: Int {
        let result = currentCalculation
        return Int(result.tdee)
    }

    /// Daily calorie deficit (negative) or surplus (positive) relative to TDEE
    var dailyDeficitOrSurplus: Int {
        targetCalories - tdee
    }

    /// Total calories burned today (TDEE + Active Calories)
    var totalBurnedToday: Int {
        tdee + activeCaloriesBurned
    }

    /// Actual calorie deficit/surplus today based on intake and total burn
    var actualDeficit: Int {
        totalBurnedToday - caloriesConsumed
    }

    private var currentCalculation: FitnessCalculationResult {
        FitnessCalculator.calculate(
            weightKg: currentWeightKg,
            heightCm: user.heightCm,
            dateOfBirth: user.dateOfBirth,
            gender: user.gender,
            activityLevel: user.activityLevel,
            goal: user.goal,
            goalSpeedKgPerWeek: user.goalSpeedKgPerWeek
        )
    }

    // MARK: - Meal Breakdown

    var breakfastCalories: Int { Int(todayLog.breakfastEntries.reduce(0) { $0 + $1.calories }) }
    var lunchCalories: Int { Int(todayLog.lunchEntries.reduce(0) { $0 + $1.calories }) }
    var dinnerCalories: Int { Int(todayLog.dinnerEntries.reduce(0) { $0 + $1.calories }) }
    var snackCalories: Int { Int(todayLog.snackEntries.reduce(0) { $0 + $1.calories }) }

    // MARK: - Progress

    var caloriesConsumed: Int { Int(todayLog.totalCalories) }
    var caloriesRemaining: Int { max(0, targetCalories - caloriesConsumed) }
    var calorieProgress: Double { todayLog.calorieProgress(target: targetCalories) }

    var proteinConsumed: Int { Int(todayLog.totalProteinG) }
    var proteinProgress: Double { todayLog.proteinProgress(target: targetProteinG) }

    var carbsConsumed: Int { Int(todayLog.totalCarbsG) }
    var carbsProgress: Double {
        guard targetCarbsG > 0 else { return 0 }
        return min(Double(carbsConsumed) / Double(targetCarbsG), 1.0)
    }

    var fatConsumed: Int { Int(todayLog.totalFatG) }
    var fatProgress: Double {
        guard targetFatG > 0 else { return 0 }
        return min(Double(fatConsumed) / Double(targetFatG), 1.0)
    }

    // MARK: - Logging Streak

    /// Number of consecutive days (ending today or yesterday) with at least one food entry.
    var loggingStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date.now)

        // If today has entries, count it; otherwise start from yesterday
        let todayLog = coreDataService.fetchNutritionLogDomain(for: checkDate)
        if let log = todayLog, !log.entries.isEmpty {
            streak = 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        } else {
            // Today has nothing yet — check from yesterday
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        // Walk backwards counting consecutive logged days
        for _ in 0..<365 {
            let log = coreDataService.fetchNutritionLogDomain(for: checkDate)
            if let log, !log.entries.isEmpty {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Weight

    var currentWeightKg: Double {
        latestWeight?.weightKg ?? user.weightKg
    }

    var weightChangeText: String {
        guard let latest = latestWeight else { return "No data" }
        let diff = latest.weightKg - user.weightKg
        let sign = diff >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", diff)) kg from start"
    }

    // MARK: - Refresh

    func refresh() {
        if let cdUser = coreDataService.fetchUserProfile(uid: user.uid),
           let updatedUser = cdUser.toDomain() {
            self.user = updatedUser
        }
        
        todayLog = coreDataService.fetchNutritionLogDomain(for: selectedDate) ?? NutritionLog(date: selectedDate)
        latestWeight = coreDataService.fetchLatestProgressEntry()
        recalculateTargets()
        
        healthMessage = nil

        Task {
            do {
                try await healthKitService.requestAuthorization()
            } catch {
                // Auth not granted — silently degrade
            }

            do {
                let cals = try await healthKitService.fetchActiveCaloriesToday()
                await MainActor.run { self.activeCaloriesBurned = Int(cals) }
            } catch {
                await MainActor.run { self.activeCaloriesBurned = 0 }
            }

            do {
                let steps = try await healthKitService.fetchStepsToday()
                await MainActor.run { self.stepsToday = Int(steps) }
            } catch {
                await MainActor.run { self.stepsToday = 0 }
            }
        }
    }

    // MARK: - Recovery Advisor

    func fetchRecoveryAdvice(workoutVM: WorkoutViewModel) {
        guard !isLoadingRecovery else { return }
        isLoadingRecovery = true

        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: .now))!

        // Yesterday's workout (if any)
        let yesterdayWorkout = workoutVM.recentSessions.first { session in
            calendar.isDate(session.startedAt, inSameDayAs: yesterday)
        }

        // Yesterday's nutrition
        let yesterdayNutrition = coreDataService.fetchNutritionLogDomain(for: yesterday)

        // Today's nutrition
        let todayNutrition = coreDataService.fetchNutritionLogDomain(for: .now)

        Task {
            do {
                let advice = try await RecoveryAdvisorService.shared.assessRecovery(
                    yesterdayWorkout: yesterdayWorkout,
                    yesterdayNutrition: yesterdayNutrition,
                    todayNutrition: todayNutrition
                )
                await MainActor.run {
                    self.recoveryAdvice = advice
                    self.isLoadingRecovery = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingRecovery = false
                }
            }
        }
    }

    /// Update weight directly (bypasses CoreData read timing issues)
    func updateWeight(_ weightKg: Double) {
        latestWeight = ProgressEntry(weightKg: weightKg)
        recalculateTargets()
    }
    
    // MARK: - Date Navigation
    
    func changeDate(to newDate: Date) {
        selectedDate = newDate
        refresh()
    }
    
    // MARK: - Dynamic Target Calculation
    
    private func recalculateTargets() {
        // Enforce dynamic Bodily limits based on current weight/age/height
        let calcResult = FitnessCalculator.calculate(
            weightKg: currentWeightKg,
            heightCm: user.heightCm,
            dateOfBirth: user.dateOfBirth,
            gender: user.gender,
            activityLevel: user.activityLevel,
            goal: user.goal,
            goalSpeedKgPerWeek: user.goalSpeedKgPerWeek
        )
        
        // Prevent infinite observation loops: Only update if the core limits ACTUALLY changed.
        let needsUpdate = calcResult.targetCalories != user.targetCalories || 
                          calcResult.targetProteinG != user.targetProteinG ||
                          calcResult.targetCarbsG != user.targetCarbsG ||
                          calcResult.targetFatG != user.targetFatG
                          
        if needsUpdate {
            user.applyCalculation(calcResult)
            
            // Persist the newly calculated bodily limits
            Task {
                    await coreDataService.saveUserProfile(user)
            }
        }
    }

    // MARK: - Weekly Habits

    /// Build week data for the habits card (Mon–Sun of current week)
    var weeklyHabitDays: [WeeklyHabitDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        // Find Monday of this week
        var weekStart = today
        while calendar.component(.weekday, from: weekStart) != 2 { // 2 = Monday
            weekStart = calendar.date(byAdding: .day, value: -1, to: weekStart)!
        }

        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            let log = coreDataService.fetchNutritionLogDomain(for: date)
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let isPast = date < today && !isToday

            let hitProtein = (log?.totalProteinG ?? 0) >= Double(targetProteinG) * 0.8
            let hitCalories = (log?.totalCalories ?? 0) >= Double(targetCalories) * 0.5
            let logged = log != nil && !(log?.entries.isEmpty ?? true)

            let completed = [hitProtein, hitCalories, logged].filter { $0 }.count
            let total = 3

            return WeeklyHabitDay(
                shortName: dayNames[offset],
                dayNumber: calendar.component(.day, from: date),
                isToday: isToday,
                isPast: isPast,
                allHabitsComplete: completed == total && (isPast || isToday),
                someHabitsComplete: completed > 0 && completed < total && (isPast || isToday),
                completionRatio: (isPast || isToday) ? Double(completed) / Double(total) : 0
            )
        }
    }

    /// Build habit trackers for this week
    var weeklyHabits: [HabitTracker] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        var weekStart = today
        while calendar.component(.weekday, from: weekStart) != 2 {
            weekStart = calendar.date(byAdding: .day, value: -1, to: weekStart)!
        }

        var proteinDays = 0
        var calorieDays = 0
        var loggedDays = 0

        for offset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            guard date <= today else { continue }
            let log = coreDataService.fetchNutritionLogDomain(for: date)

            if (log?.totalProteinG ?? 0) >= Double(targetProteinG) * 0.8 { proteinDays += 1 }
            if (log?.totalCalories ?? 0) >= Double(targetCalories) * 0.5 { calorieDays += 1 }
            if log != nil && !(log?.entries.isEmpty ?? true) { loggedDays += 1 }
        }

        return [
            HabitTracker(title: "Hit protein goal", icon: "bolt.fill", color: ThemeColors.primary, completedDays: proteinDays, targetDays: 5),
            HabitTracker(title: "Stay in calorie range", icon: "flame.fill", color: ThemeColors.info, completedDays: calorieDays, targetDays: 5),
            HabitTracker(title: "Log your meals", icon: "fork.knife", color: ThemeColors.success, completedDays: loggedDays, targetDays: 7)
        ]
    }

    // MARK: - Weekly Report

    var weeklyReport: WeeklyReportData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        // Last 7 days (Mon-Sun or last 7)
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        var dailyCals: [WeeklyReportData.DayCalorie] = []
        var totalCal = 0.0
        var totalProtein = 0.0
        var totalCarbs = 0.0
        var totalFat = 0.0
        var totalWater = 0.0
        var daysLogged = 0

        for offset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: offset, to: weekStart)!
            let log = coreDataService.fetchNutritionLogDomain(for: date)
            let cal = Int(log?.totalCalories ?? 0)
            let weekdayIndex = (calendar.component(.weekday, from: date) + 5) % 7 // Mon=0
            let dayLabel = dayNames[weekdayIndex]

            dailyCals.append(.init(day: dayLabel, calories: cal))
            totalCal += Double(cal)
            totalProtein += log?.totalProteinG ?? 0
            totalCarbs += log?.totalCarbsG ?? 0
            totalFat += log?.totalFatG ?? 0
            totalWater += log?.waterMl ?? 0

            if log != nil && !(log?.entries.isEmpty ?? true) {
                daysLogged += 1
            }
        }

        let divisor = max(daysLogged, 1)

        // Weight
        let entries = coreDataService.fetchProgressEntries(limit: 14)
        let weekEntries = entries.filter { $0.date >= weekStart }
        let startW = weekEntries.last?.weightKg ?? 0
        let endW = weekEntries.first?.weightKg ?? latestWeight?.weightKg ?? 0

        // Date range string
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let rangeStr = "\(fmt.string(from: weekStart)) – \(fmt.string(from: today))"

        // Insights
        var insights: [String] = []
        let avgCal = Int(totalCal / Double(divisor))
        if avgCal > targetCalories {
            insights.append("You averaged \(avgCal - targetCalories) calories over your goal. Try trimming snacks.")
        } else if avgCal > 0 {
            insights.append("Great job staying within your calorie goal this week!")
        }
        let avgProt = Int(totalProtein / Double(divisor))
        if avgProt < targetProteinG {
            insights.append("Your protein intake averaged \(targetProteinG - avgProt)g below target. Add more lean protein.")
        } else {
            insights.append("You hit your protein target on average — keep it up!")
        }
        if daysLogged < 5 {
            insights.append("You only logged \(daysLogged) days. Consistency is key — aim for 5+ days.")
        } else {
            insights.append("Solid logging consistency with \(daysLogged)/7 days tracked.")
        }
        if endW > 0 && startW > 0 {
            let diff = endW - startW
            if diff < -0.2 {
                insights.append("You lost \(String(format: "%.1f", abs(diff))) kg this week — great progress!")
            } else if diff > 0.3 {
                insights.append("Weight went up \(String(format: "%.1f", diff)) kg. Check your calorie balance.")
            }
        }

        return WeeklyReportData(
            dateRange: rangeStr,
            dailyCalories: dailyCals,
            avgCalories: avgCal,
            totalCalories: Int(totalCal),
            calorieGoal: targetCalories,
            avgProtein: avgProt,
            avgCarbs: Int(totalCarbs / Double(divisor)),
            avgFat: Int(totalFat / Double(divisor)),
            proteinGoal: targetProteinG,
            carbsGoal: targetCarbsG,
            fatGoal: targetFatG,
            daysLogged: daysLogged,
            avgWaterMl: Int(totalWater / Double(divisor)),
            startWeight: startW,
            endWeight: endW,
            weightChange: endW > 0 && startW > 0 ? endW - startW : 0,
            insights: insights
        )
    }

    // MARK: - Greeting

    private static func makeGreeting(name: String) -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        let firstName = name.components(separatedBy: " ").first ?? name
        switch hour {
        case 5..<12:  return "Good Morning, \(firstName)"
        case 12..<17: return "Good Afternoon, \(firstName)"
        case 17..<21: return "Good Evening, \(firstName)"
        default:      return "Good Night, \(firstName)"
        }
    }
}

// MARK: - Goal Suggestion Model

struct GoalSuggestion {
    enum Severity {
        case info
        case warning
    }

    let reason: String
    let newCalories: Int
    let severity: Severity
    let icon: String
}
