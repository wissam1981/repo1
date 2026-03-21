import SwiftUI

// MARK: - Create Workout View (Iron Pulse Redesign)
// Premium interface for building custom workout plans.

struct CreateWorkoutView: View {
    @Environment(\.dismiss) private var dismiss

    let existingPlan: WorkoutPlan?
    let onSave: (WorkoutPlan) -> Void

    @State private var planName: String = ""
    @State private var days: [WorkoutDay] = []
    @State private var showAddExercise = false
    @State private var addExerciseDayIndex: Int = 0

    init(existingPlan: WorkoutPlan?, onSave: @escaping (WorkoutPlan) -> Void) {
        self.existingPlan = existingPlan
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeColors.backgroundDark.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DESIGN")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(ThemeColors.primary)
                                    .tracking(2)
                                Text(existingPlan != nil ? "EDIT ROUTINE" : "NEW ROUTINE")
                                    .font(.system(size: 24, weight: .black))
                                    .foregroundStyle(ThemeColors.textPrimary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Plan Name Input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ROUTINE NAME")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(ThemeColors.textSecondary)
                                .tracking(1)
                            
                            TextField("E.G. PUSH PULL LEGS", text: $planName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(ThemeColors.textPrimary)
                                .padding(16)
                                .background(ThemeColors.surfaceColor)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.surfaceBorder, lineWidth: 1))
                        }
                        .padding(.horizontal, 20)

                        // Days List
                        VStack(spacing: 24) {
                            ForEach(Array(days.enumerated()), id: \.element.id) { dayIndex, day in
                                daySection(day, dayIndex: dayIndex)
                            }
                            
                            // Add Day Button
                            Button {
                                withAnimation(.spring()) {
                                    let newDay = WorkoutDay(
                                        id: UUID().uuidString,
                                        dayNumber: days.count + 1,
                                        label: "Day \(days.count + 1)",
                                        muscleGroups: [],
                                        exercises: []
                                    )
                                    days.append(newDay)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("ADD TRAINING DAY")
                                }
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(ThemeColors.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(RoundedRectangle(cornerRadius: 20).stroke(ThemeColors.primary.opacity(0.3), lineWidth: 2))
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Text("CANCEL")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        savePlan()
                        dismiss()
                    } label: {
                        Text("SAVE")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(ThemeColors.backgroundDark)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(ThemeColors.primary))
                    }
                    .disabled(days.filter{!$0.exercises.isEmpty}.isEmpty && planName.isEmpty)
                }
            }
            .onAppear {
                if let plan = existingPlan {
                    planName = plan.name
                    days = plan.days
                }
            }
            .sheet(isPresented: $showAddExercise) {
                ExerciseSelectionView { planExercise in
                    guard addExerciseDayIndex < days.count else { return }
                    var exercise = planExercise
                    exercise.order = days[addExerciseDayIndex].exercises.count + 1
                    days[addExerciseDayIndex].exercises.append(exercise)
                    if !days[addExerciseDayIndex].muscleGroups.contains(exercise.muscleGroup) {
                        days[addExerciseDayIndex].muscleGroups.append(exercise.muscleGroup)
                    }
                }
            }
        }
    }

    // MARK: - Day Section

    private func daySection(_ day: WorkoutDay, dayIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(ThemeColors.primary)
                
                TextField("DAY NAME", text: Binding(
                    get: { days[dayIndex].label.uppercased() },
                    set: { days[dayIndex].label = $0 }
                ))
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(ThemeColors.textPrimary)

                Spacer()

                Button(role: .destructive) {
                    withAnimation { _ = days.remove(at: dayIndex) }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .padding(8)
                        .background(Circle().fill(ThemeColors.surfaceColor))
                }
            }
            .padding(.horizontal, 20)

            // Exercises
            VStack(spacing: 12) {
                ForEach(Array(day.exercises.enumerated()), id: \.element.id) { exIndex, exercise in
                    exerciseRow(exercise, dayIndex: dayIndex, exIndex: exIndex)
                }
                
                // Add Exercise Button
                Button {
                    addExerciseDayIndex = dayIndex
                    showAddExercise = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("ADD EXERCISE")
                    }
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(ThemeColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(RoundedRectangle(cornerRadius: 14).fill(ThemeColors.primary.opacity(0.05)))
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .background(ThemeColors.surfaceColor)
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: PlanExercise, dayIndex: Int, exIndex: Int) -> some View {
        HStack(spacing: 16) {
            // GIF thumbnail
            ExerciseGifThumbnail(
                gifUrl: exercise.gifUrl,
                muscleGroup: exercise.muscleGroup,
                exerciseName: exercise.exerciseName,
                instructions: exercise.instructions,
                size: 52
            )
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ThemeColors.surfaceBorder, lineWidth: 1))

            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.exerciseName.uppercased())
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(ThemeColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 20) {
                    // Sets
                    HStack(spacing: 8) {
                        Text("SETS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(ThemeColors.textSecondary)
                        
                        Text("\(days[dayIndex].exercises[exIndex].sets)")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(ThemeColors.primary)
                        
                        Stepper("", value: Binding(
                            get: { days[dayIndex].exercises[exIndex].sets },
                            set: { days[dayIndex].exercises[exIndex].sets = $0 }
                        ), in: 1...10)
                        .labelsHidden()
                        .scaleEffect(0.7)
                        .frame(width: 60)
                    }

                    // Reps
                    HStack(spacing: 8) {
                        Text("REPS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(ThemeColors.textSecondary)
                        
                        TextField("8-12", text: Binding(
                            get: { days[dayIndex].exercises[exIndex].repsRange },
                            set: { days[dayIndex].exercises[exIndex].repsRange = $0 }
                        ))
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(ThemeColors.textPrimary)
                        .frame(width: 45)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(ThemeColors.surfaceColor))
                    }
                }
            }

            Spacer()

            Button {
                withAnimation { _ = days[dayIndex].exercises.remove(at: exIndex) }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(ThemeColors.textSecondary)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20).fill(ThemeColors.surfaceColor))
    }

    // MARK: - Save

    private func savePlan() {
        let trimmedName = planName.trimmingCharacters(in: .whitespaces)
        let finalName = trimmedName.isEmpty ? "CUSTOM WORKOUT" : trimmedName.uppercased()

        let plan = WorkoutPlan(
            id: existingPlan?.id ?? UUID().uuidString,
            name: finalName,
            description: "",
            difficulty: .intermediate,
            daysPerWeek: days.count,
            isPremium: false,
            category: .fullBody,
            estimatedDurationMin: 60,
            days: days,
            createdAt: existingPlan?.createdAt ?? Date()
        )
        onSave(plan)
    }
}
