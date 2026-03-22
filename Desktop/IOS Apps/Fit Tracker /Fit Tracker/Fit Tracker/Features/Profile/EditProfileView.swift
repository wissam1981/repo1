import SwiftUI

// MARK: - Edit Profile View
// Allows user to update body metrics and recalculate targets.

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (UserProfile) -> Void

    @State private var displayName: String
    @State private var gender: Gender
    @State private var dateOfBirth: Date
    @State private var heightCm: Double
    @State private var weightKg: Double
    @State private var activityLevel: ActivityLevel
    @State private var goal: FitnessGoal
    @State private var goalSpeed: Double
    @State private var goalWeightKg: Double
    @State private var hasGoalWeight: Bool

    private var user: UserProfile

    init(user: UserProfile, onSave: @escaping (UserProfile) -> Void) {
        self.user = user
        self.onSave = onSave
        self._displayName = State(initialValue: user.displayName)
        self._gender = State(initialValue: user.gender)
        self._dateOfBirth = State(initialValue: user.dateOfBirth)
        self._heightCm = State(initialValue: user.heightCm)
        self._weightKg = State(initialValue: user.weightKg)
        self._activityLevel = State(initialValue: user.activityLevel)
        self._goal = State(initialValue: user.goal)
        self._goalSpeed = State(initialValue: user.goalSpeedKgPerWeek)
        self._goalWeightKg = State(initialValue: user.goalWeightKg ?? user.weightKg)
        self._hasGoalWeight = State(initialValue: user.goalWeightKg != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal") {
                    TextField("Name", text: $displayName)

                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { g in
                            Text(g.displayName).tag(g)
                        }
                    }

                    DatePicker("Birthday", selection: $dateOfBirth, displayedComponents: .date)
                }

                Section("Body") {
                    HStack {
                        Text("Height")
                        Spacer()
                        Text(String(localized: "\(Int(heightCm)) cm"))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $heightCm, in: 120...230, step: 1)
                        .tint(.cyan)

                    HStack {
                        Text("Weight")
                        Spacer()
                        Text(String(format: "%.1f kg", weightKg))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $weightKg, in: 30...250, step: 0.5)
                        .tint(.cyan)

                    Toggle("Set Goal Weight", isOn: $hasGoalWeight.animation())
                        .tint(.cyan)

                    if hasGoalWeight {
                        HStack {
                            Text("Goal Weight")
                            Spacer()
                            Text(String(format: "%.1f kg", goalWeightKg))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $goalWeightKg, in: 30...250, step: 0.5)
                            .tint(.cyan)
                    }
                }

                Section("Fitness") {
                    Picker("Activity Level", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }

                    Picker("Goal", selection: $goal) {
                        ForEach(FitnessGoal.allCases, id: \.self) { g in
                            Text(g.displayName).tag(g)
                        }
                    }
                    
                    if let message = validationMessage {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.red.opacity(0.1))
                    }
                }

                // New calculated targets preview
                Section("Updated Targets") {
                    let result = FitnessCalculator.calculate(
                        weightKg: weightKg,
                        heightCm: heightCm,
                        dateOfBirth: dateOfBirth,
                        gender: gender,
                        activityLevel: activityLevel,
                        goal: goal,
                        goalSpeedKgPerWeek: goalSpeed
                    )
                    HStack {
                        Text("Calories")
                        Spacer()
                        Text("\(result.targetCalories) kcal")
                            .foregroundStyle(.cyan)
                    }
                    HStack {
                        Text("Protein")
                        Spacer()
                        Text("\(result.targetProteinG)g")
                            .foregroundStyle(.orange)
                    }
                    HStack {
                        Text("Carbs")
                        Spacer()
                        Text("\(result.targetCarbsG)g")
                            .foregroundStyle(.green)
                    }
                    HStack {
                        Text("Fat")
                        Spacer()
                        Text("\(result.targetFatG)g")
                            .foregroundStyle(.purple)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(validationMessage != nil)
                }
            }
        }
    }
    
    private var validationMessage: String? {
        if goal == .maintain || !hasGoalWeight { return nil }
        if goal == .lose && goalWeightKg >= weightKg {
            return "Goal weight must be less than current weight to lose fat."
        } else if goal == .gain && goalWeightKg <= weightKg {
            return "Goal weight must be greater than current weight to build muscle."
        }
        return nil
    }

    private func saveProfile() {
        var updated = user
        updated.displayName = displayName
        updated.gender = gender
        updated.dateOfBirth = dateOfBirth
        updated.heightCm = heightCm
        updated.weightKg = weightKg
        updated.goalWeightKg = hasGoalWeight ? goalWeightKg : nil
        updated.activityLevel = activityLevel
        updated.goal = goal
        updated.goalSpeedKgPerWeek = goalSpeed

        let result = FitnessCalculator.calculate(
            weightKg: weightKg,
            heightCm: heightCm,
            dateOfBirth: dateOfBirth,
            gender: gender,
            activityLevel: activityLevel,
            goal: goal,
            goalSpeedKgPerWeek: goalSpeed
        )
        updated.applyCalculation(result)
        updated.updatedAt = Date()

        onSave(updated)
        dismiss()
    }
}
