import SwiftUI

// MARK: - Exercise Swap Sheet
// Shows 3 alternative exercises for a given exercise, matching muscle group.

struct ExerciseSwapSheet: View {
    let exerciseLog: ExerciseLog
    let currentDayExercises: [PlanExercise]
    let onSwap: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss

    private var alternatives: [Exercise] {
        let placeholder = PlanExercise(
            id: exerciseLog.id,
            exerciseId: exerciseLog.exerciseId,
            exerciseName: exerciseLog.exerciseName,
            muscleGroup: exerciseLog.muscleGroup,
            sets: exerciseLog.sets.count,
            repsRange: "8-12",
            restSeconds: 90,
            order: 0
        )
        return ExerciseSwapService.findSwaps(
            for: placeholder,
            currentDayExercises: currentDayExercises
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(ThemeColors.textSecondary)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ThemeColors.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Swap Exercise")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(ThemeColors.textPrimary)
                        Text(String(localized: "Replace \(exerciseLog.exerciseName)"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
            }

            if alternatives.isEmpty {
                // No alternatives
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundStyle(ThemeColors.textSecondary)
                    Text("No alternatives found for this muscle group")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                // Alternatives list
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(alternatives) { exercise in
                            Button { onSwap(exercise) } label: {
                                HStack(spacing: 14) {
                                    // Equipment icon
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(equipmentColor(exercise.equipment).opacity(0.12))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: equipmentIcon(exercise.equipment))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(equipmentColor(exercise.equipment))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exercise.name)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(ThemeColors.textPrimary)
                                            .lineLimit(1)

                                        HStack(spacing: 8) {
                                            Text(exercise.equipment.displayName)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(equipmentColor(exercise.equipment))
                                            Text("•")
                                                .foregroundStyle(ThemeColors.textSecondary)
                                            Text(exercise.isCompound ? "Compound" : "Isolation")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(ThemeColors.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(ThemeColors.primary)
                                }
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
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(ThemeColors.backgroundDark.ignoresSafeArea())
    }

    // MARK: - Helpers

    private func equipmentIcon(_ equipment: Exercise.Equipment) -> String {
        switch equipment {
        case .bodyweight: return "figure.walk"
        case .dumbbell:   return "dumbbell.fill"
        case .barbell:    return "figure.strengthtraining.traditional"
        case .cable:      return "line.3.crossed.swirl.circle"
        case .machine:    return "gearshape.fill"
        case .kettlebell: return "figure.cross.training"
        }
    }

    private func equipmentColor(_ equipment: Exercise.Equipment) -> Color {
        switch equipment {
        case .bodyweight: return .green
        case .dumbbell:   return .orange
        case .barbell:    return .red
        case .cable:      return .cyan
        case .machine:    return .purple
        case .kettlebell: return .yellow
        }
    }
}
