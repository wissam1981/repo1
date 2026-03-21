import SwiftUI
import Observation

// MARK: - Workout View Model

@Observable
final class WorkoutViewModel {

    // MARK: - State

    var customPlans: [WorkoutPlan] = []
    var recentSessions: [WorkoutSession] = []
    var activeSession: WorkoutSession?
    var isLoading = false
    var timerSeconds = 0
    var timerActive = false

    // Create/Edit plan state
    var showCreatePlan = false
    var planToEdit: WorkoutPlan?

    // AI Generation state
    var showAIGenerate = false
    var isGenerating = false
    var generateError: String?
    var selectedSeedExercises: [Exercise] = []
    var overloadSuggestions: [String: ProgressiveOverloadService.OverloadSuggestion] = [:]

    // MARK: - Dependencies

    private let coreDataService: CoreDataService
    private let firestoreService: FirestoreServiceProtocol
    private let appState: AppState
    private let aiCoachService = AICoachService()
    private var timerTask: Task<Void, Never>?

    private let plansKey = "custom_workout_plans_v1"

    init(
        appState: AppState,
        coreDataService: CoreDataService,
        firestoreService: FirestoreServiceProtocol
    ) {
        self.appState = appState
        self.coreDataService = coreDataService
        self.firestoreService = firestoreService
    }

    // MARK: - Load Plans

    func loadPlans() async {
        isLoading = true
        defer { isLoading = false }

        // Load custom plans from UserDefaults
        if let data = UserDefaults.standard.data(forKey: plansKey),
           let plans = try? JSONDecoder().decode([WorkoutPlan].self, from: data) {
            customPlans = plans.sorted { $0.createdAt > $1.createdAt }
        }

        // Load recent sessions from CoreData
        recentSessions = coreDataService.fetchWorkoutHistory(limit: 10)
    }

    // MARK: - Save / Delete Plans

    func savePlan(_ plan: WorkoutPlan) {
        if let index = customPlans.firstIndex(where: { $0.id == plan.id }) {
            customPlans[index] = plan
        } else {
            customPlans.insert(plan, at: 0)
        }
        persistPlans()
    }

    func deletePlan(id: String) {
        customPlans.removeAll { $0.id == id }
        persistPlans()
    }

    func addExerciseToPlan(planId: String, dayIndex: Int, exercise: PlanExercise) {
        guard let planIdx = customPlans.firstIndex(where: { $0.id == planId }),
              dayIndex < customPlans[planIdx].days.count else { return }
        var ex = exercise
        ex.order = customPlans[planIdx].days[dayIndex].exercises.count + 1
        customPlans[planIdx].days[dayIndex].exercises.append(ex)
        if !customPlans[planIdx].days[dayIndex].muscleGroups.contains(ex.muscleGroup) {
            customPlans[planIdx].days[dayIndex].muscleGroups.append(ex.muscleGroup)
        }
        persistPlans()
    }

    private func persistPlans() {
        if let data = try? JSONEncoder().encode(customPlans) {
            UserDefaults.standard.set(data, forKey: plansKey)
        }
    }

    // MARK: - Start Workout

    func startWorkout(plan: WorkoutPlan, day: WorkoutDay) {
        activeSession = WorkoutSession(from: plan, day: day)
        timerSeconds = 0
        startTimer()
        loadOverloadSuggestions()
        applyOverloadSuggestions()
    }

    // MARK: - Progressive Overload

    func loadOverloadSuggestions() {
        guard let session = activeSession else { return }
        overloadSuggestions = ProgressiveOverloadService.analyze(
            upcomingExercises: session.exerciseLogs,
            recentSessions: recentSessions
        )
    }

    /// Pre-fill sets with recommended values from overload analysis
    private func applyOverloadSuggestions() {
        guard var session = activeSession else { return }

        for (exIdx, log) in session.exerciseLogs.enumerated() {
            if let suggestion = overloadSuggestions[log.exerciseId] {
                for setIdx in session.exerciseLogs[exIdx].sets.indices {
                    session.exerciseLogs[exIdx].sets[setIdx].weightKg = suggestion.recommendedWeightKg
                    session.exerciseLogs[exIdx].sets[setIdx].reps = suggestion.recommendedReps
                }
            }
        }
        activeSession = session
    }

    // MARK: - Timer

