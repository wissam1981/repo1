import SwiftUI

// MARK: - AI Parsed Meal Sheet
/// Displays AI-parsed food items for review before logging.

struct AIParsedMealSheet: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMeal: MealType
    @State private var editingItemId: String?
    @State private var editGramsText: String = ""
    @FocusState private var gramsFieldFocused: Bool

    init(viewModel: NutritionViewModel) {
        self.viewModel = viewModel
        self._selectedMeal = State(initialValue: viewModel.selectedMealType)
    }

    private var totalCalories: Double {
        viewModel.parsedFoodItems.reduce(0) { $0 + $1.effectiveCalories }
    }

    private var totalProtein: Double {
        viewModel.parsedFoodItems.reduce(0) { $0 + $1.effectiveProtein }
    }

    private var totalCarbs: Double {
        viewModel.parsedFoodItems.reduce(0) { $0 + $1.effectiveCarbs }
    }

    private var totalFat: Double {
        viewModel.parsedFoodItems.reduce(0) { $0 + $1.effectiveFat }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeColors.backgroundDark.ignoresSafeArea()

                VStack(spacing: 0) {
                    List {
                        Section {
                            headerSection
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                .listRowSeparator(.hidden)
                        }

                        Section {
                            ForEach(Array(viewModel.parsedFoodItems.enumerated()), id: \.element.id) { index, item in
                                VStack(spacing: 0) {
                                    parsedItemRow(item, index: index)

                                    // Inline weight editor
                                    if editingItemId == item.id {
                                        weightEditor(for: index, item: item)
                                    }
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { indexSet in
                                viewModel.parsedFoodItems.remove(atOffsets: indexSet)
                                if viewModel.parsedFoodItems.isEmpty { dismiss() }
                            }
                        }

                        Section {
                            mealPickerSection
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 80, trailing: 20))
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)

                    bottomBar
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.parsedFoodItems = []
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ThemeColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.primary, ThemeColors.primary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white) // White on gradient fill - keep
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("AI Meal Breakdown")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
                Text(String(localized: "\(viewModel.parsedFoodItems.count) items found"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
            }

            Spacer()
        }
        .padding(.bottom, 8)
    }

    // MARK: - Item Row

    private func parsedItemRow(_ item: ParsedFoodItem, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if editingItemId == item.id {
                    applyGramsEdit(index: index)
                    editingItemId = nil
                } else {
                    // Save any previous edit
                    if let prevId = editingItemId,
                       let prevIndex = viewModel.parsedFoodItems.firstIndex(where: { $0.id == prevId }) {
                        applyGramsEdit(index: prevIndex)
                    }
                    editingItemId = item.id
                    let grams = item.effectiveGrams
                    editGramsText = grams == floor(grams) ? "\(Int(grams))" : String(format: "%.0f", grams)
                    gramsFieldFocused = true
                }
            }
        } label: {
            HStack(spacing: 14) {
                // Weight badge (tappable)
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(editingItemId == item.id ? ThemeColors.primary.opacity(0.25) : ThemeColors.primary.opacity(0.12))
                        .frame(width: 52, height: 44)
                    VStack(spacing: 1) {
                        Text("\(Int(item.effectiveGrams))")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(ThemeColors.primary)
                        Text("g")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(ThemeColors.primary.opacity(0.6))
                    }
                }

                // Name + macros
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(item.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(ThemeColors.textPrimary)
                            .lineLimit(1)

                        if item.isAIEstimated {
                            HStack(spacing: 3) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 9))
                                Text("AI")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(ThemeColors.primary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(ThemeColors.primary.opacity(0.12))
                            )
                        }
                    }

                    HStack(spacing: 12) {
                        Text("\(Int(item.effectiveProtein))g P")
                        Text("\(Int(item.effectiveCarbs))g C")
                        Text("\(Int(item.effectiveFat))g F")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
                }

                Spacer()

                // Calories
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(item.effectiveCalories))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(ThemeColors.textPrimary)
                    Text("kcal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(ThemeColors.surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(editingItemId == item.id ? ThemeColors.primary.opacity(0.3) : ThemeColors.surfaceBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Weight Editor

    private func weightEditor(for index: Int, item: ParsedFoodItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 14))
                .foregroundStyle(ThemeColors.primary)

            TextField("Grams", text: $editGramsText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ThemeColors.textPrimary)
                .keyboardType(.numberPad)
                .focused($gramsFieldFocused)
                .frame(width: 80)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(ThemeColors.surfaceColor)
                )
                .onSubmit {
                    applyGramsEdit(index: index)
                    editingItemId = nil
                }

            Text("grams")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ThemeColors.textSecondary)

            Spacer()

            Button {
                applyGramsEdit(index: index)
                withAnimation { editingItemId = nil }
            } label: {
                Text("Done")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(ThemeColors.primary))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ThemeColors.primary.opacity(0.06))
        )
        .padding(.top, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func applyGramsEdit(index: Int) {
        guard index < viewModel.parsedFoodItems.count else { return }
        if let grams = Double(editGramsText), grams > 0 {
            viewModel.parsedFoodItems[index].customGrams = grams
        }
        gramsFieldFocused = false
    }

    // MARK: - Meal Picker

    private var mealPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log to")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(ThemeColors.textSecondary)

            HStack(spacing: 10) {
                ForEach(MealType.allCases, id: \.self) { meal in
                    Button {
                        selectedMeal = meal
                    } label: {
                        Text(meal.displayName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(selectedMeal == meal ? .white : ThemeColors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedMeal == meal ? ThemeColors.primary : ThemeColors.surfaceColor)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(ThemeColors.surfaceBorder)
                .frame(height: 1)

            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(ThemeColors.textSecondary)
                        Text(String(localized: "\(Int(totalCalories)) kcal"))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(ThemeColors.textPrimary)
                    }

                    Spacer()

                    HStack(spacing: 16) {
                        macroTotal("P", value: totalProtein, color: .blue)
                        macroTotal("C", value: totalCarbs, color: .orange)
                        macroTotal("F", value: totalFat, color: .red)
                    }
                }

                Button {
                    // Apply any pending edit
                    if let editId = editingItemId,
                       let idx = viewModel.parsedFoodItems.firstIndex(where: { $0.id == editId }) {
                        applyGramsEdit(index: idx)
                    }
                    Task {
                        await viewModel.logAllParsedItems(mealType: selectedMeal)
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text(String(localized: "Log All to \(selectedMeal.displayName)"))
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(ThemeColors.primary)
                            .shadow(color: ThemeColors.primary.opacity(0.3), radius: 10, y: 5)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(ThemeColors.backgroundDark)
        }
    }

    private func macroTotal(_ label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(Int(value))g")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(ThemeColors.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
        }
    }
}
