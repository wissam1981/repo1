import SwiftUI

// MARK: - Exercise Selection View (Iron Pulse Redesign)
// API-powered exercise picker backed by ExerciseDB (1500+ exercises).

struct ExerciseSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let onExerciseSelected: ((PlanExercise) -> Void)?
    @Binding var selectedExercises: [Exercise]
    let isMultiSelect: Bool

    @State private var searchText = ""
    @State private var selectedBodyPart: String = "all"
    @State private var exercises: [Exercise] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var hasLoadedOnce = false

    private let service = ExerciseDBService()

    private let bodyParts = [
        "all", "chest", "back", "upper legs", "lower legs",
        "shoulders", "upper arms", "lower arms", "waist", "neck", "cardio"
    ]

    init(onExerciseSelected: ((PlanExercise) -> Void)? = nil, 
         selectedExercises: Binding<[Exercise]> = .constant([]), 
         isMultiSelect: Bool = false) {
        self.onExerciseSelected = onExerciseSelected
        self._selectedExercises = selectedExercises
        self.isMultiSelect = isMultiSelect
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DISCOVER")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(ThemeColors.primary)
                            .tracking(2)
                        Text("EXERCISES")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(ThemeColors.textPrimary)
                    }
                    Spacer()
                    
                    if isMultiSelect {
                        Button { dismiss() } label: {
                            Text("DONE")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(ThemeColors.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().stroke(ThemeColors.primary, lineWidth: 1))
                        }
                    } else {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(ThemeColors.textSecondary)
                        }
                    }
                }
                .padding(20)

                // Search Bar (Custom Industrial Style)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(ThemeColors.textSecondary)
                    TextField("SEARCH 1500+ EXERCISES...", text: $searchText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(ThemeColors.textPrimary)
                        .textInputAutocapitalization(.characters)
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Body part filter chips
                bodyPartChips

                // Content
                Group {
                    if isLoading && exercises.isEmpty {
                        loadingView
                    } else if let error = errorMessage, exercises.isEmpty {
                        errorView(error)
                    } else if exercises.isEmpty && hasLoadedOnce {
                        emptyView
                    } else {
                        exerciseList
                    }
                }
            }
            .background(ThemeColors.backgroundDark.ignoresSafeArea())
            .onChange(of: searchText) { _, newValue in
                debouncedSearch(query: newValue)
            }
            .onChange(of: selectedBodyPart) { _, _ in
                loadExercises()
            }
            .onAppear {
                if !hasLoadedOnce { loadExercises() }
            }
        }
    }

    // MARK: - Body Part Chips

    private var bodyPartChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(bodyParts, id: \.self) { part in
                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            selectedBodyPart = part
                            searchText = ""
                        }
                    } label: {
                        Text(part.uppercased())
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(selectedBodyPart == part ? ThemeColors.backgroundDark : ThemeColors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(
                                    selectedBodyPart == part ? ThemeColors.primary : ThemeColors.surfaceColor
                                )
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                let groupedExercises = Dictionary(grouping: exercises) { $0.subCategory ?? "Other" }
                let sortedCategories = groupedExercises.keys.sorted()

                ForEach(sortedCategories, id: \.self) { category in
                    if let groupExercises = groupedExercises[category], !groupExercises.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.uppercased())
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(ThemeColors.primary)
                                .tracking(1)
                                .padding(.horizontal, 4)

                            ForEach(groupExercises, id: \.id) { exercise in
                                ExerciseAPIRow(
                                    exercise: exercise,
                                    isSelected: selectedExercises.contains(where: { $0.id == exercise.id })
                                ) {
                                    if isMultiSelect {
                                        if let index = selectedExercises.firstIndex(where: { $0.id == exercise.id }) {
                                            selectedExercises.remove(at: index)
                                        } else {
                                            selectedExercises.append(exercise)
                                        }
                                    } else if let onSelect = onExerciseSelected {
                                        let planExercise = PlanExercise(
                                            id: UUID().uuidString,
                                            exerciseId: exercise.id,
                                            exerciseName: exercise.name,
                                            muscleGroup: exercise.muscleGroup,
                                            subCategory: exercise.subCategory,
                                            sets: 3,
                                            repsRange: "8-12",
                                            restSeconds: 90,
                                            order: 99,
                                            notes: nil,
                                            gifUrl: exercise.gifUrl,
                                            instructions: exercise.instructions
                                        )
                                        onSelect(planExercise)
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                }

                if isLoading {
                    ProgressView().tint(ThemeColors.primary).padding()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .tint(ThemeColors.primary)
                .scaleEffect(1.5)
            Text("CALIBRATING ENGINE...")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(ThemeColors.textSecondary)
                .tracking(2)
            Spacer()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(ThemeColors.primary.opacity(0.5))
            Text(message.uppercased())
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(ThemeColors.textSecondary)
                .multilineTextAlignment(.center)

            Button("USE OFFLINE LIBRARY") {
                exercises = WorkoutExerciseLibrary.allExercises
                errorMessage = nil
                hasLoadedOnce = true
            }
            .font(.system(size: 13, weight: .black))
            .foregroundStyle(ThemeColors.primary)
            
            Spacer()
        }
        .padding(40)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(ThemeColors.textSecondary)
            Text("NO MATCHES FOUND")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(ThemeColors.textSecondary)
            Spacer()
        }
    }

    // MARK: - Data Loading

    private func loadExercises() {
        searchTask?.cancel()
        searchTask = Task {
            isLoading = true
            errorMessage = nil
            do {
                exercises = selectedBodyPart == "all" ? try await service.browseExercises() : try await service.exercisesByBodyPart(selectedBodyPart)
                hasLoadedOnce = true
            } catch {
                if !Task.isCancelled { errorMessage = error.localizedDescription }
            }
            if !Task.isCancelled { isLoading = false }
        }
    }

    private func debouncedSearch(query: String) {
        searchTask?.cancel()
        guard !query.isEmpty else { loadExercises(); return }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            isLoading = true
            do {
                exercises = try await service.searchExercises(query: query)
                hasLoadedOnce = true
            } catch {
                if !Task.isCancelled { errorMessage = error.localizedDescription }
            }
            if !Task.isCancelled { isLoading = false }
        }
    }
}

// MARK: - Exercise Row with GIF (Iron Pulse)

private struct ExerciseAPIRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // High-performance animation component
                ExerciseGifThumbnail(
                    gifUrl: exercise.gifUrl,
                    muscleGroup: exercise.muscleGroup,
                    exerciseName: exercise.name,
                    instructions: exercise.instructions,
                    size: 60
                )
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(ThemeColors.surfaceBorder, lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name.uppercased())
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(isSelected ? ThemeColors.primary : ThemeColors.textPrimary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text(exercise.muscleGroup.displayName.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(isSelected ? ThemeColors.primary : ThemeColors.primary.opacity(0.6))
                        
                        Text("•")
                            .foregroundStyle(ThemeColors.textSecondary)

                        Text(exercise.equipment.displayName.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(isSelected ? .white : ThemeColors.primary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(isSelected ? ThemeColors.primary : ThemeColors.primary.opacity(0.1)))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? ThemeColors.primary.opacity(0.05) : ThemeColors.surfaceColor)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? ThemeColors.primary.opacity(0.3) : ThemeColors.surfaceBorder, lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}
