import SwiftUI
import Observation

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case gender = 0
    case age
    case body         // height + weight
    case activity
    case goal
    case goalSpeed    // how fast (0.25, 0.5, 1.0 kg/week)
    case goalWeight   // target weight + date (estimated from speed)
    case notifications // meal reminders frequency + time
    case subscribe
    case results

    var title: String {
        switch self {
        case .gender:     return "Gender"
        case .age:        return "Date of Birth"
        case .body:       return "Body Metrics"
        case .activity:   return "Activity Level"
        case .goal:       return "Your Goal"
        case .goalWeight: return "Goal Weight"
        case .goalSpeed:  return "Goal Speed"
        case .notifications: return "Reminders"
        case .subscribe:    return "Premium"
        case .results:      return "Your Plan"
        }
    }

    var progress: Double {
        Double(rawValue + 1) / Double(OnboardingStep.allCases.count)
    }
}

// MARK: - Onboarding View Model

@Observable
final class OnboardingViewModel {

    // MARK: - Step State

    var currentStep: OnboardingStep = .gender

    // MARK: - User Inputs

    var gender: Gender = .male
    var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: .now) ?? .now
    var heightCm: Double = 175
    var weightKg: Double = 75 {
        didSet { updateEstimatedTargetDate() }
    }
    var activityLevel: ActivityLevel = .moderate
    var goal: FitnessGoal = .lose
    var selectedGoalSpeed: GoalSpeed = GoalSpeed.default {
        didSet { updateEstimatedTargetDate() }
    }
    // Goal Weight inputs
    var goalWeightKg: Double = 65 {
        didSet { updateEstimatedTargetDate() }
    }
    var goalTargetDate: Date = Calendar.current.date(byAdding: .weekOfYear, value: 12, to: .now) ?? .now
    
    // Notification inputs
    var reminderFrequency: ReminderFrequency = .daily
    var reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now

    private func updateEstimatedTargetDate() {
        let delta = abs(weightKg - goalWeightKg)
        let speed = selectedGoalSpeed.kgPerWeek
        guard speed > 0 else { return }
        let weeksNeeded = Int(ceil(delta / speed))
        goalTargetDate = Calendar.current.date(byAdding: .weekOfYear, value: weeksNeeded, to: .now) ?? .now
    }

    // MARK: - Unit Toggle

    var useMetric: Bool = true

    // Height in imperial
    var heightFeet: Int {
        get { Int(heightCm / 30.48) }
        set {
            let inches = Int(heightCm / 2.54) % 12
            heightCm = Double(newValue * 12 + inches) * 2.54
        }
    }
    var heightInches: Int {
        get { Int(heightCm / 2.54) % 12 }
        set {
            let feet = Int(heightCm / 30.48)
            heightCm = Double(feet * 12 + newValue) * 2.54
        }
    }

    // Weight in imperial
    var weightLbs: Double {
        get { FitnessCalculator.kgToLbs(weightKg) }
        set { weightKg = FitnessCalculator.lbsToKg(newValue) }
    }

    // MARK: - Computed Results

    var calculationResult: FitnessCalculationResult {
        FitnessCalculator.calculate(
            weightKg: weightKg,
            heightCm: heightCm,
            dateOfBirth: dateOfBirth,
            gender: gender,
            activityLevel: activityLevel,
            goal: goal,
            goalSpeedKgPerWeek: goal == .maintain ? 0 : selectedGoalSpeed.kgPerWeek
        )
    }

    var bmi: Double {
        FitnessCalculator.calculateBMI(weightKg: weightKg, heightCm: heightCm)
    }

    var bmiCategory: String {
        FitnessCalculator.bmiCategory(bmi: bmi)
    }

    var ageYears: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: .now).year ?? 0
    }

    // MARK: - Validation

    var isGoalWeightValid: Bool {
        if goal == .maintain { return true }
        if goal == .lose {
            return goalWeightKg < weightKg
        } else { // .gain
            return goalWeightKg > weightKg
        }
    }

    var goalWeightValidationMessage: String? {
        if goal == .maintain { return nil }
        if goal == .lose && goalWeightKg >= weightKg {
            return "Goal weight must be less than current weight to lose fat."
        } else if goal == .gain && goalWeightKg <= weightKg {
            return "Goal weight must be greater than current weight to build muscle."
        }
        return nil
    }

    // MARK: - Navigation

    var canGoBack: Bool {
        currentStep.rawValue > 0
    }

    var isLastStep: Bool {
        currentStep == .results
    }

    func goNext() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        // Skip goalSpeed and goalWeight steps if goal is maintain
        if next == .goalSpeed && goal == .maintain {
            currentStep = .goalWeight
            goNext() // will skip goalWeight too
        } else if next == .goalWeight && goal == .maintain {
            currentStep = .notifications
            goNext() // go to subscribe or results
        } else {
            currentStep = next
        }
    }

    func goBack() {
        guard let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        // Skip goalSpeed and goalWeight going back if goal is maintain
        if prev == .goalWeight && goal == .maintain {
            currentStep = .goalSpeed
            goBack() // will skip goalSpeed too
        } else if prev == .goalSpeed && goal == .maintain {
            currentStep = .goal
        } else if prev == .notifications && goal == .maintain {
            currentStep = .goal // Back from notifications to goal for maintainers
        } else {
            currentStep = prev
        }
    }

    // MARK: - Save

    var isSaving: Bool = false
    var saveError: String?

    /// Builds the final UserProfile, saves to CoreData + Firestore, marks onboarding complete.
    func completeOnboarding(
        appState: AppState,
        coreDataService: CoreDataService,
        firestoreService: FirestoreServiceProtocol
    ) async {
        guard var user = appState.currentUser else { return }
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        // Apply user inputs
        user.gender = gender
        user.dateOfBirth = dateOfBirth
        user.heightCm = heightCm
        user.weightKg = weightKg
        user.activityLevel = activityLevel
        user.goal = goal
        user.goalSpeedKgPerWeek = goal == .maintain ? 0 : selectedGoalSpeed.kgPerWeek
        user.goalWeightKg = goal == .maintain ? nil : goalWeightKg
        user.goalTargetDate = goal == .maintain ? nil : goalTargetDate
        user.mealReminderFrequency = reminderFrequency
        user.mealReminderTime = reminderTime

        // Apply calculated macro targets
        let result = calculationResult
        user.applyCalculation(result)

        // Mark onboarding complete
        user.isOnboardingComplete = true
        user.updatedAt = Date()

        // Save to CoreData (offline-first)
        await coreDataService.saveUserProfile(user)

        // Seed local food database on first launch
        await FoodDatabaseSeeder.seedIfNeeded(coreDataService: coreDataService)

        // Save to Firestore (fire and forget — offline-first)
        Task {
            do {
                try await firestoreService.saveUserProfile(user)
            } catch {
                // Firestore save failed — dirty flag on CoreData will sync later
                print("[Onboarding] Firestore save failed: \(error.localizedDescription)")
            }
        }

        // Transition to main app
        appState.handleAuthStateChange(user: user)
        
        // Schedule meal reminders based on user choice
        Task {
            await NotificationManager.shared.scheduleMealReminders(
                frequency: reminderFrequency,
                time: reminderTime
            )
        }
    }
}