    func startTimer() {
        timerActive = true
        timerTask = Task { @MainActor in
            while timerActive {
                try? await Task.sleep(for: .seconds(1))
                if timerActive {
                    timerSeconds += 1
                }
            }
        }
    }

    func stopTimer() {
        timerActive = false
        timerTask?.cancel()
        timerTask = nil
    }

    var formattedTimer: String {
        let minutes = timerSeconds / 60
        let seconds = timerSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Update Set

    func updateSet(exerciseIndex: Int, setIndex: Int, weightKg: Double, reps: Int) {
        guard var session = activeSession else { return }
        guard exerciseIndex < session.exerciseLogs.count,
              setIndex < session.exerciseLogs[exerciseIndex].sets.count else { return }

        session.exerciseLogs[exerciseIndex].sets[setIndex].weightKg = weightKg
        session.exerciseLogs[exerciseIndex].sets[setIndex].reps = reps
        session.exerciseLogs[exerciseIndex].sets[setIndex].isCompleted = true
        activeSession = session
    }

    // MARK: - Complete Workout

    func completeWorkout() async {
        guard var session = activeSession else { return }
        stopTimer()

        session.isCompleted = true
        session.completedAt = Date()
        session.durationSeconds = timerSeconds

        // Save to CoreData
        await coreDataService.saveWorkoutSession(session)

        // Sync to Firestore
        if let uid = appState.currentUser?.uid {
            do {
                try await firestoreService.saveWorkoutSession(session, userId: uid)
            } catch {
                print("[WorkoutVM] Firestore sync failed: \(error.localizedDescription)")
            }
        }

        recentSessions.insert(session, at: 0)
        activeSession = nil
    }

    // MARK: - Discard Workout

    func discardWorkout() {
        stopTimer()
        activeSession = nil
    }

    // MARK: - Daily Reset

    func checkStaleSession() {
        guard let session = activeSession else { return }
        if !Calendar.current.isDate(session.startedAt, inSameDayAs: Date()) {
            discardWorkout()
        }
    }

    // MARK: - Exercise Swap

    func swapExercise(at exerciseIndex: Int, with newExercise: Exercise) {
        guard var session = activeSession,
              exerciseIndex < session.exerciseLogs.count else { return }

        let original = session.exerciseLogs[exerciseIndex]
        let planExercise = PlanExercise(
            id: UUID().uuidString,
            exerciseId: newExercise.id,
            exerciseName: newExercise.name,
            muscleGroup: newExercise.muscleGroup,
            sets: original.sets.count,
            repsRange: "8-12",
            restSeconds: 90,
            order: original.sets.count,
            notes: nil,
            gifUrl: newExercise.gifUrl,
            instructions: newExercise.instructions
        )
        let newLog = ExerciseLog(from: planExercise)
        session.exerciseLogs[exerciseIndex] = newLog
        activeSession = session
    }

    // MARK: - AI Plan Generation

    func generateAIPlan(
        daysPerWeek: Int,
        goal: FitnessGoal,
        difficulty: WorkoutPlan.Difficulty,
        category: WorkoutPlan.Category,
        seedExercises: [Exercise]
    ) async {
        guard let user = appState.currentUser else { return }

        isGenerating = true
        generateError = nil

        let combinedLibrary = WorkoutExerciseLibrary.allExercises + seedExercises
        let exerciseCatalog = combinedLibrary.map { ex in
            "  - id: \"\(ex.id)\", name: \"\(ex.name)\", muscleGroup: \"\(ex.muscleGroup.rawValue)\""
        }.joined(separator: "\n")
        
        let mandatorySeeds = seedExercises.map { $0.name }.joined(separator: ", ")

        let systemPrompt = """
        You are a workout plan generator. Respond with ONLY valid JSON, no markdown, no explanation, no code fences.

        The JSON must match this exact structure:
        {
          "name": "string",
          "description": "string",
          "difficulty": "beginner" | "intermediate" | "advanced",
          "daysPerWeek": number,
          "category": "strength" | "hypertrophy" | "endurance" | "fullBody",
          "estimatedDurationMin": number,
          "days": [
            {
              "dayNumber": number,
              "label": "string",
              "muscleGroups": ["chest" | "back" | "legs" | "shoulders" | "arms" | "core" | "fullBody"],
              "exercises": [
                {
                  "exerciseId": "string (MUST be from the list below)",
                  "exerciseName": "string (MUST match the name from the list)",
                  "muscleGroup": "string (MUST match the muscleGroup from the list)",
                  "sets": number,
                  "repsRange": "string",
                  "restSeconds": number,
                  "order": number,
                  "notes": null
                }
              ]
            }
          ]
        }

        AVAILABLE EXERCISES (you MUST only use these):
        \(exerciseCatalog)

        Rules:
        1. Only use exerciseId values from the list above.
        2. exerciseName and muscleGroup must exactly match the list entry for that exerciseId.
        3. Each day should have 4-6 exercises.
        4. Rest seconds: compound exercises 90-180s, isolation exercises 60-90s.
        5. Generate a creative, descriptive plan name.
        6. \(mandatorySeeds.isEmpty ? "" : "MANDATORY: You MUST include these exercises in the plan: \(mandatorySeeds).")
        """

        let userPrompt = """
        Generate a workout plan:
        - Days per week: \(daysPerWeek)
        - Goal: \(goal.displayName)
        - Difficulty: \(difficulty.rawValue)
        - Category: \(category.displayName)
        - User: \(user.ageYears)yo, \(user.gender.displayName), \(user.weightKg)kg, \(user.heightCm)cm, \(user.activityLevel.displayName)
        """

        do {
            let rawResponse = try await aiCoachService.generateJSON(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt
            )

            // Strip markdown code fences if present
            let cleaned = rawResponse
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let jsonData = cleaned.data(using: .utf8) else {
                isGenerating = false
                generateError = "Failed to process AI response."
                return
            }

            let parsed = try JSONDecoder().decode(AIGeneratedPlan.self, from: jsonData)
            let plan = parsed.toWorkoutPlan(combinedLibrary: combinedLibrary)

            // Validate exercise IDs exist in library
            let validIds = Set(combinedLibrary.map(\.id))
            let invalidIds = plan.days.flatMap(\.exercises).filter { !validIds.contains($0.exerciseId) }

            if !invalidIds.isEmpty {
                isGenerating = false
                generateError = "AI generated invalid exercises. Please try again."
                return
            }

            isGenerating = false
            savePlan(plan)
            showAIGenerate = false

        } catch {
            isGenerating = false
            generateError = "Failed to generate plan: \(error.localizedDescription)"
        }
    }
}

// MARK: - AI Response Parsing

private struct AIGeneratedPlan: Decodable {
    let name: String
    let description: String
    let difficulty: String
    let daysPerWeek: Int
    let category: String
    let estimatedDurationMin: Int
    let days: [AIGeneratedDay]

