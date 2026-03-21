import SwiftUI

// MARK: - Edit Food Entry View
// Sheet presented when a user taps an existing food log to modify its portion or meal.

struct EditFoodEntryView: View {
    @Bindable var viewModel: NutritionViewModel
    let entry: NutritionEntry
    @Environment(\.dismiss) private var dismiss

    @State private var quantityText: String
    @State private var selectedMeal: MealType

    init(viewModel: NutritionViewModel, entry: NutritionEntry) {
        self.viewModel = viewModel
        self.entry = entry
        
        let initialQty = entry.servingQuantity
        self._quantityText = State(initialValue: initialQty == floor(initialQty) ? "\(Int(initialQty))" : String(format: "%.1f", initialQty))
        self._selectedMeal = State(initialValue: entry.mealType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.foodName)
                            .font(.headline)
                        if let brand = entry.brandName, !brand.isEmpty {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Portion Details")) {
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("Amount", text: $quantityText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(entry.servingUnit)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(header: Text("Meal Type")) {
                    Picker("Meal", selection: $selectedMeal) {
                        ForEach(MealType.allCases, id: \.self) { meal in
                            Label(meal.displayName, systemImage: meal.icon).tag(meal)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    Button(action: saveChanges) {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func saveChanges() {
        guard let newQuantity = Double(quantityText), newQuantity > 0 else { return }
        
        Task {
            await viewModel.updateEntry(entry, newQuantity: newQuantity, newMealType: selectedMeal)
            dismiss()
        }
    }
}
