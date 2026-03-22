import Foundation

// MARK: - Progressive Overload Service
// Analyzes workout session history and suggests weight/rep increases.

struct ProgressiveOverloadService {

    // MARK: - Suggestion Model

    struct OverloadSuggestion {
        let exerciseId: String
        let exerciseName: String
        let recommendedWeightKg: Double
        let recommendedReps: Int
        let reason: String
        let previousWeightKg: Double
        let previousReps: Int
    }

    // MARK: - Analyze History

    /// Analyzes recent sessions and returns overload suggestions for exercises in the upcoming workout
    static func analyze(
        upcomingExercises: [ExerciseLog],
        recentSessions: [WorkoutSession]
    ) -> [String: OverloadSuggestion] {
        var suggestions: [String: OverloadSuggestion] = [:]

        for exercise in upcomingExercises {
            if let suggestion = analyzeExercise(
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                recentSessions: recentSessions
            ) {
                suggestions[exercise.exerciseId] = suggestion
            }
        }

        return suggestions
    }

    // MARK: - Single Exercise Analysis

    private static func analyzeExercise(
        exerciseId: String,
        exerciseName: String,
        recentSessions: [WorkoutSession]
    ) -> OverloadSuggestion? {

        // Find the last 5 sessions that included this exercise
        let pastLogs: [(weight: Double, reps: Int, date: Date)] = recentSessions
            .compactMap { session in
                guard let log = session.exerciseLogs.first(where: { $0.exerciseId == exerciseId }) else {
                    return nil
                }
                // Get the heaviest completed set
                let completedSets = log.sets.filter(\.isCompleted)
                guard let best = completedSets.max(by: { $0.weightKg < $1.weightKg }) else {
                    return nil
                }
                return (weight: best.weightKg, reps: best.reps, date: session.startedAt)
            }
            .prefix(5)
            .map { $0 }

        guard pastLogs.count >= 2 else { return nil }

        let latestWeight = pastLogs[0].weight
        let latestReps = pastLogs[0].reps

        // Skip if no weight was logged
        guard latestWeight > 0 else { return nil }

        // Check if user completed same weight 2+ times → suggest weight increase
        let sameWeightCount = pastLogs.filter { $0.weight == latestWeight }.count

        if sameWeightCount >= 2 && latestReps >= 8 {
            // Suggest weight increase
            let increment = latestWeight >= 60 ? 2.5 : (latestWeight >= 20 ? 2.0 : 1.0)
            let newWeight = latestWeight + increment

            return OverloadSuggestion(
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                recommendedWeightKg: newWeight,
                recommendedReps: max(latestReps - 2, 6), // Slightly fewer reps at higher weight
                reason: "You've done \(formatWeight(latestWeight)) × \(latestReps) for \(sameWeightCount) sessions — try \(formatWeight(newWeight))!",
                previousWeightKg: latestWeight,
                previousReps: latestReps
            )
        }

        // Check if reps are increasing → suggest weight increase
        if pastLogs.count >= 3 {
            let repsTrend = pastLogs.prefix(3).map(\.reps)
            let isIncreasing = repsTrend[0] > repsTrend[1] && repsTrend[1] >= repsTrend[2]

            if isIncreasing && latestReps >= 12 {
                let increment = latestWeight >= 60 ? 2.5 : (latestWeight >= 20 ? 2.0 : 1.0)
                let newWeight = latestWeight + increment

                return OverloadSuggestion(
                    exerciseId: exerciseId,
                    exerciseName: exerciseName,
                    recommendedWeightKg: newWeight,
                    recommendedReps: 8,
                    reason: "Your reps are trending up — time to add weight! Try \(formatWeight(newWeight)).",
                    previousWeightKg: latestWeight,
                    previousReps: latestReps
                )
            }
        }

        // Default: suggest same weight but try for +1 rep
        if latestReps < 12 {
            return OverloadSuggestion(
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                recommendedWeightKg: latestWeight,
                recommendedReps: latestReps + 1,
                reason: "Last time: \(formatWeight(latestWeight)) × \(latestReps). Aim for \(latestReps + 1) reps!",
                previousWeightKg: latestWeight,
                previousReps: latestReps
            )
        }

        return nil
    }

    // MARK: - Helpers

    private static func formatWeight(_ kg: Double) -> String {
        kg.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(kg))kg"
            : String(format: "%.1fkg", kg)
    }
}