    struct AIGeneratedDay: Decodable {
        let dayNumber: Int
        let label: String
        let muscleGroups: [String]
        let exercises: [AIGeneratedExercise]
    }

    struct AIGeneratedExercise: Decodable {
        let exerciseId: String
        let exerciseName: String
        let muscleGroup: String
        let sets: Int
        let repsRange: String
        let restSeconds: Int
        let order: Int
        let notes: String?
    }

    func toWorkoutPlan(combinedLibrary: [Exercise]) -> WorkoutPlan {
        let library = combinedLibrary
        return WorkoutPlan(
            id: UUID().uuidString,
            name: name,
            description: description,
            difficulty: WorkoutPlan.Difficulty(rawValue: difficulty) ?? .intermediate,
            daysPerWeek: daysPerWeek,
            isPremium: false,
            category: WorkoutPlan.Category(rawValue: category) ?? .fullBody,
            estimatedDurationMin: estimatedDurationMin,
            days: days.map { day in
                WorkoutDay(
                    id: UUID().uuidString,
                    dayNumber: day.dayNumber,
                    label: day.label,
                    muscleGroups: day.muscleGroups.compactMap { Exercise.MuscleGroup(rawValue: $0) },
                    exercises: day.exercises.map { ex in
                        let libraryExercise = library.first(where: { $0.id == ex.exerciseId })
                        return PlanExercise(
                            id: UUID().uuidString,
                            exerciseId: ex.exerciseId,
                            exerciseName: ex.exerciseName,
                            muscleGroup: Exercise.MuscleGroup(rawValue: ex.muscleGroup) ?? .fullBody,
                            sets: ex.sets,
                            repsRange: ex.repsRange,
                            restSeconds: ex.restSeconds,
                            order: ex.order,
                            notes: ex.notes,
                            gifUrl: libraryExercise?.gifUrl,
                            instructions: libraryExercise?.instructions
                        )
                    }
                )
            },
            createdAt: Date()
        )
    }
}
