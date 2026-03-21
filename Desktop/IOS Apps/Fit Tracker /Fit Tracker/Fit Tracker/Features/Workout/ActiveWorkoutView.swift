import SwiftUI

// MARK: - Active Workout View (Iron Pulse Redesign)
// High-intensity training interface with focused exercise tracking.

struct ActiveWorkoutView: View {
    @Bindable var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var swapExerciseIndex: Int?
    @State private var showSwapSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // High-Impact Timer Header
                timerHeader

                // Exercise List
                if let session = viewModel.activeSession {
                    exerciseList(session)
                }

                // Bottom Action
                bottomBar
            }
            .background(ThemeColors.backgroundDark.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        viewModel.discardWorkout()
                        dismiss()
                    } label: {
                        Text("DISCARD")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(viewModel.activeSession?.dayLabel.uppercased() ?? "TRAINING")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(ThemeColors.textPrimary)
                        .tracking(2)
                }
            }
        }
        .sheet(isPresented: $showSwapSheet) {
            if let idx = swapExerciseIndex,
               let session = viewModel.activeSession,
               idx < session.exerciseLogs.count {
                ExerciseSwapSheet(
                    exerciseLog: session.exerciseLogs[idx],
                    currentDayExercises: session.exerciseLogs.map { log in
                        PlanExercise(
                            id: log.id,
                            exerciseId: log.exerciseId,
                            exerciseName: log.exerciseName,
                            muscleGroup: log.muscleGroup,
                            sets: log.sets.count,
                            repsRange: "8-12",
                            restSeconds: 90,
                            order: 0
                        )
                    },
                    onSwap: { newExercise in
                        viewModel.swapExercise(at: idx, with: newExercise)
                        showSwapSheet = false
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Timer Header

    private var timerHeader: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ELITE STATUS")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(ThemeColors.primary)
                        .tracking(2)
                    
                    Text(viewModel.formattedTimer)
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(ThemeColors.textPrimary)
                        .contentTransition(.numericText())
                }
                
                Spacer()
                
                if let session = viewModel.activeSession {
                    let done = session.exerciseLogs.flatMap(\.sets).filter(\.isCompleted).count
                    let total = session.exerciseLogs.flatMap(\.sets).count
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("COMPLETED")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .tracking(1)
                        
                        Text("\(done)/\(total) SETS")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(ThemeColors.primary)
                    }
                }
            }
            .padding(24)
            .background(ThemeColors.surfaceColor)
            
            // Progress Bar
            if let session = viewModel.activeSession {
                let done = session.exerciseLogs.flatMap(\.sets).filter(\.isCompleted).count
                let total = session.exerciseLogs.flatMap(\.sets).count
                let progress = total > 0 ? Double(done) / Double(total) : 0
                
                GeometryReader { geo in
                    Rectangle()
                        .fill(ThemeColors.primary)
                        .frame(width: geo.size.width * progress)
                        .animation(.spring(), value: progress)
                }
                .frame(height: 3)
                .background(ThemeColors.surfaceColor)
            }
        }
    }

    // MARK: - Exercise List

    private func exerciseList(_ session: WorkoutSession) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                ForEach(Array(session.exerciseLogs.enumerated()), id: \.element.id) { exIdx, exerciseLog in
                    exerciseCard(exerciseLog, exerciseIndex: exIdx)
                }
            }
            .padding(20)
            .padding(.top, 10)
        }
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ log: ExerciseLog, exerciseIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise Header
            HStack(spacing: 16) {
                // High-performance animation component
                ExerciseGifThumbnail(
                    gifUrl: log.gifUrl,
                    muscleGroup: log.muscleGroup,
                    exerciseName: log.exerciseName,
                    instructions: log.instructions,
                    size: 52
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColors.surfaceBorder, lineWidth: 1))

                VStack(alignment: .leading, spacing: 2) {
                    Text(log.exerciseName.uppercased())
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(ThemeColors.textPrimary)
                        .lineLimit(1)
                    
                    Text("\(log.muscleGroup.displayName.uppercased()) • \(log.sets.count) SETS")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(ThemeColors.primary.opacity(0.6))
                }

                Spacer()

                // Swap button
                Button {
                    swapExerciseIndex = exerciseIndex
                    showSwapSheet = true
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ThemeColors.primary.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle().fill(ThemeColors.primary.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)

                // Checkmark logic
                let allDone = log.sets.allSatisfy(\.isCompleted)
                Image(systemName: allDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(allDone ? ThemeColors.success : ThemeColors.surfaceBorder)
            }

            // Progressive Overload Badge
            if let suggestion = viewModel.overloadSuggestions[log.exerciseId] {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.orange)
                    Text(suggestion.reason)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                        )
                )
            }

            // Set Tracking Grid
            FlowLayout(spacing: 12) {
                ForEach(Array(log.sets.enumerated()), id: \.element.id) { setIdx, set in
                    Button {
                        viewModel.updateSet(
                            exerciseIndex: exerciseIndex,
                            setIndex: setIdx,
                            weightKg: set.weightKg,
                            reps: set.reps > 0 ? set.reps : 10
                        )
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(setIdx + 1)")
                                .font(.system(size: 14, weight: .black))
                            Text("SET")
                                .font(.system(size: 8, weight: .black))
                                .opacity(0.5)
                        }
                        .frame(width: 54, height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(set.isCompleted ? ThemeColors.success : ThemeColors.surfaceColor)
                        )
                        .foregroundStyle(set.isCompleted ? .white : ThemeColors.textSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(set.isCompleted ? Color.clear : ThemeColors.surfaceBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(ThemeColors.surfaceColor)
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(ThemeColors.surfaceBorder, lineWidth: 1))
        )
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(ThemeColors.surfaceBorder)
            
            Button {
                Task {
                    await viewModel.completeWorkout()
                    dismiss()
                }
            } label: {
                HStack {
                    Text("FINISH TRAINING")
                        .font(.system(size: 14, weight: .black))
                        .tracking(1)
                    Image(systemName: "checkmark.seal.fill")
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(ThemeColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: ThemeColors.primary.opacity(0.3), radius: 10, y: 5)
            }
            .padding(20)
        }
        .background(ThemeColors.backgroundDark)
    }
}

// Simple FlowLayout for sets
struct FlowLayout: View {
    var spacing: CGFloat
    var children: [AnyView]

    init<Data: RandomAccessCollection, Content: View>(
        _ data: Data,
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.spacing = spacing
        self.children = data.map { AnyView(content($0)) }
    }
    
    // Simplification for the sets grid
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> any View) {
        self.spacing = spacing
        // This is a simplification, in a real app you'd use a more robust FlowLayout or LazyVGrid
        self.children = [AnyView(content())] 
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<children.count, id: \.self) { i in
                children[i]
            }
        }
    }
}
