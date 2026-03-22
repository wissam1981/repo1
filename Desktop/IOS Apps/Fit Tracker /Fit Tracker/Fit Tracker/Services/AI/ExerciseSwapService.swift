import Foundation

// MARK: - Exercise Swap Service
// Finds same-muscle-group alternatives from the exercise library.
// Filters out exercises already in the current day's plan, ranks by equipment variety.

struct ExerciseSwapService {

    /// Returns up to 3 alternative exercises for the given exercise
    static func findSwaps(
        for exercise: PlanExercise,
        currentDayExercises: [PlanExercise],
        library: [Exercise] = WorkoutExerciseLibrary.allExercises
    ) -> [Exercise] {
        let currentIds = Set(currentDayExercises.map(\.exerciseId))

        // Find same-muscle-group exercises, excluding current ones
        let candidates = library.filter { ex in
            ex.muscleGroup == exercise.muscleGroup &&
            !currentIds.contains(ex.id)
        }

        // Rank by equipment preference:
        // 1. Bodyweight (always accessible)
        // 2. Dumbbell (most gyms have these)
        // 3. Cable
        // 4. Machine
        // 5. Barbell
        // 6. Kettlebell
        let ranked = candidates.sorted { a, b in
            equipmentScore(a.equipment) < equipmentScore(b.equipment)
        }

        return Array(ranked.prefix(3))
    }

    /// Converts an Exercise to a PlanExercise for insertion into a plan
    static func toPlanExercise(_ exercise: Exercise, replacing original: PlanExercise) -> PlanExercise {
        PlanExercise(
            id: UUID().uuidString,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            muscleGroup: exercise.muscleGroup,
            subCategory: exercise.subCategory,
            sets: original.sets,
            repsRange: original.repsRange,
            restSeconds: original.restSeconds,
            order: original.order,
            notes: nil,
            gifUrl: exercise.gifUrl,
            instructions: exercise.instructions
        )
    }

    // MARK: - Equipment Scoring

    private static func equipmentScore(_ equipment: Exercise.Equipment) -> Int {
        switch equipment {
        case .bodyweight:  return 0
        case .dumbbell:    return 1
        case .cable:       return 2
        case .machine:     return 3
        case .barbell:     return 4
        case .kettlebell:  return 5
        }
    }
}
